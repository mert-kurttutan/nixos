#!/usr/bin/env nu

# Install Nix and the shared user-wide tools for a remote Linux VM.
# Run scripts/install-nushell.sh first from Bash.
# Keep project-specific LD_LIBRARY_PATH scoped to project commands. Nix and
# the bootstrap tools must use the host's normal dynamic-library search path.
def ensure-line [file: path, line: string] {
  let existing = if ($file | path exists) { open --raw $file } else { "" }
  if not ($existing | str contains $line) {
    $"($line)\n" | save --append $file
  }
}

export def main [
  --preserve-project-environment # Keep the inherited project environment.
] {
  if not $preserve_project_environment {
    hide-env LD_LIBRARY_PATH
  }

  let tools_flake = "github:mert-kurttutan/nixos?dir=nixos/common"
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

  print "Installing shared tools from the nixos-conf common flake..."
  ^$nix --extra-experimental-features "nix-command flakes" profile add --priority 4 $"($tools_flake)#userTools"

  print "Installing remote dotfiles..."
  ^curl --fail --location --show-error https://raw.githubusercontent.com/mert-kurttutan/nixos/main/scripts/install-dotfiles-remote.nu
    | ^nu -c 'source /dev/stdin; main'

  print "Installing Codex skills..."
  let repo_url = ($env.NIXOS_CONF_REPO_URL? | default "https://github.com/mert-kurttutan/nixos.git")
  let repo_ref = ($env.NIXOS_CONF_REPO_REF? | default "main")
  let tmp_dir = (mktemp --directory)
  let repo_dir = ($tmp_dir | path join "nixos-conf")

  try {
    ^git clone --depth 1 --branch $repo_ref $repo_url $repo_dir
    ^nu ($repo_dir | path join "scripts" "install-codex-skills.nu")
  } catch {|err|
    rm --recursive --force $tmp_dir
    error make { msg: $err.msg }
  }

  rm --recursive --force $tmp_dir

  let profile_bin = ($env.HOME | path join ".nix-profile" "bin")
  let nu_config_dir = $nu.default-config-dir
  let nu_config = ($nu_config_dir | path join "config.nu")
  let nu_env = ($nu_config_dir | path join "env.nu")
  mkdir $nu_config_dir
  let legacy_path = $"path add \"($profile_bin)\""
  if ($nu_config | path exists) {
    let existing_nu_config = (open --raw $nu_config)
    if ($existing_nu_config | str contains $legacy_path) {
      $existing_nu_config
      | str replace --all $legacy_path ""
      | save --force $nu_config
    }
  }
  ensure-line $nu_config $"$env.PATH = \($env.PATH | prepend \"($profile_bin)\"\)"

  if not $preserve_project_environment {
    print "Disabling the global project library path for normal shells..."
    ensure-line ($env.HOME | path join ".bashrc") "unset LD_LIBRARY_PATH"
    ensure-line ($env.HOME | path join ".profile") "unset LD_LIBRARY_PATH"
    ensure-line $nu_env "hide-env LD_LIBRARY_PATH"
  }

  print "Remote VM user environment is ready."
  print $"Reload Bash before using the profile: source ($env.HOME)/.nix-profile/etc/profile.d/nix.sh"
}

export alias remote-vm-setup = main
