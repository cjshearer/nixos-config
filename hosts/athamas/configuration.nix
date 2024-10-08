{
  hardware.bluetooth.enable = true;

  programs.citrix_workspace.enable = true;
  programs.hyprland.enable = true;
  programs.light.brightnessKeys.enable = true;
  programs.light.enable = true;
  programs.nemo.enable = true;
  programs.pixelflasher.enable = true;
  programs.remmina.enable = true;
  programs.ytmdesktop.enable = true;

  services.greetd.tuigreet.desktop = "Hyprland";
  services.greetd.tuigreet.enable = true;
  # Userspace virtual file system (enables external storage devices)
  services.gvfs.enable = true;
  services.pipewire.enable = true;
  services.printing.enable = true;
  services.syncthing.enable = true;
  services.tailscale.enable = true;

  time.timeZone = "America/New_York";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
