{ user, ... }:

{
  # Define a user account. Don't forget to set a password with `passwd`.
  users.users.${user} = {
    isNormalUser = true;
    description = "Mert Kurttutan";
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "kvm"
    ];
  };
}
