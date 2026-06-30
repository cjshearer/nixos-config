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
          package =
            let
              steelixRev = "0522d519fd5227f77ecef387a87e51b732907562";
            in
            (pkgs.steelix.override {
              fetchFromGitHub =
                args:
                pkgs.fetchFromGitHub (
                  args
                  // {
                    rev = steelixRev;
                    hash = "sha256-bGfByNnjuzENdvTW97s4UhwglYY7ydBk54gOZmnaM4Q=";
                  }
                );
              rustPlatform = pkgs.rustPlatform // {
                fetchCargoVendor =
                  args:
                  pkgs.rustPlatform.fetchCargoVendor (
                    args
                    // {
                      hash = "sha256-dMyHrPdW7YQ3doX9IB0Fzy9O/kW14pu5OmRGyDv0iDI=";
                    }
                  );
              };
            }).overrideAttrs
              (_: {
                version = "0-unstable-2026-06-22";
              });

          languages = {
            language-server.codebook.args = [ "serve" ];
            language-server.codebook.command = "${pkgs.codebook}/bin/codebook-lsp";
            language-server.nil.command = "${pkgs.nil}/bin/nil";
            language-server.pylsp.command = "${pkgs.python3Packages.python-lsp-server}/bin/pylsp";
            language-server.roslyn-language-server.args = [
              "--autoLoadProjects"
              "--stdio"
            ];
            language-server.roslyn-language-server.command = "${pkgs.roslyn-ls}/bin/Microsoft.CodeAnalysis.LanguageServer";
            language-server.ruff.command = "${pkgs.ruff}/bin/ruff";

            language = [
              {
                name = "c-sharp";
                language-servers = [ "roslyn-language-server" ];
              }
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
        xdg.dataFile =
          let
            forestHxRev = "76f539932e78f3f7c6627379c9ca46dc8482128f";
            forestHxSrc = pkgs.fetchFromGitHub {
              owner = "Ra77a3l3-jar";
              repo = "forest.hx";
              rev = forestHxRev;
              hash = "sha256-kQox4neRkJg5te6bbozur3/TW4m7u3VrPrZI3jE985k=";
            };
            forestHxDeps = pkgs.stdenvNoCC.mkDerivation {
              pname = "forest.hx-deps";
              version = forestHxRev;

              src = forestHxSrc;

              nativeBuildInputs = [
                pkgs.cacert
                pkgs.steel
              ];
              outputHashMode = "recursive";
              outputHash = "sha256-WzVxq/RO6LP2BEKM9lEP8Ok+Bcvu+OGsPnvPs/nXttU=";

              buildPhase = ''
                runHook preBuild

                export STEEL_HOME=$TMPDIR/steel
                export GIT_SSL_CAINFO=$NIX_SSL_CERT_FILE
                mkdir -p "$STEEL_HOME"

                forge install

                find "$STEEL_HOME/cogs" -name .git -type d -prune -exec rm -rf {} +

                runHook postBuild
              '';

              installPhase = ''
                runHook preInstall

                mkdir -p "$out/cogs"
                for cog in "$STEEL_HOME"/cogs/*; do
                  if [ "$(basename "$cog")" != forest ]; then
                    cp -R "$cog" "$out/cogs/"
                  fi
                done

                runHook postInstall
              '';
            };
          in
          {
            "steel/cogs" = {
              source = "${forestHxDeps}/cogs";
              recursive = true;
            };
            "steel/cogs/forest".source = forestHxSrc;
          };

        xdg.configFile."helix/init.scm".text = ''
          (require "forest/forest.scm")
        '';

        home.sessionVariables.EDITOR = "hx";
        home.sessionVariables.VISUAL = "hx";
      }
    )
  ];
}
