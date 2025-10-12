{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.programs.sauerbraten;
in
{
  options.programs.sauerbraten.enable = mkEnableOption "sauerbraten";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ sauerbraten ];

    networking.firewall.allowedUDPPortRanges = [
      {
        from = 28785;
        to = 28786;
      }
    ];
  };
}
