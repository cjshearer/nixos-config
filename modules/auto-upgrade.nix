{
  lib,
  ...
}:
{
  system.autoUpgrade.allowReboot = true;
  system.autoUpgrade.enable = true;
  system.autoUpgrade.flake = lib.mkDefault "github:cjshearer/nixos-config";
  system.autoUpgrade.rebootWindow = {
    lower = "01:00";
    upper = "05:00";
  };
  system.autoUpgrade.upgrade = false;
}
