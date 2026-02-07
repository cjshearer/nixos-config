{
  pkgs,
  lib,
  stdenv,
  fetchurl,
  dpkg,
  zlib,
  openssl,
  libselinux,
  tzdata,
  dmidecode,
  cryptsetup,
  iptables,
  libcap,
  udev,
  ...
}:

let
  duoclient = stdenv.mkDerivation rec {
    pname = "duoclient";
    version = "2.0.0";

    src = fetchurl {
      url = "https://desktop.pkg.duosecurity.com/duo-desktop-latest.amd64.deb";
      hash = "sha256-XpW/qg9mMzW9hd049f0l60epbwH5ob2W5uY6wk/GObk=";
    };

    nativeBuildInputs = [
      dpkg
    ];

    dontBuild = true;

    installPhase = ''
      mkdir $out
      cp -R opt $out/opt
    '';

    meta = with lib; {
      description = "Cisco duo desktop client";
      homepage = "https://duo.cisco.com";
      maintainers = [
        {
          name = "Martin Ertsås";
          email = "mertsas@cisco.com";
        }
      ];
      platforms = [ "x86_64-linux" ];
    };
  };
  duokeys = stdenv.mkDerivation {
    name = "duokeys";
    version = "1.0.0";

    src = ./.;

    buildPhase = ''
      mkdir https
      chmod 700 https
      ${pkgs.openssl}/bin/openssl req \
        -newkey rsa:2048 -keyout https/duo-desktop.key \
        -x509 \
        -days 1095 \
        -nodes \
        -config ${duoclient}/opt/duo/duo-desktop/localhost.cfg \
        -out https/duo-desktop.crt
      ${pkgs.openssl}/bin/openssl pkcs12 -inkey https/duo-desktop.key -in https/duo-desktop.crt -export -out https/duo-desktop.pfx -passout pass:
      rm -fr https/duo-desktop.key
      chmod 600 https/duo-desktop.pfx
      chmod 644 https/duo-desktop.crt
    '';

    installPhase = ''
      mkdir -p $out/etc/opt/duo/duo-desktop
      cp -r https $out/etc/opt/duo/duo-desktop/https

      mkdir -p $out/usr/local/share/ca-certificates/
      cp https/duo-desktop.crt $out/usr/local/share/ca-certificates/duo-desktop.crt
    '';
  };
  fhs = pkgs.buildFHSEnv {
    name = "fhs";

    targetPkgs =
      pkgs:
      (with pkgs; [
        icu
        zlib
        openssl
        libselinux
        tzdata
        stdenv.cc.cc.lib
        duokeys
        dmidecode
        cryptsetup
        iptables
        libcap
        udev
      ]);

    runScript = "${pkgs.bash}/bin/bash";
  };
in
pkgs.writeShellScriptBin "duo-desktop" ''
  ${fhs}/bin/fhs -c ${duoclient}/opt/duo/duo-desktop/duo-desktop
''
