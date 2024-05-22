{ pkgs ? import <nixpkgs> { } }:
let
  pyinstaller = pkgs.callPackage ./pyinstaller { };
in
{
  hyprec = pkgs.callPackage ./hyprec { };
  ideamaker = pkgs.libsForQt5.callPackage ./ideamaker { };
  pixelflasher = pkgs.callPackage ./pixelflasher { inherit pyinstaller; };
}
