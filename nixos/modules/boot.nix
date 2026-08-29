{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages;

  boot.kernelParams = [
    # Needed to prevent freezing due to hardware issues on 13th gen Intel CPUs.
    "intel_idle.max_cstate=1"
    "acpi_backlight=native"
    # "nvidia-drm.modeset=0"
    "nvidia-drm.fbdev=1"
    # "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    # "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    # "initcall_blacklist=simpledrm_platform_driver_init"
  ];

  boot.kernel.sysctl = {
    "vm.dirty_writeback_centisecs" = 1500;
    "kernel.nmi_watchdog" = 0;
  };

  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=1
  '';

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
