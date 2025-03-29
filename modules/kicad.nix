{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.kicad;
in
{
  options.programs.kicad.enable = mkEnableOption "kicad";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ kicad-small ];
  };
}
