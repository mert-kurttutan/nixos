{ pkgs, ... }:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Do not forget to add an editor to edit configuration.nix.
    # The Nano editor is also installed by default.
    s-tui
    stress
    pkgs.home-manager
    gparted
    devenv
    vim
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
}
