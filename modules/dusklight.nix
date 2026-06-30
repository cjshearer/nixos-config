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

    users.cjshearer.services.rclone.operations.dusklight = {
      enable = true;
      exclude = [
        "/*cache.db"
        "/logs/"
      ];
      operation = "bisync";
      src = "onedrive:Games/Dusklight";
      dst = "/home/cjshearer/.local/share/TwilitRealm/Dusklight";
    };
  };
}
