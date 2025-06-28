{
  description = "Cody Shearer's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
    let
      mkSystems = systems: builtins.listToAttrs (map
        (systemConfig: {
          name = systemConfig.hostname;
          value = nixpkgs.lib.nixosSystem {
            specialArgs = { inherit inputs systemConfig; };
            modules = [
              ./overlays
              ./modules
              ./hosts/${systemConfig.hostname}.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.backupFileExtension = "bak";
                home-manager.extraSpecialArgs = { inherit inputs systemConfig; };
                home-manager.useGlobalPkgs = true;
                home-manager.users.cjshearer.programs.home-manager.enable = true;
                home-manager.useUserPackages = true;
              }
            ];
          };
        })
        systems
      );
    in
    {
      nixosConfigurations = mkSystems [
        { username = "cjshearer"; hostname = "athamas"; }
        { username = "cjshearer"; hostname = "charon"; }
        { username = "cjshearer"; hostname = "sisyphus"; }
      ];

      packages.x86_64-linux = import ./pkgs nixpkgs.legacyPackages.x86_64-linux;
    };
}
