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
        options.programs.kubectl.enable = lib.mkEnableOption "kubectl";

        config = lib.mkIf config.programs.kubectl.enable {
          home.packages = [ pkgs.kubectl ];
        };
      }
    )
  ];
}
