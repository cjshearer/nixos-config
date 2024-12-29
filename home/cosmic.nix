{ pkgs, config, lib, ... }:
let inherit (config.lib.cosmic) Actions mapBinds;
in lib.mkIf config.programs.cosmic.enable {
  # list current cosmic configurations with:
  # find ~/.config/cosmic -type f -exec echo -e '\n// {}\n' >> cosmic.ron \; -exec cat {} >> cosmic.ron \;
  programs.cosmic = {
    comp.settings = {
      autotile = true;
      cursor_follows_focus = true;
      focus_follows_cursor = true;
      focus_follows_cursor_delay = 20;
      input_touchpad.scroll_config.natural_scroll = true;
    };
    input.binds = mapBinds
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
}
