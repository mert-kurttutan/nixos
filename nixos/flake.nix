{
  description = "NixOS configuration of Mert Kurttutan";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    common.url = "path:./common";
    common.inputs.nixpkgs.follows = "nixpkgs";
    zed.url = "github:mert-kurttutan/zed-nix";
    typst.url = "github:mert-kurttutan/typst-nix";
    typst.inputs.nixpkgs.follows = "nixpkgs";
    git-xet.url = "github:mert-kurttutan/git-xet-nix";
    cecc-linux.url = "github:mert-kurttutan/cecc-linux-nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      common,
      zed,
      typst,
      git-xet,
      cecc-linux,
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
                home-manager.users.${username} = {
                  imports = [
                    common.homeModules.default
                    ./home-manager/home.nix
                  ];
                };
              }
            ];
          };
      };
    };
}
