{
  lib,
  config,
  ...
}:
let
  immichLocalPath = "/var/lib/immich";
  immichRcloneUnit = config.users.cjshearer.services.rclone.operations.immich.unitName;
in
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
  services.immich.mediaLocation = immichLocalPath;
  services.immich.user = "cjshearer";

  services.tailscale.enable = true;

  systemd.services.immich-server.after = [ "${immichRcloneUnit}.service" ];
  systemd.services.immich-server.requires = [ "${immichRcloneUnit}.service" ];
  systemd.services.immich-server.wants = [
    "${immichRcloneUnit}.timer"
    "tailscaled-serve-immich.service"
  ];

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

  users.cjshearer.services.rclone.operations.immich = {
    src = immichLocalPath;
    dst = "onedrive:/app/immich";
    enable = true;
    operation = "bisync";
  };
}
