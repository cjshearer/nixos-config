{
  home-manager.sharedModules = [
    (
      { lib, config, ... }:
      lib.mkIf config.programs.go.enable {
        programs.go.env.CGO_ENABLED = "0";
      }
    )
  ];
}
