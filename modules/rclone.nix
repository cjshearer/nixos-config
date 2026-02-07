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
# - 7d5d7dd: moved mount back to a system unit, run as my user, so that immich and other systemd
#   units can depend on it, but while keeping rclone config management in home-manager.
# - #######: removed inotify-driven symlink service that mirrored OneDrive into $HOME due to fragility, stale references, and systemd lifecycle issues. Replaced it with explicit XDG user directory mappings pointing directly at the rclone-mounted OneDrive path. This restores clear boundaries between local state and cloud-backed data while simplifying mount behavior and failure modes.
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
  };

  # requires on config file from home-manager existing, which is yet another user unit :/
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
    home-manager.users.cjshearer.xdg.userDirs.documents = "${cfg.mountPoint}/Documents";
    home-manager.users.cjshearer.xdg.userDirs.music = "${cfg.mountPoint}/Music";
    home-manager.users.cjshearer.xdg.userDirs.pictures = "${cfg.mountPoint}/Pictures";
    home-manager.users.cjshearer.xdg.userDirs.videos = "${cfg.mountPoint}/Videos";
  };
}
