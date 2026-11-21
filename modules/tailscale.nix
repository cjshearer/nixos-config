{
  lib,
  config,
  ...
}:
let
  isServer = builtins.elem config.networking.hostName [ "charon" ];
in
{
  config = lib.mkIf config.services.tailscale.enable {
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

    # The upstream module uses `serve set-config`, which infers the listener
    # protocol from the target. It therefore cannot recreate an HTTPS listener
    # backed by an HTTP server and fails with "port 443 is already serving
    # https" (https://github.com/tailscale/tailscale/issues/18381). Use NixOS's
    # native serve implementation until this is fixed.
    services.tailscale.serve.enable = lib.mkForce false;

    systemd.services = lib.mapAttrs' (
      name: service:
      let
        serviceName = "svc:${name}";
      in
      lib.nameValuePair "tailscaled-serve-${name}" {
        description = "Tailscale Serve proxy for ${serviceName}";

        after = [ "tailscaled.service" ];
        requires = [ "tailscaled.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.mapAttrsToList (
            endpoint: target:
            "${lib.getExe config.services.tailscale.package} serve --service=${serviceName} ${
              {
                http = "--https";
                https = "--https";
                tcp = "--tcp";
                "tls-terminated-tcp" = "--tls-terminated-tcp";
              }
              .${builtins.head (lib.splitString ":" target)}
            }=${lib.last (lib.splitString ":" endpoint)} ${lib.escapeShellArg target}"
          ) service.endpoints;
          ExecStop = "${lib.getExe config.services.tailscale.package} serve drain ${serviceName}";
          RemainAfterExit = true;
        };
      }
    ) config.services.tailscale.serve.services;
  };
}
