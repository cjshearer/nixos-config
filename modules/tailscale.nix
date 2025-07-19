{ lib, config, pkgs, ... }: lib.mkIf config.services.tailscale.enable {
  services.tailscale.extraSetFlags =
    [
      "--ssh"
    ] ++ builtins.attrNames (
      lib.filterAttrs
        (flag: hostnames: builtins.elem config.networking.hostName hostnames)
        {
          "--advertise-exit-node" = [ "charon" ];
        }
    );

  services.tailscale.useRoutingFeatures = {
    charon = "server";
  }.${config.networking.hostName} or "client";

  # Workaround for "Failed to start Network Manager Wait Online." Toggle this on while switching
  # configurations if you see this failure
  # systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
}
