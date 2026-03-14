{
  home-manager.sharedModules = [
    (
      {
        lib,
        osConfig,
        ...
      }:
      {
        # I added this because Atuin, despite having its bash integration enabled by default, did
        # not install its shell hook, as bash was only enabled at the system level
        programs.bash.enable = lib.mkDefault osConfig.programs.bash.enable;
      }
    )
  ];
}
