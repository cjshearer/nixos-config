{
  self,
  ...
}:
{
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [ "cjshearer" ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [ self.overlays.packages ];
}
