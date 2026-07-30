#!/usr/bin/env nu

const flake_dir = path self nixos
const target_dir = "/etc/nixos"
const host = "nixos"

print $"Updating flake inputs in ($flake_dir)"
nix flake update --flake $flake_dir

print $"Syncing ($flake_dir) to ($target_dir)"
sudo rsync -a --delete $"($flake_dir)/" $"($target_dir)/"
# --exclude='flake.lock'

print $"Rebuilding ($host) from ($target_dir)"
sudo nixos-rebuild switch --flake $"($target_dir)#($host)"

print "Removing old NixOS generations"
sudo nix-collect-garbage -d

print "Setting the current system as the next boot configuration"
sudo /run/current-system/bin/switch-to-configuration boot
