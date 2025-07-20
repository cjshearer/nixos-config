{
  lib,
  config,
  ...
}:
{
  options.users.cjshearer.programs.thunderbird.enable = lib.mkEnableOption "thunderbird";

  config = lib.mkIf config.users.cjshearer.programs.thunderbird.enable {
    home-manager.users.cjshearer.programs.thunderbird = {
      enable = true;
      profiles.default.isDefault = true;
    };
  };
}
