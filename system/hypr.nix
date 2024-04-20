{ lib, config, pkgs, ... }: lib.mkIf config.programs.hyprland.enable {
  # https://github.com/ryan4yin/nix-config/blob/main/modules/nixos/desktop.nix#L30_L60
  services.xserver.enable = false;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };
}
