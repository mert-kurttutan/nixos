{
  description = "NixOS configuration of Mert Kurttutan";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    claude-code.url = "github:sadjow/claude-code-nix/08c857d3f5ecbf16b8de8c7d6b83d277a064a406";
    codex.url = "github:sadjow/codex-cli-nix/def85c75aa8344f38b9b9fd893cf59debc1d1300";
    zed.url = "github:mert-kurttutan/zed-nix";
    typst.url = "github:typst/typst-flake";
    typst.inputs.nixpkgs.follows = "nixpkgs";
    git-xet.url = "github:mert-kurttutan/git-xet-nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      claude-code,
      codex,
      zed,
      typst,
      git-xet,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      formatter.${system} = pkgs.nixfmt-tree;
      nixosConfigurations = {
        nixos =
          let
            username = "kmert";
            user = username; # Define user variable
            specialArgs = { inherit username inputs user; };
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs;
            system = system;

            modules = [
              ./configuration.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup";
                home-manager.extraSpecialArgs = inputs // specialArgs;
                home-manager.users.${username} = import ./home-manager/home.nix;
              }
            ];
          };
      };
    };
}
