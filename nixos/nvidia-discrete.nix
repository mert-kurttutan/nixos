{ lib, ... }:

{
  hardware.nvidia.prime = {
    offload = {
      enable = lib.mkForce false;
      enableOffloadCmd = lib.mkForce false;
    };
    sync.enable = lib.mkForce false;
    intelBusId = lib.mkForce "PCI:0:2:0";
    nvidiaBusId = lib.mkForce "PCI:1:0:0";
  };

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };
}
