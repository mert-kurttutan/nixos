{
  description = "Minimal shared development tools for personal machines";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    binary-flakes.url = "github:mert-kurttutan/binary-flakes";
    binary-flakes.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, binary-flakes, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      codexWithPipewireAudioFor =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        import ./codex-voice-patch.nix {
          inherit pkgs;
          codex = binary-flakes.packages.${system}.codex;
        };
      userToolsFor =
        system: codexPackage:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.buildEnv {
          name = "common-user-tools";
          paths =
            with pkgs;
            [
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
            ]
            ++ [ codexPackage ];
          ignoreCollisions = true;
          pathsToLink = [ "/bin" ];
        };
    in
    {
      packages = forAllSystems (system: {
        codexPipewire = codexWithPipewireAudioFor system;
        userTools = userToolsFor system binary-flakes.packages.${system}.codex;
      });

      homeModules.default =
        {
          pkgs,
          codexPackage ? binary-flakes.packages.${pkgs.stdenv.hostPlatform.system}.codex,
          ...
        }:
        {
          home.packages = [
            (userToolsFor pkgs.stdenv.hostPlatform.system codexPackage)
          ];
        };
    };
}
