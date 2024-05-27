{
  description = "Cody Shearer's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
    let
      mkSystem = { username, hostname, architecture } @ systemConfig: {
        ${hostname} = nixpkgs.lib.nixosSystem {
          system = architecture;
          specialArgs = { inherit inputs systemConfig; };
          modules = [
            ./overlays
            ./system
            ./hosts/${hostname}/configuration.nix
            ./hosts/${hostname}/hardware-configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username}.imports = [
                ./home
                ./hosts/${hostname}/home.nix
              ];
              home-manager.extraSpecialArgs = { inherit inputs systemConfig; };
            }
          ];
        };
      };
    in
    {
      nixosConfigurations = mkSystem {
        username = "cjshearer";
        hostname = "sisyphus";
        architecture = "x86_64-linux";
      };
    };
}
