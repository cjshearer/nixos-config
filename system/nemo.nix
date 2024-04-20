{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.nemo;
in
{
  options.programs.nemo.enable = mkEnableOption "nemo";

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.cinnamon.nemo ];
  };
}
