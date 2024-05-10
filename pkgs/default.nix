pkgs: {
  hyprec = pkgs.callPackage ./hyprec { };
  ideamaker = pkgs.unstable.libsForQt5.callPackage ./ideamaker { };
}
