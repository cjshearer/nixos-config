{ pkgs, ... }: {
  programs.waybar.enable = true;
  # https =//nix-community.github.io/home-manager/options.xhtml#opt-programs.waybar.settings
  # force reload waybar: pkill waybar && hyprctl dispatch exec waybar
  programs.waybar.settings = {
    mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      spacing = 4;
      modules-left = [
        "hyprland/workspaces"
      ];
      modules-center = [
        "clock"
      ];
      modules-right = [
        "pulseaudio"
      ];
      clock = {
        format = "{:%I:%M}";
      };
      pulseaudio = {
        format = "{volume}% {icon} {format_source}";
        format-bluetooth = "{volume}%  {icon} {format_source}";
        format-bluetooth-muted = "  {icon} {format_source}";
        format-muted = " {format_source}";
        format-source = "{volume}% ";
        format-source-muted = "";
        format-icons = {
          headphone = "";
          handsfree = "";
          headset = "";
          phone = "";
          portable = "";
          car = "";
          default = [ "" "" "" ];
        };
        # TODO: probably need home.packages = [pavucontrol]
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };
    };
  };
  programs.waybar.style = ''
    * {
      font-family: 'Roboto', 'Font Awesome';
    }
  '';

  ## Font Awesome
  home.packages = with pkgs; [ font-awesome ];
  fonts.fontconfig.enable = true;

  ## Hyprland
  wayland.windowManager.hyprland.settings.exec-once = [ "waybar" ];
  wayland.windowManager.hyprland.settings = {
    # https://github.com/librephoenix/nixos-config/blob/e5260a945e77037aa01a49ced7166fb7533152b1/user/wm/hyprland/hyprland.nix#L193
    # TODO: ensure window floats in correct position
    "$pavucontrol" = "class:^(pavucontrol)$";
    windowrulev2 = [
      "float,$pavucontrol"
      "size 86% 40%,$pavucontrol"
      "move 50% 6%,$pavucontrol"
      "workspace special silent,$pavucontrol"
      "opacity 0.80,$pavucontrol"
    ];
  };
} 
