{ config, lib, ... }:
{
  options.hardware.seeed-xiao-ble.enable = lib.mkEnableOption "seeed-xiao-ble";

  config = lib.mkIf config.hardware.seeed-xiao-ble.enable {
    services.udev.extraRules = ''
      KERNEL=="ttyACM*", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="615e", MODE:="0666"
    '';
  };
}
