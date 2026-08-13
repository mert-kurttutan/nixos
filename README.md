# Introduction
This projects is to store my flake config for my local development machine so that I can have
a version controlled system for my local tools
The intended workflow is to update here (controlled with git), then run the system update workflow:

`./update-system.nu`

This syncs the repo config to `/etc/nixos`, runs `sudo nixos-rebuild switch --flake /etc/nixos#nixos`, removes old NixOS generations, and sets the current system as the next boot configuration.

To also update the flake inputs in `nixos/` before rebuilding:

`./update-system.nu --update-flake`

## Remote dotfile install without Nix

For a non-Nix remote machine, install the dotfiles with:

```bash
curl -fsSL https://raw.githubusercontent.com/mert-kurttutan/nixos/main/scripts/install-dotfiles-remote.sh | bash
```

The script clones this repo into a temporary directory, copies `dotfiles/` into `$HOME`, skips `dotfiles/backups/`, downloads the Zellij sidebar plugin, patches the plugin path for the remote user's home directory, and removes the temporary clone afterward.

Required remote commands:

```bash
git curl sed bash
```

Override the source repo or branch if needed:

```bash
curl -fsSL https://raw.githubusercontent.com/mert-kurttutan/nixos/main/scripts/install-dotfiles-remote.sh \
  | NIXOS_CONF_REPO_URL=https://github.com/mert-kurttutan/nixos.git NIXOS_CONF_REPO_REF=main bash
```
