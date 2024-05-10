{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.hyprec;
in
{
  options.programs.hyprec.enable = mkEnableOption "hyprec";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ hyprec ];
  };
}
