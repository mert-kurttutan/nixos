{ pkgs, inputs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # Packages in each category are sorted alphabetically
    # Desktop apps
    # anki
    # code-cursor
    # imv
    # mpv
    # obsidian
    # pavucontrol
    # teams-for-linux
    # telegram-desktop
    # terminal emulators
    alacritty
    ghostty

    # version control
    # gitbutler

    # CLI utils
    bc
    bottom
    brightnessctl
    dive
    dua
    cliphist
    fastfetch
    fd
    ffmpeg
    ffmpegthumbnailer
    fzf
    gh
    just
    # git-graph
    htop
    # hyprpicker
    ntfs3g
    # mediainfo
    microfetch
    playerctl
    ripgrep
    # showmethekey
    # silicon
    udisks
    ueberzugpp
    unzip
    w3m
    wget
    wl-clipboard
    wtype
    zellij

    # yt-dlp

    # Coding stuff
    # openjdk23
    nodejs
    python311

    # Other
    nix-prefetch-scripts
    kubectl
    nnn # terminal file manager

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep # recursively searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq
    fzf # A command-line fuzzy finder

    pandoc

    # networking tools
    mtr # A network diagnostic tool
    vnstat # A network traffic monitor
    iperf3
    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses
    sniffnet
    # misc
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor
    nil
    devenv
    cachix
    # productivity
    hugo # static site generator
    glow # markdown previewer in terminal
    # discord-ptb
    # rustdesk

    btop # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring
    powertop # power monitoring
    powerstat

    # web
    postman

    # # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb
    docker-compose
    kubernetes
    minikube
    sccache
    kubernetes-helm

    # js
    fnm
    deno

    # AI
    inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
    warp-terminal
    inputs.codex.packages.${pkgs.stdenv.hostPlatform.system}.codex
    inputs.typst.packages.${pkgs.stdenv.hostPlatform.system}.default

    # rust
    rustup

    # c/c++
    gcc
    (lib.hiPrio clang)
    meson

    # cuda
    cudatoolkit

    # go
    go

    # python
    uv

    # ide/editors
    vscode
    helix
    # marimo

    inputs.zed.packages.${pkgs.stdenv.hostPlatform.system}.zed

    # browsers
    brave

    # cloud
    awscli2
    # aws-sam-cli

    # shell
    nushell
  ];
}
