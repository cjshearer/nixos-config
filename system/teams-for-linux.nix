{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.teams-for-linux;
in
{
  options.programs.teams-for-linux.enable = mkEnableOption "teams-for-linux";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ teams-for-linux ];
  };
}
