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
# - 46ee857: added reusable rclone bisync jobs for OneDrive subdirectories so services can run
#   against local disk while still mirroring cloud-backed data on a schedule.
# - 9b189b3: refactored OneDrive transfers into a direct src.dst operation model, folded mount into
#   operations, added copy support, and made enablement explicit per pair.
# - 68fcddf: fixed bisync first-run failure: mkWorkDir now includes a hash of src/dst so stale
#   listing files from previous configurations can't poison the *.lst check; --recover is no longer
#   passed during the initial --resync since it requires pre-existing listing files.
# - 6b6ef6e: emit exclude patterns for mount operations as well, since root OneDrive mounts need to
#   filter known-bad paths such as the Personal Vault.
# - 9cbd8ac: exclude OneDrive's Personal Vault from the root mounts. It cannot be listed through the
#   API and produces repeated invalidResourceId errors (rclone#8736).
# - a0fc96e: pass the vfs and dir-cache flags on the mount command line, where they are actually
#   honored. They were set in the [onedrive] remote config, but they are global flags rather than
#   backend options, so rclone silently ignored them. Also cap the vfs cache by size and minimum
#   free space so it cannot fill the root filesystem.
# - 20df0f4: rate-limit and time-bound every rclone operation. OneDrive throttles the concurrent
#   mount and bisync jobs, and FUSE requests block for the full retry window, which froze the
#   filesystem.
# - a76d50b: expire bisync lock files after 10m. An interrupted run left a lock that never expired,
#   so the job failed forever until it was deleted by hand. rclone renews the lock while a run is
#   active, so this only reclaims locks owned by dead processes.
# - b808cf3: run bisync jobs every 15m with jitter instead of every minute. The frequent cadence
#   hammered OneDrive alongside the mount and contributed to throttling. The 10m lock expiry stays
#   below the interval so a stranded lock is always reclaimed by the next run.
# - 6c90267: let the mount service recover from a wedged mount on its own. Restart unconditionally,
#   bound the stop with a timeout and hand rclone SIGINT so it unmounts, instead of requiring a
#   manual lazy unmount and restart.
# - 0819b1f: force rclone onto IPv4 and bound request retries. This host's IPv6 addresses go
#   deprecated while v6 connects to the internet fail, so rclone's IPv6 sockets black-hole and
#   stall every request until timeout. Binding to 0.0.0.0 sidesteps that, and shorter
#   --timeout/--low-level-retries keep one stalled request from holding the VFS lock for minutes.
# - 20f70ad: seed one-way syncs. A "sync" from a local source to a remote destination copies the
#   remote into the source with `--ignore-existing` before the first run, so an empty local
#   service directory cannot hide remote data. The seed is implicit and its unit is a read-only
#   output that the periodic sync waits for. A marker makes the seed one-shot so later local
#   changes are not re-seeded.
# - 89ebd4b: drop operation options every caller left at the same value. An operation is enabled
#   by its presence, all timed operations share one cadence, and unit names derive from the
#   operation name and type.
# - #######: mounting onedrive directly on each client resulted in poor performance, so we shift
#   the hub that hosts access from onedrive to charon, which exposes onedrive over webdav. Now
#   clients share a cache outside of onedrive, avoiding slow API calls and throttling.
{
  lib,
  pkgs,
  config,
  ...
}:
let
  rcloneBin = lib.getExe pkgs.rclone;
  webdav = config.users.cjshearer.services.rclone.webdav;

  remoteName = "onedrive";

  mountPoint = "/mnt/onedrive";
  wrappers = "/run/wrappers/bin";
  unmount = path: "${wrappers}/fusermount3 -uz ${lib.escapeShellArg path}";

  dirCacheTime = "24h";
  pollInterval = "30s";

  # `--exclude` flags for a list of glob patterns.
  excludeFlags =
    patterns:
    lib.concatMap (pattern: [
      "--exclude"
      pattern
    ]) patterns;

  isRemotePath = path: builtins.match "^[^/][^:]*:.*" path != null;

  mkUnitName = name: operation: "rclone-${name}-${operation}";
  mkSeedUnitName = name: operation: "${mkUnitName name operation}-seed";

  isSeedOp = op: op.cfg.operation == "sync" && !isRemotePath op.cfg.src && isRemotePath op.cfg.dst;

  operations = lib.mapAttrsToList (name: opCfg: {
    inherit name;
    cfg = opCfg;
  }) config.users.cjshearer.services.rclone.operations;

  # OneDrive throttles concurrent rclone processes, and IPv6 on charon is
  # unreliable (global addresses go deprecated while v6 connects to the internet
  # fail), so rclone's default IPv6 sockets black-hole and every request on them
  # stalls until timeout. Bind to 0.0.0.0 to force IPv4, and bound request
  # retries so one stalled request cannot hold a process for minutes.
  onedriveArgs = lib.escapeShellArgs [
    "--bind"
    "0.0.0.0"
    "--tpslimit"
    "10"
    "--tpslimit-burst"
    "1"
    "--timeout"
    "15s"
    "--contimeout"
    "10s"
    "--low-level-retries"
    "2"
    "--retries"
    "3"
  ];

  mkExecStart =
    op:
    let
      src = lib.escapeShellArg op.cfg.src;
      dst = lib.escapeShellArg op.cfg.dst;
      excludeArgs = lib.escapeShellArgs (excludeFlags op.cfg.exclude);
    in
    if op.isSeed or false then
      let
        marker = "/home/cjshearer/.local/state/rclone/${op.name}.seeded";
      in
      pkgs.writeShellScript "rclone-${op.name}-seed" ''
        set -euo pipefail
        marker=${lib.escapeShellArg marker}
        if [ -e "$marker" ]; then
          exit 0
        fi
        ${rcloneBin} copy --ignore-existing ${onedriveArgs} ${excludeArgs} ${dst} ${src}
        ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg (builtins.dirOf marker)}
        ${pkgs.coreutils}/bin/touch "$marker"
      ''
    else
      pkgs.writeShellScript "rclone-${op.name}" (
        ''
          set -euo pipefail
          ${rcloneBin} mkdir ${onedriveArgs} ${src}
          ${rcloneBin} mkdir ${onedriveArgs} ${dst}
        ''
        + (
          {
            copy = "exec ${rcloneBin} copy ${onedriveArgs} --update ${excludeArgs} ${src} ${dst}";
            sync = "exec ${rcloneBin} sync ${onedriveArgs} ${excludeArgs} ${src} ${dst}";
          }
          .${op.cfg.operation}
        )
      );

  mkService =
    op:
    let
      isSeed = op.isSeed or false;
      needsNetwork = isRemotePath op.cfg.src || isRemotePath op.cfg.dst;
      needsSeed = !isSeed && isSeedOp op;
    in
    lib.nameValuePair
      (if isSeed then mkSeedUnitName op.name op.cfg.operation else mkUnitName op.name op.cfg.operation)
      {
        after = lib.optional needsNetwork "network-online.target" ++ lib.optional needsSeed op.cfg.seedUnit;
        requires = lib.optional needsSeed op.cfg.seedUnit;
        wants = lib.optional needsNetwork "network-online.target";
        wantedBy = lib.optional isSeed "multi-user.target";
        serviceConfig = {
          User = "cjshearer";
          Type = "oneshot";
          TimeoutStartSec = "infinity";
          ExecStart = mkExecStart op;
        };
      };

  mkTimer =
    op:
    lib.nameValuePair (mkUnitName op.name op.cfg.operation) {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitInactiveSec = "15m";
        RandomizedDelaySec = "1m";
      };
    };

  # -- WebDAV hub ------------------------------------------------------------------------------
  #
  # The server is reachable directly on the tailnet and through the tailnet files service for
  # Android. Access is controlled by Tailscale.

  port = 8090;

  cacheDirName = "rclone-webdav";

  clientUrl = "http://charon:${toString port}/";

