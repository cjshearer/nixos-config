{ lib, config, ... }:
{
  options.users.cjshearer.programs.git.enable = lib.mkEnableOption "git";

  config = lib.mkIf config.users.cjshearer.programs.git.enable {
    home-manager.users.cjshearer.programs.git = {
      enable = true;
      settings = {
        # https://jvns.ca/blog/2024/02/16/popular-git-config-options
        diff.algorithm = "histogram";
        help.autocorrect = 10;
        init.defaultBranch = "main";
        merge.conflictStyle = "zdiff3";
        pull.rebase = true;
        push.autoSetupRemote = true;
        rebase.autoStash = true;
        rere.enabled = true;
        url."git@github.com:".insteadOf = "https://github.com/";
        user.email = "cjshearer@live.com";
        user.name = "cjshearer";
      };
    };
  };
}
