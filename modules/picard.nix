{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.picard;
in
{
  options.programs.picard.enable = mkEnableOption "picard";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ picard ];
  };
}
