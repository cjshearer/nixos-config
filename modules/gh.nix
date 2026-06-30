{
  home-manager.sharedModules = [
    (
      { lib, config, ... }:
      lib.mkIf config.programs.gh.enable {
        programs.gh.settings.git_protocol = "ssh";
      }
    )
  ];
}
