{
  pkgs,
  config,
  lib,
  ...
}:
{
  options.users.cjshearer.programs.helix.enable = lib.mkEnableOption "helix";

  config = lib.mkIf config.users.cjshearer.programs.helix.enable {
    home-manager.users.cjshearer.programs.helix = {
      enable = true;
      languages = {
        language-server.nil.command = "${pkgs.nil}/bin/nil";
        language-server.pylsp.command = "${pkgs.python3Packages.python-lsp-server}/bin/pylsp";
        language-server.ruff.command = "${pkgs.ruff}/bin/ruff";
        language = [
          {
            name = "markdown";
            soft-wrap.enable = true;
          }
          {
            name = "nix";
            auto-format = true;
          }
        ];
      };
      settings.editor.rulers = [ 100 ];
    };
    home-manager.users.cjshearer.home.sessionVariables.EDITOR = "hx";
    home-manager.users.cjshearer.home.sessionVariables.VISUAL = "hx";
  };
}
