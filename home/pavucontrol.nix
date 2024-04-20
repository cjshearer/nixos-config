{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.pavucontrol;
in
{
  options.programs.pavucontrol.enable = mkEnableOption "pavucontrol";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ pavucontrol ];
  };
}
