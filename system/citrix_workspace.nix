{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.citrix_workspace;
in
{
  options.programs.citrix_workspace.enable = mkEnableOption "citrix_workspace";

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.unstable.citrix_workspace ];
  };
}
