{
  description = "Cody Shearer's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/release-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... } @ inputs:
    let
      mkSystems = systems: builtins.listToAttrs (map
        (systemConfig: {
          name = systemConfig.hostname;
          value = nixpkgs.lib.nixosSystem {
            system = systemConfig.architecture;
            specialArgs = { inherit inputs systemConfig; };
            modules = [
              ./overlays
              ./system
              ./hosts/${systemConfig.hostname}/configuration.nix
              ./hosts/${systemConfig.hostname}/hardware-configuration.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.${systemConfig.username}.imports = [
                  ./home
                  ./hosts/${systemConfig.hostname}/home.nix
                ];
                home-manager.extraSpecialArgs = { inherit inputs systemConfig; };
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

      packages.x86_64-linux = import ./pkgs nixpkgs-unstable.legacyPackages.x86_64-linux;
    };
}
