{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.greetd.tuigreet;
in
{
  options.services.greetd.tuigreet = {
    enable = mkEnableOption "tuigreet service";
    desktop = mkOption {
      description = "The program to run on succesful login";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    services.greetd.enable = true;
    services.greetd.settings = {
      # https://github.com/sjcobb2022/nixos-config/blob/main/hosts/common/optional/greetd.nix
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${cfg.desktop}";
        user = "greeter";
      };
    };
  };
}
