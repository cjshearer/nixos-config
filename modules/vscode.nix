{
  config,
  pkgs,
  lib,
  ...
}:
{

  options.users.cjshearer.programs.vscode.enable = lib.mkEnableOption "vscode";

  config = lib.mkIf config.users.cjshearer.programs.vscode.enable {
    home-manager.users.cjshearer = {
      home.packages = [
        pkgs.nil
        pkgs.biome
      ];

      programs.vscode.enable = true;

      services.gnome-keyring.enable = true;
      services.vscode-server.enable = true;
    };
  };
}
