{ home-manager, ... }: {
  imports = [ home-manager.nixosModules.home-manager ];

  home-manager.backupFileExtension = "bak";
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
}
