{
  lib,
  config,
  ...
}:
{
  options.users.cjshearer.programs.zellij.enable = lib.mkEnableOption "zellij";

  config = lib.mkIf config.users.cjshearer.programs.zellij.enable {
    home-manager.users.cjshearer.programs.zellij = {
      attachExistingSession = true;
      enable = true;
      enableBashIntegration = true;
      settings = {
        pane_frames = false;
        keys.locked = {
          "A-left".MoveFocusOrTab = "Left";
          "A-right".MoveFocusOrTab = "Right";
          "A-up".MoveFocusOrTab = "Up";
          "A-down".MoveFocusOrTab = "Down";
        };
      };
    };
  };
}
