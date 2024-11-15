{ systemConfig, lib, config, pkgs, ... }: lib.mkIf config.services.tailscale.enable {

  services.tailscale.extraUpFlags =
    [
      "--ssh"
      "--reset"
    ] ++ builtins.attrNames (
      lib.filterAttrs
        (flag: hostnames: builtins.elem systemConfig.hostname hostnames)
        {
          "--advertise-exit-node" = [ "charon" ];
        }
    );

  services.tailscale.useRoutingFeatures = {
    athamas = "client";
    charon = "server";
    sisyphus = "client";
  }.${systemConfig.hostname};
}
