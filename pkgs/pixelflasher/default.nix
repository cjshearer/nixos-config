{ lib
, stdenv
, android-tools
, cacert
, fetchFromGitHub
, makeDesktopItem
, makeWrapper
, python311
, substituteAll
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "PixelFlasher";
  version = "7.3.2.0";

  src = fetchFromGitHub {
    owner = "badabing2005";
    repo = "PixelFlasher";
    rev = "v${finalAttrs.version}";
    hash = "sha256-U7fZ3Tx5TjYTus6IwOW9gAejY6jn7weGwcnyfS7IGSc=";
  };

  phases = [
    "unpackPhase"
    "buildPhase"
    "installPhase"
    "fixupPhase"
  ];

  buildPhase = ''
    # we set the default android-tools path for convenience
    sed -i 's#platform_tools_path = None#platform_tools_path = "${android-tools}\/bin"#' config.py

    sh build.sh
  '';

  installPhase = ''
    install -D dist/${finalAttrs.pname} $out/bin/${finalAttrs.pname}

    install -D images/icon-dark-256.png $out/share/pixmaps/${finalAttrs.pname}.png

    ln -s ${finalAttrs.desktopItem}/share/applications $out/share/
  '';

  fixupPhase = ''
    wrapProgram $out/bin/${finalAttrs.pname} \
      --set REQUESTS_CA_BUNDLE "${cacert}/etc/ssl/certs/ca-bundle.crt"
  '';

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = with python311.pkgs; [
    android-tools
    attrdict
    beautifulsoup4
    bsdiff4
    chardet
    cryptography
    darkdetect
    httplib2
    json5
    lz4
    markdown
    platformdirs
    protobuf
    psutil
    pyinstaller
    pyperclip
    requests
    rsa
    six
    wxpython
  ];

  desktopItem = makeDesktopItem {
    name = finalAttrs.pname;
    exec = finalAttrs.pname;
    icon = finalAttrs.pname;
    desktopName = finalAttrs.pname;
    categories = [ "Utility" ];
    genericName = finalAttrs.meta.description;
    noDisplay = false;
    startupNotify = true;
    terminal = false;
    type = "Application";
  };

  meta = {
    description = "Pixel™ phone flashing GUI utility with features";
    homepage = "https://github.com/badabing2005/PixelFlasher";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "PixelFlasher";
    platforms = lib.platforms.all;
  };
})
