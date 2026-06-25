{ lib, config, ... }:
{
  options.users.cjshearer.programs.jujutsu.enable = lib.mkEnableOption "jujutsu";

  config = lib.mkIf config.users.cjshearer.programs.jujutsu.enable {
    home-manager.users.cjshearer.programs.jujutsu = {
      enable = true;
      settings = {
        remotes.origin.auto-track-bookmarks = "*";
        user.email = "cjshearer@live.com";
        user.name = "cjshearer";
      };
    };
  };
}
