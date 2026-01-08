{ config, pkgs, ... }:

let
  script = ./dev-shell-template.sh;
in
{
  home.file.".local/bin/dev-shell-template" = {
    source = script;
    executable = true;
  };

  home.sessionPath = [ "$HOME/.local/bin" ];
}
