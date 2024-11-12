{
  programs.citrix_workspace.enable = true;
  programs.light.brightnessKeys.enable = true;
  programs.light.enable = true;
  # pyinstaller broken on unstable:
  # https://github.com/NixOS/nixpkgs/commit/89a1044a08f38490c527032ef4b0f2143bcae57b
  # programs.pixelflasher.enable = true;
  programs.remmina.enable = true;
  programs.ytmdesktop.enable = true;

  services.desktopManager.cosmic.enable = true;
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
