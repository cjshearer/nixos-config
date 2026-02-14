{
  description = "Cody Shearer's NixOS Configuration";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      byNamePackages = builtins.readDir ./pkgs/by-name;
      pythonModules = builtins.readDir ./pkgs/python-modules;
    in
    {
      nixosConfigurations = (
        nixpkgs.lib.pipe ./hosts [
          nixpkgs.lib.fileset.toList
          (map (path: nixpkgs.lib.removeSuffix ".nix" (builtins.baseNameOf path)))
          (map (hostname: {
            name = hostname;
            value = nixpkgs.lib.nixosSystem {
              specialArgs = inputs;
              modules = [
                ./modules
                ./hosts/${hostname}.nix
                {
                  networking.hostName = hostname;
                  nixpkgs.overlays = [ self.overlays.packages ];
                }
              ];
            };
          }))
          builtins.listToAttrs
        ]
      );

      overlays.packages =
        final: prev:
        builtins.mapAttrs (
          name: _: (final.pkgs.callPackage (./pkgs/by-name + "/${name}/package.nix") { })
        ) byNamePackages
        // {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (
              python-final: python-prev:
              builtins.mapAttrs (
                name: _: (python-final.callPackage (./pkgs/python-modules + "/${name}") { })
              ) pythonModules
            )
          ];
        };

      packages = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.packages ];
          };
        in
        builtins.mapAttrs (name: _: pkgs.${name}) byNamePackages
        // builtins.mapAttrs (name: _: pkgs.python3Packages.${name}) pythonModules
      );
    };
}
