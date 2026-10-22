# Sync PCSX2 state over the tailnet, and back it up to OneDrive.
#
# Syncthing is the multi-master engine: hosts that run the game share the folder
# and merge each other's changes. One always-on host holds the folder without
# running the game and mirrors it to OneDrive. A single writer is what makes a
# bare `rclone sync` safe: a joiner or a host that is behind never pushes, so it
# cannot delete a remote file the fleet has not shared.
{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.users.cjshearer.programs.pcsx2;
  syncthing = config.users.cjshearer.services.syncthing;
  rclone = config.users.cjshearer.services.rclone;
  path = "/home/cjshearer/.config/PCSX2";

  # Hosts that run the game and hosts that only hold the folder to replicate it,
  # so every host agrees on the folder's device list.
  peers = builtins.attrNames (
    lib.filterAttrs (
      _: host:
      let
        peer = host.config.users.cjshearer.programs.pcsx2;
      in
      peer.enable || peer.replicate
    ) self.nixosConfigurations
  );

  holds = cfg.enable || cfg.replicate;
in
{
  options.users.cjshearer.programs.pcsx2 = {
    enable = lib.mkEnableOption "PCSX2";

    replicate = lib.mkEnableOption ''
      holding the PCSX2 folder to back it up to OneDrive, without running the
      game
    '';
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home-manager.users.cjshearer.home.packages = [ pkgs.pcsx2 ];
    })

    (lib.mkIf holds {
      users.cjshearer.services.syncthing.enable = lib.mkDefault true;
    })

    (lib.mkIf (holds && syncthing.enable) {
      services.syncthing.settings.folders.pcsx2 = {
        label = "PCSX2";
        inherit path;
        devices = peers;
        ignorePatterns = [
          "/cache/"
          "/logs/"
        ];
        versioning.type = "staggered";
      };
    })

    # Only the replica writes to OneDrive. The operation has no timer: it runs
    # when the folder is ready, and its first run restores OneDrive into the
    # folder before it ever pushes. There is no maxDelete, because a write only
    # happens once the local copy is the complete fleet state.
    (lib.mkIf (cfg.replicate && syncthing.enable && rclone.enable) {
      users.cjshearer.services.rclone.operations.pcsx2 = {
        src = path;
        dst = "onedrive:Games/PCSX2";
        operation = "sync";
        enable = true;
        trigger = "pcsx2";
        exclude = [
          ".stfolder/**"
          ".stversions/**"
          ".stignore"
          ".syncthing.*.tmp"
        ];
      };
    })
  ];
}
