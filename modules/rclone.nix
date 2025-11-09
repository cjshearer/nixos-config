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
      mounts."" = {
        enable = true;
        mountPoint = cfg.mountPoint;
      };
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

    home-manager.users.cjshearer.systemd.user.services."rclone-mount\:@onedrive-symlink" =
      lib.mkIf cfg.symlink.enable
        {
          Unit = {
            # This unit must be started after rclone mount, as inotify would otherwise be watching
            # the inode that the directory was previously pointing to, rather than the new inode
            # pointing to the root of the mounted file system.
            Description = "Symlink OneDrive Folders to Home Directory";
            PartOf = "rclone-mount\:@onedrive.service";
            After = "rclone-mount\:@onedrive.service";
            Wants = "rclone-mount\:@onedrive.service";
            Requires = "rclone-mount\:@onedrive.service";
          };

          Service = {
            Type = "simple";
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

          Install.WantedBy = [ "default.target" ];
        };
  };
}
