# Sync Dusklight state over the tailnet between the hosts that run it.
#
# This replaces the OneDrive bisync job: game state does not need to leave the
# tailnet, and two multi-master engines on the same tree resolve conflicts
# differently. The folder is shared only with hosts that enable this module, so
# a host without Dusklight never sees it.
{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.users.cjshearer.programs.dusklight;
  syncthing = config.users.cjshearer.services.syncthing;
  path = "/home/cjshearer/.local/share/TwilitRealm/Dusklight";

  peers = builtins.attrNames (
    lib.filterAttrs (
      _: host: host.config.users.cjshearer.programs.dusklight.enable
    ) self.nixosConfigurations
  );
in
{
  options.users.cjshearer.programs.dusklight.enable = lib.mkEnableOption "dusklight";

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home-manager.users.cjshearer.home.packages = [ pkgs.dusklight ];

      users.cjshearer.services.syncthing.enable = lib.mkDefault true;
    })

    (lib.mkIf (cfg.enable && syncthing.enable) {
      services.syncthing.settings.folders.dusklight = {
        label = "Dusklight";
        inherit path;
        devices = peers;
        ignorePatterns = [
          "/*cache.db"
          "/logs/"
        ];
        versioning.type = "staggered";
      };
    })
  ];
}
