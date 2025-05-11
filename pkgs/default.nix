{ pkgs, ... }:
{
  fusion360 = pkgs.callPackage ./fusion360 { };
  ideamaker = pkgs.callPackage ./ideamaker { };
}
