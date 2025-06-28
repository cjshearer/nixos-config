{ lib, systemConfig, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.atuin;
in
{
  options.programs.atuin.enable = mkEnableOption "atuin";

  config = mkIf cfg.enable {
    home-manager.users.cjshearer.programs = {
      atuin = {
        enable = true;
        enableBashIntegration = true;
      };
      bash.enable = true;
    };
  };
}
