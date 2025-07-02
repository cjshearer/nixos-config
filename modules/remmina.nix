{ pkgs, lib, config, ... }: {
  options.users.cjshearer.services.remmina.enable = lib.mkEnableOption "remmina";

  config = lib.mkIf config.users.cjshearer.services.remmina.enable {
    # evaluate rustdesk as alternative for this and citrix_workspace
    home-manager.users.cjshearer.services.remmina.enable = true;
    home-manager.users.cjshearer.systemd.user.services.remmina-auto-launch = {
      Unit = {
        Description = "Launches work RDP upon detection of ~/Downloads/app.rdp";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "remmina" ''
          PATH=${
            lib.makeBinPath [
              pkgs.inotify-tools
              pkgs.remmina
              pkgs.gnused
              pkgs.findutils
            ]
          }
          find ~/Downloads/ -name "app*.rdp" -delete
          inotifywait -m -e create ~/Downloads | while read path action file; do
            if [ "$file" != "app.rdp" ]; then
              continue
            fi
            execpath=$(sed -nr 's/shell working directory:s:(.*)/\1/p' "$path/$file")
            loadbalanceinfo=$(sed -nr 's/loadbalanceinfo:s:(.*)/\1/p' "$path/$file")
            find ~/Downloads/ -name "app*.rdp" -delete
            remmina --update-profile ~/.local/share/remmina/work.remmina --set-option execpath="$execpath" --set-option loadbalanceinfo="$loadbalanceinfo"
            remmina -c ~/.local/share/remmina/work.remmina --enable-extra-hardening --no-tray-icon
          done
        '';
        RestartSec = 10;
        Restart = "on-failure";
      };
    };
  };
}
