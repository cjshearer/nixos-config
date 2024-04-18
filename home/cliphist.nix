{ pkgs, ... }:
{
  services.cliphist.enable = true;
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "${pkgs.wl-clipboard}/bin/wl-copy --type text --watch cliphist store"
      "${pkgs.wl-clipboard}/bin/wl-copy --type image --watch cliphist store"
    ];
    bind = [
      "$mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy"
    ];
  };
}
