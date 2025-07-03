{ config, pkgs, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  networking.wireless.enable = false;

  nixpkgs.hostPlatform = "x86_64-linux";

  services.tailscale.enable = true;

  time.timeZone = "America/New_York";
}
