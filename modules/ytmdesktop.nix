{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.ytmdesktop;
in
{
  options.programs.ytmdesktop.enable = mkEnableOption "ytmdesktop";

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.ytmdesktop.override {
        # TODO: validate this
        commandLineArgs = "--password-store=\"gnome-libsecret\"";
      })
    ];

    # required for last.fm integration
    services.gnome.gnome-keyring.enable = true;
  };
}
