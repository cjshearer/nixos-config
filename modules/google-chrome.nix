{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.google-chrome;
in
{
  options.programs.google-chrome.enable = mkEnableOption "google-chrome";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ google-chrome ];
  };
}
