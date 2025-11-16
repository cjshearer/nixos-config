# Decision History:
# - 457adb6: replaced abraunegg/onedrive + syncthing with a system unit running rclone mount. I
#   don't recall why, but rclone is more portable across systems (e.g. NixOs and Android) and
#   storage backends. I also added a systemd service to symlink folders from mount to home
#   directory, so I can access them easily.
# - 4f56be1: migrated to home-manager's module for rclone.conf configuration management, removing my
#   custom systemd unit for rclone mount and replacing the systemd unit for symlinking with a user
#   unit.
# - 5869b11: created my own version of the configuration activation script to work around not being
#   able to persist secrets managed outside of home-manager
# - 4fa846f: replaced my custom activation script with a hack to persist rclone secrets using the
#   new systemd configuration script for rclone:
#   https://github.com/nix-community/home-manager/pull/7688#issuecomment-3217292389
# - 35d9209: disabled vfs refresh, since onedrive has been polling for changes well enough in recent
#   months to not need to workaround stale caches
# - f5ba42c: split OneDrive remote and symlink into separate options, since with immich I want to
#   run this on a server where I don't need symlinks in the home directory
# - ???????: moved mount back to a system unit, run as my user, so that immich and other systemd
#   units can depend on it, but while keeping rclone config management in home-manager.
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.users.cjshearer.services.rclone.onedrive;
in
{
  options.users.cjshearer.services.rclone.onedrive = {
    enable = lib.mkEnableOption "rclone onedrive remote";
    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/onedrive";
      description = "The mount point for the OneDrive remote.";
    };
    symlink.enable = lib.mkEnableOption "symlink onedrive root folders to home directory";
    symlink.to = lib.mkOption {
      type = lib.types.str;
      default = config.home-manager.users.cjshearer.home.homeDirectory;
      description = "The directory to symlink OneDrive root folders into.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.mountPoint} 0755 cjshearer users -"
    ];
    systemd.services."rclone-mount\:@onedrive" = {
      requires = [ "network-online.target" ];
      serviceConfig = {
        # required for fusermount setuid wrapper
        Environment = [ "PATH=/run/wrappers/bin/:$PATH" ];
        ExecStart = "${pkgs.rclone}/bin/rclone mount --vfs-cache-mode full onedrive: ${cfg.mountPoint}";
        ExecStop = "/run/wrappers/bin/fusermount -uz ${cfg.mountPoint}";
        Group = "users";
        Restart = "on-failure";
        Type = "notify";
        User = "cjshearer";
      };
      wantedBy = [ "default.target" ];
    };
    home-manager.users.cjshearer.programs.rclone.enable = true;
    home-manager.users.cjshearer.programs.rclone.remotes.onedrive = {
      config = {
        delta = true;
        dir_cache_time = "52w";
        drive_type = "personal";
        poll_interval = "30s";
        type = "onedrive";
        vfs_cache_max_age = "2w";
        vfs_cache_mode = "full";
      };
      # this is a hack to persist rclone secrets that are not managed by home-manager:
      # https://github.com/nix-community/home-manager/pull/7688#issuecomment-3217292389
      secrets = {
        drive_id = ''
          $(
          tmp=$(mktemp)
          ${pkgs.rclone}/bin/rclone config dump --config "$savedConfigPath" \
            | ${pkgs.jq}/bin/jq -r '.onedrive.drive_id // empty' > "$tmp"
          echo "$tmp"
          )'';

        token = ''
          $(
          tmp=$(mktemp)
          ${pkgs.rclone}/bin/rclone config dump --config "$savedConfigPath" \
            | ${pkgs.jq}/bin/jq -r '.onedrive.token // empty' > "$tmp"
          echo "$tmp"
          )'';
      };
    };

    systemd.services."rclone-mount\:@onedrive-symlink" = lib.mkIf cfg.symlink.enable {
      # This unit must be started after rclone mount, as inotify would otherwise be watching
      # the inode that the directory was previously pointing to, rather than the new inode
      # pointing to the root of the mounted file system.
      description = "Symlink OneDrive Folders to Home Directory";
      partOf = [ "rclone-mount\:@onedrive.service" ];
      after = [ "rclone-mount\:@onedrive.service" ];
      requires = [ "rclone-mount\:@onedrive.service" ];
      wantedBy = [ "default.target" ];

      serviceConfig = {
        Type = "simple";
        User = "cjshearer";
        Group = "users";
        ExecStart = pkgs.writeShellScript "rclone-mount\:@onedrive-symlink" ''
          ${pkgs.coreutils}/bin/ln -sf ${cfg.mountPoint}/* ${cfg.symlink.to}
          ${pkgs.inotify-tools}/bin/inotifywait \
            -m \
            -e create,delete,moved_to,moved_from \
            ${cfg.mountPoint} | \
            while read path action file; do
              if [ $action = "CREATE" ] || [ $action = "MOVED_TO" ]; then
                ln -sf "${cfg.mountPoint}/$file" ${cfg.symlink.to}
              else
                rm "${cfg.symlink.to}/$file"
            fi
          done
        '';
        ExecStop = "${pkgs.findutils}/bin/find ${cfg.symlink.to} -maxdepth 1 -xtype l -delete";
        RestartSec = 10;
        Restart = "on-failure";
      };
    };
  };
}
