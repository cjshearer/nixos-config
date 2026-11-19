{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.users.cjshearer.programs.dusklight.enable = lib.mkEnableOption "dusklight";

  config = lib.mkIf config.users.cjshearer.programs.dusklight.enable {
    home-manager.users.cjshearer.home.packages = [
      (pkgs.symlinkJoin {
        name = "dusklight-webdav";
        paths = [ pkgs.dusklight ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/dusklight --add-flags "--user-dir /mnt/onedrive/Games/Dusklight"
        '';
      })
    ];

    users.cjshearer.services.rclone.webdav.client.enable = lib.mkDefault true;
  };
}
