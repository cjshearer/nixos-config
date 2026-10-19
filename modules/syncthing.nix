# Syncthing mesh that exists only on the tailnet.
#
# Identity is a deterministic function of the hostname. The keys are not a
# security boundary here: Tailscale is. Deriving them means a rebuilt host comes
# back with the same device ID and there is no secret to store or distribute.
#
# The sync protocol itself is TLS and cannot be disabled. The point of the
# controls below is that no packet outside the tailnet can reach or leave the
# Syncthing process:
#
#   - discovery, relaying, NAT traversal, STUN, usage reporting, crash reporting
#     and auto-upgrade are all off
#   - the listener binds 0.0.0.0:22000, but the nftables firewall only opens
#     22000 on tailscale0
#   - the service cgroup additionally denies every source/destination address
#     outside the Tailscale IPv4/IPv6 ranges and loopback
#
# The cgroup filter is the important one: it still holds if the firewall is
# disabled, if another service opens the port, or if Syncthing ever tries to
# dial a public address.
#
# This module only provides the mesh and its identities. Which folders are
# shared is application configuration and belongs with the service that owns
# the data, so a host can join the mesh without being forced into a particular
# folder layout.
{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.users.cjshearer.services.syncthing;
  hostName = config.networking.hostName;

  # Borrowed from modules/nix-substituters.nix: ask the flake for every host
  # that opted into the mesh, rather than maintaining a second host list.
  peers = lib.remove hostName (
    builtins.attrNames (
      lib.filterAttrs
        (_: host: host.config.users.cjshearer.services.syncthing.enable or false)
        self.nixosConfigurations
    )
  );

  nixHosts = [ hostName ] ++ peers;

  # Salmoneus is an Android device, so it manages its own identity instead of
  # deriving one from a hostname. It is part of every mesh: any host that joins
  # can reach the phone without repeating this ID in each host's configuration.
  extraDevices = cfg.extraDevices // {
    salmoneus = {
      id = "PBZ3WST-MSVTFVK-6W6LXJP-6ZET3IZ-LK65ML5-Y4CM5FM-JMBUQXM-HPPOEQJ";
      addresses = [ "tcp4://salmoneus:22000" ];
    };
  };
  extraNames = builtins.attrNames extraDevices;
  allNames = nixHosts ++ extraNames;

  syncthingIdentity = pkgs.callPackage ../pkgs/syncthing-identity { };

  mkKeys =
    host:
    pkgs.runCommand "syncthing-keys-${host}" {
      nativeBuildInputs = [ syncthingIdentity ];
    } ''
      mkdir -p $out
      ${lib.getExe syncthingIdentity} \
        --host ${host} \
        --cert $out/cert.pem \
        --key $out/key.pem \
        --id $out/device-id
    '';

  keys = lib.genAttrs nixHosts mkKeys;
  derivedIds = lib.mapAttrs (
    _: key: lib.removeSuffix "\n" (builtins.readFile "${key}/device-id")
  ) keys;
  ids = derivedIds // lib.mapAttrs (_: device: device.id) extraDevices;
  localKey = keys.${hostName};
in
{
  options.users.cjshearer.services.syncthing = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.services.tailscale.enable;
      description = "Join the Syncthing mesh. Requires Tailscale.";
    };

    extraDevices = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            id = lib.mkOption { type = lib.types.str; };
            addresses = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
        }
      );
      default = { };
      description = "Devices that manage their own identity, such as Android.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = "cjshearer";
      group = "users";
      dataDir = "/home/cjshearer";
      guiAddress = "127.0.0.1:8384";

      cert = "${localKey}/cert.pem";
      key = "${localKey}/key.pem";

      settings = {
        options = {
          # IPv4 TCP only; no QUIC/UDP and no IPv6 listener.
          listenAddresses = [ "tcp4://0.0.0.0:22000" ];

          # No discovery of any kind, no relays, no NAT traversal, no STUN.
          globalAnnounceServers = [ ];
          globalAnnounceEnabled = false;
          localAnnounceEnabled = false;
          relaysEnabled = false;
          natEnabled = false;
          stunServers = [ ];
          announceLANAddresses = false;
          reconnectIntervalS = 60;

          # No phones home.
          urAccepted = -1;
          autoUpgradeIntervalH = 0;
          crashReportingEnabled = false;
          startBrowser = false;
        };

        # Include the local device so overrideDevices doesn't delete it; its
        # address is intentionally empty.
        devices = lib.genAttrs allNames (
          name:
          if builtins.elem name extraNames then {
            id = extraDevices.${name}.id;
            addresses = extraDevices.${name}.addresses;
          } else {
            id = ids.${name};
            addresses = lib.optional (name != hostName) "tcp4://${name}:22000";
          }
        );
      };
    };

    # Defense in depth: only the tailnet interface may reach the sync port.
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22000 ];

    systemd.services.syncthing = {
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];

      serviceConfig = {
        # Primary enforcement. Allow only Tailscale traffic and loopback; deny
        # everything else in both directions at the cgroup level.
        IPAddressAllow = [
          "100.64.0.0/10"
          "fd7a:115c:a1e0::/48"
          "127.0.0.0/8"
          "::1/128"
        ];
        IPAddressDeny = [
          "0.0.0.0/0"
          "::/0"
        ];
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
          "AF_NETLINK"
        ];
      };
    };
  };
}
