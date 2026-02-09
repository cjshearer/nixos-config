{ lib, ... }:
{
  imports = lib.pipe ./. [
    (lib.fileset.fileFilter (file: file.name != "default.nix"))
    (lib.fileset.toList)
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  networking.networkmanager.enable = true;
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

  system.autoUpgrade.allowReboot = true;
  system.autoUpgrade.enable = true;
  system.autoUpgrade.flake = "github:cjshearer/nixos-config";
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
}
