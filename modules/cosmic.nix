{ lib, systemConfig, config, pkgs, inputs, ... }:
lib.mkIf config.services.desktopManager.cosmic.enable {
  services.displayManager.cosmic-greeter.enable = true;

  # https://github.com/lilyinstarlight/nixos-cosmic?tab=readme-ov-file#cosmic-utilities---clipboard-manager-not-working
  environment.sessionVariables = {
    NIXOS_OZONE_WL = 1;
    COSMIC_DATA_CONTROL_ENABLED = 1;
  };

  environment.systemPackages = [
    pkgs.wl-clipboard
    pkgs.cosmic-ext-applet-clipboard-manager
  ];

  nix.settings.substituters = [ "https://cosmic.cachix.org/" ];
  nix.settings.trusted-public-keys = [
    "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
  ];

  # list current cosmic configurations with:
  # find ~/.config/cosmic -type f -exec echo -e '\n// {}\n' >> cosmic.ron \; -exec cat {} >> cosmic.ron \;
  home-manager.users.${systemConfig.username} = {
    gtk = {
      enable = true;
      iconTheme.name = "Adwaita-dark";
      iconTheme.package = pkgs.adwaita-icon-theme;
      theme.name = "Adwaita-dark";
      theme.package = pkgs.gnome-themes-extra;
    };

    programs.cosmic = {
      comp.settings = {
        autotile = true;
        cursor_follows_focus = true;
        focus_follows_cursor = true;
        focus_follows_cursor_delay = 20;
        input_touchpad.scroll_config.natural_scroll = true;
      };
      input.binds =
        let inherit (config.lib.cosmic)
          Actions mapBinds;
        in
        mapBinds
          {
            Super."slash" = Actions.Disable;
            Super."m" = Actions.Disable;
            Super."h" = Actions.System "HomeFolder";
            Super."t" = Actions.Disable;
            Super."q" = Actions.System "Terminal";
            Super."e" = Actions.System "Launcher";
            Super.Shift."m" = Actions.Minimize;
            Super.Shift."s" = Actions.System "Screenshot";
            Super.Shift."f" = Actions.Maximize;
            Print = Actions.Disable;
            Super."b" = Actions.Disable;
            Super."l" = Actions.System "LockScreen";
            Super."c" = Actions.Close;
            Super."f" = Actions.Disable;
          } ++ [{ modifiers = [ "Super" ]; action = "Disable"; }];
    };
  };
}
