{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.programs.obsidian;
in
{
  options.programs.obsidian.enable = mkEnableOption "obsidian";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ obsidian ];
  };
}
