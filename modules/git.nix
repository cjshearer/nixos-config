{ lib, config, systemConfig, ... }: lib.mkIf config.programs.git.enable {
  home-manager.users.${systemConfig.username}.programs.git = {
    enable = true;
    userName = "cjshearer";
    userEmail = "cjshearer@live.com";

    extraConfig = {
      pull.rebase = true;
      rebase.autoStash = true;
      # TODO: https://jvns.ca/blog/2024/02/16/popular-git-config-options
    };
  };
}
