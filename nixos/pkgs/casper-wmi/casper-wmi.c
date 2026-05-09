// SPDX-License-Identifier: GPL-2.0-or-later
#include <linux/acpi.h>
#include <linux/bitfield.h>
#include <linux/bitops.h>
#include <linux/bits.h>
#include <linux/cleanup.h>
#include <linux/container_of.h>
#include <linux/device.h>
#include <linux/dmi.h>
#include <linux/err.h>
#include <linux/hwmon.h>
#include <linux/kernel.h>
#include <linux/leds.h>
#include <linux/led-class-multicolor.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/mutex_types.h>
#include <linux/platform_profile.h>
#include <linux/slab.h>
#include <linux/sysfs.h>
#include <linux/types.h>
#include <linux/wmi.h>

#include <asm/cpu_device_id.h>
#include <asm/intel-family.h>

#define CASPER_WMI_GUID "644C5791-B7B0-4123-A90B-E93876E0DAAD"

#define CASPER_READ 0xfa00
#define CASPER_WRITE 0xfb00
#define CASPER_GET_HARDWAREINFO 0x0200
#define CASPER_SET_LED 0x0100
#define CASPER_POWERPLAN 0x0300

#define CASPER_KEYBOARD_LED_1 0x03
#define CASPER_KEYBOARD_LED_2 0x04
#define CASPER_KEYBOARD_LED_3 0x05
#define CASPER_ALL_KEYBOARD_LEDS 0x06
#define CASPER_CORNER_LEDS 0x07

#define CASPER_LED_COUNT 4

static const char * const zone_names[CASPER_LED_COUNT] = {
	"casper:rgb:kbd_zoned_backlight-right",
	"casper:rgb:kbd_zoned_backlight-middle",
	"casper:rgb:kbd_zoned_backlight-left",
	"casper:rgb:biaslight",
};

#define CASPER_LED_ALPHA GENMASK(31, 24)
#define CASPER_LED_RED	 GENMASK(23, 16)
#define CASPER_LED_GREEN GENMASK(15, 8)
#define CASPER_LED_BLUE  GENMASK(7, 0)

#define CASPER_DEFAULT_COLOR (CASPER_LED_RED | CASPER_LED_GREEN | \
			      CASPER_LED_BLUE)
#define CASPER_FAN_CPU 0
#define CASPER_FAN_GPU 1

enum casper_power_profile_old {
	CASPER_HIGH_PERFORMANCE = 1,
	CASPER_GAMING		= 2,
	CASPER_TEXT_MODE	= 3,
	CASPER_POWERSAVE	= 4,
};

enum casper_power_profile_new {
	CASPER_NEW_HIGH_PERFORMANCE	= 0,
	CASPER_NEW_GAMING		= 1,
	CASPER_NEW_AUDIO		= 2,
};

struct casper_quirk_entry {
	bool big_endian_fans;
	bool no_power_profiles;
	bool new_power_scheme;
	bool debug_mailbox;
	bool separate_effective_state;
};

struct casper_fourzone_led {
	struct led_classdev_mc mc_led;
	struct mc_subled subleds[3];
};

struct casper_wmi_args {
	u16 a0, a1;
	u32 a2, a3, a4, a5, a6, a7, a8;
};

struct casper_debug_state {
	u16 query_cmd;
	struct casper_wmi_args query_result;
	u16 write_cmd;
	u32 write_a2;
	u32 write_a3;
};

struct casper_drv {
	struct mutex mutex;
	struct casper_fourzone_led *leds;
	struct wmi_device *wdev;
	struct casper_quirk_entry quirk;
	struct casper_debug_state debug;
};

enum casper_led_mode {
	LED_NORMAL = 0x10,
	LED_BLINK = 0x20,
	LED_FADE = 0x30,
	LED_HEARTBEAT = 0x40,
	LED_REPEAT = 0x50,
	LED_RANDOM = 0x60,
};

static const char *casper_linux_profile_name(enum platform_profile_option profile)
{
	switch (profile) {
	case PLATFORM_PROFILE_LOW_POWER:
		return "low-power";
	case PLATFORM_PROFILE_BALANCED:
		return "balanced";
	case PLATFORM_PROFILE_BALANCED_PERFORMANCE:
		return "balanced-performance";
	case PLATFORM_PROFILE_PERFORMANCE:
		return "performance";
	default:
		return "unknown";
	}
}

