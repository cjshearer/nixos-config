{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.programs.google-chrome;
in
{
  options.programs.google-chrome.enable = mkEnableOption "google-chrome";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ google-chrome ];

    # https://github.com/justinhschaaf/nixos-config/blob/8985aa030ebac955d0c23a35a0381ba64b4c6e4c/modules/programs/desktop.nix#L194
    # https://gist.github.com/velzie/053ffedeaecea1a801a2769ab86ab376
    # https://cloud.google.com/docs/chrome-enterprise/policies/
    environment.etc =
      let
        options = builtins.toJSON {
          # Enable Manifest v2 while you still can
          ExtensionManifestV2Availability = 2;
        };
      in
      {
        "opt/chrome/policies/managed/policy.json".text = options;
        "opt/chrome/policies/managed/default.json".text = options;
        "opt/chrome/policies/managed/extra.json".text = options;
      };
  };
}
