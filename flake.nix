{
  description = "Cody Shearer's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    nixos-cosmic.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixos-cosmic, nixpkgs, home-manager, ... } @ inputs:
    let
      mkSystems = systems: builtins.listToAttrs (map
        (systemConfig: {
          name = systemConfig.hostname;
          value = nixpkgs.lib.nixosSystem {
            system = systemConfig.architecture;
            specialArgs = { inherit inputs systemConfig; };
            modules = [
              ./overlays
              ./modules
              nixos-cosmic.nixosModules.default
              ./hosts/${systemConfig.hostname}.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.backupFileExtension = "bak";
                home-manager.extraSpecialArgs = { inherit inputs systemConfig; };
                home-manager.useGlobalPkgs = true;
                home-manager.users.${systemConfig.username}.programs.home-manager.enable = true;
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
        { username = "cjshearer"; hostname = "sisyphus"; architecture = "x86_64-linux"; }
        { username = "cjshearer"; hostname = "athamas"; architecture = "x86_64-linux"; }
        { username = "cjshearer"; hostname = "charon"; architecture = "aarch64-linux"; }
      ];

      packages.x86_64-linux = import ./pkgs nixpkgs.legacyPackages.x86_64-linux;
    };
}
