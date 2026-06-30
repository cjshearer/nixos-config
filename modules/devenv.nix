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
        options.programs.devenv.enable = lib.mkEnableOption "devenv";

        config = lib.mkIf config.programs.devenv.enable {
          home.packages = [ pkgs.devenv ];
        };
      }
    )
  ];
}
