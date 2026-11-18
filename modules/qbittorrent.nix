{
  lib,
  config,
  pkgs,
  ...
}:
lib.mkIf config.services.qbittorrent.enable {
  services.qbittorrent = {
    package = pkgs.qbittorrent-nox.overrideAttrs (old: {
      version = "5.2.4";
      src = old.src.override {
        rev = "release-5.2.4";
        hash = "sha256-HCfcwO8GEi4Ixfa+Ue2vgWyp407R3VDGRoLxUqJl1eM=";
      };
    });
    user = "cjshearer";
    group = "users";
    profileDir = "/home/cjshearer/.local/share/qBittorrent";
    serverConfig = {
      LegalNotice.Accepted = true;
      Preferences.Downloads.SavePath = "/home/cjshearer/onedrive-uploads";
      Preferences.Downloads.TempPath = "/tmp/qbittorrent/downloads";
      Preferences.Downloads.TempPathEnabled = true;
      Preferences.WebUI.AuthSubnetWhitelist = "100.64.0.0/10";
      Preferences.WebUI.AuthSubnetWhitelistEnabled = true;
      Preferences.WebUI.LocalHostAuth = false;
    };
  };

  systemd.services.tailscaled-serve-qbittorrent = {
    partOf = [ "qbittorrent.service" ];
    requires = [ "tailscaled.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --service=svc:torrent ${builtins.toString config.services.qbittorrent.webuiPort}";
      ExecStop = "${config.services.tailscale.package}/bin/tailscale serve drain svc:torrent";
      RemainAfterExit = true;
    };
  };

  systemd.services.qbittorrent.serviceConfig.PrivateUsers = lib.mkForce false;
  systemd.services.qbittorrent.serviceConfig.ProtectHome = lib.mkForce false;

  users.cjshearer.services.rclone.operations.qbittorrent = {
    src = "/home/cjshearer/.local/share/qBittorrent";
    dst = "onedrive:/app/qBittorrent";
    enable = true;
    operation = "bisync";
  };

  users.cjshearer.services.rclone.operations.onedrive-uploads = {
    src = "/home/cjshearer/onedrive-uploads";
    dst = "onedrive:/";
    enable = true;
    operation = "copy";
  };
}
