---
name: nix-flake-inputs
description: Maintain NixOS flake inputs when choosing or reviewing a nixpkgs source URL.
---

# NixOS flake inputs

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
