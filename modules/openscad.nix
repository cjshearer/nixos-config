{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.programs.openscad;
in
{
  options.programs.openscad.enable = mkEnableOption "openscad";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ openscad ];
  };
}
