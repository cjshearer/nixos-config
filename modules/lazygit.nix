{
  config,
  lib,
  ...
}:
{
  options.users.cjshearer.programs.lazygit.enable = lib.mkEnableOption "lazygit";

  config = lib.mkIf config.users.cjshearer.programs.lazygit.enable {
    home-manager.users.cjshearer.programs.lazygit = {
      enable = true;
      enableBashIntegration = true;
      settings.gui.showIcons = true;
      settings.gui.nerdFontsVersion = 3;
    };
  };
}
