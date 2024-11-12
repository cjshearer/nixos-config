{ systemConfig, lib, config, pkgs, ... }: lib.mkIf config.services.tailscale.enable {
  services.tailscale.extraUpFlags = [ "--ssh" "--reset" ];
  services.tailscale.package = pkgs.tailscale;
}