static const char *casper_fw_profile_name(struct casper_drv *drv, u32 value)
{
	if (drv->quirk.new_power_scheme) {
		switch (value) {
		case CASPER_NEW_HIGH_PERFORMANCE:
			return "new-high-performance";
		case CASPER_NEW_GAMING:
			return "new-gaming";
		case CASPER_NEW_AUDIO:
			return "new-audio";
		default:
			return "new-unknown";
		}
	}

	switch (value) {
	case CASPER_HIGH_PERFORMANCE:
		return "high-performance";
	case CASPER_GAMING:
		return "gaming";
	case CASPER_TEXT_MODE:
		return "text-mode";
	case CASPER_POWERSAVE:
		return "powersave";
	default:
		return "old-unknown";
	}
}

static int casper_query(struct casper_drv *drv, u16 a1,
			struct casper_wmi_args *out);
static int casper_set(struct casper_drv *drv, u16 a1, u8 led_id, u32 data);
static int casper_get_powerplan(struct casper_drv *drv, u32 *value);
static int casper_set_powerplan(struct casper_drv *drv, u32 value);
static int casper_get_hardwareinfo(struct casper_drv *drv,
				   struct casper_wmi_args *info);
static int casper_collect_state(struct casper_drv *drv,
				struct casper_wmi_args *powerplan,
				struct casper_wmi_args *hardwareinfo);

static void casper_debug_dump_hardwareinfo(struct device *dev,
					   struct casper_drv *drv,
					   const char *context)
{
	struct casper_wmi_args info = { 0 };
	int ret;

	ret = casper_get_hardwareinfo(drv, &info);
	if (ret) {
		dev_warn(dev,
			 "casper-wmi: %s hardwareinfo query failed, err=%d\n",
			 context, ret);
		return;
	}

	dev_info(dev,
		 "casper-wmi: %s hardwareinfo a2=%u a3=%u a4=%u a5=%u a6=%u a7=%u a8=%u\n",
		 context, info.a2, info.a3, info.a4, info.a5,
		 info.a6, info.a7, info.a8);
}

static ssize_t raw_powerplan_show(struct device *dev,
				  struct device_attribute *attr, char *buf)
{
	struct casper_drv *drv = dev_get_drvdata(dev);
	u32 value;
	int ret;

	ret = casper_get_powerplan(drv, &value);
	if (ret)
		return ret;

	return sysfs_emit(buf, "fw=%u name=%s\n",
			  value, casper_fw_profile_name(drv, value));
}

static ssize_t raw_powerplan_store(struct device *dev,
				   struct device_attribute *attr,
				   const char *buf, size_t count)
{
	struct casper_drv *drv = dev_get_drvdata(dev);
	struct casper_wmi_args readback = { 0 };
	u32 value;
	int ret;

	ret = kstrtou32(buf, 0, &value);
	if (ret)
		return ret;

	dev_info(dev, "casper-wmi: raw_powerplan write firmware=%s (%u)\n",
		 casper_fw_profile_name(drv, value), value);

	ret = casper_set_powerplan(drv, value);
	if (ret)
		return ret;

	ret = casper_query(drv, CASPER_POWERPLAN, &readback);
	if (ret)
		return ret;

	dev_info(dev, "casper-wmi: raw_powerplan readback firmware=%s (%u)\n",
		 casper_fw_profile_name(drv, readback.a2), readback.a2);
	casper_debug_dump_hardwareinfo(dev, drv, "after raw_powerplan write");
	return count;
}

static ssize_t raw_hardwareinfo_show(struct device *dev,
				     struct device_attribute *attr, char *buf)
{
	struct casper_drv *drv = dev_get_drvdata(dev);
	struct casper_wmi_args info = { 0 };
	int ret;

	ret = casper_get_hardwareinfo(drv, &info);
	if (ret)
		return ret;

	return sysfs_emit(buf,
			  "a2=%u a3=%u a4=%u a5=%u a6=%u a7=%u a8=%u\n",
			  info.a2, info.a3, info.a4, info.a5,
			  info.a6, info.a7, info.a8);
}

static ssize_t query_cmd_show(struct device *dev,
			      struct device_attribute *attr, char *buf)
{
	struct casper_drv *drv = dev_get_drvdata(dev);

	return sysfs_emit(buf, "0x%04x\n", drv->debug.query_cmd);
}

static ssize_t query_cmd_store(struct device *dev, struct device_attribute *attr,
			       const char *buf, size_t count)
{
	struct casper_drv *drv = dev_get_drvdata(dev);
	unsigned int cmd;
	int ret;

	ret = kstrtouint(buf, 0, &cmd);
	if (ret)
		return ret;

	drv->debug.query_cmd = cmd;
	ret = casper_query(drv, drv->debug.query_cmd, &drv->debug.query_result);
	if (ret)
		return ret;

	return count;
}

static ssize_t query_result_show(struct device *dev,
				 struct device_attribute *attr, char *buf)
{
	struct casper_drv *drv = dev_get_drvdata(dev);
	struct casper_wmi_args *out = &drv->debug.query_result;

