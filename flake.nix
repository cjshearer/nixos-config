{
  description = "Cody Shearer's NixOS Configuration";

  inputs = {
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      vscode-server,
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
                home-manager.nixosModules.home-manager
                {
                  home-manager.backupFileExtension = "bak";
                  home-manager.sharedModules = [ vscode-server.homeModules.default ];
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
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
        builtins.mapAttrs (name: _: self.legacyPackages.${system}.${name}) byNamePackages
        // builtins.mapAttrs (name: _: self.legacyPackages.${system}.python3Packages.${name}) pythonModules
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
