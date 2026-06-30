{
  home-manager.sharedModules = [
    (
      { lib, config, ... }:
      lib.mkIf config.programs.git.enable {
        programs.git.settings = {
          # https://jvns.ca/blog/2024/02/16/popular-git-config-options
          diff.algorithm = "histogram";
          help.autocorrect = 10;
          init.defaultBranch = "main";
          merge.conflictStyle = "zdiff3";
          pull.rebase = true;
          push.autoSetupRemote = true;
          rebase.autoStash = true;
          rere.enabled = true;
          url."ssh://git@github.com/".insteadOf = "https://github.com/";
          user.email = "cjshearer@live.com";
          user.name = "cjshearer";
        };
      }
    )
  ];
}
