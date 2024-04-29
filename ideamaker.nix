{ stdenv
, autoPatchelfHook
, dpkg
, fetchurl
, lib
, libcork
, libGLU
, makeDesktopItem
, qtbase
, qtserialport
, quazip
, wrapQtAppsHook
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ideamaker";
  version = "4.3.3";
  buildNumber = "6560";
  src = fetchurl {
    url = "https://download.raise3d.com/${finalAttrs.pname}/release/${finalAttrs.version}/ideaMaker_${finalAttrs.version}.${finalAttrs.buildNumber}-ubuntu_amd64.deb";
    sha256 = "sha256-aTVWCTgnVKD16uhJUVz0vR7KPGJqCVj0xoL53Qi3IKM=";
  };
  # curl 7.47.0 is needed, as the app segfaults on launch in 7.47.1 and beyond,
  # (or atleast 7.50.3, 7.62, 7.79.1, and 8.7.1)
  latest-curl-compatible-with-libcurl-so-4-3-0 = (import
    (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/5ed9176c52e4ceed2755a19b3e8357a0772de8ff.tar.gz";
    })
    { }).curl;

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    wrapQtAppsHook
  ];
  buildInputs = [
    finalAttrs.latest-curl-compatible-with-libcurl-so-4-3-0
    libcork
    libGLU
    qtbase
    qtserialport
    quazip
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -D usr/lib/x86_64-linux-gnu/ideamaker/ideamaker $out/bin/${finalAttrs.pname}
    
    patchelf --replace-needed libquazip.so.1 libquazip1-qt5.so $out/bin/${finalAttrs.pname}

    install -D usr/share/ideamaker/icons/ideamaker-icon.png $out/share/pixmaps/${finalAttrs.pname}.png
    ln -s ${finalAttrs.desktopItem}/share/applications $out/share/

    runHook postInstall
  '';

  desktopItem = makeDesktopItem {
    name = finalAttrs.pname;
    exec = finalAttrs.pname;
    icon = finalAttrs.pname;
    desktopName = "Ideamaker";
    genericName = finalAttrs.meta.description;
    categories = [ "Utility" "Viewer" "Engineering" ];
    mimeTypes = [ "application/sla" ];
  };

  meta = with lib; {
    homepage = "https://www.raise3d.com/ideamaker/";
    description = "Raise3D's 3D slicer software";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ ];
  };
})
