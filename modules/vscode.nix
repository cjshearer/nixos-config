{
  home-manager.sharedModules = [
    (
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        config = lib.mkMerge [
          (lib.mkIf config.programs.vscode.enable {
            services.gnome-keyring.enable = true;
            services.vscode-server.enable = true;
          })
          (lib.mkIf config.services.vscode-server.enable {
            home.packages = [
              pkgs.biome
              pkgs.nil
            ]
            ++ lib.optional config.programs.go.enable pkgs.gopls;
          })
        ];
      }
    )
  ];
}
