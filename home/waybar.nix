{ lib, config, pkgs, ... }: lib.mkIf config.programs.waybar.enable {
  # for rapid development (it appears reload isn't always accurate):
  # cd ~/.config/waybar/
  # cp --remove-destination "$(readlink config)" config
  # cp --remove-destination "$(readlink style.css)" style.css
  # nix-shell -p entr --command "ls | entr -s 'pkill -SIGUSR2 waybar'"
  # 
  # Don't forget to remove the files when you're done, else home-manager
  # will pitch a fit when you try to rebuild:
  # rm ~/.config/waybar/{config,style.css}
  # 
  # to fully relaunch waybar:
  # pkill waybar & hyprctl dispatch exec waybar
  # 
  # To convert config.json to nix: https://json-to-nix.pages.dev/
  # For gtk style variables: https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/named-colors.html
  # 
  # Config adapted from: https://github.com/robertjk/dotfiles/blob/master/.config/waybar/config
  programs.waybar.settings = {
    mainBar = {
      backlight = {
        format = " {percent}%";
        interval = 2;
        on-scroll-down = "brightnessctl set 2%-";
        on-scroll-up = "brightnessctl set +2%";
      };
      battery = {
        format = " {icon} {capacity}%";
        format-discharging = "{icon} {capacity}%";
        format-icons = [
          ""
          ""
          ""
          ""
          ""
        ];
        interval = 10;
        states = {
          critical = 15;
          warning = 30;
        };
        tooltip = true;
      };
      "clock#date" = {
        format = "{:%e %b %Y}";
        interval = 10;
      };
      "clock#time" = {
        format = "{:%H:%M:%S}";
        interval = 1;
      };
      cpu = {
        format = " {usage}% ({load})";
        interval = 3;
        states = {
          critical = 90;
          warning = 70;
        };
      };
      height = 32;
      layer = "bottom";
      memory = {
        format = " {}%";
        interval = 3;
        states = {
          critical = 90;
          warning = 70;
        };
      };
      modules-center = [
        "clock#date"
        "clock#time"
      ];
      modules-left = [
        "hyprland/workspaces"
      ];
      modules-right = [
        "network"
        "pulseaudio"
        "cpu"
        "memory"
        "temperature"
        "backlight"
        "tray"
        "battery"
      ];
      network = {
        format-disconnected = " Disconnected";
        format-ethernet = " {ifname}: {ipaddr}/{cidr}";
        format-wifi = " {essid}";
        interval = 3;
        tooltip-format = "{ifname}: {ipaddr} (signal: {signalStrength}%)";
      };
      position = "top";
      pulseaudio = {
        format = "{icon} {volume}% {format_source}";
        format-bluetooth = " {volume}% {format_source}";
        format-bluetooth-muted = "  {volume}% {format_source}";
        format-icons = {
          car = "";
          default = [
            ""
            ""
            ""
          ];
          handsfree = "";
          headphone = "";
          headset = "";
          phone = "";
          portable = "";
        };
        format-muted = " {volume}% {format_source}";
        format-source = "  {volume}%";
        format-source-muted = " {volume}%";
        on-click = lib.getExe pkgs.pavucontrol;
        scroll-step = 2;
        tooltip = true;
      };
      temperature = {
        critical-threshold = 75;
        format = "{icon} {temperatureC}°C";
        format-icons = [
          ""
          ""
          ""
          ""
          ""
        ];
        interval = 3;
      };
      tray = {
        icon-size = 16;
        spacing = 10;
      };
    };
  };

  fonts.fontAwesome.enable = true;
  programs.waybar.style = ''
    /* Adapted from: https://github.com/robertjk/dotfiles/blob/master/.config/waybar/style.css */
    @keyframes blink-warning {
      70% {
        color: white;
      }

      to {
        color: white;
        background-color: @warning_color;
      }
    }

    @keyframes blink-critical {
      70% {
        color: white;
      }

      to {
        color: white;
        background-color: @error_color;
      }
    }

    * {
      border: none;
      border-radius: 0;
      min-height: 0;
      margin: 0;
      padding: 0;
      font-family: 'monospace', 'Font Awesome';
    }

    .module {
      margin-left: 10px;
      margin-right: 10px;
    }

    #battery {
      animation-timing-function: linear;
      animation-iteration-count: infinite;
      animation-direction: alternate;
    }

    #battery.warning {
      color: @warning_color;
    }

    #battery.critical {
      color: @error_color;
    }

    #battery.warning.discharging {
      animation-name: blink-warning;
      animation-duration: 3s;
    }

    #battery.critical.discharging {
      animation-name: blink-critical;
      animation-duration: 2s;
    }

    #cpu.warning {
      color: @warning_color;
    }

    #cpu.critical {
      color: @error_color;
    }

    #waybar {
      background: @headerbar_bg_color;
      color: @theme_text_color;
    }

    #workspaces {
      margin-left: 0px;
    }

    #workspaces button {
      padding-left: 10px;
      padding-right: 10px;
      background-color: transparent;
    }

    /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
    #workspaces button:hover {
      box-shadow: inherit;
      text-shadow: inherit;
    }

    #workspaces button.visible {
      background: @theme_unfocused_selected_bg_color;
    }
  '';
} 
