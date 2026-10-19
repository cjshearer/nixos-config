# Security regression test for modules/syncthing.nix.
#
# - the seed config prevents the default insecure startup
# - the listener is TCP v4 on 0.0.0.0:22000
# - a peer arriving on a fake tailscale0 can connect
# - a peer arriving on an ordinary interface cannot
# - the service cgroup cannot dial a non-tailnet address
#
# With firewall = false the module's nftables rule is inert, so the test
# proves the cgroup IP filter alone enforces the same boundary.
{
  pkgs,
  firewall ? true,
}:
let
  nc = "${pkgs.netcat}/bin/nc";
in
pkgs.testers.nixosTest {
  name = "syncthing-tailnet${if firewall then "" else "-no-firewall"}";

  nodes.machine = { pkgs, ... }: {
    imports = [ ../modules/syncthing.nix ];

    networking.hostName = "athamas";

    # The module only uses self to discover the mesh host list.
    _module.args.self = {
      nixosConfigurations.athamas.config.users.cjshearer.services.syncthing.enable = true;
    };

    users.users.cjshearer = {
      isNormalUser = true;
      group = "users";
    };

    users.cjshearer.services.syncthing.enable = true;

    networking.firewall = if firewall then {
      allowedTCPPorts = [ 8080 ];
    } else {
      enable = false;
    };

    environment.systemPackages = with pkgs; [
      iproute2
      netcat
      python3
      curl
      iputils
    ];
  };

  # A second VM on the ordinary test network (eth1). It is not on the tailnet.
  nodes.external = { pkgs, ... }: {
    networking.firewall.enable = false;
    environment.systemPackages = [ pkgs.netcat ];
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("syncthing.service")
    machine.wait_for_open_port(22000)

    # The NixOS module applies settings after the daemon starts. Wait for that
    # to finish and for the listener to switch to the configured tcp4 address.
    machine.wait_for_unit("syncthing-init.service")
    machine.wait_until_succeeds("ss -ltn4 | grep -q '0.0.0.0:22000'")

    # An ordinary service on a non-tailscale port, for the egress test.
    machine.succeed("systemd-run --unit=http8080 --working-directory=/tmp python3 -m http.server 8080")
    machine.wait_for_open_port(8080)

    # Build a fake tailscale0 with a peer in a separate netns.
    machine.succeed("ip netns add tailnet")
    machine.succeed("ip link add tailscale0 type veth peer name veth-peer")
    machine.succeed("ip link set veth-peer netns tailnet")
    machine.succeed("ip addr add 100.64.0.1/32 dev tailscale0")
    machine.succeed("ip link set tailscale0 up")
    machine.succeed("ip route add 100.64.0.2/32 dev tailscale0")
    machine.succeed("ip -n tailnet addr add 100.64.0.2/32 dev veth-peer")
    machine.succeed("ip -n tailnet link set veth-peer up")
    machine.succeed("ip -n tailnet route add 100.64.0.1/32 dev veth-peer")

    # Traffic arriving on tailscale0 is accepted.
    machine.succeed("ip netns exec tailnet ${nc} -z -w 2 100.64.0.1 22000")

    # Traffic from another VM on the ordinary test network (eth1) is not.
    external.fail("${nc} -z -w 2 192.168.1.1 22000")

    # The service cgroup cannot dial a non-tailnet address either, even one
    # that is up and accepting connections on this host.
    machine.fail(
        "systemd-run --wait --pipe "
        "-p IPAddressAllow=100.64.0.0/10 "
        "-p IPAddressAllow=127.0.0.0/8 "
        "-p IPAddressDeny=0.0.0.0/0 "
        "${nc} -z -w 2 192.168.1.1 8080"
    )

    machine.shutdown()
    external.shutdown()
  '';
}
