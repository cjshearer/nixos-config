{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.users.cjshearer.programs.vscode.enable = lib.mkEnableOption "vscode";
  options.users.cjshearer.services.vscode-server.enable = lib.mkEnableOption "vscode-server";

  config = lib.mkMerge [
    (lib.mkIf config.users.cjshearer.programs.vscode.enable {
      home-manager.users.cjshearer = {
        programs.vscode.enable = true;

        services.gnome-keyring.enable = true;
      };
      users.cjshearer.services.vscode-server.enable = true;
    })
    (lib.mkIf config.users.cjshearer.services.vscode-server.enable {
      home-manager.users.cjshearer = {
        home.packages = [
          pkgs.biome
          pkgs.nil
        ]
        ++ lib.optional config.users.cjshearer.programs.go.enable pkgs.gopls;
        services.vscode-server.enable = true;
      };
    })
  ];
}
