{ pkgs, ... }:
{
  hyprec = pkgs.callPackage ./hyprec { };
  pixelflasher = pkgs.unstable.callPackage ./pixelflasher { };
}
