{
  imports = [
    ../../configuration.nix
    ./hardware-configuration.nix
    ./boot.nix
    ./gpu.nix
    ./hardware.nix
  ];

  networking.hostName = "excalibur";

  specialisation = {
    hybrid.configuration.imports = [ ./nvidia-hybrid.nix ];
    discrete.configuration.imports = [ ./nvidia-discrete.nix ];
  };
}
