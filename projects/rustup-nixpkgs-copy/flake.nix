{
  description = "Nixpkgs rustup package exposed as a reusable overlay";

  inputs.nixpkgs.url = "https://releases.nixos.org/nixos/unstable/nixos-26.11pre1089111.6510408d147d/nixexprs.tar.zst";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    in
    {
      overlays.default = final: prev: {
        rustup = prev.callPackage ./default.nix {
          nixpkgsSrc = nixpkgs.outPath;
        };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = (pkgs.extend self.overlays.default).rustup;
          rustup = (pkgs.extend self.overlays.default).rustup;
        }
      );
    };
}
