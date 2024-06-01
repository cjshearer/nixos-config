{ pkgs, ... }:
let
  pyinstaller = pkgs.callPackage ./pyinstaller { };
in
{
  hyprec = pkgs.callPackage ./hyprec { };
  pixelflasher = pkgs.callPackage ./pixelflasher { inherit pyinstaller; };
  ytmdesktop = pkgs.callPackage ./ytmdesktop { };
}