	return sysfs_emit(buf,
			  "cmd=0x%04x a2=%u a3=%u a4=%u a5=%u a6=%u a7=%u a8=%u\n",
			  drv->debug.query_cmd, out->a2, out->a3, out->a4,
			  out->a5, out->a6, out->a7, out->a8);
}

static ssize_t write_cmd_show(struct device *dev,
			      struct device_attribute *attr, char *buf)
{
	struct casper_drv *drv = dev_get_drvdata(dev);

	return sysfs_emit(buf, "0x%04x\n", drv->debug.write_cmd);
}

static ssize_t write_cmd_store(struct device *dev, struct device_attribute *attr,
			       const char *buf, size_t count)
{
	struct casper_drv *drv = dev_get_drvdata(dev);
	unsigned int cmd;
	int ret;

	ret = kstrtouint(buf, 0, &cmd);
	if (ret)
		return ret;

	drv->debug.write_cmd = cmd;
	return count;
}

static ssize_t write_a2_show(struct device *dev,
			     struct device_attribute *attr, char *buf)
{
	struct casper_drv *drv = dev_get_drvdata(dev);

	return sysfs_emit(buf, "0x%08x\n", drv->debug.write_a2);
}

static ssize_t write_a2_store(struct device *dev, struct device_attribute *attr,
			      const char *buf, size_t count)
{
	struct casper_drv *drv = dev_get_drvdata(dev);
	int ret;

	ret = kstrtou32(buf, 0, &drv->debug.write_a2);
	if (ret)
		return ret;

	return count;
}

static ssize_t write_a3_show(struct device *dev,
			     struct device_attribute *attr, char *buf)
{
	struct casper_drv *drv = dev_get_drvdata(dev);

	return sysfs_emit(buf, "0x%08x\n", drv->debug.write_a3);
}

static ssize_t write_a3_store(struct device *dev, struct device_attribute *attr,
			      const char *buf, size_t count)
{
	struct casper_drv *drv = dev_get_drvdata(dev);
	int ret;

	ret = kstrtou32(buf, 0, &drv->debug.write_a3);
	if (ret)
		return ret;

	return count;
}

static ssize_t write_commit_store(struct device *dev,
				  struct device_attribute *attr,
				  const char *buf, size_t count)
{
	struct casper_drv *drv = dev_get_drvdata(dev);
	struct casper_wmi_args readback = { 0 };
	bool commit;
	int ret;

	ret = kstrtobool(buf, &commit);
	if (ret)
		return ret;
	if (!commit)
		return count;

	ret = casper_set(drv, drv->debug.write_cmd, drv->debug.write_a2,
			 drv->debug.write_a3);
	if (ret)
		return ret;

	ret = casper_query(drv, drv->debug.write_cmd, &readback);
	if (!ret)
		drv->debug.query_result = readback;

	dev_info(dev,
		 "casper-wmi: write_commit cmd=0x%04x a2=0x%08x a3=0x%08x query_ret=%d\n",
		 drv->debug.write_cmd, drv->debug.write_a2,
		 drv->debug.write_a3, ret);
	casper_debug_dump_hardwareinfo(dev, drv, "after write_commit");
	return count;
}

static ssize_t state_snapshot_show(struct device *dev,
				   struct device_attribute *attr, char *buf)
{
	struct casper_drv *drv = dev_get_drvdata(dev);
	struct casper_wmi_args plan = { 0 };
	struct casper_wmi_args info = { 0 };
	int ret;

	ret = casper_collect_state(drv, &plan, &info);
	if (ret)
		return ret;

	return sysfs_emit(buf,
			  "powerplan=%u powerplan_name=%s hardwareinfo a2=%u a3=%u a4=%u a5=%u a6=%u a7=%u a8=%u separate_effective_state=%d\n",
			  plan.a2, casper_fw_profile_name(drv, plan.a2),
			  info.a2, info.a3, info.a4, info.a5, info.a6,
			  info.a7, info.a8, drv->quirk.separate_effective_state);
}

static DEVICE_ATTR_RW(raw_powerplan);
static DEVICE_ATTR_RO(raw_hardwareinfo);
static DEVICE_ATTR_RW(query_cmd);
static DEVICE_ATTR_RO(query_result);
static DEVICE_ATTR_RW(write_cmd);
static DEVICE_ATTR_RW(write_a2);
static DEVICE_ATTR_RW(write_a3);
static DEVICE_ATTR_WO(write_commit);
static DEVICE_ATTR_RO(state_snapshot);

