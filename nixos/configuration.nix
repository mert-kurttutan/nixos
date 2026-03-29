# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  ...
}:

let
  casperWmi = config.boot.kernelPackages.callPackage ./pkgs/casper-wmi { };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./gpu.nix
  ];
  hardware.cpu.intel.updateMicrocode = true;
  hardware.nvidia = {
    # Use open source kernel modules for newer GPUs
    open = true;

    # modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;

    # Choose appropriate driver version
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };
  # services.openssh = {
  #   enable = true;
  #   settings = {
  #     PermitRootLogin = "no";
  #    PasswordAuthentication = false;
  #    PubkeyAuthentication = true;
  #    Port = 2222;
  #    };
  #   allowSFTP = true;
  # };
  programs.nix-ld.enable = true;

  # networking.firewall.allowedTCPPorts = [ 2222 8080 ];

  # Enable NVIDIA proprietary drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.prime = {
    # sync.enable = true;
    # offload = {
    #   enable = true;
    #   # enableOffloadCmd = true;
    # };
    # dedicated
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
  boot.kernelPackages = pkgs.linuxPackages;
  boot.extraModulePackages = [ casperWmi ];
  boot.kernelModules = [ "casper-wmi" ];
  # Bootloader.
  boot.kernelParams = [
    "intel_idle.max_cstate=1"
    "acpi_backlight=native"
    "nvidia-drm.modeset=0"
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

  services.udev.extraRules = ''
    SUBSYSTEM=="pci", ATTR{power/control}="auto"
  '';
  services.tlp.enable = true;
  services.tlp.settings = {
      # CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_performance";
  };
  services.power-profiles-daemon.enable = false;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.vnstat.enable = true;
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  networking.hosts = {
    "127.0.0.2" = [ "other-localhost" ];
  };
  # Set your time zone.
  time.timeZone = "Europe/Istanbul";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  services.geoclue2.enable = true;
  services.cpupower-gui.enable = true;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "tr_TR.UTF-8";
    LC_IDENTIFICATION = "tr_TR.UTF-8";
    LC_MEASUREMENT = "tr_TR.UTF-8";
    LC_MONETARY = "tr_TR.UTF-8";
    LC_NAME = "tr_TR.UTF-8";
    LC_NUMERIC = "tr_TR.UTF-8";
    LC_PAPER = "tr_TR.UTF-8";
    LC_TELEPHONE = "tr_TR.UTF-8";
    LC_TIME = "tr_TR.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Enable the COSMIC login manager, COSMIC desktop environment
  # services.displayManager.cosmic-greeter.enable = true;
  # services.desktopManager.cosmic.enable = true;

  # KDE Plasma 6
  # services.desktopManager.plasma6.enable = true;
  # services.displayManager.sddm.enable = true;
  # services.displayManager.sddm.wayland.enable = true;

  services.flatpak.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "tr";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "trq";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    # media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.kmert = {
    isNormalUser = true;
    description = "Mert Kurttutan";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
  programs.steam = {
    enable = true;
  };
  # Install firefox.
  programs.firefox = {
    enable = true;
    preferences = {
      # Disable problematic GPU features
      "layers.acceleration.force-enabled" = false;
      "gfx.webrender.enabled" = false;
      "media.ffmpeg.vaapi.enabled" = false;

      # Or alternatively, use software rendering during power changes
      "gfx.canvas.accelerated" = false;
      "layers.gpu-process.enabled" = false;
    };
  };
  programs.chromium = {
    enable = true;
  };
  # Create a wrapped Firefox that sets the environment variable
  nixpkgs.overlays = [
    (self: super: {
      firefox = super.firefox.overrideAttrs (oldAttrs: {
        buildCommand = (oldAttrs.buildCommand or "") + ''
          wrapProgram $out/bin/firefox \
            --set __NV_DISABLE_EXPLICIT_SYNC 1
        '';
      });
    })
  ];

  # In configuration.nix
  nixpkgs.config.packageOverrides = pkgs: {
    mesa = pkgs.mesa.overrideAttrs (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        cat > $out/share/drirc.d/00-mesa-defaults.conf <<EOF
        <?xml version="1.0" standalone="yes"?>
        <driconf>
          <device>
            <application name="Brave Browser" executable="brave">
              <option name="adaptive_sync" value="false" />
              <option name="no_fp16" value="true" />
            </application>
          </device>
        </driconf>
        EOF
      '';
    });
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    s-tui
    stress
    pkgs.home-manager
    gparted
    devenv
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    brightnessctl
    lshw
    pciutils
    mesa-demos
    xorg-server
    dmidecode
    linuxKernel.packages.linux_zen.turbostat
    linuxKernel.packages.linux_zen.cpupower
    sysbench
  ];

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_DISABLE_RDD_SANDBOX = "1";
    # LIBVA_DRIVER_NAME = "nvidia";
    # LIBVA_DRIVER_NAME = "nvidia";
    # GBM_BACKEND = "nvidia-drm";
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      # dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
    };
  };

  # virtualisation.docker = {
  #   enable = true;
  #   # Customize Docker daemon settings using the daemon.settings option
  #   # daemon.settings = {
  #   #   dns = [ "1.1.1.1" "8.8.8.8" ];
  #   #   log-driver = "journald";
  #   #   registry-mirrors = [ "https://mirror.gcr.io" ];
  #   #   storage-driver = "overlay2";
  #   # };
  #   # Use the rootless mode - run Docker daemon as non-root user
  #   rootless = {
  #     enable = true;
  #     setSocketVariable = true;
  #   };
  # };
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    iosevka
  ];
  fonts.fontconfig = {
    defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "Iosevka" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # networking.firewall = {
  #   enable = true;
  #   allowedTCPPorts = [ 8080 ];
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  # systemd.additionalUpstreamSystemUnits = [ "debug-shell.service" ];

}
