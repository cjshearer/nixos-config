{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.programs.freecad;
in
{
  options.programs.freecad.enable = mkEnableOption "freecad";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ freecad ];
  };
}
