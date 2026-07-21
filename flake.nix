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

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    systems.url = "github:nix-systems/default-linux";
  };

  outputs =
    {
      self,
      systems,
      nixpkgs,
      ...
    }@inputs:
    let
      # List package directories (those containing the given entry file) under a root, mirroring
      # how ./hosts and ./modules are enumerated with lib.fileset.
      packageDirs =
        entryFile: root:
        nixpkgs.lib.optionals (builtins.pathExists root) (
          map (file: baseNameOf (dirOf file)) (
            nixpkgs.lib.fileset.toList (nixpkgs.lib.fileset.fileFilter (file: file.name == entryFile) root)
          )
        );

      byNamePackages = packageDirs "package.nix" ./pkgs/by-name;
      pythonModules = packageDirs "default.nix" ./pkgs/python-modules;
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      nixosConfigurations =
        nixpkgs.lib.genAttrs
          (map (x: nixpkgs.lib.removeSuffix ".nix" (builtins.baseNameOf x)) (
            nixpkgs.lib.fileset.toList ./hosts
          ))
          (
            hostname:
            nixpkgs.lib.nixosSystem {
              specialArgs = inputs;
              modules = [
                ./hosts/${hostname}.nix
                { networking.hostName = hostname; }
                self.nixosModules.default
              ];
            }
          );

      nixosModules.default.imports = nixpkgs.lib.fileset.toList ./modules;

      overlays.packages =
        final: prev:
        nixpkgs.lib.genAttrs byNamePackages (
          name: final.callPackage (./pkgs/by-name + "/${name}/package.nix") { }
        )
        // {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (
              python-final: python-prev:
              nixpkgs.lib.genAttrs pythonModules (
                name: python-final.callPackage (./pkgs/python-modules + "/${name}") { }
              )
            )
          ];
        }
        # awaiting https://github.com/NixOS/nixpkgs/pull/540826
        // {
          gdalMinimal = prev.gdalMinimal.overrideAttrs (old: {
            disabledTests = old.disabledTests ++ [ "test_zarr_read_simple_sharding" ];
          });
        };

      packages = eachSystem (
        system:
        nixpkgs.lib.genAttrs byNamePackages (name: self.legacyPackages.${system}.${name})
        // nixpkgs.lib.genAttrs pythonModules (name: self.legacyPackages.${system}.python3Packages.${name})
      );

      legacyPackages = eachSystem (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.packages ];
        }
      );
    };
}
