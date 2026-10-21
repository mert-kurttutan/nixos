---
name: nix-flake-inputs
description: Maintain NixOS flake inputs when choosing or reviewing a nixpkgs source URL.
---

# NixOS flake inputs

## Node.js in project flakes

The host provides `fnm` and uses it to select the Node.js version. When creating
or updating a project flake, assume the host's `fnm` setup is available and do
not add `nodejs`, `fnm`, or a Node.js version manager to the dev shell just to
provide Node.js. Let the host-selected version supply `node` and its bundled
`npm`. Add project-specific JavaScript dependencies through the project's lock
file and package manager as usual.

## Rust in project flakes

The host provides `rustup`, which supplies `rustc` and `cargo`; the active
toolchain is the host's rustup selection. The host also has `wasm-pack` and
`cargo-bloat` installed in `~/.cargo/bin`. When creating or updating a project
flake, assume these host tools are available and do not add another Rust
toolchain, `rustup`, `wasm-pack`, or `cargo-bloat` to the dev shell just to
provide them. For Rust/Wasm builds, `wasm-pack` manages its matching
`wasm-bindgen` CLI and can install `wasm32-unknown-unknown` when using rustup.
Pin Rust crate dependencies with `Cargo.lock`.

For `nixpkgs` inputs, prefer the official NixOS channel tarball over a GitHub URL:

```nix
nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
```

For a different channel, replace `nixos-unstable` with the desired branch name.

Do not use an indirect flake reference such as `nixpkgs/nixos-unstable` in the
flake's `inputs` section; registry resolution can make updates environment-dependent.

The channel tarball is compatible with normal flake commands and the lockable
HTTP tarball protocol, so it remains lockable and reproducible through
`flake.lock`.

Source: https://discourse.nixos.org/t/psa-use-nixos-org-tarballs-for-your-flake-inputs/79950
