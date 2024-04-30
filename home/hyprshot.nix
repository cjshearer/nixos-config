{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.hyprshot;
in
{
  options.programs.hyprshot.enable = mkEnableOption "hyprshot";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ unstable.hyprshot ];
  };
}
