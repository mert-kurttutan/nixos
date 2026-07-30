{ config, pkgs, ... }:

let
  script = ./dev-shell-template.sh;
  nixDownloadSummary = ../../../scripts/nix-download-summary.nu;
  normalizeBashShebang = ../../../scripts/normalize-bash-shebang.nu;
in
{
  home.file.".local/bin/dev-shell-template" = {
    source = script;
    executable = true;
  };

  home.file.".local/bin/normalize-bash-shebang" = {
    source = normalizeBashShebang;
    executable = true;
  };

  home.file.".local/bin/nix-download-summary" = {
    source = nixDownloadSummary;
    executable = true;
  };

  home.sessionPath = [ "$HOME/.local/bin" ];
}
