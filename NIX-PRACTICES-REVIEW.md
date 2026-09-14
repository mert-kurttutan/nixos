# Nix practices review

Reviewed: 2026-09-14

This is a review-only document. The recommendations below have **not** been
applied to the NixOS configuration.

## Recommended follow-up changes

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
