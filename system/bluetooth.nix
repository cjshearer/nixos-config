{ lib, config, ... }: lib.mkIf config.hardware.bluetooth.enable {
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
}
