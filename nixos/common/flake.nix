{
  description = "Minimal shared development tools for personal machines";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    codex.url = "github:mert-kurttutan/codex-cli-nix/use-zstd-assets";
    codex.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, codex, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      userToolsFor = system:
        let
          pkgs = import nixpkgs { inherit system; };
        in pkgs.buildEnv {
          name = "common-user-tools";
          paths = with pkgs; [
            bashInteractive
            coreutils
            curl
            findutils
            gh
            git
            jq
            less
            nushell
            ripgrep
            shellcheck
          ] ++ [ codex.packages.${system}.codex ];
          ignoreCollisions = true;
          pathsToLink = [ "/bin" ];
        };
    in {
      packages = forAllSystems (system: {
        userTools = userToolsFor system;
      });

      homeModules.default = { pkgs, ... }:
        {
          home.packages = [
            (userToolsFor pkgs.stdenv.hostPlatform.system)
          ];
        };
    };
}
