{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.programs.ytmdesktop;
in
{
  options.programs.ytmdesktop.enable = mkEnableOption "ytmdesktop";

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (
        (pkgs.ytmdesktop.override {
          # TODO: validate this
          commandLineArgs = "--password-store=\"gnome-libsecret\"";
        }).overrideAttrs
        (finalAttrs: {
          version = "2.0.10";

          src = pkgs.fetchFromGitHub {
            owner = "ytmdesktop";
            repo = "ytmdesktop";
            tag = "v${finalAttrs.version}";
            leaveDotGit = true;

            postFetch = ''
              cd $out
              git rev-parse HEAD > .COMMIT
              find -name .git -print0 | xargs -0 rm -rf
            '';

            hash = "sha256-CA3Vb7Wp4WrsWSVtIwDxnEt1pWYb73WnhyoMVKoqvOE=";
          };

          yarnOfflineCache = pkgs.yarn-berry.fetchYarnBerryDeps {
            inherit (finalAttrs) src missingHashes;
            hash = "sha256-1jlnVY4KWm+w3emMkCkdwUtkqRB9ZymPPGuvgfQolrA=";
          };

          passthru.updateScript = pkgs.nix-update-script { };
        })
      )
    ];

    # required for last.fm integration
    services.gnome.gnome-keyring.enable = true;
  };
}
