{
  lib,
  config,
  ...
}:
let
  isServer = builtins.elem config.networking.hostName [ "charon" ];
in
lib.mkIf config.services.tailscale.enable {
  services.tailscale.extraSetFlags = [
    "--accept-routes"
    "--ssh"
  ]
  ++ lib.optionals isServer [
    "--advertise-connector"
    "--advertise-exit-node"
  ];

  services.tailscale.extraUpFlags = lib.optionals isServer [
    "--advertise-tags=tag:server"
  ];

  services.tailscale.useRoutingFeatures = if isServer then "server" else "client";

  # https://tailscale.com/docs/reference/best-practices/performance#linux-optimizations-for-subnet-routers-and-exit-nodes
  systemd.network.links."50-tailscale" = lib.mkIf isServer {
    matchConfig.Type = "ether";

    linkConfig = {
      GenericReceiveOffloadList = false; # rx-gro-list off
      GenericReceiveOffloadUDPForwarding = true; # rx-udp-gro-forwarding on
    };
  };
}
