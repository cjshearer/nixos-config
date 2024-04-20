{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.discord;
in
{
  options.programs.discord.enable = mkEnableOption "discord";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ discord ];
  };
}
