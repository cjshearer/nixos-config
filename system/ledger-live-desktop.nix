{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.ledger-live-desktop;
in
{
  options.programs.ledger-live-desktop.enable = mkEnableOption "ledger-live-desktop";

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.unstable.ledger-live-desktop ];
    hardware.ledger.enable = true;
  };
}
