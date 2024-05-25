{ systemConfig, inputs, ... }: {
  imports = [
    ./bluetooth.nix
    ./hypr.nix
    ./liquidctl.nix
    ./nemo.nix
    ./onedrive.nix
    ./pipewire.nix
    ./pixelflasher.nix
    ./qbittorrent.nix
    ./syncthing.nix
    ./tailscale.nix
    ./tuigreet.nix
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
  nixpkgs.overlays = [
    (final: _prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = final.system;
        config.allowUnfree = true;
        config.permittedInsecurePackages = [
          "openssl-1.0.1u" # required by ideamaker
          "curl-7.47.0" # required by ideamaker
        ];
      };
    })
    (final: _prev: import ../pkgs { pkgs = _prev.pkgs.unstable; })
    inputs.nix-vscode-extensions.overlays.default
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  users.users.${systemConfig.username} = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
