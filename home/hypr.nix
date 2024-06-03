{ lib, config, pkgs, ... }:
with lib;
mkIf config.wayland.windowManager.hyprland.enable {
  # TODO: consider using https://github.com/hyprland-community/hyprnix, which supplies better configuration for things like keybinds 
  wayland.windowManager.hyprland.extraConfig =
    strings.optionalString config.programs.hyprshot.enable ''
      bind = $mainMod, s, submap, screenshot
      submap = screenshot
      bind =, o, exec, hyprshot -m output
      bind =, o, submap, reset
      bind =, r, exec, hyprshot -m region
      bind =, r, submap, reset
      bind =, w, exec, hyprshot -m window
      bind =, w, submap, reset
      bind =, escape, submap, reset
      submap = reset
    ''
    + strings.optionalString config.programs.hyprec.enable ''
      bind = $mainMod, r, submap, screenrec
      submap = screenrec
      bind =, o, exec, hyprec -m output
      bind =, o, submap, reset
      bind =, r, exec, hyprec -m region
      bind =, r, submap, reset
      bind =, w, exec, hyprec -m window
      bind =, w, submap, reset
      bind =, s, exec, pkill wl-screenrec -SIGINT
      bind =, s, submap, reset
      bind =, escape, submap, reset
      submap = reset
    '';
  wayland.windowManager.hyprland.settings = {
    # See https://wiki.hyprland.org/Configuring/Monitors/
    monitor = ",preferred,auto,auto";

    # Some default env vars.
    env = "XCURSOR_SIZE,24";

    exec-once = optionals config.services.cliphist.enable [
      "${pkgs.wl-clipboard}/bin/wl-copy --type text --watch cliphist store"
      "${pkgs.wl-clipboard}/bin/wl-copy --type image --watch cliphist store"
    ]
    ++ optionals config.programs.waybar.enable [
      "waybar"
    ];

    # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
    input = {
      numlock_by_default = true;

      kb_layout = "us";
      kb_variant = "";
      kb_model = "";
      kb_options = "";
      kb_rules = "";

      follow_mouse = 1;
      # fix HD2 mouse not moving camera in-game
      mouse_refocus = false;

      touchpad = {
        natural_scroll = false;
      };

      sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
    };

    general = {
      # See https://wiki.hyprland.org/Configuring/Variables/ for more

      gaps_in = 2;
      gaps_out = 2;
      border_size = 2;
      "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
      "col.inactive_border" = "rgba(595959aa)";

      layout = "dwindle";

      # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
      allow_tearing = false;
    };

    decoration = {
      # See https://wiki.hyprland.org/Configuring/Variables/ for more
      rounding = 10;

      blur = {
        enabled = false;
        size = 3;
        passes = 1;
      };

      drop_shadow = true;
      shadow_range = 4;
      shadow_render_power = 3;
      "col.shadow" = "rgba(1a1a1aee)";
    };

    # https://wiki.hyprland.org/Configuring/Animations/ for more
    animations = {
      enabled = true;
      bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

      animation = [
        "windows, 1, 7, myBezier"
        "windowsOut, 1, 7, default, popin 80%"
        "border, 1, 10, default"
        "borderangle, 1, 8, default"
        "fade, 1, 2, default"
        "workspaces, 1, 4, default"
      ];
    };

    dwindle = {
      # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
      pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
      preserve_split = true; # you probably want this
    };

    master = {
      # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
      new_is_master = true;
    };

    gestures = {
      # See https://wiki.hyprland.org/Configuring/Variables/ for more
      workspace_swipe = false;
    };

    misc = {
      # See https://wiki.hyprland.org/Configuring/Variables/ for more
      disable_hyprland_logo = true;
      force_default_wallpaper = 0;
    };

    # Example per-device config
    # See https://wiki.hyprland.org/Configuring/Keywords/#executing for more
    device = [
      {
        name = "epic-mouse-v1";
        sensitivity = "-0.5";
      }
    ];

    # See https://wiki.hyprland.org/Configuring/Keywords/ for more
    "$mainMod" = "SUPER";

    # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
    bind = [
      "$mainMod, Q, exec, kitty"
      "$mainMod, C, killactive,"
      "$mainMod, M, exit,"
      "$mainMod, F, togglefloating,"
      "$mainMod SHIFT, F, fullscreen,0"
      # dwindle
      "$mainMod, P, pseudo,"
      "$mainMod, J, togglesplit,"

      # Move focus with mainMod + arrow keys
      "$mainMod, left, movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"

      # Scroll through existing workspaces with mainMod + scroll
      "$mainMod, mouse_down, workspace, e+1"
      "$mainMod, mouse_up, workspace, e-1"
    ]
    ++ optionals config.services.cliphist.enable [
      "$mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy"
    ]
    ++ optionals config.programs.rofi.enable [
      "$mainMod, E, exec, rofi -show drun -show-icons"
    ]
    ++ map
      (n: "$mainMod SHIFT, ${toString n}, movetoworkspace, ${toString (
            if n == 0
            then 10
            else n
          )}") [ 1 2 3 4 5 6 7 8 9 0 ]
    ++ map
      (n: "$mainMod, ${toString n}, workspace, ${toString (
            if n == 0
            then 10
            else n
          )}") [ 1 2 3 4 5 6 7 8 9 0 ];

    bindm = [
      # Move/resize windows with mainMod + LMB/RMB and dragging
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];

    # Bind Media Keys 
    bindel = [
      ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    ];
    bindl = [
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
      ", XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
      ", XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
    ];

    # https://wiki.hyprland.org/Configuring/Window-Rules/
    "$pavucontrol" = "class:^(pavucontrol)$";
    windowrulev2 = [
      "float, $pavucontrol"
      "size 15% 40%, $pavucontrol"
      # TODO: close on lost focus https://wiki.hyprland.org/IPC/
      # "workspace special scratchpad, $pavucontrol"
      "move onscreen cursor -50% -50%, $pavucontrol"

      # fix steam menu pop-ups immediately closing
      # https://www.reddit.com/r/hyprland/comments/17paps4/issues_with_steam_menu_popups
      "stayfocused,class:(steam),title:(^$)"
    ];
  };

  # https://wiki.hyprland.org/Nix/Hyprland-on-Home-Manager/#fixing-problems-with-themes
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 12;
  };

  gtk = {
    enable = true;
    theme = {
      package = pkgs.flat-remix-gtk;
      name = "Flat-Remix-GTK-Blue-Dark";
    };

    iconTheme = {
      package = pkgs.gnome.adwaita-icon-theme;
      name = "Adwaita";
    };
  };
}
