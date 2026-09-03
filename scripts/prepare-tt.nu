#!/usr/bin/env nu

# Prepare a local tt-metal development machine.
#
# The script installs basic Ubuntu packages, ensures Nix is installed, clones
# the tt-metal, tt-docs, and ttnn-profile repositories under projects/tenstorrent,
# and installs Codex.
#
# After this script finishes, build tt-metal manually:
#   cd projects/tenstorrent/tt-metal
#   nix develop -c ./build_metal.sh

def fail [message: string] {
  error make {
    msg: $message
  }
}

def ubuntu-id [] {
  if not ("/etc/os-release" | path exists) {
    return ""
  }

  open /etc/os-release
  | lines
  | where { |line| $line =~ "=" }
  | split column -n 2 "=" key value
  | update value { |row| $row.value | str trim --char '"' }
  | where key == "ID"
  | get value?
  | first
  | default ""
}

def nix-profile-hint [] {
  if ("/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" | path exists) {
    return "source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  }

  if ("/etc/profile.d/nix.sh" | path exists) {
    return "source /etc/profile.d/nix.sh"
  }

  "open a new login shell"
}

def activate-nix [] {
  let nix_bins = [
    "/nix/var/nix/profiles/default/bin"
    $"($env.HOME? | default "")/.nix-profile/bin"
  ]

  let existing_bins = (
    $nix_bins
    | where { |path| ($path | path exists) }
  )

  if ($existing_bins | is-empty) {
    return false
  }

  let current_path = ($env.PATH | default [])
  $env.PATH = (
    $existing_bins
    | append $current_path
    | uniq
  )

  not (which nix | is-empty)
}

def show-nix-status [] {
  if (activate-nix) {
    print "Nix is available in this Nushell script."
    return
  }

  print "Nix appears to be installed, but the nix command is not available in this shell."
  print $"For Bash, run: (nix-profile-hint)"
}

def prepare-folders [] {
  let projects_dir = "projects/tenstorrent"

  if ($projects_dir | path exists) {
    print $"Projects folder already exists: ($projects_dir)"
    return
  }

  print $"Creating projects folder: ($projects_dir)"
  mkdir $projects_dir
}

def ensure-apt-packages [packages: list<string>] {
  if (which dpkg | is-empty) {
    fail "dpkg was not found in PATH."
  }

  let missing = (
    $packages
    | where { |package|
        let status = (do { ^dpkg -s $package } | complete)
        $status.exit_code != 0
      }
  )

  if ($missing | is-empty) {
    return
  }

  let os_id = (ubuntu-id)

  if $os_id != "ubuntu" {
    fail $"This installer is intended for Ubuntu systems. Detected OS ID: ($os_id)"
  }

  if (which sudo | is-empty) {
    fail "sudo was not found in PATH."
  }

  print "Updating apt package lists..."
  ^sudo apt-get update

  print $"Installing packages: ($missing | str join ', ')"
  ^sudo apt-get install -y ...$missing
}

def install-apt-packages [] {
  ensure-apt-packages [curl wget git neofetch libatomic1 unzip]
}

def install-nix [] {
  if not (which nix | is-empty) {
    print "Nix is already installed. Skipping install."
    ^nix --version
    return
  }

  if ("/nix/receipt.json" | path exists) {
    print "Nix appears to be installed already. Skipping install."
    show-nix-status
    return
  }

  let os_id = (ubuntu-id)

  if $os_id != "ubuntu" {
    fail $"This installer is intended for Ubuntu systems. Detected OS ID: ($os_id)"
  }

  ensure-apt-packages [curl]

  print "Installing Nix with the Determinate Systems installer..."
  ^curl -fsSL https://install.determinate.systems/nix | ^sh -s -- install

  if (which nix | is-empty) {
    show-nix-status
  } else {
    ^nix --version
  }
}

def clone-or-update-repo [
  name: string
  url: string
  target_dir: string
  --branch: string
  --recurse-submodules
] {
  if ($target_dir | path exists) {
    print $"($name) already exists: ($target_dir)"
    print "Fetching latest refs..."
    git -C $target_dir fetch origin

    if ($branch | is-not-empty) {
      git -C $target_dir checkout $branch
      git -C $target_dir pull --ff-only origin $branch
    } else {
      git -C $target_dir pull --ff-only
    }

    if $recurse_submodules {
      print $"Updating submodules for ($name)..."
      git -C $target_dir submodule update --init --recursive
    }

    return
  }

  print $"Cloning ($name) into: ($target_dir)"

  if ($branch | is-not-empty) and $recurse_submodules {
    git clone --recurse-submodules --branch $branch $url $target_dir
  } else if ($branch | is-not-empty) {
    git clone --branch $branch $url $target_dir
  } else if $recurse_submodules {
    git clone --recurse-submodules $url $target_dir
  } else {
    git clone $url $target_dir
  }
}

def clone-git-repos [] {
  ensure-apt-packages [git]

  let projects_dir = "projects/tenstorrent"

  clone-or-update-repo tt-metal git@github.com:mert-kurttutan/tt-metal.git $"($projects_dir)/tt-metal" --branch nix-dev --recurse-submodules
  clone-or-update-repo tt-docs git@github.com:mert-kurttutan/tt-docs.git $"($projects_dir)/tt-docs"
  clone-or-update-repo ttnn-profile git@github.com:mert-kurttutan/ttnn-profile.git $"($projects_dir)/ttnn-profile"
}

def install-codex [] {
  if not (which codex | is-empty) {
    print "Codex is already installed. Skipping install."
    ^codex --version
    return
  }

  ensure-apt-packages [curl bash]

  print "Installing fnm..."
  ^curl -fsSL https://fnm.vercel.app/install | ^bash

  print "Installing latest Node.js with fnm..."
  ^bash -lc 'export PATH="$HOME/.local/share/fnm:$PATH"; eval "$(fnm env --shell bash)"; fnm install --latest; fnm use latest'

  print "Installing Codex CLI..."
  ^bash -lc 'export PATH="$HOME/.local/share/fnm:$PATH"; eval "$(fnm env --shell bash)"; fnm use latest; npm i -g @openai/codex'

  print "Codex installation complete."
  ^bash -lc 'export PATH="$HOME/.local/share/fnm:$PATH"; eval "$(fnm env --shell bash)"; fnm use latest >/dev/null; codex --version'
}

def main [] {
  prepare-folders
  install-apt-packages
  install-nix
  clone-git-repos
  install-codex
}
