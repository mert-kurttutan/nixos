{ pkgs, ... }:

{
  programs.steam.enable = true;

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };

    containers.enable = true;
    podman = {
      enable = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # virtualisation.docker = {
  #   enable = true;
  #   # Customize Docker daemon settings using the daemon.settings option.
  #   # daemon.settings = {
  #   #   dns = [ "1.1.1.1" "8.8.8.8" ];
  #   #   log-driver = "journald";
  #   #   registry-mirrors = [ "https://mirror.gcr.io" ];
  #   #   storage-driver = "overlay2";
  #   # };
  #   # Use rootless mode and run Docker daemon as non-root user.
  #   rootless = {
  #     enable = true;
  #     setSocketVariable = true;
  #   };
  # };
}