in
{
  options.users.cjshearer.services.rclone = {
    operations = lib.mkOption {
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
              operation = lib.mkOption {
                type = lib.types.enum [
                  "copy"
                  "sync"
                ];
              };
              exclude = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = ''
                  Exclude paths matching these glob patterns (passed as `--exclude` flags).
                  Applies to "copy" and "sync" operations.
                  To exclude a directory and all its contents, use a pattern like `dir/**`
                  or `/dir/**`. To exclude only the directory entry itself (not its children),
                  append a `/` separator, e.g. `dir/`.
                '';
              };
              seedUnit = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
                default = "${mkSeedUnitName name config.operation}.service";
                description = "Systemd unit name for this operation's seed step.";
              };
            };
          }
        )
      );
    };

    webdav = {
      server.enable = lib.mkEnableOption "the WebDAV hub for the OneDrive remote";
      client.enable = lib.mkEnableOption "mounting the WebDAV hub";
    };
  };

  config = lib.mkMerge [
    # The OneDrive remote config and its operations. The remote is also needed by the WebDAV
    # server, so it is gated on either.
    (lib.mkIf (operations != [ ] || webdav.server.enable) {
      systemd.services =
        lib.listToAttrs (map mkService operations)
        // lib.listToAttrs (
          map (op: mkService (op // { isSeed = true; })) (lib.filter isSeedOp operations)
        );
      systemd.timers = lib.listToAttrs (map mkTimer operations);

      # This assumes the operations are onedrive. If that changes, so should this configuration.
      home-manager.users.cjshearer.programs.rclone = {
        enable = true;
        remotes.${remoteName} = {
          config = {
            delta = true;
            drive_type = "personal";
            type = "onedrive";
          };

          # this is a hack to persist rclone secrets that are not managed by home-manager:
          # https://github.com/nix-community/home-manager/pull/7688#issuecomment-3217292389
          secrets = {
            drive_id = ''
              $(
              tmp=$(mktemp)
              ${rcloneBin} config dump --config "$configPath" \
                | ${lib.getExe pkgs.jq} -r '.${remoteName}.drive_id // empty' > "$tmp"
              echo "$tmp"
              )'';

            token = ''
              $(
              tmp=$(mktemp)
              ${rcloneBin} config dump --config "$configPath" \
                | ${lib.getExe pkgs.jq} -r '.${remoteName}.token // empty' > "$tmp"
              echo "$tmp"
              )'';
          };
        };
      };
    })

    # Serve the remote over WebDAV on charon.
    (lib.mkIf webdav.server.enable {
      assertions = [
        {
          assertion = config.services.tailscale.enable;
          message = "The WebDAV hub is served over the tailnet but services.tailscale.enable is false.";
        }
      ];

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];

      # OneDrive cannot list the Personal Vault through the API and emits repeated
      # invalidResourceId errors (rclone#8736).
      systemd.services.rclone-webdav = {
        description = "rclone WebDAV server for OneDrive";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          User = "cjshearer";
          CacheDirectory = cacheDirName;
          Restart = "always";
          RestartSec = "5s";
          ExecStart = pkgs.writeShellScript "rclone-webdav-server" ''
            exec ${rcloneBin} serve webdav ${remoteName}: ${onedriveArgs} \
              --addr :${toString port} \
              ${
                lib.escapeShellArgs [
                  "--cache-dir"
                  "/var/cache/${cacheDirName}"
                  "--vfs-cache-mode"
                  "full"
                  "--vfs-cache-max-size"
                  "20G"
                  "--vfs-cache-max-age"
                  "2w"
                  "--vfs-cache-min-free-space"
                  "10G"
                  "--dir-cache-time"
                  dirCacheTime
                  "--poll-interval"
                  pollInterval
                ]
              } \
              ${lib.escapeShellArgs (excludeFlags [ "/Personal Vault/**" ])}
          '';
        };
      };

      services.tailscale.serve.services.files.endpoints."tcp:443" = "http://127.0.0.1:${toString port}";
    })

    # Mount the WebDAV hub on client hosts.
    (lib.mkIf webdav.client.enable {
      assertions = [
        {
          assertion = config.services.tailscale.enable;
          message = "The WebDAV client uses Tailscale but services.tailscale.enable is false.";
        }
      ];

      # The WebDAV client talks to charon, not to OneDrive, so it only needs the IPv4 bind.
      systemd.services.rclone-webdav-client = {
        description = "Mount the charon WebDAV hub";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "tailscaled.service"
        ];
        wants = [
          "network-online.target"
          "tailscaled.service"
        ];
        serviceConfig = {
          User = "cjshearer";
          Environment = [
            "PATH=${wrappers}:$PATH"
          ];
          Type = "notify";
          Restart = "on-failure";
          RestartSec = "15s";
          TimeoutStopSec = "15s";
          KillSignal = "SIGINT";
          ExecStartPre = [
            "-${unmount mountPoint}"
            (pkgs.writeShellScript "rclone-webdav-client-check" ''
              exec ${lib.getExe pkgs.curl} \
                --fail --silent --show-error \
                --connect-timeout 3 --max-time 10 \
                ${lib.escapeShellArg clientUrl}
            '')
          ];
          ExecStart = pkgs.writeShellScript "rclone-webdav-client-start" ''
            exec ${rcloneBin} mount :webdav: ${lib.escapeShellArg mountPoint} \
              --bind 0.0.0.0 \
              --webdav-url ${lib.escapeShellArg clientUrl} \
              --webdav-vendor other \
              ${lib.escapeShellArgs [
                "--vfs-cache-mode"
                "writes"
                "--dir-cache-time"
                dirCacheTime
              ]}
          '';
          ExecStop = unmount mountPoint;
          ExecStopPost = "-${unmount mountPoint}";
        };
      };

      home-manager.users.cjshearer.xdg.userDirs = {
        documents = "${mountPoint}/Documents";
        music = "${mountPoint}/Music";
        pictures = "${mountPoint}/Pictures";
        videos = "${mountPoint}/Videos";
      };
    })
  ];
}
