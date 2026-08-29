{ config, pkgs, ... }:

{
  hardware.cpu.intel.updateMicrocode = true;

  # Enable NVIDIA proprietary drivers.
  hardware.nvidia = {
    # Use open source kernel modules for newer GPUs.
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;

    # Choose appropriate driver version.
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # hardware.nvidia.prime = {
  #   # sync.enable = true;
  #   offload = {
  #     enable = true;
  #     enableOffloadCmd = true;
  #   };
  #   # dedicated
  #   intelBusId = "PCI:0:2:0";
  #   nvidiaBusId = "PCI:1:0:0";
  # };

  services.udev.extraRules = ''
    SUBSYSTEM=="pci", ATTR{power/control}="auto"
  '';

  # Mesa application-specific driver defaults.
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

  # environment.sessionVariables = {
  #   # LIBVA_DRIVER_NAME = "nvidia";
  #   # LIBVA_DRIVER_NAME = "nvidia";
  #   # GBM_BACKEND = "nvidia-drm";
  #   # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  #   NVD_BACKEND = "direct";
  # };
}
