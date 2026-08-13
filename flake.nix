{
  description = "Cody Shearer's NixOS Configuration";

  inputs = {
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";

    ncro.inputs.nixpkgs.follows = "nixpkgs";
    ncro.url = "github:manic-systems/ncro";

    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    systems.url = "github:nix-systems/default-linux";
    
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs =
    {
      self,
      systems,
      nixpkgs,
      ...
    }@inputs:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      nixosConfigurations = nixpkgs.lib.genAttrs' (nixpkgs.lib.fileset.toList ./hosts) (host: rec {
        name = nixpkgs.lib.removeSuffix ".nix" (builtins.baseNameOf host);
        value = nixpkgs.lib.nixosSystem {
          specialArgs = inputs;
          modules = [
            host
            { networking.hostName = name; }
            self.nixosModules.default
          ];
        };
      });

      nixosModules.default.imports = nixpkgs.lib.fileset.toList ./modules;

      packages = eachSystem (
        system:
        nixpkgs.lib.filesystem.packagesFromDirectoryRecursive {
          inherit (nixpkgs.legacyPackages.${system}) callPackage;
          directory = ./pkgs;
        }
      );

      legacyPackages = eachSystem (system: import nixpkgs { inherit system; });
    };
}
