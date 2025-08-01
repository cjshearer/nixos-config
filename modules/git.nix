{ lib, config, ... }:
{
  options.users.cjshearer.programs.git.enable = lib.mkEnableOption "git";

  config = lib.mkIf config.users.cjshearer.programs.git.enable {
    home-manager.users.cjshearer.programs.git = {
      enable = true;

      userName = "cjshearer";
      userEmail = "cjshearer@live.com";

      extraConfig = {
        pull.rebase = true;
        push.autoSetupRemote = true;
        rebase.autoStash = true;
        # TODO: https://jvns.ca/blog/2024/02/16/popular-git-config-options
      };
    };
  };
}
