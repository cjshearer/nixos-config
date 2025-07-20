{
  lib,
  config,
  ...
}:
lib.mkIf config.programs.steam.enable {
  home-manager.users.cjshearer.home.file.".config/autostart/steam.desktop".text = ''
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
