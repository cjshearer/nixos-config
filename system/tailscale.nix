{ systemConfig, lib, config, pkgs, ... }: lib.mkIf config.services.tailscale.enable {
  services.tailscale.extraUpFlags = [ "--ssh" "--reset" ];
  services.tailscale.package = pkgs.unstable.tailscale;
  services.tailscale.permitCertUid = lib.mkIf config.services.caddy.enable
    config.services.caddy.user;
}
