# Local copy of the Nixpkgs rustup package

This flake starts from a copy of the rustup package implementation from the
Nixpkgs revision pinned by this repository's `nixos/flake.lock`:

- Nixpkgs revision: `6510408d147d8c5e6d76043e899e9251756f6a75`
- Upstream package: [`pkgs/development/tools/rust/rustup`](https://github.com/NixOS/nixpkgs/tree/6510408d147d8c5e6d76043e899e9251756f6a75/pkgs/development/tools/rust/rustup)

`flake.nix` exports `overlays.default` (which replaces `pkgs.rustup`) and
`packages.<system>.rustup`. The copied derivation is kept at the project root
instead of mirroring Nixpkgs' internal directory tree. It has only been adapted to
accept `nixpkgsSrc`, because its wrapper helper files are provided by the
Nixpkgs input rather than duplicated into this project. The upstream linker
wrapper behavior is otherwise unchanged so far.
