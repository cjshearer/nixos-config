{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.programs.blender;
in
{
  options.programs.blender.enable = mkEnableOption "blender";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ blender ];
  };
}
