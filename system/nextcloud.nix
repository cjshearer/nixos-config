{ systemConfig, lib, config, pkgs, ... }: lib.mkIf config.services.nextcloud.enable {
  services.nextcloud = {
    # apps can also be managed by nix with extraApps = {};
    appstoreEnable = true;
    config.adminpassFile = "/etc/nextcloud/adminpassFile";
    configureRedis = true;
    database.createLocally = true;
    extraAppsEnable = true;
    # would need to use caddy's tailscale integration to make this work with https
    hostName = "${systemConfig.hostname}.beardie-dragon.ts.net";
    maxUploadSize = "16G";
    package = pkgs.nextcloud29;
    settings.trusted_domains = [ "100.82.255.118" ];
  };
}
