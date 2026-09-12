#!/usr/bin/env nu

# Install Nix and the shared user-wide tools for a standard GitHub Codespace.
# Run scripts/install-nushell.sh first from Bash.
def main [] {
  let tools_flake = "github:mert-kurttutan/nixos?dir=codespace"
  let daemon_nix = "/nix/var/nix/profiles/default/bin/nix"
  let user_nix = $"($env.HOME)/.nix-profile/bin/nix"
  let nix_installed = (which nix | is-not-empty) or ($daemon_nix | path exists) or ($user_nix | path exists)

  if not $nix_installed {
    let installer = (mktemp)
    print "Installing single-user Nix..."
    ^curl --fail --location --show-error https://nixos.org/nix/install -o $installer
    ^sh $installer --no-daemon
    rm $installer
  } else {
    print "Nix is already installed."
  }

  let nix = if ($daemon_nix | path exists) {
    $daemon_nix
  } else if ($user_nix | path exists) {
    $user_nix
  } else {
    "nix"
  }

  let nix_config_dir = ($env.HOME | path join ".config" "nix")
  let nix_config = ($nix_config_dir | path join "nix.conf")
  mkdir $nix_config_dir
  let existing_config = if ($nix_config | path exists) { open $nix_config } else { "" }
  if not ($existing_config | str contains "experimental-features") {
    "experimental-features = nix-command flakes\n" | save --append $nix_config
  }

  print "Installing shared tools from the nixos-conf Codespace flake..."
  ^$nix --extra-experimental-features "nix-command flakes" profile add --priority 4 $"($tools_flake)#userTools"

  let profile_bin = ($env.HOME | path join ".nix-profile" "bin")
  let nu_config_dir = $nu.default-config-dir
  let nu_config = ($nu_config_dir | path join "config.nu")
  mkdir $nu_config_dir
  let existing_nu_config = if ($nu_config | path exists) { open $nu_config } else { "" }
  let path_config = $"path add \"($profile_bin)\"\n"
  if not ($existing_nu_config | str contains $profile_bin) {
    $path_config | save --append $nu_config
  }

  print "Codespace user environment is ready."
}
