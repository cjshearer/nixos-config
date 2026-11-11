{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.users.cjshearer.services.syncthing;
  hostName = config.networking.hostName;

  syncthingConfig = pkgs.callPackage ../pkgs/syncthing-config/package.nix { };
  syncthingTriggers = pkgs.callPackage ../pkgs/syncthing-triggers/package.nix { };

  identityDir = "/home/cjshearer/.local/state/syncthing/identity";
  certPath = "${identityDir}/cert.pem";
  keyPath = "${identityDir}/key.pem";

  meshHosts = builtins.attrNames (
    lib.filterAttrs (
      _: host: host.config.users.cjshearer.services.syncthing.enable
    ) self.nixosConfigurations
  );

  meshConfig = pkgs.writeText "syncthing-mesh.json" (
    builtins.toJSON {
      localHost = hostName;
      inherit meshHosts;
      extraDevices = lib.mapAttrsToList (name: device: {
        inherit name;
        inherit (device) id addresses;
      }) cfg.extraDevices;
      folders = lib.mapAttrsToList (id: devices: {
        inherit id devices;
      }) cfg.folderDevices;
    }
  );

  prepare = pkgs.writeShellScript "syncthing-config-prepare" ''
    exec ${syncthingConfig}/bin/syncthing-config prepare \
      --host ${lib.escapeShellArg hostName} \
      --cert ${lib.escapeShellArg certPath} \
      --key ${lib.escapeShellArg keyPath}
  '';

  apply = pkgs.writeShellScript "syncthing-config-apply" ''
    exec ${syncthingConfig}/bin/syncthing-config apply \
      --config ${lib.escapeShellArg "${meshConfig}"} \
      --config-dir ${lib.escapeShellArg config.services.syncthing.configDir} \
      --gui ${lib.escapeShellArg config.services.syncthing.guiAddress}
  '';

  pipelinesFile = pkgs.writeText "syncthing-pipelines.json" (
    builtins.toJSON (
      lib.mapAttrs (
        _: steps:
        map (step: {
          inherit (step) name events command;
        }) steps
      ) cfg.pipelines
    )
  );
in
{
  options.users.cjshearer.services.syncthing = {
    enable = lib.mkEnableOption "the Syncthing mesh";

    extraDevices = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            id = lib.mkOption { type = lib.types.str; };
            addresses = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
        }
      );
      default = {
        salmoneus = {
          id = "PBZ3WST-MSVTFVK-6W6LXJP-6ZET3IZ-LK65ML5-Y4CM5FM-JMBUQXM-HPPOEQJ";
          addresses = [ "tcp4://salmoneus:22000" ];
        };
      };
      description = "Devices that manage their own identity, such as Android.";
    };

    folderDevices = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      description = "Folder ID to the host names that share it.";
    };

    pipelines = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.listOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption { type = lib.types.str; };
              events = lib.mkOption {
                type = lib.types.listOf (
                  lib.types.enum [
                    "ready"
                    "conflict"
                  ]
                );
              };
              command = lib.mkOption { type = lib.types.str; };
            };
          }
        )
      );
      default = { };
      description = "Ordered commands to run when a folder is ready.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/cjshearer/.local/state/files";
      description = "State directory shared by file sets and pipeline cursors.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = "cjshearer";
      group = "users";
      dataDir = "/home/cjshearer";
      guiAddress = "127.0.0.1:8384";

      cert = certPath;
      key = keyPath;

      settings.options = {
        listenAddresses = [ "tcp4://0.0.0.0:22000" ];

        globalAnnounceServers = [ ];
        globalAnnounceEnabled = false;
        localAnnounceEnabled = false;
        relaysEnabled = false;
        natEnabled = false;
        stunServers = [ ];
        announceLANAddresses = false;
        reconnectIntervalS = 60;

        urAccepted = -1;
        autoUpgradeIntervalH = 0;
        crashReportingEnabled = false;
        startBrowser = false;
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22000 ];

    systemd.services.syncthing = {
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];

      serviceConfig = {
        IPAddressAllow = [
          "100.64.0.0/10"
          "fd7a:115c:a1e0::/48"
          "127.0.0.0/8"
          "::1/128"
        ];
        IPAddressDeny = [
          "0.0.0.0/0"
          "::/0"
        ];
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
          "AF_NETLINK"
        ];
        ExecStartPre = lib.mkBefore [ prepare ];
      };
    };

    systemd.services.syncthing-init.serviceConfig.ExecStartPost = lib.mkAfter [ apply ];

    systemd.services.syncthing-triggers = lib.mkIf (cfg.pipelines != { }) {
      description = "Run ordered commands when a Syncthing folder is ready";
      after = [
        "syncthing.service"
        "syncthing-init.service"
      ];
      wants = [
        "syncthing.service"
        "syncthing-init.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "cjshearer";
        Group = "users";
        Restart = "always";
        RestartSec = "5s";
        KillMode = "control-group";
        ExecStart = pkgs.writeShellScript "syncthing-triggers" ''
          exec ${syncthingTriggers}/bin/syncthing-triggers dispatch \
            --config ${lib.escapeShellArg "${config.services.syncthing.configDir}/config.xml"} \
            --gui ${lib.escapeShellArg config.services.syncthing.guiAddress} \
            --pipelines ${lib.escapeShellArg "${pipelinesFile}"} \
            --state-dir ${lib.escapeShellArg cfg.stateDir}
        '';
      };
    };
  };
}
