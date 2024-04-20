{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.fonts.fontAwesome;
in
{
  options.fonts.fontAwesome.enable = mkEnableOption "font awesome";

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [ font-awesome ];
  };
}
