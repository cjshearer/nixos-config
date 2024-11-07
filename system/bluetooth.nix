{ lib, config, ... }: lib.mkIf config.hardware.bluetooth.enable {
  hardware.bluetooth.powerOnBoot = true;
}
