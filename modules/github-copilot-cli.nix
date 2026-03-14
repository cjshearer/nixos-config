{
  home-manager.sharedModules = [
    (
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        options.programs.github-copilot-cli.enable = lib.mkEnableOption "github-copilot-cli";

        config = lib.mkIf config.programs.github-copilot-cli.enable {
          home.packages = [ pkgs.github-copilot-cli ];
        };
      }
    )
  ];
}
