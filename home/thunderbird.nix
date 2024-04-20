{ lib, config, ... }: lib.mkIf config.programs.thunderbird.enable {
  programs.thunderbird.profiles.default.isDefault = true;
}
