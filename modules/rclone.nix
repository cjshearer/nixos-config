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
# - ba91782: removed inotify-driven symlink service that mirrored OneDrive into $HOME due to
#   fragility, stale references, and systemd lifecycle issues. Replaced it with explicit XDG user
#   directory mappings pointing directly at the rclone-mounted OneDrive path. This restores clear
#   boundaries between local state and cloud-backed data while simplifying mount behavior and
#   failure modes.
# - 46ee857 added reusable rclone bisync jobs for OneDrive subdirectories so services can run
#   against local disk while still mirroring cloud-backed data on a schedule.
# - ########: refactored OneDrive transfers into a direct src.dst operation model, folded mount into
#   operations, added copy support, and made enablement explicit per pair.
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.users.cjshearer.services.rclone.operations;

  isRemotePath = path: builtins.match "^[^/][^:]*:.*" path != null;
  mkWorkDir = name: "/home/cjshearer/.local/share/rclone-bisync/${name}";

  flattenOperations = lib.mapAttrsToList (name: opCfg: {
    inherit name;
    cfg = opCfg;
  }) cfg;
  enabledOperations = lib.filter (op: op.cfg.enable) flattenOperations;

  mkExcludeArgs =
    op:
    let
      inherit (op.cfg) operation exclude;
    in
    lib.optionalString ((operation == "copy" || operation == "bisync") && exclude != [ ]) (
      lib.concatMapStringsSep " " (pattern: "--exclude ${lib.escapeShellArg pattern}") exclude
    );

  mkExecStart =
    op:
    let
      src = lib.escapeShellArg op.cfg.src;
      dst = lib.escapeShellArg op.cfg.dst;
      workdir = lib.escapeShellArg (mkWorkDir op.name);
      excludeArgs = mkExcludeArgs op;
    in
    pkgs.writeShellScript "rclone-bisync-${op.name}" (
      ''
        set -euo pipefail
        ${lib.getExe pkgs.rclone} mkdir ${src}
        ${lib.getExe pkgs.rclone} mkdir ${dst}
      ''
      + (
        if op.cfg.operation == "mount" then
          "exec ${lib.getExe pkgs.rclone} mount --vfs-cache-mode full ${src} ${dst}"
        else if op.cfg.operation == "copy" then
          "exec ${lib.getExe pkgs.rclone} copy --update ${excludeArgs} ${src} ${dst}"
        else
          ''
            ${lib.getExe pkgs.rclone} mkdir ${workdir}

            resync_args=()
            check_sync_args=("--check-sync=false")

            # To ensure we download from the remote if the local copy is empty, we check if a previous
            # resync has been performed by looking for a .lst file in the workdir.
            if ! ${lib.getExe pkgs.findutils} ${workdir} -maxdepth 1 -name '*.lst' -print -quit | grep -q .; then
              resync_args+=(--resync --resync-mode newer)
              check_sync_args=()
            fi

            exec ${lib.getExe pkgs.rclone} bisync \
              --recover \
              --resilient \
              --workdir ${workdir} \
              ${excludeArgs} \
              "''${check_sync_args[@]}" \
              "''${resync_args[@]}" \
              ${src} \
              ${dst}
          ''
      )
    );

  mkService =
    op:
    let
      name = op.cfg.unitName;
      needsNetwork = isRemotePath op.cfg.src || isRemotePath op.cfg.dst;
    in
    lib.nameValuePair name {
      after = lib.optional needsNetwork "network-online.target";
      wants = lib.optional needsNetwork "network-online.target";
      wantedBy = lib.optional (op.cfg.operation == "mount") "multi-user.target";
      serviceConfig = {
        User = "cjshearer";
        Group = "users";
      }
      // lib.optionalAttrs (op.cfg.operation == "mount") {
        Environment = [
          "PATH=/run/wrappers/bin/:$PATH"
        ];
        Type = "notify";
        Restart = "on-failure";
        ExecStart = mkExecStart op;
        ExecStop = "/run/wrappers/bin/fusermount -uz ${lib.escapeShellArg op.cfg.dst}";
      }
      // lib.optionalAttrs (op.cfg.operation != "mount") {
        Type = "oneshot";
        TimeoutStartSec = "infinity";
        ExecStart = mkExecStart op;
      };
    };

  mkTimer =
    op:
    lib.nameValuePair op.cfg.unitName {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitInactiveSec = op.cfg.interval;
      };
    };

in
{
  options.users.cjshearer.services.rclone.operations = lib.mkOption {
    default = { };

    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, config, ... }: {
          options = {
            src = lib.mkOption {
              type = lib.types.str;
              description = "Source path (local or remote).";
            };
            dst = lib.mkOption {
              type = lib.types.str;
              description = "Destination path (local or remote).";
            };
            enable = lib.mkEnableOption "rclone operation";
            operation = lib.mkOption {
              type = lib.types.enum [
                "mount"
                "copy"
                "bisync"
              ];
              default = "bisync";
            };
            interval = lib.mkOption {
              type = lib.types.str;
              default = "1m";
            };
            exclude = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = ''
                Exclude paths matching these glob patterns (passed as `--exclude` flags).
                Only applies to "copy" and "bisync" operations; ignored for "mount".
                To exclude a directory and all its contents, use a pattern like `dir/**`
                or `/dir/**`. To exclude only the directory entry itself (not its children),
                append a `/` separator, e.g. `dir/`.
              '';
            };
            unitName = lib.mkOption {
              type = lib.types.str;
              description = "Systemd unit base name for this operation.";
            };
          };
          config.unitName = lib.mkDefault "rclone-${name}-${config.operation}";
        }
      )
    );
  };

  config = lib.mkIf (enabledOperations != [ ]) {

    systemd.services = lib.listToAttrs (map mkService enabledOperations);
    systemd.timers = lib.listToAttrs (
      map mkTimer (lib.filter (op: op.cfg.operation != "mount") enabledOperations)
    );

    # This assumes all operations use onedrive. If that changes, so should this configuration.
    home-manager.users.cjshearer.programs.rclone = {
      enable = true;
      remotes.onedrive = {
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
            ${lib.getExe pkgs.rclone} config dump --config "$configPath" \
              | ${lib.getExe pkgs.jq} -r '.onedrive.drive_id // empty' > "$tmp"
            echo "$tmp"
            )'';

          token = ''
            $(
            tmp=$(mktemp)
            ${lib.getExe pkgs.rclone} config dump --config "$configPath" \
              | ${lib.getExe pkgs.jq} -r '.onedrive.token // empty' > "$tmp"
            echo "$tmp"
            )'';
        };
      };
    };

    # This assumes the operation is a mount, but in practice that will always be the case.
    home-manager.users.cjshearer.xdg.userDirs = {
      documents = "/mnt/onedrive/Documents";
      music = "/mnt/onedrive/Music";
      pictures = "/mnt/onedrive/Pictures";
      videos = "/mnt/onedrive/Videos";
    };
  };
}
