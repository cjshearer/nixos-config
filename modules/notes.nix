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

  # Only mirror a completed folder. An idle folder with no files and no peers
  # must not erase the remote copy, so require at least one local or global
  # file and no pending needs.
  replicationReady = ''
    key=$(${pkgs.gnused}/bin/sed -n 's:.*<apikey>\(.*\)</apikey>.*:\1:p' ${syncthingConfig})
    ${pkgs.curl}/bin/curl -fsS -H "X-API-Key: $key" \
      'http://${config.services.syncthing.guiAddress}/rest/db/status?folder=notes' \
      | ${pkgs.jq}/bin/jq -e '.state == "idle" and .needFiles == 0 and (.localFiles > 0 or .globalFiles > 0)' >/dev/null
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
        exclude = [
          ".stfolder/**"
          ".stversions/**"
          ".stignore"
          ".syncthing.*.tmp"
        ];
        precheck = replicationReady;
      };
    })
  ];
}
