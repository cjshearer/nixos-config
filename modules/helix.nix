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
