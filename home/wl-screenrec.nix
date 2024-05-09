{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.wl-screenrec;
in
{
  options.programs.wl-screenrec.enable = mkEnableOption "wl-screenrec";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ wl-screenrec ];
  };
}
