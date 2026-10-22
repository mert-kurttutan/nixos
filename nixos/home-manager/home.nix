{
  pkgs,
  lib,
  codexPackage,
  username,
  homeDirectory,
  ...
}:
let
  zedNvidia = pkgs.writeShellScriptBin "zed-nvidia" ''
    exec env ZED_DEVICE_ID=0x2820 zed "$@"
  '';
  codexDesktop = pkgs.writeShellScriptBin "codex-desktop" ''
    cd ${lib.escapeShellArg homeDirectory}
    exec ${pkgs.alacritty}/bin/alacritty \
      --option 'window.startup_mode="Maximized"' \
      --working-directory ${lib.escapeShellArg homeDirectory} \
      -e ${pkgs.zellij}/bin/zellij --new-session-with-layout ${codexLayout}
  '';
  codexLayout = pkgs.writeText "codex-layout.kdl" ''
    layout {
      default_tab_template {
        pane size=1 borderless=true {
          plugin location="zellij:tab-bar"
        }
        pane split_direction="vertical" {
          pane name="side" size="8%" borderless=false {
            plugin location="vertical-sidebar"
          }
          pane split_direction="vertical" {
            pane name="Codex" focus=true command="${codexPackage}/bin/codex"
            pane name="shell"
          }
        }
        pane size=1 borderless=true {
          plugin location="zellij:status-bar"
        }
      }

      tab name="Codex" focus=true
    }
  '';
in
{
  imports = [
    ./home-packages.nix
  ];
  home.username = username;
  home.homeDirectory = homeDirectory;

  # set cursor size and dpi for 4k monitor
  xresources.properties = {
    # "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };
  # Packages that should be installed to the user profile.
  home.packages = [
    zedNvidia
    codexDesktop
  ];

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.11";

  xdg.desktopEntries.zed-nvidia = {
    name = "Zed (NVIDIA)";
    genericName = "Text Editor";
    comment = "Launch Zed on the NVIDIA GPU";
    exec = "zed-nvidia %U";
    icon = "zed";
    terminal = false;
    type = "Application";
    categories = [
      "Utility"
      "TextEditor"
      "Development"
      "IDE"
    ];
    mimeType = [
      "text/plain"
      "application/x-zerosize"
      "x-scheme-handler/zed"
    ];
  };

  xdg.desktopEntries.codex-cli = {
    name = "Codex";
    genericName = "AI Coding Assistant";
    comment = "Launch Codex CLI in Zellij";
    exec = "${codexDesktop}/bin/codex-desktop";
    icon = "utilities-terminal";
    terminal = false;
    type = "Application";
    categories = [
      "Development"
    ];
  };

}
