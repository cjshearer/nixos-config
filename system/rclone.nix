{ systemConfig, lib, pkgs, config, ... }:
let cfg = config.services.rclone; in
{
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
  options.services.rclone.onedrive.mount = lib.mkOption {
    type = lib.types.str;
    default = "/mnt/onedrive";
    description = "Path to mount OneDrive";
  };
  options.services.rclone.onedrive.symlinks = lib.mkOption {
    type = lib.types.str;
    default = "/home/${systemConfig.username}";
    description = "Path to symlink OneDrive folders to";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rclone ];

    # TODO: see what config options I can reuse from here to make rclone faster:
    # https://github.com/insertokname/nixos_config/blob/2594ebbf6c75593f10d9b72190056f647f0bceab/hardware/laptop/services/rclone.nix#L10

    systemd.tmpfiles.rules = [
      "d /mnt/onedrive 0755 ${systemConfig.username} root -"
    ];

    # TODO: see why I need --allow-other, despite running rclone as my user
    programs.fuse.userAllowOther = true;

    # While I could use the `fileSystems` option to mount OneDrive, using an fstab entry would cause
    # rclone to be run as root, which makes the vfs cache owned by root. This was problematic when I
    # tried to use syncthing to sync the vfs cache between devices, as syncthing would also need to
    # run as root, but I don't remember that working when I tried last. Furthermore, updating the
    # mount when using `fileSystems` would sometimes throw an error about --remount not being
    # supported (https://github.com/rclone/rclone/issues/6488). If and when that is supported, I
    # could consider using it, since the experiment with syncing the vfs cache did not have the
    # desired effect (an open file was not updated when its underlying cache was updated).
    systemd.services.mnt-onedrive = {
      description = "rclone mount of OneDrive";
      serviceConfig = {
        Type = "notify";
        ExecStart = builtins.replaceStrings [ "\n" ] [ "" ] ''
          ${pkgs.rclone}/bin/rclone mount onedrive:/sync ${cfg.onedrive.mount}
            --allow-other
            --cache-dir ${cfg.cachedir}
            --config ${cfg.conf}
            --default-permissions
            --onedrive-delta
            --rc
            --vfs-cache-mode full
        '';
        # We prefetch the directory/filenames to speed up access to the files
        ExecStartPost=builtins.replaceStrings [ "\n" ] [ "" ] ''
          ${pkgs.rclone}/bin/rclone rc vfs/refresh
            _async=true
            --rc-addr 127.0.0.1:5572 
            recursive=true
        '';

        # TODO: prefetch directory/filenames at rclone mount: https://github.com/rclone/rclone/issues/4291

        ExecStop = "${pkgs.fuse3}/bin/fusermount3 -uz ${cfg.onedrive.mount}";
        Restart = "on-failure";
        RestartSec = "10s";
        User = systemConfig.username;
        Group = "root";
        Environment = [ "PATH=/run/wrappers/bin/:$PATH" ];
      };
      requires = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };

    # My userdirs are stored in OneDrive, so I want to symlink them to my home directory. If this
    # becomes troublesome, consider changing the default XDG user dirs to point to OneDrive, but
    # consider the edge case where OneDrive is not mounted.
    systemd.services.mnt-onedrive-symlinks = {
      description = "Symlink OneDrive folders to home directory";
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "mnt-onedrive-symlinks" ''
          ln -sf ${cfg.onedrive.mount}/* ${cfg.onedrive.symlinks}
          ${pkgs.inotify-tools}/bin/inotifywait -m -e create,delete,moved_to,moved_from ${cfg.onedrive.mount} | while read path action file; do
            if [ $action = "CREATE" ] || [ $action = "MOVED_TO" ]; then
              ln -sf "${cfg.onedrive.mount}/$file" ${cfg.onedrive.symlinks}
            elif [ -L "${cfg.onedrive.symlinks}/$file" ] && ([ $action = "DELETE" ] || [ $action = "MOVED_FROM" ]); then
              rm "${cfg.onedrive.symlinks}/$file"
            fi
          done
        '';
        ExecStop = "${pkgs.findutils}/bin/find ${cfg.onedrive.symlinks} -maxdepth 1 -xtype l -delete";
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

    # TODO: explore options for updating peers' files when they change:
    # - https://forum.rclone.org/t/refreshing-rclone-cache-for-specific-paths/38786
    # - use rclone to mount the mounted mount? (e.g. salmoneus -> sisyphus:/mnt/onedrive)
  };
}
