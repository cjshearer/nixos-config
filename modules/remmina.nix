{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.remmina;
in
{
  options.programs.remmina.enable = mkEnableOption "remmina";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ remmina ];
  };
}
