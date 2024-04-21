{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.libreoffice;
in
{
  options.programs.libreoffice.enable = mkEnableOption "libreoffice";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ libreoffice-qt ];
  };
}
