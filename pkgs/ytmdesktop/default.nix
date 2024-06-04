# Submitted to nixpkgs: https://github.com/NixOS/nixpkgs/pull/317309
# Please 👍 the PR if you want it merged
{ lib
, asar
, binutils
, commandLineArgs ? ""
, electron_30
, fetchurl
, makeDesktopItem
, makeWrapper
, stdenvNoCC
, zstd
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ytmdesktop";
  version = "2.0.5";
  meta = {
    changelog = "${finalAttrs.meta.downloadPage}/tag/v${finalAttrs.version}";
    description = "A Desktop App for YouTube Music";
    downloadPage = "https://github.com/ytmdesktop/ytmdesktop/releases";
    homepage = "https://ytmdesktop.app/";
    license = lib.licenses.gpl3Only;
    mainProgram = finalAttrs.pname;
    maintainers = [ lib.maintainers.cjshearer ];
    platforms = lib.platforms.linux;
  };

  desktopItem = makeDesktopItem {
    desktopName = "Youtube Music Desktop App";
    exec = finalAttrs.pname;
    icon = finalAttrs.pname;
    name = finalAttrs.pname;
    genericName = finalAttrs.meta.description;
    mimeTypes = [ "x-scheme-handler/ytmd" ];
    categories = [
      "AudioVideo"
      "Audio"
    ];
    startupNotify = true;
  };

  nativeBuildInputs = [
    asar
    binutils
    electron_30
    makeWrapper
    zstd
  ];

  src = fetchurl {
    url = "${finalAttrs.meta.downloadPage}/download/v${finalAttrs.version}/youtube-music-desktop-app_${finalAttrs.version}_amd64.deb";
    hash = "sha256-0j8HVmkFyTk/Jpq9dfQXFxd2jnLwzfEiqCgRHuc5g9o=";
  };

  unpackPhase = ''
    ar x $src data.tar.zst
    tar xf data.tar.zst
  '';

  patchPhase = ''
    pushd usr/lib/youtube-music-desktop-app

    asar extract resources/app.asar patched-asar

    # workaround for https://github.com/electron/electron/issues/31121
    sed -i "s#process\.resourcesPath#'$out/lib/resources'#g" \
      patched-asar/.webpack/main/index.js

    asar pack patched-asar resources/app.asar

    popd
  '';

  installPhase = ''
    pushd usr/lib/youtube-music-desktop-app

    mkdir -p $out/lib
    cp -r {locales,resources{,.pak}} $out/lib

    makeWrapper ${lib.getExe electron_30} $out/bin/${finalAttrs.pname} \
      --add-flags $out/lib/resources/app.asar \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
      --add-flags ${lib.escapeShellArg commandLineArgs}

    popd

    mkdir -p $out/share/pixmaps
    cp usr/share/pixmaps/youtube-music-desktop-app.png $out/share/pixmaps/${finalAttrs.pname}.png

    ln -s ${finalAttrs.desktopItem}/share/applications $out/share/
  '';
})
