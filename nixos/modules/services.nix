{ user, ... }:

{
  services.excalibur-control-center = {
    enable = true;
    users = [ user ];
  };

  services.vnstat.enable = true;
  services.geoclue2.enable = true;
  services.envfs.enable = true;

  # TODO: revisit; cpupower-gui 1.0.0 crashes on boot under Python 3.14 argparse.
  services.cpupower-gui.enable = false;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable SSH access for remote terminal sessions.
  # Access is intended to be through the private Tailscale network; do not
  # configure router port forwarding for SSH.
  services.openssh = {
    enable = true;
    openFirewall = false;
  };
  services.tailscale.enable = true;
}
