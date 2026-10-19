# Security regression test for modules/syncthing.nix.
#
# The cgroup IP filter is the enforced boundary, so the firewall is off here:
# the NixOS firewall dropping traffic on a non-trusted interface is a default,
# not something this module decides.
#
# - the listener is TCP v4 on 0.0.0.0:22000
# - a peer arriving on a fake tailscale0 can connect
# - a peer arriving on an ordinary interface cannot
# - the unit carries the tailnet-only filter in both directions
{
  pkgs,
  ...
}:
let
  nc = "${pkgs.netcat}/bin/nc";
in
pkgs.testers.nixosTest {
  name = "syncthing-tailnet";

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

    networking.firewall.enable = false;

    environment.systemPackages = with pkgs; [
      iproute2
      netcat
    ];
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("syncthing.service")

    # The NixOS module applies settings after the daemon starts. Wait for that
    # to finish and for the listener to switch to the configured tcp4 address.
    machine.wait_for_unit("syncthing-init.service")
    machine.wait_until_succeeds("ss -ltn4 | grep -q '0.0.0.0:22000'")

    # Two peers in a netns: one on a fake tailscale0, one on an ordinary link.
    machine.succeed("ip netns add peers")
    machine.succeed("ip link add tailscale0 type veth peer name veth-tail")
    machine.succeed("ip link set veth-tail netns peers")
    machine.succeed("ip addr add 100.64.0.1/32 dev tailscale0")
    machine.succeed("ip link set tailscale0 up")
    machine.succeed("ip route add 100.64.0.2/32 dev tailscale0")
    machine.succeed("ip -n peers addr add 100.64.0.2/32 dev veth-tail")
    machine.succeed("ip -n peers link set veth-tail up")
    machine.succeed("ip -n peers route add 100.64.0.1/32 dev veth-tail")

    machine.succeed("ip link add lan0 type veth peer name veth-lan")
    machine.succeed("ip link set veth-lan netns peers")
    machine.succeed("ip addr add 10.9.9.1/32 dev lan0")
    machine.succeed("ip link set lan0 up")
    machine.succeed("ip route add 10.9.9.2/32 dev lan0")
    machine.succeed("ip -n peers addr add 10.9.9.2/32 dev veth-lan")
    machine.succeed("ip -n peers link set veth-lan up")
    machine.succeed("ip -n peers route add 10.9.9.1/32 dev veth-lan")

    # Traffic arriving on tailscale0 is accepted.
    machine.succeed("ip netns exec peers ${nc} -z -w 2 100.64.0.1 22000")

    # Traffic arriving on an ordinary interface is not, with no firewall to
    # blame: the cgroup filter drops it.
    machine.fail("ip netns exec peers ${nc} -z -w 2 10.9.9.1 22000")

    # The unit carries the tailnet-only filter in both directions. The lists
    # are unordered sets, so compare sets rather than matching a string.
    expected = {
        "IPAddressAllow": {"100.64.0.0/10", "fd7a:115c:a1e0::/48"},
        "IPAddressDeny": {"0.0.0.0/0", "::/0"},
    }
    for prop, entries in expected.items():
        actual = set(machine.succeed(f"systemctl show syncthing -p {prop} --value").split())
        assert entries <= actual, f"{prop} is missing {entries - actual}"
  '';
}
