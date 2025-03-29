{ systemConfig, inputs, ... }: {
  imports = [
    ./atuin.nix
    ./blender.nix
    ./citrix_workspace.nix
    ./cosmic.nix
    ./cosmic.nix
    ./direnv.nix
    ./discord.nix
    ./git.nix
    ./google-chrome.nix
    ./ideamaker.nix
    ./kicad.nix
    ./ledger-live-desktop.nix
    ./libreoffice.nix
    ./liquidctl.nix
    ./logiops.nix
    ./obsidian.nix
    ./picard.nix
    ./pipewire.nix
    ./pixelflasher.nix
    ./qbittorrent.nix
    ./rclone.nix
    ./remmina.nix
    ./ssh.nix
    ./tailscale.nix
    ./thunderbird.nix
    ./vscode.nix
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
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.0.1u" # required by ideamaker
    "curl-7.47.0" # required by ideamaker
  ];

  system.etc.overlay.mutable = false;

  users.users.cjshearer.extraGroups = [
    "networkmanager"
    "wheel"
  ];
  users.users.cjshearer.isNormalUser = true;
  users.users.cjshearer.uid = 1000;
}
