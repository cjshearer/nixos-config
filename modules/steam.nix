{
  home-manager.sharedModules = [
    (
      { lib, osConfig, ... }:
      lib.mkIf osConfig.programs.steam.enable {
        home.file.".config/autostart/steam.desktop".text = ''
          [Desktop Entry]
          Name=Steam
          Exec=steam %U -silent
          Icon=steam
          Terminal=false
          Type=Application
          Categories=Network;FileTransfer;Game;
          MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
          PrefersNonDefaultGPU=true
          X-KDE-RunOnDiscreteGpu=true
        '';
      }
    )
  ];
}
