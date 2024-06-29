{ lib, config, ... }: lib.mkIf config.services.pipewire.enable {
  security.rtkit.enable = true;
  services.pipewire = {
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
