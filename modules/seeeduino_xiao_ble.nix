{ config, lib, ... }:
{
  options.hardware.seeeduino_xiao_ble.enable = lib.mkEnableOption "seeeduino_xiao_ble";

  config = lib.mkIf config.hardware.seeeduino_xiao_ble.enable {
    services.udev.extraRules = ''
      KERNEL=="ttyACM*", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="615e", MODE:="0666"
    '';
  };
}
