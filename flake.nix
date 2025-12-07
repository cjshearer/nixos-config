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
                ./overlays
                ./modules
                ./hosts/${hostname}.nix
                { networking.hostName = hostname; }
              ];
            };
          }))
          builtins.listToAttrs
        ]
      );

      packages = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
        system: import ./pkgs nixpkgs.legacyPackages.${system}
      );
    };
}
