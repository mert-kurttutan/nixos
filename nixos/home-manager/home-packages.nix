{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    # Packages in each category are sorted alphabetically
    # Desktop apps
    # anki
    # code-cursor
    # imv
    # mpv
    inputs.binary-flakes.packages.${pkgs.stdenv.hostPlatform.system}.obsidian
    # pavucontrol
    # teams-for-linux
    # telegram-desktop
    # terminal emulators
    alacritty
    ghostty

    # version control
    # gitbutler

    # CLI utils
    bash-completion
    bc
    bottom
    brightnessctl
    cliphist
    dive
    dua
    fastfetch
    fd
    ffmpeg
    ffmpegthumbnailer
    git-lfs
    htop
    just
    # hyprpicker
    # mediainfo
    microfetch
    ntfs3g
    playerctl
    inputs.binary-flakes.packages.${pkgs.stdenv.hostPlatform.system}.proton-pass-cli
    yazi
    # showmethekey
    # silicon
    tmux
    udisks
    ueberzugpp
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
    kubectl
    nix-prefetch-scripts

    # archives
    p7zip
    unzip
    xz
    zip

    # utils
    fzf # A command-line fuzzy finder
    yq-go # yaml processor https://github.com/mikefarah/yq

    pandoc

    # networking tools
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    dnsutils # `dig` + `nslookup`
    ipcalc # it is a calculator for the IPv4/v6 addresses
    iperf3
    ldns # replacement of `dig`, it provide the command `drill`
    mtr # A network diagnostic tool
    nmap # A utility for network discovery and security auditing
    sniffnet
    socat # replacement of openbsd-netcat
    vnstat # A network traffic monitor
    # misc
    file
    gawk
    gnused
    gnupg
    gnutar
    tree
    which
    zstd

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    cachix
    devenv
    nil
    nix-output-monitor
    # productivity
    glow # markdown previewer in terminal
    hugo # static site generator
    # discord-ptb
    # rustdesk

    btop # replacement of htop/nmon
    iftop # network monitoring
    iotop # io monitoring
    powerstat
    powertop # power monitoring

    # web
    postman

    # # system call monitoring
    lsof # list open files
    ltrace # library call monitoring
    strace # system call monitoring

    # system tools
    docker-compose
    ethtool
    kubernetes
    kubernetes-helm
    lm_sensors # for `sensors` command
    pciutils # lspci
    podman-desktop
    # minikube # TODO: revisit; currently conflicts with kubectl via bin/kubectl
    sccache
    sysstat
    usbutils # lsusb

    # vm
    gnome-boxes
    qemu
    virt-manager

    # js
    deno
    fnm

    # AI
    # warp-terminal
    inputs.typst.packages.${pkgs.stdenv.hostPlatform.system}.default

    # rust
    rustup

    # c/c++
    (lib.hiPrio clang)
    gcc
    meson

    # cuda
    cudatoolkit

    # go
    go

    # python
    uv

    # ide/editors
    helix
    # marimo
    vscode

    inputs.binary-flakes.packages.${pkgs.stdenv.hostPlatform.system}.zed

    # browsers
    brave

    # cloud
    awscli2
    # aws-sam-cli

    # shell
  ];
}
