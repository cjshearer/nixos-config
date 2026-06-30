{
  home-manager.sharedModules = [
    (
      {
        lib,
        pkgs,
        config,
        ...
      }:
      lib.mkIf config.programs.helix.enable {
        programs.helix = {
          # Build Helix from the upstream fork that compiles in the Steel (Scheme) plugin
          # system (PR helix-editor/helix#8675, not yet merged).
          package =
            let
              src = pkgs.fetchFromGitHub {
                owner = "mattwparas";
                repo = "helix";
                rev = "0522d519fd5227f77ecef387a87e51b732907562";
                hash = "sha256-bGfByNnjuzENdvTW97s4UhwglYY7ydBk54gOZmnaM4Q=";
              };
            in
            pkgs.helix.override {
              helix-unwrapped = pkgs.helix-unwrapped.overrideAttrs {
                version = "25.7.1-steel-unstable-2026-06-22";
                inherit src;
                cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
                  inherit src;
                  name = "helix-unwrapped-steel-vendor";
                  hash = "sha256-dMyHrPdW7YQ3doX9IB0Fzy9O/kW14pu5OmRGyDv0iDI=";
                };
                # The nixpkgs mdbook patch targets upstream's commands.rs, which the fork has
                # diverged from. Drop it and the bundled mdbook docs (not needed for the editor).
                patches = [ ];
                postPatch = "";
                outputs = [ "out" ];
                postBuild = "";
                postInstall = ''
                  installShellCompletion contrib/completion/hx.{bash,fish,zsh}
                  mkdir -p $out/share/{applications,icons/hicolor/256x256/apps}
                  cp contrib/Helix.desktop $out/share/applications/Helix.desktop
                  cp contrib/helix.png $out/share/icons/hicolor/256x256/apps/helix.png
                '';
                # Fork's hx --version string differs from the override version label.
                doInstallCheck = false;
              };
            };

          languages = {
            language-server.codebook.args = [ "serve" ];
            language-server.codebook.command = "${pkgs.codebook}/bin/codebook-lsp";
            language-server.nil.command = "${pkgs.nil}/bin/nil";
            language-server.pylsp.command = "${pkgs.python3Packages.python-lsp-server}/bin/pylsp";
            language-server.ruff.command = "${pkgs.ruff}/bin/ruff";

            language = [
              {
                name = "markdown";
                language-servers = [ "codebook" ];
                soft-wrap.enable = true;
              }
              {
                name = "nix";
                auto-format = true;
              }
            ];
          };
          settings.editor = {
            rulers = [ 100 ];
            text-width = 100;
          };
        };
        home.sessionVariables.EDITOR = "hx";
        home.sessionVariables.VISUAL = "hx";
      }
    )
  ];
}
