{
  config,
  pkgs,
  lib,
  vscode-server,
  ...
}:
{

  options.users.cjshearer.programs.vscode.enable = lib.mkEnableOption "vscode";

  config = lib.mkIf config.users.cjshearer.programs.vscode.enable {
    home-manager.users.cjshearer = {
      imports = [ vscode-server.homeModules.default ];

      home.packages = [
        pkgs.nil
        pkgs.biome
      ];

      programs.vscode = {
        enable = true;
        package = (
          pkgs.vscode.override {
            commandLineArgs = "--password-store=\"gnome-libsecret\"";
          }
        );
      };

      services.gnome-keyring.enable = true;
      services.vscode-server.enable = true;
    };
  };
}
