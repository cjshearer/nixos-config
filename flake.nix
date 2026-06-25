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

    robotnix.inputs.androidPkgs.inputs.nixpkgs.follows = "nixpkgs";
    robotnix.inputs.nixpkgs.follows = "nixpkgs";
    robotnix.url = "github:nix-community/robotnix";

    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs =
    {
      self,
      nixpkgs,
      robotnix,
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
    in
    let
      hosts = map (x: nixpkgs.lib.removeSuffix ".nix" (builtins.baseNameOf x)) (
        nixpkgs.lib.fileset.toList ./hosts
      );
      robotnixHosts = [ "salmoneus" ];
      nixosHosts = builtins.filter (n: !(builtins.elem n robotnixHosts)) hosts;
    in
    {
      nixosConfigurations = nixpkgs.lib.genAttrs nixosHosts (
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

      robotnixConfigurations = nixpkgs.lib.genAttrs robotnixHosts (
        hostname: robotnix.lib.robotnixSystem ./hosts/${hostname}.nix
      );

      nixosModules.default.imports = nixpkgs.lib.fileset.toList ./modules;

      overlays.packages =
        final: prev:
        nixpkgs.lib.genAttrs byNamePackages (
          name: final.pkgs.callPackage (./pkgs/by-name + "/${name}/package.nix") { }
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
        };

      packages = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
        system:
        nixpkgs.lib.genAttrs byNamePackages (name: self.legacyPackages.${system}.${name})
        // nixpkgs.lib.genAttrs pythonModules (name: self.legacyPackages.${system}.python3Packages.${name})
      );

      legacyPackages = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.packages ];
        }
      );
    };
}
