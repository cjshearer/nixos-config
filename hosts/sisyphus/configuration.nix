{
  hardware.bluetooth.enable = true;

  programs.hyprland.enable = true;
  programs.nemo.enable = true;
  programs.steam.enable = true;

  services.greetd.tuigreet.desktop = "Hyprland";
  services.greetd.tuigreet.enable = true;
  services.liquidctl.enable = true;
  services.onedrive.enable = true;
  services.pipewire.enable = true;
  services.printing.enable = true;
  services.tailscale.enable = true;

  time.timeZone = "America/New_York";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
