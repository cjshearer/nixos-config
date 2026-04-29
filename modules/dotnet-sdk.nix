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
        options.programs.dotnet-sdk.enable = lib.mkEnableOption "dotnet-sdk";

        config = lib.mkIf config.programs.dotnet-sdk.enable {
          home.packages = [ pkgs.dotnet-sdk ];
        };
      }
    )
  ];
}
