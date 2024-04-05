{ pkgs, lib, ... }:
{
  dconf.enable = true;
  dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = [
        "pop-shell@system76.com"
      ];
    };

    "org/gnome/shell/extensions/pop-shell" = {
      active-hint = false;
      gap-outer = lib.hm.gvariant.mkUint32 0;
      gap-inner = lib.hm.gvariant.mkUint32 0;
    };
  };

  home.packages = with pkgs; [ gnomeExtensions.pop-shell ];
}
