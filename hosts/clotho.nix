{
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  boot.loader.systemd-boot.enable = true;

  networking.networkmanager.enable = true;
  networking.wireless.enable = false;

  nixpkgs.hostPlatform = "x86_64-linux";

  services.tailscale.enable = true;

  time.timeZone = "America/New_York";
}
