{ lib, pkgs, systemConfig, config, ... }:
with lib;
let
  cfg = config.programs.remmina;
in
{
  options.programs.remmina.enable = mkEnableOption "remmina";

  config = mkIf cfg.enable {
    # evaluate rustdesk as alternative for this and citrix_workspace
    environment.systemPackages = with pkgs; [ remmina ];

    home-manager.users.${systemConfig.username}.systemd.user.services.remmina = {
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
