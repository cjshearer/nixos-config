{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.users.cjshearer.programs.rclone.remotes.onedrive.enable =
    lib.mkEnableOption "OneDrive remote for rclone";
  options.users.cjshearer.programs.rclone.remotes.onedrive.symlink.enable =
    lib.mkEnableOption "Symlink OneDrive folders to home directory";

  config = lib.mkMerge [
    (lib.mkIf config.users.cjshearer.programs.rclone.remotes.onedrive.enable {
      systemd.tmpfiles.rules = [
        "d /mnt/onedrive 0755 cjshearer users -"
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
          mountPoint = "/mnt/onedrive";
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
    })
    (lib.mkIf config.users.cjshearer.programs.rclone.remotes.onedrive.symlink.enable {
      home-manager.users.cjshearer.systemd.user.services."rclone-mount\:@onedrive-symlink" =
        let
          home = config.home-manager.users.cjshearer.home.homeDirectory;
        in
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
              ${pkgs.coreutils}/bin/ln -sf /mnt/onedrive/* ${home}
              ${pkgs.inotify-tools}/bin/inotifywait \
                -m \
                -e create,delete,moved_to,moved_from \
                /mnt/onedrive | \
                while read path action file; do
                  if [ $action = "CREATE" ] || [ $action = "MOVED_TO" ]; then
                    ln -sf "/mnt/onedrive/$file" ${home}
                  else
                    rm "${home}/$file"
                fi
              done
            '';
            ExecStop = "${pkgs.findutils}/bin/find ${home} -maxdepth 1 -xtype l -delete";
            RestartSec = 10;
            Restart = "on-failure";
          };
          Install.WantedBy = [ "default.target" ];
        };
    })
  ];
}
