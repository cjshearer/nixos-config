# Serve the OneDrive remote over WebDAV from charon, and mount that hub on client hosts.
#
# The server is reachable directly on the tailnet and through the tailnet files service for
# Android. Access is controlled by Tailscale.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  rclone = config.users.cjshearer.services.rclone;
  webdav = rclone.webdav;

  remote = "onedrive:";
  port = 8090;
  tailscaleService = "svc:files";
  serverHost = "charon";
  mountPoint = "/mnt/onedrive";
  cacheDir = "/var/cache/rclone-webdav";
  cacheMaxSize = "20G";
  cacheMaxAge = "2w";
  cacheMinFreeSpace = "10G";
  dirCacheTime = "24h";
  pollInterval = "30s";
  exclude = [ "/Personal Vault/**" ];
  clientUrl = "http://${serverHost}:${toString port}/";
  fusermount = "/run/wrappers/bin/fusermount3";

  vfsArgs = [
    "--cache-dir"
    cacheDir
    "--vfs-cache-mode"
    webdav.cacheMode
    "--vfs-cache-max-size"
    cacheMaxSize
    "--vfs-cache-max-age"
    cacheMaxAge
    "--vfs-cache-min-free-space"
    cacheMinFreeSpace
    "--dir-cache-time"
    dirCacheTime
    "--poll-interval"
    pollInterval
  ];

  excludeArgs = lib.concatMap (pattern: [
    "--exclude"
    pattern
  ]) exclude;

  serverExec = lib.escapeShellArgs (
    [
      (lib.getExe pkgs.rclone)
      "serve"
      "webdav"
      remote
    ]
    ++ rclone.globalArgs
    ++ [
      # The server talks to OneDrive upstream, so bind that side to IPv4.
      "--bind"
      "0.0.0.0"
      "--addr"
      ":${toString port}"
    ]
    ++ vfsArgs
    ++ excludeArgs
  );

  clientExec = pkgs.writeShellScript "rclone-webdav-client-start" ''
    exec ${lib.getExe pkgs.rclone} mount :webdav: ${lib.escapeShellArg mountPoint} \
      ${lib.escapeShellArgs rclone.globalArgs} \
      --webdav-url ${lib.escapeShellArg clientUrl} \
      --webdav-vendor other \
      --vfs-cache-mode writes \
      --dir-cache-time ${dirCacheTime} \
      --poll-interval ${pollInterval}
  '';

  clientCheck = pkgs.writeShellScript "rclone-webdav-client-check" ''
    exec ${lib.getExe pkgs.curl} \
      --fail --silent --show-error \
      --connect-timeout 3 --max-time 10 \
      ${lib.escapeShellArg clientUrl}
  '';
in
{
  options.users.cjshearer.services.rclone.webdav = {
    enable = lib.mkEnableOption "the WebDAV hub for the OneDrive remote";

    cacheMode = lib.mkOption {
      type = lib.types.enum [
        "off"
        "minimal"
        "writes"
        "full"
      ];
      default = "full";
      description = "rclone VFS cache mode for the server.";
    };

    client.enable = lib.mkEnableOption "mounting the WebDAV hub";
  };

  config = lib.mkMerge [
    (lib.mkIf webdav.enable {
      assertions = [
        {
          assertion = config.services.tailscale.enable;
          message = "The WebDAV hub is served over the tailnet but services.tailscale.enable is false.";
        }
      ];

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];

      systemd.services.rclone-webdav = {
        description = "rclone WebDAV server for OneDrive";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          User = "cjshearer";
          Group = "users";
          CacheDirectory = "rclone-webdav";
          Restart = "always";
          RestartSec = "5s";
          ExecStart = serverExec;
        };
      };

      systemd.services.tailscaled-serve-rclone-webdav = {
        description = "Publish the rclone WebDAV hub on the tailnet";
        wantedBy = [ "multi-user.target" ];
        partOf = [ "rclone-webdav.service" ];
        requires = [ "tailscaled.service" ];
        after = [
          "tailscaled.service"
          "rclone-webdav.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --service=${tailscaleService} http://127.0.0.1:${toString port}";
          ExecStop = "${config.services.tailscale.package}/bin/tailscale serve drain ${tailscaleService}";
        };
      };
    })

    (lib.mkIf webdav.client.enable {
      assertions = [
        {
          assertion = config.services.tailscale.enable;
          message = "The WebDAV client uses Tailscale but services.tailscale.enable is false.";
        }
      ];

      systemd.services.rclone-webdav-client = {
        description = "Mount the charon WebDAV hub";
        wantedBy = [ "multi-user.target" ];
        restartIfChanged = false;
        stopIfChanged = false;
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
          Group = "users";
          Environment = [
            "PATH=/run/wrappers/bin/:$PATH"
          ];
          Type = "notify";
          Restart = "on-failure";
          RestartSec = "15s";
          TimeoutStopSec = "15s";
          KillSignal = "SIGINT";
          ExecStartPre = [
            "-${fusermount} -uz ${lib.escapeShellArg mountPoint}"
            clientCheck
          ];
          ExecStart = clientExec;
          ExecStop = "${fusermount} -uz ${lib.escapeShellArg mountPoint}";
          ExecStopPost = "-${fusermount} -uz ${lib.escapeShellArg mountPoint}";
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
