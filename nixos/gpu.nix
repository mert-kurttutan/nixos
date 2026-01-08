{ pkgs, ... }:

{
  services.xserver.videoDrivers = [ "modesetting" ]; # modesetting didn't help
  # boot.blacklistedKernelModules = [ "nouveau" ];  # bbswitch

  # boot.kernelParams = [ "acpi_rev_override=5" "i915.enable_guc=2" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelParams = [ "i915.force_probe=a788" ];
  hardware.graphics = {
    enable = true;
    # driSupport = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      # vpl-gpu-rt
      # vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      # vaapiVdpau
      # libvdpau-va-gl
    ];
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  # Nvidia version mapping
  # use 580 or above as this solves the suspend/resume problem of nvidia
  # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
  #   version = "580.65.06";
  #   sha256_64bit = "sha256-BLEIZ69YXnZc+/3POe1fS9ESN1vrqwFy6qGHxqpQJP8=";
  #   sha256_aarch64 = "sha256-4CrNwNINSlQapQJr/dsbm0/GvGSuOwT/nLnIknAM+cQ=";
  #   openSha256 = "sha256-BKe6LQ1ZSrHUOSoV6UCksUE0+TIa0WcCHZv4lagfIgA=";
  #   settingsSha256 = "sha256-9PWmj9qG/Ms8Ol5vLQD3Dlhuw4iaFtVHNC0hSyMCU24=";
  #   persistencedSha256 = "sha256-ETRfj2/kPbKYX1NzE0dGr/ulMuzbICIpceXdCRDkAxA=";
  # };

}