static struct attribute *casper_debug_attrs[] = {
	&dev_attr_raw_powerplan.attr,
	&dev_attr_raw_hardwareinfo.attr,
	&dev_attr_query_cmd.attr,
	&dev_attr_query_result.attr,
	&dev_attr_write_cmd.attr,
	&dev_attr_write_a2.attr,
	&dev_attr_write_a3.attr,
	&dev_attr_write_commit.attr,
	&dev_attr_state_snapshot.attr,
	NULL,
};

static const struct attribute_group casper_debug_attr_group = {
	.name = "debug",
	.attrs = casper_debug_attrs,
};

static int casper_set(struct casper_drv *drv, u16 a1, u8 led_id, u32 data)
{
	struct casper_wmi_args wmi_args;
	struct acpi_buffer input;
	acpi_status status;

	wmi_args = (struct casper_wmi_args) {
		.a0 = CASPER_WRITE,
		.a1 = a1,
		.a2 = led_id,
		.a3 = data
	};

	input = (struct acpi_buffer) {
		(acpi_size) sizeof(struct casper_wmi_args),
		&wmi_args
	};

	guard(mutex)(&drv->mutex);

	status = wmidev_block_set(drv->wdev, 0, &input);
	if (ACPI_FAILURE(status))
		return -EIO;

	return 0;
}

static int casper_query(struct casper_drv *drv, u16 a1,
			struct casper_wmi_args *out)
{
	struct casper_wmi_args wmi_args;
	struct acpi_buffer input;
	union acpi_object *obj;
	acpi_status status;
	int ret = 0;

	wmi_args = (struct casper_wmi_args) {
		.a0 = CASPER_READ,
		.a1 = a1
	};
	input = (struct acpi_buffer) {
		(acpi_size) sizeof(struct casper_wmi_args),
		&wmi_args
	};

	guard(mutex)(&drv->mutex);

	status = wmidev_block_set(drv->wdev, 0, &input);
	if (ACPI_FAILURE(status))
		return -EIO;

	obj = wmidev_block_query(drv->wdev, 0);
	if (!obj)
		return -EIO;

	if (obj->type != ACPI_TYPE_BUFFER) { // obj will be 0x10 on failure
		ret = -EINVAL;
		goto freeobj;
	}
	if (obj->buffer.length != sizeof(struct casper_wmi_args)) {
		ret = -EIO;
		goto freeobj;
	}

	memcpy(out, obj->buffer.pointer, sizeof(struct casper_wmi_args));

freeobj:
	kfree(obj);
	return ret;
}

static int casper_get_powerplan(struct casper_drv *drv, u32 *value)
{
	struct casper_wmi_args plan = { 0 };
	int ret;

	ret = casper_query(drv, CASPER_POWERPLAN, &plan);
	if (ret)
		return ret;

	*value = plan.a2;
	return 0;
}

static int casper_set_powerplan(struct casper_drv *drv, u32 value)
{
	return casper_set(drv, CASPER_POWERPLAN, value, 0);
}

static int casper_get_hardwareinfo(struct casper_drv *drv,
				   struct casper_wmi_args *info)
{
	return casper_query(drv, CASPER_GET_HARDWAREINFO, info);
}

static int casper_collect_state(struct casper_drv *drv,
				struct casper_wmi_args *powerplan,
				struct casper_wmi_args *hardwareinfo)
{
	int ret;

	ret = casper_query(drv, CASPER_POWERPLAN, powerplan);
	if (ret)
		return ret;

	return casper_get_hardwareinfo(drv, hardwareinfo);
}

static u32 get_zone_color(struct casper_fourzone_led z)
{
	return  FIELD_PREP(CASPER_LED_RED, z.subleds[0].intensity) |
		FIELD_PREP(CASPER_LED_GREEN, z.subleds[1].intensity) |
		FIELD_PREP(CASPER_LED_BLUE, z.subleds[2].intensity);
}

static enum led_brightness get_casper_brightness(struct led_classdev *led_cdev)
{
	struct casper_drv *drv = dev_get_drvdata(led_cdev->dev->parent);
	struct casper_wmi_args hardware_alpha = {0};

	if (strcmp(led_cdev->name, zone_names[3]) == 0)
		return drv->leds[3].mc_led.led_cdev.brightness;

	casper_query(drv, CASPER_GET_HARDWAREINFO, &hardware_alpha);

	return hardware_alpha.a6;
}

static void set_casper_brightness(struct led_classdev *led_cdev,
				  enum led_brightness brightness)
{
	u32 led_data, led_data_no_alpha;
	struct casper_drv *drv;
	u8 zone_to_change;
	size_t zone;

	drv = dev_get_drvdata(led_cdev->dev->parent);

	for (size_t i = 0; i < CASPER_LED_COUNT; i++)
		if (strcmp(led_cdev->name, zone_names[i]) == 0)
			zone = i;
	if (zone == 3)
		zone_to_change = CASPER_CORNER_LEDS;
	else
		zone_to_change = zone + CASPER_KEYBOARD_LED_1;

