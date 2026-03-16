{ lib, config, ... }:
{
  options.users.cjshearer.programs.go.enable = lib.mkEnableOption "go";

  config = lib.mkIf config.users.cjshearer.programs.go.enable {
    home-manager.users.cjshearer.programs.go = {
      enable = true;
      env.CGO_ENABLED = "0";
    };
  };
}
