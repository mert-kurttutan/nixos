# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  inputs,
  pkgs,
  homeDirectory,
  ...
}:

{
  imports = [
    ./modules
    inputs.cecc-linux.nixosModules.default
  ];
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.11"; # Did you read the comment?

  environment.sessionVariables = {
    CUDA_PATH = "${pkgs.cudatoolkit}";
    PROTON_PASS_LINUX_KEYRING = "dbus";
    # Proton Pass SSH-agent socket for Git/OpenSSH sessions.
    SSH_AUTH_SOCK = "${homeDirectory}/.ssh/proton-pass-agent.sock";
  };

  # systemd.additionalUpstreamSystemUnits = [ "debug-shell.service" ];

}
