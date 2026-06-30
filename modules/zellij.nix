{
  home-manager.sharedModules = [
    (
      { lib, config, ... }:
      lib.mkIf config.programs.zellij.enable {
        programs.zellij.settings = {
          pane_frames = false;
          keys.locked = {
            "A-left".MoveFocusOrTab = "Left";
            "A-right".MoveFocusOrTab = "Right";
            "A-up".MoveFocusOrTab = "Up";
            "A-down".MoveFocusOrTab = "Down";
          };
        };
      }
    )
  ];
}
