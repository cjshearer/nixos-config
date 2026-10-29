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
        version = "6730e028070472eccad093ab54ab39c64210f3d5";
        src = pkgs.fetchFromGitHub {
          owner = "badabing2005";
          repo = "PixelFlasher";
          tag = "v${finalAttrs.version}";
          hash = "sha256-2MUtmG4waVT1EDXuio4lU/FSEkfOBDRPnTfPzOk1Fd4=";
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
