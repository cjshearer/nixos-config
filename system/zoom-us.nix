{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.zoom-us;
in
{
  options.programs.zoom-us.enable = mkEnableOption "zoom-us";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ zoom-us ];
  };
}
