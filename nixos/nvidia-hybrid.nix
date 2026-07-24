{ lib, ... }:

{
  hardware.nvidia.prime = {
    offload = {
      enable = lib.mkForce true;
      enableOffloadCmd = lib.mkForce true;
    };
    sync.enable = lib.mkForce false;
    intelBusId = lib.mkForce "PCI:0:2:0";
    nvidiaBusId = lib.mkForce "PCI:1:0:0";
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
