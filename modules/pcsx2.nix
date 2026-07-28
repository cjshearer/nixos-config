{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.users.cjshearer.programs.pcsx2.enable = lib.mkEnableOption "PCSX2";

  config = lib.mkIf config.users.cjshearer.programs.pcsx2.enable {
    home-manager.users.cjshearer.home.packages = [ pkgs.pcsx2 ];

    users.cjshearer.services.rclone.operations.pcsx2 = {
      enable = true;
      exclude = [
        "/cache/"
        "/logs/"
      ];
      operation = "bisync";
      src = "onedrive:Games/PCSX2";
      dst = "/home/cjshearer/.config/PCSX2/";
    };
  };
}
