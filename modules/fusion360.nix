{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.fusion360;
in
{
  options.programs.fusion360.enable = mkEnableOption "fusion360";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ fusion360 ];
  };
}
