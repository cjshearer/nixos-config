{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.users.cjshearer.programs.dusklight.enable = lib.mkEnableOption "dusklight";

  config = lib.mkIf config.users.cjshearer.programs.dusklight.enable {
    home-manager.users.cjshearer.home.packages = [ pkgs.dusklight ];

    # Keep local game saves mirrored with OneDrive via the rclone bisync operation engine.
    users.cjshearer.services.rclone.operations.dusklight = {
      enable = true;
      operation = "bisync";
      src = "onedrive:Games/Dusklight/USA";
      dst = "/home/cjshearer/.local/share/TwilitRealm/Dusklight/USA";
    };
  };
}
