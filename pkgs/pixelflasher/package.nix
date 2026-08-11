{
  pixelflasher,
  fetchFromGitHub,
  ...
}:
let
  version = "9.1.5.0";
in
pixelflasher.overrideAttrs (old: {
  inherit version;
  src = fetchFromGitHub {
    owner = "badabing2005";
    repo = "PixelFlasher";
    tag = "v${version}";
    hash = "sha256-SAo6od26CULyoxufSpMbkLPm+qx+XNak3irQLep5Ubw=";
  };
})
