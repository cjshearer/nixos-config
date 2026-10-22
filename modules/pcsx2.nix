# Sync PCSX2 state over the tailnet between the hosts that run it.
#
# This replaces the OneDrive bisync job: game state does not need to leave the
# tailnet, and two multi-master engines on the same tree resolve conflicts
# differently. The folder is shared only with hosts that enable this module, so
# a host without PCSX2 never sees it.
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
  path = "/home/cjshearer/.config/PCSX2";

  peers = builtins.attrNames (
    lib.filterAttrs (
      _: host: host.config.users.cjshearer.programs.pcsx2.enable
    ) self.nixosConfigurations
  );
in
{
  options.users.cjshearer.programs.pcsx2.enable = lib.mkEnableOption "PCSX2";

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home-manager.users.cjshearer.home.packages = [ pkgs.pcsx2 ];

      users.cjshearer.services.syncthing.enable = lib.mkDefault true;
    })

    (lib.mkIf (cfg.enable && syncthing.enable) {
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
  ];
}
