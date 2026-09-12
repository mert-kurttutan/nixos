{
  description = "Shared user-wide tools for GitHub Codespaces";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    codex.url = "github:mert-kurttutan/codex-cli-nix/use-zstd-assets";
    codex.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, codex, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          userTools = pkgs.buildEnv {
            name = "codespace-user-tools";
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
        });
    };
}
