{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.users.cjshearer.programs.vscode.enable = lib.mkEnableOption "vscode";

  config = lib.mkIf config.users.cjshearer.programs.vscode.enable {
    home-manager.users.cjshearer.home.packages = [
      pkgs.nil
      pkgs.biome
    ];

    home-manager.users.cjshearer.programs.vscode = {
      enable = true;
      package = (
        pkgs.vscode.override {
          commandLineArgs = "--password-store=\"gnome-libsecret\"";
        }
      );
    };

    home-manager.users.cjshearer.services.gnome-keyring.enable = true;
  };
}
