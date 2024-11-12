{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.citrix_workspace;
in
{
  options.programs.citrix_workspace.enable = mkEnableOption "citrix_workspace";

  config = mkIf cfg.enable {
    # nix-prefetch-url file://$(realpath ~/Downloads/linuxx64-24.8.0.98.tar.gz)
    environment.systemPackages = [
      # temporary fix pending: https://github.com/NixOS/nixpkgs/issues/348868
      (pkgs.citrix_workspace.override {
        libvorbis = pkgs.libvorbis.override {
          libogg = pkgs.libogg.overrideAttrs (prevAttrs: {
            cmakeFlags = (prevAttrs.cmakeFlags or [ ]) ++ [
              (lib.cmakeBool "BUILD_SHARED_LIBS" true)
            ];
          });
        };
      })
    ];
  };
}
