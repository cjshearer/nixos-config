{ stdenv
, autoPatchelfHook
, curl
, dpkg
, fetchurl
, fetchzip
, lib
, libcork
, libGLU
, makeDesktopItem
, openssl_1_1
, qtbase
, qtserialport
, quazip
, shared-mime-info
, system
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

  openssl_1_0_1 = openssl_1_1.overrideAttrs (previous: {
    version = "1.0.1u";
    src = fetchurl {
      url = "https://www.openssl.org/source/openssl-1.0.1u.tar.gz";
      sha256 = "0fb7y9pwbd76pgzd7xzqfrzibmc0vf03sl07f34z5dhm2b5b84j3";
    };
    patches = [ ];
    withDocs = false;
    outputs = lib.lists.remove "doc" previous.outputs;
    meta.knownVulnerabilities = [
      "OpenSSL 1.0.1 is reaching its end of life on 2016/12/31 https://endoflife.software/applications/security-libraries/openssl"
    ];
  });

  # we need curl 7.47.0, as the app segfaults on launch in 7.47.1 and beyond
  # (tested with 7.47.1, 7.50.3, 7.62, 7.79.1, and 8.7.1)
  curl_7_47 = (curl.override {
    gnutlsSupport = true;
    gssSupport = false;
    http2Support = false;
    opensslSupport = false; # suppresses flags unsupported by curl 7.47.0
    pslSupport = false;
    scpSupport = false;
  }).overrideAttrs (previous: {
    version = "7.47.0";
    src = fetchzip {
      url = "https://curl.se/download/curl-7.47.0.tar.lzma";
      sha256 = "sha256-XlZk1nJbSmiQp7jMSE2QRCY4C9w2us8BgosBSzlD4dE=";
    };
    configureFlags = previous.configureFlags ++ [
      "--with-ca-bundle=/etc/ssl/certs/ca-certificates.crt"
      "--with-ssl=${lib.getLib finalAttrs.openssl_1_0_1}"
    ];
  });

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    shared-mime-info
    wrapQtAppsHook
  ];

  buildInputs = [
    finalAttrs.curl_7_47
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

    install -D usr/lib/x86_64-linux-gnu/ideamaker/ideamaker \
      $out/bin/${finalAttrs.pname}
    
    patchelf --replace-needed libquazip.so.1 libquazip1-qt5.so \
      $out/bin/${finalAttrs.pname}

    mimetypeDir=$out/share/icons/hicolor/128x128/mimetypes
    mkdir -p ''$mimetypeDir
    for file in usr/share/ideamaker/icons/*.ico; do
      mv $file ''$mimetypeDir/''$(basename ''${file%.ico}).png
    done
    install -D ${./mimetypes.xml} \
      $out/share/mime/packages/${finalAttrs.pname}.xml

    install -D usr/share/ideamaker/icons/ideamaker-icon.png \
      $out/share/pixmaps/${finalAttrs.pname}.png

    ln -s ${finalAttrs.desktopItem}/share/applications $out/share/

    runHook postInstall
  '';

  desktopItem = makeDesktopItem {
    name = finalAttrs.pname;
    exec = finalAttrs.pname;
    icon = finalAttrs.pname;
    desktopName = "Ideamaker";
    comment = "ideaMaker - www.raise3d.com";
    categories = [ "Qt" "Utility" "3DGraphics" "Viewer" "Engineering" ];
    genericName = finalAttrs.meta.description;
    mimeTypes = [
      "application/x-ideamaker"
      "model/3mf"
      "model/obj"
      "model/stl"
      "text/x.gcode"
    ];
    noDisplay = false;
    startupNotify = true;
    terminal = false;
    type = "Application";
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
