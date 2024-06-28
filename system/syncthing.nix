{ systemConfig, lib, pkgs, config, ... }: lib.mkIf config.services.syncthing.enable {
  services.syncthing = {
    configDir = "/home/${systemConfig.username}/.config/syncthing";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        athamas = {
          addresses = [ tcp://athamas:22000 ];
          id = "H6ZCHM7-Z6KGQZ4-YPS34HA-77XGUA3-V74HH4F-5VTXKMP-CKIKFZU-GG7TLQY";
        };
        salmoneus = {
          addresses = [ tcp://salmoneus:22000 ];
          id = "XDIQ5TQ-JR3OPNT-2K6RAZ2-CLTR4AE-RCOM5IU-IV3V2ZF-HQMRXWE-LP4IRAY";
        };
        sisyphus = {
          addresses = [ tcp://sisyphus:22000 ];
          id = "MCRXYZA-654GQQ3-5IOWJOH-MRY3NOP-NUVUAUL-KZGK4TJ-3WYS2E7-GZCL5Q3";
        };
      };
      folders = lib.filterAttrs (_: v: builtins.elem systemConfig.hostname v.devices) {
        "audiobooks" = {
          path = "/home/${systemConfig.username}/OneDrive/audiobooks";
          devices = [ "salmoneus" "sisyphus" ];
        };
        "my-notes" = {
          path = "/home/${systemConfig.username}/OneDrive/documents/my-notes";
          devices = [ "athamas" "salmoneus" "sisyphus" ];
        };
      };
      options = {
        announceLANAddresses = false;
        globalAnnounceEnabled = false;
        localAnnounceEnabled = false;
        relaysEnabled = false;
        urAccepted = -1;
      };
    };
    user = systemConfig.username;
  };
}
