{ stdenv
, autoPatchelfHook
, curl
, dpkg
, fetchurl
, lib
, libcork
, libGLU
, makeDesktopItem
, qt5
}:
stdenv.mkDerivation rec {
  pname = "ideamaker";
  version = "4.0.1";
  versionMinor = "4802";

  src = fetchurl {
    url = "https://download.raise3d.com/${pname}/release/${version}/ideaMaker_${version}.${versionMinor}-ubuntu_amd64.deb";
    sha256 = "sha256-veHEaKmV/PdebyvH6L5vUV4btCTP2SJhN9+qkyhYSOc=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    qt5.wrapQtAppsHook
  ];
  buildInputs = [
    curl
    libcork
    libGLU
    qt5.qtbase
    qt5.qtserialport
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib,share/pixmaps}
    cp usr/lib/x86_64-linux-gnu/ideamaker/ideamaker $out/bin
    cp usr/lib/x86_64-linux-gnu/ideamaker/libquazip.so.1 $out/lib
    ln -s "${desktopItem}/share/applications" $out/share/
    cp usr/share/ideamaker/icons/ideamaker-icon.png $out/share/pixmaps/${pname}.png

    runHook postInstall
  '';

  desktopItem = makeDesktopItem {
    name = pname;
    exec = pname;
    icon = pname;
    desktopName = "Ideamaker";
    genericName = meta.description;
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
}
