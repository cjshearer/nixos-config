{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.blueman;
in
{
  options.programs.blueman.enable = mkEnableOption "blueman";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ blueman ];
    dconf.settings."org/blueman/general" = {
      plugin-list = [ "!ConnectionNotifier" ];
    };
  };
}
