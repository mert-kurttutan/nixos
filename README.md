# Introduction
This projects is to store my flake config for my local development machine so that I can have
a version controlled system for my local tools
The intended workflow is to update here (controlled with git), then run the system update workflow:

`./update-system.nu`

This syncs the repo config to `/etc/nixos`, runs `sudo nixos-rebuild switch --flake /etc/nixos#nixos`, removes old NixOS generations, and sets the current system as the next boot configuration.

To also update the flake inputs in `nixos/` before rebuilding:

`./update-system.nu --update-flake`
