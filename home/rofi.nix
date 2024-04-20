{ lib, config, pkgs, ... }: lib.mkIf config.programs.rofi.enable {
  programs.rofi.package = pkgs.rofi-wayland;
  programs.rofi.theme = "Arc-Dark";
}
