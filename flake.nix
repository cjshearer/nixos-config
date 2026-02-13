{
  description = "Cody Shearer's NixOS Configuration";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix4vscode.url = "github:nix-community/nix4vscode";
    nix4vscode.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix4vscode,
      ...
    }@inputs:
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
                  nixpkgs.overlays = [
                    nix4vscode.overlays.default
                    self.overlays.packages
                  ];
                }
              ];
            };
          }))
          builtins.listToAttrs
        ]
      );

      overlays.packages =
        final: _prev:
        builtins.mapAttrs (
          name: _: (final.pkgs.callPackage (./pkgs/by-name + "/${name}/default.nix") { })
        ) (builtins.readDir ./pkgs/by-name);

      packages = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
        system: self.overlays.packages nixpkgs.legacyPackages.${system} { }
      );
    };
}
