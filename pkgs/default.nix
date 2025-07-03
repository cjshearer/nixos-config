{ pkgs, ... }: {
  prepare-nixos-disk = pkgs.callPackage ./prepare-nixos-disk { };
  ideamaker = pkgs.callPackage ./ideamaker { };
}
