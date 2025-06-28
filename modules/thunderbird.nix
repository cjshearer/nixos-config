{ lib, config, systemConfig, ... }: lib.mkIf config.programs.thunderbird.enable {
  home-manager.users.cjshearer.programs.thunderbird = {
    enable = true;
    profiles.default.isDefault = true;
  };
}
