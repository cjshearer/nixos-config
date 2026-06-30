{
  home-manager.sharedModules = [
    (
      { lib, config, ... }:
      lib.mkIf config.programs.jujutsu.enable {
        programs.jujutsu.settings = {
          remotes.origin.auto-track-bookmarks = "*";
          user.email = "cjshearer@live.com";
          user.name = "cjshearer";
        };
      }
    )
  ];
}
