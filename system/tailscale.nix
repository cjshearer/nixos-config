{ systemConfig, lib, config, pkgs, ... }: lib.mkIf config.services.tailscale.enable {
  # I don't want to use authkeyfile. It's a workaround for https://github.com/nixos/nixpkgs/issues/276912
  services.tailscale.authKeyFile = /home/${systemConfig.username}/.config/ts-auth-key;
  services.tailscale.package = pkgs.unstable.tailscale;
  services.tailscale.extraUpFlags = [ "--ssh" "--reset" ];
}
