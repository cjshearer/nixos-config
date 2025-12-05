{ pkgs, ... }:
{
  prepare-nixos-disk = pkgs.callPackage ./prepare-nixos-disk { };
  ideamaker = pkgs.callPackage ./ideamaker { };
  google-photos-takeout-helper = pkgs.callPackage ./google-photos-takeout-helper { };
}
