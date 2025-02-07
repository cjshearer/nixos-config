{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.qbittorrent;
in
{
  options.programs.qbittorrent.enable = mkEnableOption "qbittorrent";

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.qbittorrent ];
  };
}
