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
        options.programs.awscli2.enable = lib.mkEnableOption "awscli2";

        config = lib.mkIf config.programs.awscli2.enable {
          home.packages = [ pkgs.awscli2];
        };
      }
    )
  ];
}
