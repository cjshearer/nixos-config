{ config, pkgs, ... }: {
  programs.rofi.enable = true;
  programs.rofi.package = pkgs.rofi-wayland;
  programs.rofi.theme = "Arc-Dark";
  wayland.windowManager.hyprland.settings.bind = [
    "$mainMod, E, exec, rofi -show drun -show-icons"
  ];
}
