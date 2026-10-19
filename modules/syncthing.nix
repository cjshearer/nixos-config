# Syncthing mesh that exists only on the tailnet.
#
# Syncthing's sync protocol uses TLS and cannot be disabled, which means that if we want to
# preconfigure devices to sync with each other, we need to know at build time what device id the
# other device has, leading us to an indesirable workflow of applying nix configs that enable
# syncthing, grabbing the generated device id, then adding that to the nix configs, then reapplying
# so other peers see that device.
#
# Because we use Tailscale for secure communications, Syncthing's certificate exchange is pure
# overhead, so to avoid managing it we derive certificates deterministically from the hostname of
# each device, enforcing tailscale as the access control through firewall and cgroup filters:
#
# - discovery, relaying, NAT traversal, STUN, usage reporting, crash reporting and auto-upgrade
#   are all off
# - the listener binds 0.0.0.0:22000, but iptables only opens 22000 on tailscale0
# - the service cgroup additionally denies every source/destination address outside the Tailscale
#   IPv4/IPv6 ranges and loopback
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

  # Every enabled host, including this one: the module only configures enabled
  # hosts, so this is the whole mesh.
  meshHosts = builtins.attrNames (
    lib.filterAttrs (
      _: host: host.config.users.cjshearer.services.syncthing.enable
    ) self.nixosConfigurations
  );

  syncthingIdentity = pkgs.buildPackages.callPackage ../pkgs/syncthing-identity { };

  mkKeys =
    host:
    pkgs.buildPackages.runCommand "syncthing-keys-${host}"
      {
        nativeBuildInputs = [ syncthingIdentity ];
      }
      ''
        mkdir -p $out
        ${lib.getExe syncthingIdentity} \
          --host ${host} \
          --cert $out/cert.pem \
          --key $out/key.pem \
          --id $out/device-id
      '';

  keys = lib.genAttrs meshHosts mkKeys;
  nixDevices = lib.mapAttrs (name: key: {
    id = lib.removeSuffix "\n" (builtins.readFile "${key}/device-id");
    addresses = lib.optional (name != hostName) "tcp4://${name}:22000";
  }) keys;
  localKey = keys.${hostName};
in
{
  options.users.cjshearer.services.syncthing = {
    enable = lib.mkEnableOption "the Syncthing mesh";

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
      default = {
        salmoneus = {
          id = "PBZ3WST-MSVTFVK-6W6LXJP-6ZET3IZ-LK65ML5-Y4CM5FM-JMBUQXM-HPPOEQJ";
          addresses = [ "tcp4://salmoneus:22000" ];
        };
      };
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

        # Include the local device so overrideDevices doesn't delete it; its address is
        # intentionally empty.
        devices = nixDevices // cfg.extraDevices;
      };
    };

    # Defense in depth: only the tailnet interface may reach the sync port.
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22000 ];

    systemd.services.syncthing = {
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];

      serviceConfig = {
        # Primary enforcement. Allow only Tailscale traffic and loopback; deny everything else in
        # both directions at the cgroup level.
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
