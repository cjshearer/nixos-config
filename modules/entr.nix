{
  home-manager.sharedModules = [
    (
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        options.programs.entr.enable = lib.mkEnableOption "entr";

        config = lib.mkIf config.programs.entr.enable {
          home.packages = [ pkgs.entr ];
        };
      }
    )
  ];
}
