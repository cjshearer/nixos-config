{ systemConfig, inputs, ... }: {
  imports = [
    ./citrix_workspace.nix
    ./cosmic.nix
    ./ideamaker.nix
    ./ledger-live-desktop.nix
    ./liquidctl.nix
    ./logiops.nix
    ./onedrive.nix
    ./picard.nix
    ./pipewire.nix
    ./pixelflasher.nix
    ./qbittorrent.nix
    ./remmina.nix
    ./syncthing.nix
    ./tailscale.nix
    ./ytmdesktop.nix
    ./zoom-us.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  networking.hostName = systemConfig.hostname;
  networking.networkmanager.enable = true;
  networking.stevenblack.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "cjshearer" ];

  nixpkgs.config.allowUnfree = true;

  qt.enable = true;
  qt.style = "adwaita-dark";

  users.users.${systemConfig.username} = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
