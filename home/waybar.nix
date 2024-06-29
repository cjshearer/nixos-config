{ lib, config, pkgs, ... }: lib.mkIf config.programs.waybar.enable {
  # force reload waybar: pkill waybar && hyprctl dispatch exec waybar
  programs.waybar.settings = {
    mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      spacing = 4;
      modules-center = [
        "hyprland/workspaces"
        "clock"
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
        on-click = lib.mkIf config.programs.pavucontrol.enable "${pkgs.pavucontrol}/bin/pavucontrol";
      };
    };
  };

  fonts.fontAwesome.enable = true;
  programs.waybar.style = ''
    * {
      border: none;
      border-radius: 0px;
      font-family: 'Roboto', 'Font Awesome';
    }

    window#waybar {
      background-color: transparent;
      color: #ffffff;
    }
  '';
} 
