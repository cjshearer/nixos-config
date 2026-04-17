{ lib, config, ... }:
{
  options.users.cjshearer.programs.gh.enable = lib.mkEnableOption "gh";

  config = lib.mkIf config.users.cjshearer.programs.gh.enable {
    home-manager.users.cjshearer.programs.gh = {
      enable = true;
      settings.git_protocol = "ssh";
    };
  };
}
