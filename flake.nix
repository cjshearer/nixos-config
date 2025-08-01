{
  description = "Cody Shearer's NixOS Configuration";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";
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

      packages.x86_64-linux = import ./pkgs nixpkgs.legacyPackages.x86_64-linux;
    };
}
