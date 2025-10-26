{
  config,
  lib,
  ...
}:
{
  options.users.cjshearer.programs.helix.enable = lib.mkEnableOption "helix";

  config = lib.mkIf config.users.cjshearer.programs.helix.enable {
    home-manager.users.cjshearer.programs.helix = {
      enable = true;
    };
  };
}
