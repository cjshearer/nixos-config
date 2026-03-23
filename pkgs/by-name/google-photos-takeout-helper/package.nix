{
  lib,
  fetchFromGitHub,
  buildDartApplication,
}:
buildDartApplication rec {
  pname = "google-photos-takeout-helper";
  version = "5.1.0";

  src = fetchFromGitHub {
    owner = "Xentraxx";
    repo = "GooglePhotosTakeoutHelper";
    rev = "v${version}";
    hash = "sha256-JjZsQfD3u7gHWTOD/1KV+3Aq2fak/cNs2OwRYm0AON0=";
  };

  dartEntryPoints = {
    "bin/gpth" = "bin/gpth.dart";
  };

  autoPubspecLock = src + "/pubspec.lock";

  meta = {
    description = "Organizes and cleans up photos retrieved through Google Takeout";
    homepage = "https://github.com/Xentraxx/GooglePhotosTakeoutHelper";
    changelog = "https://github.com/Xentraxx/GooglePhotosTakeoutHelper/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    mainProgram = "gpth";
    maintainers = [ ];
  };
}
