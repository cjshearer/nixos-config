# Share the notes folder across the Syncthing mesh.
#
# The mesh module intentionally does not choose folders. This module is the
# first consumer: it keeps the data policy with the data owner, so the mesh can
# carry other folders later and a host can join without inheriting notes.
#
# Replication lives here too. A host only opts in; the source, remote, sync
# direction, exclusions, and safety checks stay in one place.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  syncthing = config.users.cjshearer.services.syncthing;
  cfg = syncthing.notes;

  syncthingConfig = "${config.services.syncthing.dataDir}/.config/syncthing/config.xml";
  oneDrivePath = "onedrive:Documents/my-notes";

  # One merger only: .stversions is local to each host, so a second host would
  # merge the same conflict against a different base and create another one.
  notesMerge = pkgs.callPackage ../pkgs/notes-merge/package.nix { };

  # Only mirror a settled folder: a pull or push that races the peers would
  # fight Syncthing. An empty folder is allowed through, because the sync
  # restores it from OneDrive instead of erasing the remote copy.
  replicationReady = ''
    key=$(${pkgs.gnused}/bin/sed -n 's:.*<apikey>\(.*\)</apikey>.*:\1:p' ${syncthingConfig})
    ${pkgs.curl}/bin/curl -fsS -H "X-API-Key: $key" \
      'http://${config.services.syncthing.guiAddress}/rest/db/status?folder=notes' \
      | ${pkgs.jq}/bin/jq -e '.state == "idle" and .needFiles == 0' >/dev/null
  '';
in
{
  options.users.cjshearer.services.syncthing.notes = {
    enable = lib.mkEnableOption "the notes folder on the Syncthing mesh";

    path = lib.mkOption {
      type = lib.types.str;
      default = "/home/cjshearer/Notes";
      description = "Local notes directory. Must not be a FUSE mount.";
    };

    replicate = lib.mkEnableOption "one-way rclone replication of the notes folder";
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && syncthing.enable) {
      services.syncthing.settings.folders.notes = {
        label = "Notes";
        path = cfg.path;
        devices = lib.attrNames config.services.syncthing.settings.devices;
        versioning.type = "staggered";
      };

      systemd.tmpfiles.rules = [
        "d '${cfg.path}' 0700 cjshearer users -"
      ];
    })

    (lib.mkIf (cfg.enable && cfg.replicate && syncthing.enable) {
      users.cjshearer.services.rclone.operations.notes = {
        src = cfg.path;
        dst = oneDrivePath;
        operation = "sync";
        enable = true;
        maxDelete = 50;
        pullIfEmpty = true;
        exclude = [
          ".stfolder/**"
          ".stversions/**"
          ".stignore"
          ".syncthing.*.tmp"
          # Merged locally on the replicator; never mirror a conflict copy.
          "*.sync-conflict-*"
        ];
        precheck = replicationReady;
      };

      # Clean three-way merges only. Anything else stays as a conflict file.
      #
      # Syncthing has no conflict event and no command hooks, but its event
      # stream reports every folder state transition. Long-poll StateChanged and
      # merge as soon as the notes folder returns to idle, which is the point a
      # pull has finished installing everything it downloaded, conflict copies
      # included. This replaces the old 1-minute timer: the merge runs when the
      # folder settles instead of on a fixed cadence, and stays quiet otherwise.
      systemd.services."notes-merge" = {
        description = "Merge Syncthing conflict copies when the notes folder settles";
        after = [ "syncthing.service" ];
        wants = [ "syncthing.service" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.ConditionPathIsDirectory = cfg.path;
        serviceConfig = {
          User = "cjshearer";
          Group = "users";
          Restart = "always";
          RestartSec = "5s";
          ExecStart = pkgs.writeShellScript "notes-merge-watch" ''
            set -euo pipefail

            config=${lib.escapeShellArg syncthingConfig}
            events="http://${config.services.syncthing.guiAddress}/rest/events"

            api_key() {
              ${pkgs.gnused}/bin/sed -n 's:.*<apikey>\(.*\)</apikey>.*:\1:p' "$config"
            }

            # Merge once, and only from a settled folder: the event says the
            # folder *was* idle, and a peer can push again before we run.
            merge() {
              if ! (${replicationReady}); then
                echo "syncthing is not idle; skipping conflict merge"
                return 0
              fi
              ${notesMerge}/bin/notes-merge --folder ${lib.escapeShellArg cfg.path}
            }

            # Resume at the end of the stream so a restart does not replay the
            # buffered history; the merge below covers anything that happened
            # while we were down.
            since=$(${pkgs.curl}/bin/curl -fsS \
              -H "X-API-Key: $(api_key)" "$events?since=0&limit=1" \
              | ${pkgs.jq}/bin/jq -r '.[-1].id // 0') || since=0

            merge || true

            while :; do
              batch=$(${pkgs.curl}/bin/curl -fsS \
                -H "X-API-Key: $(api_key)" \
                "$events?since=$since&timeout=60&events=StateChanged") \
                || { ${pkgs.coreutils}/bin/sleep 5; continue; }

              next=$(printf '%s' "$batch" \
                | ${pkgs.jq}/bin/jq -r 'if length > 0 then .[-1].id else empty end')
              if [ -n "$next" ]; then since=$next; fi

              if printf '%s' "$batch" \
                | ${pkgs.jq}/bin/jq -e 'any(.[]; .data.folder == "notes" and .data.to == "idle")' >/dev/null; then
                merge || echo "merge failed; will retry when the folder settles again" >&2
              fi
            done
          '';
        };
      };
    })
  ];
}
