{ pkgs, ... }:
{
  ideamaker = pkgs.callPackage ./ideamaker { };
  pixelflasher = pkgs.callPackage ./pixelflasher { };
}