	led_data_no_alpha = get_zone_color(drv->leds[zone]) & ~CASPER_LED_ALPHA;

	if (brightness == drv->leds[zone].mc_led.led_cdev.brightness)
		brightness = get_casper_brightness(&drv->leds[zone].mc_led.led_cdev);

	led_data = FIELD_PREP(CASPER_LED_ALPHA, brightness | LED_NORMAL) | led_data_no_alpha;
	casper_set(drv, CASPER_SET_LED, zone_to_change, led_data);
}

/*
 * On newer machines such as the G911, the remembered profile selected through
 * CASPER_POWERPLAN appears to be distinct from the effective AC/DC vendor
 * state. Windows snapshots show the same selected profile can land in
 * different effective states depending on power source, so keep the Linux
 * mapping stable here and investigate the effective state through debug sysfs.
 */
static int casper_platform_profile_probe(void *drvdata, unsigned long *choices)
{
	struct casper_drv *drv = drvdata;

	set_bit(PLATFORM_PROFILE_LOW_POWER, choices);
	set_bit(PLATFORM_PROFILE_BALANCED, choices);
	if (!drv->quirk.new_power_scheme)
		set_bit(PLATFORM_PROFILE_BALANCED_PERFORMANCE, choices);
	set_bit(PLATFORM_PROFILE_PERFORMANCE, choices);

	return 0;
}

static int casper_platform_profile_get(struct device *dev, enum platform_profile_option *profile)
{
	struct casper_drv *drv = dev_get_drvdata(dev);
	struct casper_wmi_args ret_buff = {0};
	int ret;

	ret = casper_query(drv, CASPER_POWERPLAN, &ret_buff);
	if (ret)
		return ret;

	if (drv->quirk.new_power_scheme) {
		switch (ret_buff.a2) {
		case CASPER_NEW_HIGH_PERFORMANCE:
			*profile = PLATFORM_PROFILE_PERFORMANCE;
			break;
		case CASPER_NEW_GAMING:
			*profile = PLATFORM_PROFILE_BALANCED;
			break;
		case CASPER_NEW_AUDIO:
			*profile = PLATFORM_PROFILE_LOW_POWER;
			break;
		default:
			dev_warn(dev, "casper-wmi: unknown new firmware power profile value=%u\n",
				 ret_buff.a2);
			return -EINVAL;
		}
		dev_info(dev, "casper-wmi: get platform_profile=%s from firmware=%s (%u)\n",
			 casper_linux_profile_name(*profile),
			 casper_fw_profile_name(drv, ret_buff.a2), ret_buff.a2);
		return 0;
	}

	switch (ret_buff.a2) {
	case CASPER_HIGH_PERFORMANCE:
		*profile = PLATFORM_PROFILE_PERFORMANCE;
		break;
	case CASPER_GAMING:
		*profile = PLATFORM_PROFILE_BALANCED_PERFORMANCE;
		break;
	case CASPER_TEXT_MODE:
		*profile = PLATFORM_PROFILE_BALANCED;
		break;
	case CASPER_POWERSAVE:
		*profile = PLATFORM_PROFILE_LOW_POWER;
		break;
	default:
		dev_warn(dev, "casper-wmi: unknown old firmware power profile value=%u\n",
			 ret_buff.a2);
		return -EINVAL;
	}

	dev_info(dev, "casper-wmi: get platform_profile=%s from firmware=%s (%u)\n",
		 casper_linux_profile_name(*profile),
		 casper_fw_profile_name(drv, ret_buff.a2), ret_buff.a2);
	return 0;
}

