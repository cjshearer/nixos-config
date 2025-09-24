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
              cfg = config.programs.entr;
            in
            {
              options.programs.entr.enable = lib.mkEnableOption "entr";

              config = lib.mkIf cfg.enable {
                home.packages = [ pkgs.entr ];
              };
            }
          )
        ];
      }
    );
  };
}
