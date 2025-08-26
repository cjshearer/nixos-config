{
  lib,
  ...
}:
{
  options.home-manager.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submoduleWith {
        modules = [
          (
            {
              config,
              lib,
              pkgs,
              ...
            }:
            let
              cfg = config.programs.devenv;
            in
            {
              options.programs.devenv.enable = lib.mkEnableOption "devenv";

              config = lib.mkIf cfg.enable {
                home.packages = [ pkgs.devenv ];
              };
            }
          )
        ];
      }
    );
  };
}
