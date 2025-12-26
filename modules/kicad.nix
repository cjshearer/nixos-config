{
  lib,
  config,
  ...
}:
let
  kicad = (
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.kicad;
    in
    {
      options.programs.kicad = {
        enable = lib.mkEnableOption "KiCad";

        package = lib.mkPackageOption pkgs "kicad" { };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.kicad ];
      };
    }
  );
in
{
  options.home-manager.users = lib.mkOption {
    type =
      with lib.types;
      attrsOf (
        lib.types.submoduleWith {
          modules = [ kicad ];
        }
      );
  };

  options.users.cjshearer.programs.kicad.enable = lib.mkEnableOption "KiCad";

  config = lib.mkIf config.users.cjshearer.programs.kicad.enable {
    home-manager.users.cjshearer.programs.kicad.enable = true;
  };
}
