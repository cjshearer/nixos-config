{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.citrix_workspace;
in
{
  options.programs.citrix_workspace.enable = mkEnableOption "citrix_workspace";

  config = mkIf cfg.enable {
    # https://www.citrix.com/downloads/workspace-app/legacy-workspace-app-for-linux/workspace-app-for-linux-latest13.html
    # nix-prefetch-url file://$(realpath ~/Downloads/linuxx64-24.8.0.98.tar.gz)
    environment.systemPackages = [
      pkgs.citrix_workspace
    ];

    nixpkgs.config.permittedInsecurePackages = [
      "libxml2-2.13.8"
    ];
  };
}
