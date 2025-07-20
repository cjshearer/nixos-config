{
  lib,
  config,
  pkgs,
  ...
}:
lib.mkIf config.services.desktopManager.cosmic.enable {
  services.displayManager.cosmic-greeter.enable = true;

  home-manager.users.cjshearer = {
    gtk = {
      enable = true;
      iconTheme.name = "Adwaita-dark";
      iconTheme.package = pkgs.adwaita-icon-theme;
      theme.name = "Adwaita-dark";
      theme.package = pkgs.gnome-themes-extra;
    };

    # Initial setup:
    # 1. If you have existing manual configs, move them from ~/.config/cosmic to a temporary
    #    location, or remove them if you don't care about them.
    # 2. Restart your session: `pkill cosmic-session`. This was necessary for me, as cosmic
    #    settings "desynced" from the actual settings.
    # 3. Run:
    #    `find ~/.config/cosmic -type f,l -exec echo -e '\n// {}\n' >> cosmic.ron \; -exec cat {} > cosmic.ron \;`
    #    and temporarily stage it with git. This will help you ignore default values.
    # 4. Make changes to the settings (initial setup: restore your backup) and rerun the above
    #    command.
    # 5. Use the diff between the staged default values and your now unstaged changes to
    #    cosmic.ron below. Remove cosmic.ron after you're done.
    #
    # To update settings: repeat steps 3-5.
    #
    # Troubleshooting:
    # - If home-manager fails to apply the settings, you may need to set a backup extension to allow
    #   home-manager to overwrite the existing files. I use .bak.
    # - If you have issues with settings not applying, try deleting the backup files that
    #   home-manager creates: `find ~/.config/cosmic/ -name "*.bak" -type f -delete`.

    home.file.".config/cosmic/com.system76.CosmicComp/v1/autotile".text = "true";
    home.file.".config/cosmic/com.system76.CosmicComp/v1/cursor_follows_focus".text = "true";
    home.file.".config/cosmic/com.system76.CosmicComp/v1/focus_follows_cursor_delay".text = "50";
    home.file.".config/cosmic/com.system76.CosmicComp/v1/focus_follows_cursor".text = "true";
    home.file.".config/cosmic/com.system76.CosmicComp/v1/input_default".text = ''
      (
        state: Enabled,
        acceleration: Some((
          profile: Some(Flat),
          speed: 0.0,
        )),
      )
    '';
    home.file.".config/cosmic/com.system76.CosmicComp/v1/input_touchpad".text = ''
      (
      state: Enabled,
      scroll_config: Some((
        method: None,
        natural_scroll: Some(true),
        scroll_button: None,
        scroll_factor: None,
      )),
      )
    '';

    home.file.".config/cosmic/com.system76.CosmicEdit/v1/tab_width".text = "2";

    home.file.".config/cosmic/com.system76.CosmicIdle/v1/screen_off_time".text = "Some(300000)";
    home.file.".config/cosmic/com.system76.CosmicIdle/v1/suspend_on_ac_time".text =
      if config.networking.hostName == "sisyphus" then "None" else "Some(1800000)";

    home.file.".config/cosmic/com.system76.CosmicPanel.Panel/v1/anchor_gap".text = "true";
    home.file.".config/cosmic/com.system76.CosmicPanel.Panel/v1/autohide".text = ''
      Some((
        wait_time: 200,
        transition_time: 50,
        handle_size: 4,
      ))
    '';
    home.file.".config/cosmic/com.system76.CosmicPanel.Panel/v1/autohover_delay_ms".text = ''
      Some(500)
    '';
    home.file.".config/cosmic/com.system76.CosmicPanel.Panel/v1/border_radius".text = "8";
    home.file.".config/cosmic/com.system76.CosmicPanel.Panel/v1/exclusive_zone".text = "false";
    home.file.".config/cosmic/com.system76.CosmicPanel.Panel/v1/expand_to_edges".text = "false";
    home.file.".config/cosmic/com.system76.CosmicPanel.Panel/v1/margin".text = "4";
    home.file.".config/cosmic/com.system76.CosmicPanel.Panel/v1/plugins_center".text = "Some([])";
    home.file.".config/cosmic/com.system76.CosmicPanel.Panel/v1/plugins_wings".text = ''
      Some(([
        "com.system76.CosmicAppletTime",
        "com.system76.CosmicAppletStatusArea",
        "com.system76.CosmicAppletNotifications",
        "io.github.wiiznokes.cosmic-ext-applet-clipboard-manager",
      ], [
        "com.system76.CosmicAppletAudio",
        "com.system76.CosmicAppletBluetooth",
        "com.system76.CosmicAppletNetwork",
        "com.system76.CosmicAppletBattery",
        "com.system76.CosmicAppletPower",
      ]))
    '';
    home.file.".config/cosmic/com.system76.CosmicPanel.Panel/v1/spacing".text = "0";
    home.file.".config/cosmic/com.system76.CosmicPanel/v1/entries".text = ''[ "Panel" ]'';

    home.file.".config/cosmic/com.system76.CosmicPortal/v1/screenshot".text = ''
      (
        save_location: Clipboard,
        choice: Rectangle,
      )
    '';

    home.file.".config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom".text = ''
      {
        (
          modifiers: [
            Super,
          ],
          key: "e",
        ): System(Launcher),
        (
          modifiers: [
            Super,
          ],
          key: "f",
        ): Disable,
        (
          modifiers: [],
          key: "Print",
        ): Disable,
        (
          modifiers: [
            Super,
          ],
          key: "c",
        ): Close,
        (
          modifiers: [
            Super,
          ],
          key: "b",
        ): Disable,
        (
          modifiers: [
            Super,
          ],
          key: "h",
        ): System(HomeFolder),
        (
          modifiers: [
            Super,
          ],
          key: "slash",
        ): Disable,
        (
          modifiers: [
            Super,
            Shift,
          ],
          key: "m",
        ): Minimize,
        (
          modifiers: [
            Super,
          ],
          key: "t",
        ): Disable,
        (
          modifiers: [
            Super,
          ],
          key: "q",
        ): System(Terminal),
        (
          modifiers: [
            Super,
            Shift,
          ],
          key: "f",
        ): Maximize,
        (
          modifiers: [
            Super,
          ],
          key: "l",
        ): System(LockScreen),
        (
          modifiers: [
            Super,
            Shift,
          ],
          key: "s",
        ): System(Screenshot),
        (
          modifiers: [
            Super,
          ],
        ): Disable,
        (
          modifiers: [
            Super,
          ],
          key: "m",
        ): Disable,
      }
    '';
    home.file.".config/cosmic/com.system76.CosmicSettings.Wallpaper/v1/custom-colors".text = ''
      [
        Single((0.0, 0.0, 0.0)),
      ]
    '';

    home.file.".config/cosmic/com.system76.CosmicTheme.Dark/v1/active_hint".text = "1";
    home.file.".config/cosmic/com.system76.CosmicTheme.Dark/v1/gaps".text = "(0, 3)";
    home.file.".config/cosmic/com.system76.CosmicTheme.Dark/v1/spacing".text = ''
      (
        space_none: 0,
        space_xxxs: 4,
        space_xxs: 4,
        space_xs: 8,
        space_s: 8,
        space_m: 16,
        space_l: 24,
        space_xl: 32,
        space_xxl: 48,
        space_xxxl: 64,
      )
    '';

    home.file.".config/cosmic/com.system76.CosmicTk/v1/header_size".text = "Compact";
    home.file.".config/cosmic/com.system76.CosmicTk/v1/interface_density".text = "Compact";

  };

  qt.enable = true;
  qt.style = "adwaita-dark";
}
