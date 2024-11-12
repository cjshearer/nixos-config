{
  hardware.bluetooth.enable = true;

  programs.citrix_workspace.enable = true;
  # programs.ideamaker.enable = true;
  programs.ledger-live-desktop.enable = true;
  programs.picard.enable = true;
  # pyinstaller broken on unstable:
  # https://github.com/NixOS/nixpkgs/commit/89a1044a08f38490c527032ef4b0f2143bcae57b
  # programs.pixelflasher.enable = true;
  programs.qbittorrent.enable = true;
  programs.remmina.enable = true;
  programs.steam.enable = true;
  programs.ytmdesktop.enable = true;
  programs.zoom-us.enable = true;

  services.desktopManager.cosmic.enable = true;
  services.liquidctl.enable = true;
  services.ollama.enable = true;
  services.onedrive.enable = true;
  services.pipewire.enable = true;
  services.syncthing.enable = true;
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
