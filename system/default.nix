{ systemConfig, inputs, ... }: {
  imports = [
    ./bluetooth.nix
    ./hypr.nix
    ./ledger-live-desktop.nix
    ./liquidctl.nix
    ./nemo.nix
    ./ollama.nix
    ./onedrive.nix
    ./pipewire.nix
    ./pixelflasher.nix
    ./qbittorrent.nix
    ./remmina.nix
    ./syncthing.nix
    ./tailscale.nix
    ./teams-for-linux.nix
    ./tuigreet.nix
    ./ytmdesktop.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  networking.hostName = systemConfig.hostname;
  networking.networkmanager.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  users.users.${systemConfig.username} = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
