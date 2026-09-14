# Nix practices review

Reviewed: 2026-09-14

This is a review-only document. The recommendations below have **not** been
applied to the NixOS configuration.

## Recommended follow-up changes

### Use the system package set in Home Manager

`nixos/flake.nix` currently enables `home-manager.useUserPackages`, but leaves
`home-manager.useGlobalPkgs` at its default of `false`. The Home Manager NixOS
module recommends enabling `useGlobalPkgs` when Home Manager is integrated into
NixOS. This avoids a second Nixpkgs evaluation and keeps system and Home Manager
package configuration consistent.

Before applying this, verify that the system-level `nixpkgs.config.allowUnfree`
setting is sufficient for every Home Manager package. The duplicate
`nixpkgs.config.allowUnfree` in `nixos/home-manager/home-packages.nix` could then
be removed.

Reference: <https://home-manager.dev/manual/unstable/nix-flakes/nixos.html>

### Replace `packageOverrides` with an overlay

`nixos/modules/hardware.nix` customizes Mesa using
`nixpkgs.config.packageOverrides`. Current Nixpkgs documentation describes
overlays as the more powerful and distributable mechanism, with `final` used
for dependencies and `prev` used to access the package being overridden.

The Mesa customization can be expressed as a `nixpkgs.overlays` entry while
retaining the existing `overrideAttrs` behavior.

Reference: <https://nixos.org/manual/nixpkgs/unstable/#chap-overlays>

### `legacyPackages` is still the correct package-set output

The use of `nixpkgs.legacyPackages.${system}` in `nixos/flake.nix` is not a
legacy practice that needs replacing. Nixpkgs intentionally exposes its large
package set through `legacyPackages`: unlike `packages`, this prevents commands
such as `nix flake show` from eagerly traversing the entire package tree. The
name refers to the flake output shape, not to obsolete packages.

The same pattern is already used by the official NixOS Flakes documentation.

`nixos/common/flake.nix` currently uses `import nixpkgs { inherit system; }`.
Because that import does not add configuration or overlays, it could be
simplified to `nixpkgs.legacyPackages.${system}` in a future cleanup. By
contrast, `binary-flakes/flake.nix` intentionally uses `import nixpkgs` because
it supplies both `allowUnfree` and a custom overlay; that import should remain.

Reference: <https://github.com/NixOS/nixpkgs/blob/master/flake.nix>
Reference: <https://wiki.nixos.org/wiki/Flakes/en>

## Lower-priority cleanup

## Already aligned observations

- The main flake uses the official NixOS channel tarball URL for `nixpkgs` and
  keeps resolved inputs in `flake.lock`.
- The configuration enables flakes through `nix.settings.experimental-features`.
- The external `binary-flakes` input is followed by the local `common` flake,
  avoiding an unnecessary second instance of that input.
- The flake exposes a formatter through `formatter.x86_64-linux`.
