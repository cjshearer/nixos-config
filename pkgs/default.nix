{ pkgs, ... }:
{
  hyprec = pkgs.callPackage ./hyprec { };
  pixelflasher = pkgs.callPackage ./pixelflasher { };
}
