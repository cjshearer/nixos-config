{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.programs.pixelflasher;
in
{
  options.programs.pixelflasher.enable = mkEnableOption "pixelflasher";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ pixelflasher ];
    programs.adb.enable = true;
  };
}
