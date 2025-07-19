{ lib, pkgs, config, home-manager, ... }:
{
  options.users.cjshearer.programs.rclone.enable = lib.mkEnableOption "rclone";

  options.users.cjshearer.programs.rclone.remotes = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          persist = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = ''
              A list of keys that should be persisted from prior rclone configurations.
            '';
          };
        };
      }
    );
    default = { };
  };

  config = lib.mkIf config.users.cjshearer.programs.rclone.enable {
    systemd.tmpfiles.rules = [
      "d /mnt/onedrive 0755 cjshearer users -"
    ];
    home-manager.users.cjshearer.programs.rclone.enable = true;

    users.cjshearer.programs.rclone.remotes.onedrive.persist = [ "drive_id" "token" ];

    # override the default activation script to allow persisting existing rclone configuration
    home-manager.users.cjshearer.home.activation.createRcloneConfig =
      let
        cfg = config.home-manager.users.cjshearer.programs.rclone;
        iniFormat = pkgs.formats.ini { };
        safeConfig = lib.pipe cfg.remotes [
          (lib.mapAttrs (_: v: v.config))
          (iniFormat.generate "rclone.conf@pre-secrets")
        ];

        # https://github.com/rclone/rclone/issues/8190
        injectSecret =
          remote:
          lib.mapAttrsToList
            (secret: secretFile: ''
              ${lib.getExe cfg.package} config update \
                ${remote.name} config_refresh_token=false \
                ${secret} "$(cat ${secretFile})" \
                --quiet --non-interactive > /dev/null
            '') remote.value.secrets or { };

        injectAllSecrets =
          lib.concatMap injectSecret (lib.mapAttrsToList lib.nameValuePair cfg.remotes);
      in
      lib.mkForce (
        home-manager.lib.hm.dag.entryAfter [ "writeBoundary" cfg.writeAfter ] ''
          previousConfig=$(${pkgs.rclone}/bin/rclone config dump)

          run install $VERBOSE_ARG -D -m600 ${safeConfig} \
            "${config.home-manager.users.cjshearer.xdg.configHome}/rclone/rclone.conf"
          ${lib.concatLines injectAllSecrets}

          # convert remotes.<remoteName>.persist.[persistItem] to a list of
          # "remoteName,persistItem" pairs
          valuesToPersist=(${
            lib.pipe config.users.cjshearer.programs.rclone.remotes [
              (lib.mapAttrsToList (remoteName: remote:
                  lib.map (persistItem: ''"${remoteName},${persistItem}"'') remote.persist
                ))
              (lib.flatten)
              (lib.concatStringsSep " ")
            ]
          })

          for pair in "''${valuesToPersist[@]}"; do
            IFS=',' read -r remoteName persistItem <<< "$pair"

            ${pkgs.rclone}/bin/rclone config update \
              "$remoteName" \
              "$persistItem" \
              "$(
                ${pkgs.coreutils}/bin/echo "$previousConfig" |
                ${pkgs.jq}/bin/jq -r ."$remoteName"."$persistItem"' // ""'
              )" \
              --quiet --non-interactive > /dev/null
          done
        ''
      );

    home-manager.users.cjshearer.programs.rclone.remotes.onedrive = {
      config = {
        drive_type = "personal";
        type = "onedrive";
      };
      mounts."" = {
        enable = true;
        mountPoint = "/mnt/onedrive";
        options = {
          dir-cache-time = "52w";
          onedrive-delta = true;
          onedrive-drive-type = "personal";
          poll-interval = "30s";
          vfs-cache-max-age = "2w";
          vfs-cache-mode = "full";
          vfs-refresh = true;
        };
      };
    };
    home-manager.users.cjshearer.systemd.user.services."rclone-mount\:@onedrive-symlink" =
      let home = config.home-manager.users.cjshearer.home.homeDirectory; in {
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

    home-manager.users.cjshearer.systemd.user.services."rclone-mount\:@onedrive-token-sidecar" = {
      Unit = {
        Description = "Saves OneDrive Token with systemd-creds";
        PartOf = "rclone-mount\:@onedrive.service";
        After = "rclone-mount\:@onedrive.service";
      };

      Service = {
        Type = "notify";
        # PreExecStart = "${pkgs.rbw}/bin/rbw get 62ce2991-91ad-4de3-a61f-acd200201a26 --field onedrive_token > /run/rclone/onedrive-token";
        ExecStart = pkgs.writeShellScript "rclone-mount\:@onedrive-token-sidecar" ''
          ${pkgs.inotify-tools}/bin/inotifywait \
            -m \
            -e modify,create,delete \
            ${pkgs.rbw}/bin/rbw get 62ce2991-91ad-4de3-a61f-acd200201a26 --field onedrive_token | \
            while read; do
              # Save the token to systemd-creds
              systemd-creds encrypt \
                --user \
                --name onedrive-token \< ${pkgs.rbw}/bin/rbw get 62ce2991-91ad-4de3-a61f-acd200201a26 --field onedrive_token
            done
        '';
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
