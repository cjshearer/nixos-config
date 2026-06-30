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
        options.programs.kicad.enable = lib.mkEnableOption "KiCad";

        config = lib.mkIf config.programs.kicad.enable {
          home.packages = [ pkgs.kicad ];
        };
      }
    )
  ];
}
