{ user, ... }:

{
  services.excalibur-control-center = {
    enable = true;
    users = [ user ];
  };

  services.vnstat.enable = true;
  services.geoclue2.enable = true;

  # TODO: revisit; cpupower-gui 1.0.0 crashes on boot under Python 3.14 argparse.
  services.cpupower-gui.enable = false;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  services.tailscale.enable = true;
}
