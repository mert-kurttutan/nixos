# Local copy of the Nixpkgs rustup package

This flake starts from a copy of the rustup package implementation from the
Nixpkgs revision pinned by this repository's `nixos/flake.lock`:

- Nixpkgs revision: `6510408d147d8c5e6d76043e899e9251756f6a75`
- Upstream package: [`pkgs/development/tools/rust/rustup`](https://github.com/NixOS/nixpkgs/tree/6510408d147d8c5e6d76043e899e9251756f6a75/pkgs/development/tools/rust/rustup)

`flake.nix` exports `overlays.default` (which replaces `pkgs.rustup`) and
`packages.<system>.rustup`. The NixOS flake imports this as `rustup-fixed`, and
`home-manager/home-packages.nix` installs that package output directly instead
of selecting `pkgs.rustup` from Nixpkgs.

The derivation accepts `nixpkgsSrc` because its linker-wrapper helper files
come from the Nixpkgs input. On Linux, its patch adjusts rustup-installed
toolchain binaries for NixOS and wraps their `ld.lld` with Nixpkgs' linker
wrapper. The generated LLD launcher calls `rustup-ld-wrapper` by name; the
package places that command in `$out/bin` as a symlink to its linker wrapper.
This avoids embedding a store path to a rustup package generation that can
later be garbage collected. The rustup package's `bin` directory must be on
`PATH` when the toolchain invokes LLD.

Run `nu reproduce-stale-linker-wrapper.nu` from this directory to build the
flake and exercise the wrapper with a toolchain in an isolated temporary
rustup home.