static int casper_platform_profile_set(struct device *dev, enum platform_profile_option profile)
{
	struct casper_drv *drv = dev_get_drvdata(dev);
	struct casper_wmi_args readback = { 0 };
	enum casper_power_profile_old prf_old;
	enum casper_power_profile_new prf_new;
	int ret;

	if (drv->quirk.new_power_scheme) {

		switch (profile) {
		case PLATFORM_PROFILE_PERFORMANCE:
			prf_new = CASPER_NEW_HIGH_PERFORMANCE;
			break;
		case PLATFORM_PROFILE_BALANCED:
			prf_new = CASPER_NEW_GAMING;
			break;
		case PLATFORM_PROFILE_LOW_POWER:
			prf_new = CASPER_NEW_AUDIO;
			break;
		default:
			return -EINVAL;
		}

		dev_info(dev,
			 "casper-wmi: set platform_profile=%s -> firmware=%s (%u)\n",
			 casper_linux_profile_name(profile),
			 casper_fw_profile_name(drv, prf_new), prf_new);
		ret = casper_set_powerplan(drv, prf_new);
		if (ret)
			dev_warn(dev,
				 "casper-wmi: failed to set platform_profile=%s, err=%d\n",
				 casper_linux_profile_name(profile), ret);
		else {
			ret = casper_query(drv, CASPER_POWERPLAN, &readback);
			if (ret)
				dev_warn(dev,
					 "casper-wmi: failed to read back power plan after set, err=%d\n",
					 ret);
			else
				dev_info(dev,
					 "casper-wmi: readback platform_profile=%s firmware=%s (%u)\n",
					 casper_linux_profile_name(profile),
					 casper_fw_profile_name(drv, readback.a2),
					 readback.a2);
			casper_debug_dump_hardwareinfo(dev, drv, "after profile set");
			ret = 0;
		}
		return ret;
	}

	switch (profile) {
	case PLATFORM_PROFILE_PERFORMANCE:
		prf_old = CASPER_HIGH_PERFORMANCE;
		break;
	case PLATFORM_PROFILE_BALANCED_PERFORMANCE:
		prf_old = CASPER_GAMING;
		break;
	case PLATFORM_PROFILE_BALANCED:
		prf_old = CASPER_TEXT_MODE;
		break;
	case PLATFORM_PROFILE_LOW_POWER:
		prf_old = CASPER_POWERSAVE;
		break;
	default:
		return -EINVAL;
	}

	dev_info(dev, "casper-wmi: set platform_profile=%s -> firmware=%s (%u)\n",
		 casper_linux_profile_name(profile),
		 casper_fw_profile_name(drv, prf_old), prf_old);
	ret = casper_set_powerplan(drv, prf_old);
	if (ret)
		dev_warn(dev,
			 "casper-wmi: failed to set platform_profile=%s, err=%d\n",
			 casper_linux_profile_name(profile), ret);
	else {
		ret = casper_query(drv, CASPER_POWERPLAN, &readback);
		if (ret)
			dev_warn(dev,
				 "casper-wmi: failed to read back power plan after set, err=%d\n",
				 ret);
		else
			dev_info(dev,
				 "casper-wmi: readback platform_profile=%s firmware=%s (%u)\n",
				 casper_linux_profile_name(profile),
				 casper_fw_profile_name(drv, readback.a2),
				 readback.a2);
		casper_debug_dump_hardwareinfo(dev, drv, "after profile set");
		ret = 0;
	}
	return ret;
}

static umode_t casper_wmi_hwmon_is_visible(const void *drvdata,
					   enum hwmon_sensor_types type,
					   u32 attr, int channel)
{
	return 0444;
}

static int casper_wmi_hwmon_read(struct device *dev,
				 enum hwmon_sensor_types type, u32 attr,
				 int channel, long *val)
{
	struct casper_drv *drv = dev_get_drvdata(dev->parent);
	struct casper_wmi_args out = { 0 };
	int ret;

	ret = casper_query(drv, CASPER_GET_HARDWAREINFO, &out);
	if (ret)
		return ret;

	switch (channel) {
	case CASPER_FAN_CPU:
			if (drv->quirk.big_endian_fans)
				*val = be16_to_cpu(*(__be16 *)&out.a4);
			else
				*val = out.a4;
			break;
	case CASPER_FAN_GPU:
			if (drv->quirk.big_endian_fans)
				*val = be16_to_cpu(*(__be16 *)&out.a5);
			else
				*val = out.a5;
		break;
	}

	return 0;
}

static int casper_wmi_hwmon_read_string(struct device *dev,
					enum hwmon_sensor_types type, u32 attr,
					int channel, const char **str)
{
	if (channel == CASPER_FAN_CPU)
		*str = "cpu_fan_speed";
	else if (channel == CASPER_FAN_GPU)
		*str = "gpu_fan_speed";
	return 0;
}

static const struct hwmon_ops casper_wmi_hwmon_ops = {
	.is_visible = &casper_wmi_hwmon_is_visible,
	.read = &casper_wmi_hwmon_read,
	.read_string = &casper_wmi_hwmon_read_string,
};

static const struct hwmon_channel_info *const casper_wmi_hwmon_info[] = {
	HWMON_CHANNEL_INFO(fan,
			   HWMON_F_INPUT | HWMON_F_LABEL,
			   HWMON_F_INPUT | HWMON_F_LABEL),
	NULL
};

static const struct hwmon_chip_info casper_wmi_hwmon_chip_info = {
	.ops = &casper_wmi_hwmon_ops,
	.info = casper_wmi_hwmon_info,
};

static struct casper_quirk_entry gen_older_than_11 = {
	.big_endian_fans = true,
	.new_power_scheme = false,
};

