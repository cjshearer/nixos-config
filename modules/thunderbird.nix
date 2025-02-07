{ lib, config, systemConfig, ... }: lib.mkIf config.programs.thunderbird.enable {
  home-manager.users.${systemConfig.username}.programs.thunderbird = {
    enable = true;
    profiles.default.isDefault = true;
  };
}
