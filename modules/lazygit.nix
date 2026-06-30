{
  home-manager.sharedModules = [
    (
      { lib, config, ... }:
      lib.mkIf config.programs.lazygit.enable {
        programs.lazygit.enableBashIntegration = true;
        programs.lazygit.settings.gui.showIcons = true;
        programs.lazygit.settings.gui.nerdFontsVersion = 3;
      }
    )
  ];
}
