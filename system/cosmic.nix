{ lib, config, pkgs, nixos-cosmic, ... }: lib.mkIf config.services.desktopManager.cosmic.enable {
  services.displayManager.cosmic-greeter.enable = true;

  # https://github.com/lilyinstarlight/nixos-cosmic?tab=readme-ov-file#cosmic-utilities---clipboard-manager-not-working
  environment.sessionVariables = {
    NIXOS_OZONE_WL = 1;
    COSMIC_DATA_CONTROL_ENABLED = 1;
  };

  environment.systemPackages = [
    pkgs.wl-clipboard
    pkgs.cosmic-ext-applet-clipboard-manager
  ];

  nix.settings.substituters = [ "https://cosmic.cachix.org/" ];
  nix.settings.trusted-public-keys = [
    "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
  ];
}
