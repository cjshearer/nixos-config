{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.programs.pixelflasher;
in
{
  options.programs.pixelflasher.enable = mkEnableOption "pixelflasher";

  options.programs.pixelflasher.package = mkOption {
    type = types.package;
    default = (
      pkgs.pixelflasher.overrideAttrs (finalAttrs: {
        version = "9.1.5.0";
        src = pkgs.fetchFromGitHub {
          owner = "badabing2005";
          repo = "PixelFlasher";
          tag = "v${finalAttrs.version}";
          hash = "sha256-SAo6od26CULyoxufSpMbkLPm+qx+XNak3irQLep5Ubw=";
        };
      })
    );
    description = "The package to use for pixelflasher.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      android-tools
      cfg.package
    ];
  };
}
