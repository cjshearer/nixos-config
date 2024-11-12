{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.obsidian;
in
{
  options.programs.obsidian.enable = mkEnableOption "obsidian";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ obsidian ];
  };
}
