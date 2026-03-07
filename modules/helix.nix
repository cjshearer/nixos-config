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
    };
    home-manager.users.cjshearer.home.packages = [
      pkgs.ruff
      pkgs.python3Packages.python-lsp-server
    ];
  };
}
