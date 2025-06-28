{ lib, pkgs, config, ... }: lib.mkIf config.services.pipewire.enable {
  services.pipewire.wireplumber.configPackages = [
    (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/11-bluetooth-policy.conf" ''
      wireplumber.settings = { bluetooth.autoswitch-to-headset-profile = false }
    '')
  ];
}
