{ pkgs, ... }:
{
  imports = [
    ./modules
    ./home-packages.nix
  ];
  programs.home-manager.enable = true;
  # TODO please change the username & home directory to your own
  home.username = "kmert";
  home.homeDirectory = "/home/kmert";

  # set cursor size and dpi for 4k monitor
  xresources.properties = {
    # "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };
  # Packages that should be installed to the user profile.
  programs.bash = {
    enable = true;
    enableCompletion = true;
    # TODO add your custom bashrc here
    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin:$HOME/.cargo/bin"
      export CUDA_PATH=${pkgs.cudatoolkit}
      ld-path-python() {
        export LD_LIBRARY_PATH=/run/opengl-driver/lib:$LD_LIBRARY_PATH
      }
    '';

    # set some aliases, feel free to add more or remove some
    shellAliases = {
      k = "kubectl";
      urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
      urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
    };
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.11";

  home.sessionVariables = {
    CUDA_PATH = "${pkgs.cudatoolkit}";
  };
}
