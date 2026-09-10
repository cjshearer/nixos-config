{
  home-manager.sharedModules = [
    (
      { lib, config, pkgs, ... }:
      lib.mkIf config.programs.go.enable {
        programs.go.env.CGO_ENABLED = "0";
        programs.go.package = pkgs.go_latest;
      }
    )
  ];
}
