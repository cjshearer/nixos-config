{
  lib,
  config,
  ...
}:
# https://github.com/simonwjackson/mountainous/blob/main/modules/nixos/services/photos/default.nix
# https://github.com/sarveshrulz/nixos_config/blob/main/system/raspberrypi/users/sarvesh/home.nix
# https://github.com/simisimis/s/blob/4b39dccbc5bc850572e7eab40aa9b6dcd20efe65/hosts/kouti/proxy.nix#L348-L360
# state can be removed with:
# sudo rm -rf /var/lib/{immich,postgresql,redis-immich} /var/cache/immich/
lib.mkIf config.services.immich.enable {
  services.immich.database.name = "cjshearer";
  services.immich.database.user = "cjshearer";
  services.immich.group = "users";
  services.immich.host = "127.0.0.1";
  services.immich.mediaLocation = "${config.users.cjshearer.services.rclone.onedrive.mountPoint}/app/immich";
  services.immich.user = "cjshearer";

  services.tailscale.enable = true;

  systemd.services.immich-server.requisite = [ "rclone-mount\:@onedrive.service" ];
  systemd.services.immich-server.wants = [ "tailscaled-serve-immich.service" ];

  systemd.services.tailscaled-serve-immich = {
    partOf = [ "immich-server.service" ];
    requires = [ "tailscaled.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --service=svc:photos ${builtins.toString config.services.immich.port}";
      ExecStop = "${config.services.tailscale.package}/bin/tailscale serve drain svc:photos";
      RemainAfterExit = true;
    };
  };

  users.cjshearer.services.rclone.onedrive.enable = true;
}
