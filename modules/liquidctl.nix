{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.services.liquidctl;
in
{
  options.services.liquidctl.enable = mkEnableOption "liquidctl";

  config = mkIf cfg.enable {
    systemd.services.liquidctl = {
      enable = true;
      description = "AIO startup service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = [
          "${pkgs.liquidctl}/bin/liquidctl initialize all"
          "${pkgs.liquidctl}/bin/liquidctl set logo color off"
          "${pkgs.liquidctl}/bin/liquidctl set ring color off"
        ];
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