static struct casper_quirk_entry gen_newer_than_11 = {
	.big_endian_fans = false,
	.new_power_scheme = true,
};

static const struct x86_cpu_id casper_gen[] = {
	X86_MATCH_VFM(INTEL_KABYLAKE, &gen_older_than_11),
	X86_MATCH_VFM(INTEL_COMETLAKE, &gen_older_than_11),
	X86_MATCH_VFM(INTEL_TIGERLAKE, &gen_newer_than_11),
	X86_MATCH_VFM(INTEL_ALDERLAKE, &gen_newer_than_11),
	X86_MATCH_VFM(INTEL_RAPTORLAKE, &gen_newer_than_11),
	X86_MATCH_VFM(INTEL_METEORLAKE, &gen_newer_than_11),
	X86_MATCH_VFM(INTEL_RAPTORLAKE_S, &gen_newer_than_11),
	{}
};

static struct casper_quirk_entry quirk_no_power_profile = {
	.no_power_profiles = true,
};

static struct casper_quirk_entry quirk_has_power_profile = {
	.no_power_profiles = false,
};

static struct casper_quirk_entry quirk_g911 = {
	.no_power_profiles = false,
	.debug_mailbox = true,
	.separate_effective_state = true,
};

static const struct dmi_system_id casper_quirks[] = {
	{
		.ident = "CASPER EXCALIBUR G650",
		.matches = {
			DMI_MATCH(DMI_SYS_VENDOR,
				  "CASPER BILGISAYAR SISTEMLERI"),
			DMI_MATCH(DMI_PRODUCT_NAME, "EXCALIBUR G650")
		},
		.driver_data = &quirk_no_power_profile
	},
	{
		.ident = "CASPER EXCALIBUR G670",
		.matches = {
			DMI_MATCH(DMI_SYS_VENDOR,
				  "CASPER BILGISAYAR SISTEMLERI"),
			DMI_MATCH(DMI_PRODUCT_NAME, "EXCALIBUR G670")
		},
		.driver_data = &quirk_no_power_profile
	},
	{
		.ident = "CASPER EXCALIBUR G750",
		.matches = {
			DMI_MATCH(DMI_SYS_VENDOR,
				  "CASPER BILGISAYAR SISTEMLERI"),
			DMI_MATCH(DMI_PRODUCT_NAME, "EXCALIBUR G750")
		},
		.driver_data = &quirk_no_power_profile
	},
	{
		.ident = "CASPER EXCALIBUR G770",
		.matches = {
			DMI_MATCH(DMI_SYS_VENDOR,
				  "CASPER BILGISAYAR SISTEMLERI"),
			DMI_MATCH(DMI_PRODUCT_NAME, "EXCALIBUR G770")
		},
		.driver_data = &quirk_has_power_profile
	},
	{
		.ident = "CASPER EXCALIBUR G780",
		.matches = {
			DMI_MATCH(DMI_SYS_VENDOR,
				  "CASPER BILGISAYAR SISTEMLERI"),
			DMI_MATCH(DMI_PRODUCT_NAME, "EXCALIBUR G780")
		},
		.driver_data = &quirk_has_power_profile
	},
	{
		.ident = "CASPER EXCALIBUR G870",
		.matches = {
			DMI_MATCH(DMI_SYS_VENDOR,
				  "CASPER BILGISAYAR SISTEMLERI"),
			DMI_MATCH(DMI_PRODUCT_NAME, "EXCALIBUR G870")
		},
		.driver_data = &quirk_has_power_profile
	},
	{
		.ident = "CASPER EXCALIBUR G900",
		.matches = {
			DMI_MATCH(DMI_SYS_VENDOR,
				  "CASPER BILGISAYAR SISTEMLERI"),
			DMI_MATCH(DMI_PRODUCT_NAME, "EXCALIBUR G900")
		},
		.driver_data = &quirk_has_power_profile
	},
	{
		.ident = "CASPER EXCALIBUR G911",
		.matches = {
			DMI_MATCH(DMI_SYS_VENDOR,
				  "CASPER BILGISAYAR SISTEMLERI"),
			DMI_MATCH(DMI_PRODUCT_NAME, "EXCALIBUR G911")
		},
		.driver_data = &quirk_g911
	},
	{ }
};




static const struct platform_profile_ops casper_platform_profile_ops = {
	.probe = casper_platform_profile_probe,
	.profile_get = casper_platform_profile_get,
	.profile_set = casper_platform_profile_set,
};

static int casper_platform_profile_register(struct casper_drv *drv)
{
	struct device *ppdev;
	ppdev = devm_platform_profile_register(&drv->wdev->dev, "casper-wmi", drv, &casper_platform_profile_ops);
	return PTR_ERR_OR_ZERO(ppdev);
}

