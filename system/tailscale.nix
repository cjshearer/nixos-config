{ systemConfig, lib, config, pkgs, ... }: lib.mkIf config.services.tailscale.enable {
  services.tailscale.package = pkgs.unstable.tailscale;
  services.tailscale.extraUpFlags = [ "--ssh" "--reset" ];
}
