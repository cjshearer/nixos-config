{
  lib,
  config,
  ...
}:
# https://github.com/simonwjackson/mountainous/blob/main/modules/nixos/services/photos/default.nix
# https://github.com/sarveshrulz/nixos_config/blob/main/system/raspberrypi/users/sarvesh/home.nix
lib.mkIf config.services.immich.enable {
  services.immich.host = "127.0.0.1";
  systemd.services.tailscale-serve-immich = {
    description = "Configure Tailscale serving features";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --service=svc:photos ${builtins.toString config.services.immich.port}";
      ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --reset";
      RemainAfterExit = true;
    };
  };
  services.tailscale.enable = true;
}
