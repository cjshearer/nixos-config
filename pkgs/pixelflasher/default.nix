{
  lib,
  android-tools,
  cacert,
  fetchFromGitHub,
  makeDesktopItem,
  makeWrapper,
  python311,
  stdenv,
  substituteAll,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "pixelflasher";
  version = "7.6.0.0";

  desktopItem = makeDesktopItem {
    desktopName = "PixelFlasher";
    name = "pixelflasher";
    exec = "pixelflasher";
    icon = "pixelflasher";
    categories = [ "Utility" ];
    genericName = finalAttrs.meta.description;
    noDisplay = false;
    startupNotify = true;
    terminal = false;
    type = "Application";
  };

  src = fetchFromGitHub {
    owner = "badabing2005";
    repo = "PixelFlasher";
    rev = "v${finalAttrs.version}";
    hash = "sha256-5LKvLb7QiHZl80+T3+IcuhLyySkVQJl4E6ItJ8Cmdsw=";
  };

  buildPhase = ''
    # we set the default android-tools path for convenience
    substituteInPlace config.py --replace-fail \
      "platform_tools_path = None" "platform_tools_path = '${lib.getBin android-tools}/bin'"

    sh build.sh
  '';

  installPhase = ''
    install -D dist/PixelFlasher $out/bin/pixelflasher
    install -D images/icon-dark-256.png $out/share/pixmaps/pixelflasher.png

    ln -s ${finalAttrs.desktopItem}/share/applications $out/share/
  '';

  fixupPhase = ''
    wrapProgram $out/bin/pixelflasher \
      --set REQUESTS_CA_BUNDLE "${cacert}/etc/ssl/certs/ca-bundle.crt" \
      --set PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION python
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

  meta = {
    description = "Pixel™ phone flashing GUI utility with features";
    homepage = "https://github.com/badabing2005/PixelFlasher";
    license = lib.licenses.gpl3Only;
    maintainers = [ lib.maintainers.cjshearer ];
    mainProgram = "pixelflasher";
    platforms = lib.platforms.all;
  };
})
