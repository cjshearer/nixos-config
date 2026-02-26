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
      # TODO: refactor with lib.fileset
      byNamePackages =
        if builtins.pathExists ./pkgs/by-name then builtins.readDir ./pkgs/by-name else { };
      pythonModules =
        if builtins.pathExists ./pkgs/python-modules then builtins.readDir ./pkgs/python-modules else { };
    in
    {
      nixosConfigurations =
        nixpkgs.lib.genAttrs
          (map (x: nixpkgs.lib.removeSuffix ".nix" (builtins.baseNameOf x)) (
            nixpkgs.lib.fileset.toList ./hosts
          ))
          (
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

      nixosModules.default = {
        imports = [ home-manager.nixosModules.home-manager ] ++ nixpkgs.lib.fileset.toList ./modules;

        boot.loader.efi.canTouchEfiVariables = true;

        home-manager.backupFileExtension = "bak";
        home-manager.sharedModules = [ vscode-server.homeModules.default ];
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        home-manager.users.cjshearer.programs.bash.bashrcExtra = ''
          source ~/.bash_aliases
        '';
        networking.stevenblack.enable = true;

        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };

        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        nix.settings.trusted-users = [ "cjshearer" ];

        nixpkgs.config.allowUnfree = true;

        nixpkgs.overlays = [ self.overlays.packages ];

        system.autoUpgrade.allowReboot = true;
        system.autoUpgrade.enable = true;
        system.autoUpgrade.flake = nixpkgs.lib.mkDefault "github:cjshearer/nixos-config";
        system.autoUpgrade.rebootWindow = {
          lower = "01:00";
          upper = "05:00";
        };
        system.autoUpgrade.upgrade = false;

        system.etc.overlay.mutable = false;

        users.users.cjshearer.extraGroups = [
          "networkmanager"
          "wheel"
        ];
        users.users.cjshearer.isNormalUser = true;
        users.users.cjshearer.uid = 1000;
      };

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
