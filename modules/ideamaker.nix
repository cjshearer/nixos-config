{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.ideamaker;
in
{
  options.programs.ideamaker.enable = mkEnableOption "ideamaker";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ ideamaker ];
  };
}
