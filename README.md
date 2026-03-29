# Introduction
This projects is to store my flake config for my local development machine so that I can have
a version controlled system for my local tools
The intended workflow is to update here (controlled with git). The order in which to run the followings is important. Then sync my actual nixos folder with the repo
then run 
`sudo nixos-rebuild switch`

Run the following if you want to remove old generations of nixos:
`sudo nix-collect-garbage -d`

To change the default boot selection for the next reboot, you can use the following command:
`sudo /run/current-system/bin/switch-to-configuration boot`