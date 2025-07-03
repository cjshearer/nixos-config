{ lib, config, pkgs, ... }: {
  options.users.cjshearer.programs.rbw.enable = lib.mkEnableOption "rbw";

  config = lib.mkIf config.users.cjshearer.programs.rbw.enable {
    home-manager.users.cjshearer.programs.rbw = {
      enable = true;
      settings.email = "cjshearer@live.com";
      settings.pinentry = pkgs.pinentry-tty;
    };
  };
}