static int casper_multicolor_register(struct casper_drv *drv)
{
	int ret = 0;

	drv->leds = devm_kcalloc(&drv->wdev->dev,
		CASPER_LED_COUNT, sizeof(*drv->leds), GFP_KERNEL);
	if (!drv->leds)
		return -ENOMEM;

	for (size_t i = 0; i < CASPER_LED_COUNT; i++) {
		for (size_t j = 0; j < 3; j++) {
			drv->leds[i].subleds[j] = (struct mc_subled) {
				.color_index = LED_COLOR_ID_RED + j,
				.brightness = 255,
				.intensity = 255
			};
		}
		drv->leds[i].mc_led = (struct led_classdev_mc){
			.led_cdev = {
				.name = zone_names[i],
				.brightness = 0,
				.max_brightness = 2,
				.brightness_set = &set_casper_brightness,
				.brightness_get = &get_casper_brightness,
				.color = LED_COLOR_ID_MULTI,
			},
			.num_colors = 3,
			.subled_info = drv->leds[i].subleds
		};

		ret = devm_led_classdev_multicolor_register(&drv->wdev->dev,
							&drv->leds[i].mc_led);
		if (ret)
			return -ENODEV;
	}

	// Setting leds to the default color
	ret = casper_set(drv, CASPER_SET_LED, CASPER_ALL_KEYBOARD_LEDS,
			 CASPER_DEFAULT_COLOR);
	if (ret)
		return ret;

	ret = casper_set(drv, CASPER_SET_LED, CASPER_CORNER_LEDS,
			 CASPER_DEFAULT_COLOR);
	return ret;
}

static int casper_wmi_probe(struct wmi_device *wdev, const void *context)
{
	const struct casper_quirk_entry *model_quirk;
	const struct dmi_system_id *dmi_id;
	const struct x86_cpu_id *gen_id;
	struct device *hwmon_dev;
	struct casper_drv *drv;
	int ret;

	drv = devm_kzalloc(&wdev->dev, sizeof(*drv), GFP_KERNEL);
	if (!drv)
		return -ENOMEM;

	drv->wdev = wdev;
	dev_set_drvdata(&wdev->dev, drv);

	gen_id = x86_match_cpu(casper_gen);
	if (!gen_id)
		return -ENODEV;

	drv->quirk = *(const struct casper_quirk_entry *)gen_id->driver_data;

	dmi_id = dmi_first_match(casper_quirks);
	if (!dmi_id)
		return -ENODEV;

	model_quirk = dmi_id->driver_data;
	drv->quirk.no_power_profiles = model_quirk->no_power_profiles;
	drv->quirk.debug_mailbox = model_quirk->debug_mailbox;
	drv->quirk.separate_effective_state = model_quirk->separate_effective_state;

	ret = devm_mutex_init(&wdev->dev, &drv->mutex);
	if (ret)
		return ret;

	dev_info(&wdev->dev,
		 "casper-wmi: detected model=%s, new_power_scheme=%d, no_power_profiles=%d, separate_effective_state=%d\n",
		 dmi_id->ident, drv->quirk.new_power_scheme,
		 drv->quirk.no_power_profiles, drv->quirk.separate_effective_state);
	casper_debug_dump_hardwareinfo(&wdev->dev, drv, "probe");

	if (drv->quirk.debug_mailbox) {
		ret = devm_device_add_group(&wdev->dev, &casper_debug_attr_group);
		if (ret)
			return ret;
	}

	ret = casper_multicolor_register(drv);
	if (ret)
		return ret;

	hwmon_dev = devm_hwmon_device_register_with_info(&wdev->dev,
						"casper_wmi", wdev,
						&casper_wmi_hwmon_chip_info,
						NULL);
	if (IS_ERR(hwmon_dev))
		return PTR_ERR(hwmon_dev);

	if (!drv->quirk.no_power_profiles) {
		ret = casper_platform_profile_register(drv);
		if (ret)
			return ret;
	}

	return 0;
}

static const struct wmi_device_id casper_wmi_id_table[] = {
	{ CASPER_WMI_GUID, NULL },
	{ }
};
MODULE_DEVICE_TABLE(wmi, casper_wmi_id_table);

static struct wmi_driver casper_drv = {
	.driver = {
		.name = "casper-wmi",
	},
	.id_table = casper_wmi_id_table,
	.probe = casper_wmi_probe,
	.no_singleton = true,
};

module_wmi_driver(casper_drv);

MODULE_AUTHOR("Mustafa Ekşi <mustafa.eskieksi@gmail.com>");
MODULE_DESCRIPTION("Casper Excalibur Laptop WMI driver");
MODULE_LICENSE("GPL");
