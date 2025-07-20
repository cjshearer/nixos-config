{ lib, config, ... }:
{
  options.users.cjshearer.programs.atuin.enable = lib.mkEnableOption "atuin";

  config = lib.mkIf config.users.cjshearer.programs.atuin.enable {
    home-manager.users.cjshearer.programs.atuin = {
      enable = true;
    };
    home-manager.users.cjshearer.programs.bash.enable = true;
  };
}
