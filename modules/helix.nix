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
        home.sessionVariables.EDITOR = "hx";
        home.sessionVariables.VISUAL = "hx";
      }
    )
  ];
}
