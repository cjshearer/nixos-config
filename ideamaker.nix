{ stdenv
, autoPatchelfHook
, curl
, dpkg
, e2fsprogs
, fetchurl
, lib
, libcork
, libGLU
, lz4
, makeDesktopItem
, nlopt
, opencascade-occt
, openssl_1_1
, openvdb
  # , qtbase
, quazip
, tbb
, wrapQtAppsHook
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ideamaker";
  version = "5.0.5";
  buildNumber = "8310";

  src = fetchurl {
    url = "https://download.raise3d.com/${finalAttrs.pname}/release/${finalAttrs.version}/ideaMaker_${finalAttrs.version}.${finalAttrs.buildNumber}-ubuntu_amd64.deb";
    sha256 = "sha256-qPYfpZfBmiGz4+4OsBTN3Rulb/AjjS4vIuzXLAZChfQ=";
  };

  # Fixes runtime error:
  # no version information available
  # curl-with-versioned-symbols = curl.overrideAttrs (old: {
  #   configureFlags = old.configureFlags ++ [ "--enable-versioned-symbols" ];
  # });

  # myQtbase = qtbase.override {
  #   withGtk3 = true;
  # };

  # Fix for sized delete operator (_ZdlPvm) missing in libQt5Core.so:
  # Without -D_GLIBCXX_USE_CXX11_ABI=1, _ZdlPvm is only defined in libstdc++.so,
  # causing undefined symbol errors in Qt 5.15.0. This flag enables C++11 ABI,
  # which includes _ZdlPvm, and ensures it's linked into libQt5Core.so.
  # 
  # Want:
  # objdump -T original/ideamaker/libs/libQt5Core.so.5.15.2 | grep _ZdlPvm
  # 00000000003cbae0 g    DF .text  0000000000000005  Qt_5        _ZdlPvm
  #
  # Got:
  # objdump -T /nix/store/...-qtbase-5.15.12/lib/libQt5Core.so.5.15.12 | grep _ZdlPvm
  # 0000000000000000      DF *UND*  0000000000000000 (CXXABI_1.3.9) _ZdlPvm
  # 
  # References:
  # https://stackoverflow.com/questions/53022608/application-crashes-with-symbol-zdlpvm-version-qt-5-not-defined-in-file-libqt
  # https://community.intel.com/t5/Intel-C-Compiler/What-are-the-flags-so-that-the-sized-delete-operator-ZdlPvm-is/m-p/1355293
  # https://forum.qt.io/post/656903
  # https://github.com/Theano/Theano/issues/5141
  # myQtbase = qtbase.overrideAttrs (old: {
  #   configureFlags = old.configureFlags ++ [
  #     # "QMAKE_CXXFLAGS+=-D_GLIBCXX_USE_CXX11_ABI=1"
  #     # results in:
  #     # objdump -T /nix/store/12ghsdc4317xjsr5fxjni34jqzsayall-qtbase-5.15.12/lib/libQt5Core.so.5 | grep _ZdlPvm
  #     # 0000000000000000      DF *UND*  0000000000000000 (CXXABI_1.3.9) _ZdlPvm

  #     # "-D_GLIBCXX_USE_CXX11_ABI=1"
  #     # results in:
  #     # objdump -T /nix/store/...-qtbase-5.15.12/lib/libQt5Core.so | grep _ZdlPvm
  #     # 0000000000000000      DF *UND*  0000000000000000 (CXXABI_1.3.9) _ZdlPvm

  #     # "QMAKE_CXXFLAGS+=-D_GLIBCXX_USE_CXX11_ABI=0"
  #     # results in:
  #     # objdump -T /nix/store/c8yrlbsv87hp7qf85z5wgzjs7fj26zwp-qtbase-5.15.12/lib/libQt5Core.so.5.15.12 | grep _ZdlPvm
  #     # 0000000000000000      DF *UND*  0000000000000000 (CXXABI_1.3.9) _ZdlPvm

  #     # "QMAKE_CXXFLAGS+=-fno-sized-deallocation"
  #     # results in:
  #     # objdump -T /nix/store/5d73558bwnxvcb2m8v8ssngzfphhxls1-qtbase-5.15.12/lib/libQt5Core.so.5.15.12 | grep _ZdlPvm
  #     # <empty output>

  #     # "--enable-versioned-symbols" invalid flag
  #   ];
  # });

  # CXXFLAGS = [
  #   "-std=c++17"
  # ];

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    wrapQtAppsHook
  ];
  buildInputs = [
    curl
    # ^supplies libcurl.so.4, wanted by ideamaker
    libcork
    # ^supplies:
    # libcork.so.1 wanted by libIMCoreMesh.so.1.0.0
    libGLU
    # ^supplies:
    # libGLU.so.1 wanted by ideamaker and libIMCoreRenderTool.so.1.0.0
    lz4
    # ^supplies:
    # liblz4.so.1 wanted by libblosc.so.1.14.2
    nlopt
    # ^supplies:
    # libnlopt.so.0 wanted by libIMCoreSlice.so.1.0.0
    opencascade-occt
    # ^supplies:
    # libTKLCAF.so.7 wanted by libIMCoreFileFormat.so.1.0.0
    # libTKMath.so.7 wanted libIMCoreFileFormat.so.1.0.0
    # libTKMesh.so.7 wanted libIMCoreFileFormat.so.1.0.0
    # libTKTopAlgo.so.7 wanted libIMCoreFileFormat.so.1.0.0
    # libTKXCAF.so.7 wanted libIMCoreFileFormat.so.1.0.0
    # libTKXDESTEP.so.7 wanted libIMCoreFileFormat.so.1.0.0
    # libTKXDEIGES.so.7 wanted libIMCoreFileFormat.so.1.0.0
    # libTKXSBase.so.7 wanted libIMCoreFileFormat.so.1.0.0
    openssl_1_1
    # ^supplies:
    # libcrypto.so.1.1, wanted by ideamaker
    # qt5.full
    # ^supplies:
    # libQt5Network.so.5 wanted by ideamaker
    # libQt5Widgets.so.5 wanted by ideamaker
    # libQt5Gui.so.5 wanted by ideamaker, libIMCoreFileFormat.so.1.0.0, libIMCoreMesh.so.1.0.0, libIMCoreProfileTool.so.1.0.0, libIMCoreRenderTool.so.1.0.0, libIMCoreSlice.so.1.0.0, libIMCoreUtility.so.1.0.0
    # libQt5Core.so.5 wanted by ideamaker, libIMCoreFileFormat.so.1.0.0, libpoly2tri.so.1.0.0, libIMCoreMath.so.1.0.0, libIMCoreMesh.so.1.0.0, libquazip.so.1.0.0, libIMCoreProfileTool.so.1.0.0, libIMCoreRenderTool.so.1.0.0, libIMCoreSlice.so.1.0.0, libIMCoreUtility.so.1.0.0, libIMPlugin1.so.1.0.0
    quazip
    # ^supplies:
    # libquazip1-qt5.so (originally libquazip.so.1), wanted by libIMCoreFileFormat.so.1.0.0,libIMCoreProfileTool.so.1.0.0, libIMCoreUtility.so.1.0.0
    tbb
    # ^supplies: libtbb.so.2 wanted by ideamaker, libIMCoreFileFormat.so.1.0.0,libIMCoreMesh.so.1.0.0, libopenvdb.so.5.0.0, libIMCoreRenderTool.so.1.0.0, libIMCoreSlice.so.1.0.0, libIMCoreUtility.so.1.0.0, libIMPlugin1.so.1.0.0
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -D usr/lib/x86_64-linux-gnu/ideamaker/ideamaker $out/bin/${finalAttrs.pname}

    objcopy --redefine-sym _ZdlPvm@@Qt_5=_ZdlPvm@CXXABI_1.3.9 $out/bin/${finalAttrs.pname}

    # Proprietary libs:
    mkdir $out/lib
    cp -a usr/lib/x86_64-linux-gnu/ideamaker/libIM* $out/lib
    # objcopy --redefine-sym _ZdlPvm@@Qt_5=_ZdlPvm@CXXABI_1.3.9 $out/lib/*

    # cp -a usr/lib/x86_64-linux-gnu/ideamaker/lib{Qt5,icu*}* $out/lib
    # cp -a usr/lib/x86_64-linux-gnu/ideamaker/plugins $out/lib

    # libIMCoreMath.so.1.0.0 wants libpoly2tri.so.1, but libsForQt5.poly2tri-c only has libpoly2tri-c-0.1.so (is it a drop in replacement?), so we copy it
    cp -a usr/lib/x86_64-linux-gnu/ideamaker/libpoly2tri.so* $out/lib
    objcopy --redefine-sym _ZdlPvm@@Qt_5=_ZdlPvm@CXXABI_1.3.9 $out/lib/libpoly2tri.so.1.0.0
  
    # libIMCoreUtility.so.1.0.0, libIMCoreProfileTool.so.1.0.0, and
    # libIMCoreFileFormat.so.1.0.0 wants libquazip.so.1, but libsForQt5.quazip 
    # only has libquazip1-qt5.so.1.4.0, so we copy it
    # cp -a usr/lib/x86_64-linux-gnu/ideamaker/libquazip.so* $out/lib
    patchelf --replace-needed libquazip.so.1 libquazip1-qt5.so $out/lib/*

    # libIMCoreMesh.so.1.0.0 wants libopenvdb.so.5.0, but libsForQt5.openvdb
    # only has libopenvdb.so.10.0, so we copy it, as well as its transitive  
    # dependencies:
    cp -a usr/lib/x86_64-linux-gnu/ideamaker/{libopenvdb,libHalf,libblosc,liblog4cplus,libboost_iostreams,libsnappy}* $out/lib
    # TODO: check if we can just patchelf --replace-needed

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
