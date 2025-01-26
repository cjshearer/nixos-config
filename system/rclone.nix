{ systemConfig, lib, pkgs, config, ... }: {
  options.services.rclone.enable = lib.mkEnableOption "rclone";
  options.services.rclone.conf = lib.mkOption {
    type = lib.types.str;
    default = "/home/${systemConfig.username}/.config/rclone/rclone.conf";
    description = "Path to rclone configuration file";
  };
  options.services.rclone.cachedir = lib.mkOption {
    type = lib.types.str;
    default = "/home/${systemConfig.username}/.cache/rclone";
    description = "Path to rclone cache directory";
  };

  config = lib.mkIf config.services.rclone.enable {
    environment.systemPackages = [ pkgs.rclone ];

    # fileSystems."/mnt/onedrive" = {
    #   device = "onedrive:/sync";
    #   fsType = "rclone";
    #   options = [
    #     "uid=${toString config.users.users.${systemConfig.username}.uid}"
    #     "_netdev" # don't mount until device is queried
    #     "allow_other" # allow access for other users
    #     "nodev" # ignore device files on mount
    #     "nofail" # don’t fail if mount fails
    #     "rw" # read/write mode
    #     "vfs-cache-mode=full"
    #     "config=${config.services.rclone.conf}"
    #     "cache-dir=${config.services.rclone.cachedir}"
    #     "onedrive-delta"
    #   ];
    # };

    # TODO: convert to fileSystems."/mnt/OneDrive" = { ... } once rclone supports --remount
    # https://github.com/rclone/rclone/issues/6488. That said, running rclone as root, as would 
    # happen in this case, would cause the vfs file cache to be owned by root, which would require
    # running syncthing as root as well. If I recall correctly, that didn't work when I tried it.

    # TODO: see what config options I can reuse from here to make rclone faster:
    # https://github.com/insertokname/nixos_config/blob/2594ebbf6c75593f10d9b72190056f647f0bceab/hardware/laptop/services/rclone.nix#L10

    systemd.tmpfiles.rules = [
      "d /mnt/onedrive 0755 ${systemConfig.username} root -"
    ];

    programs.fuse.userAllowOther = true;

    systemd.services.mnt-onedrive-symlinks = {
      description = "Symlink OneDrive folders to home directory";
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "mnt-onedrive-symlinks" ''
          ln -sf /mnt/onedrive/* /home/${systemConfig.username}/
          ${pkgs.inotify-tools}/bin/inotifywait -m -e create,delete,moved_to,moved_from /mnt/onedrive | while read path action file; do
            if [ $action = "CREATE" ] || [ $action = "MOVED_TO" ]; then
              ln -sf "/mnt/onedrive/$file" /home/${systemConfig.username}/
            elif [ -L "/home/${systemConfig.username}/$file" ] && ([ $action = "DELETE" ] || [ $action = "MOVED_FROM" ]); then
              rm "/home/${systemConfig.username}/$file"
            fi
          done
        '';
        ExecStop = "${pkgs.findutils}/bin/find /home/${systemConfig.username}/ -maxdepth 1 -xtype l -delete";
        RestartSec = 10;
        Restart = "on-failure";
        User = systemConfig.username;
        Group = "root";
      };
      # This unit must be started after rclone mount, as inotify would otherwise be watching the
      # inode that the directory was previously pointing to, rather than the new inode pointing to
      # the root of the mounted file system.
      partOf = [ "mnt-onedrive.service" ];
      requires = [ "mnt-onedrive.service" ];
      after = [ "mnt-onedrive.service" ];
      bindsTo = [ "mnt-onedrive.service" ];
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.mnt-onedrive = {
      description = "rclone mount of OneDrive";
      serviceConfig = {
        Type = "notify";
        ExecStart = "${pkgs.rclone}/bin/rclone mount --allow-other --default-permissions --vfs-cache-mode full --config ${config.services.rclone.conf} --cache-dir ${config.services.rclone.cachedir} --onedrive-delta onedrive:/sync /mnt/onedrive";

        # TODO: prefetch directory/filenames at rclone mount: https://github.com/rclone/rclone/issues/4291

        ExecStop = "${pkgs.fuse3}/bin/fusermount3 -uz /mnt/onedrive";
        Restart = "on-failure";
        RestartSec = "10s";
        User = systemConfig.username;
        Group = "root";
        Environment = [ "PATH=/run/wrappers/bin/:$PATH" ];
      };
      requires = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };

    # TODO: setup automatic vfs refresh on peer change:
    # https://forum.rclone.org/t/refreshing-rclone-cache-for-specific-paths/38786
    # https://rclone.org/rc/. I tried something like this, where I setup syncthing to sync the vfs
    # cache between devices, but found that an open file is not updated when its underlying cache
    # is updated. I may need to use the rc command to refresh the cache, but I should first try a
    # small scale test to see if it works.
  };
}
