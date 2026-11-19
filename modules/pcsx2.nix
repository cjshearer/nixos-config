{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.users.cjshearer.programs.pcsx2.enable = lib.mkEnableOption "PCSX2";

  config = lib.mkIf config.users.cjshearer.programs.pcsx2.enable {
    home-manager.users.cjshearer.home.packages = [
      (pkgs.symlinkJoin {
        name = "pcsx2-webdav";
        paths = [ pkgs.pcsx2 ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/pcsx2-qt --set XDG_CONFIG_HOME /mnt/onedrive/Games
        '';
      })
    ];

    users.cjshearer.services.rclone.webdav.client.enable = lib.mkDefault true;
  };
}
