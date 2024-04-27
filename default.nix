# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = { }; overlays = [ ]; };
in
{
  ideamaker = pkgs.libsForQt5.callPackage ./ideamaker.nix {
    curl = pkgs.curl.overrideAttrs (old: {
      configureFlags = old.configureFlags ++ [ "--enable-versioned-symbols" ];
    });
    # qtbase = pkgs.libsForQt5.qtbase.overrideAttrs
    #   (old: {
    #     configureFlags = pkgs.lib.lists.remove "-verbose" old.configureFlags ++ [
    #       # "QMAKE_CCX=${pkgs.gcc6.outPath}/bin/g++"
    #       # "QMAKE_CC=${pkgs.gcc6.outPath}/bin/gcc"
    #       # "-D_GLIBCXX_USE_CXX11_ABI=1"
    #       # "-developer-build"
    #       # "-static"
    #       # "-platform linux-g++-5"
    #       # "-DQT_NO_VERSION_TAGGING"
    #     ];

    #     # qmake doesn't rebuild with c++14 unless we change some other flag, 
    #     # for some stupid (probably cache) reason
    #     # configureFlags = pkgs.lib.lists.remove "-verbose" old.configureFlags ++ [ "QMAKE_CXXFLAGS+=-std=c++14" ];
    #     # configureFlags = [
    #     #   "-plugindir"
    #     #   "\${out}/\${qtPluginPrefix}"
    #     #   "-qmldir"
    #     #   "\${out}/\${qtQmlPrefix}"
    #     #   "-docdir"
    #     #   "\${out}/\${qtDocPrefix}"
    #     #   # "-verbose"
    #     #   "-confirm-license"
    #     #   "-opensource"
    #     #   "-release"
    #     #   "-shared"
    #     #   "-accessibility"
    #     #   "-optimized-qmake"
    #     #   "-no-strip"
    #     #   "-system-proxies"
    #     #   "-pkg-config"
    #     #   "-gui"
    #     #   "-widgets"
    #     #   "-opengl"
    #     #   "desktop"
    #     #   "-icu"
    #     #   "-L"
    #     #   "/nix/store/dpwk00dz15y9c0jx2zqa0xrwpjv3nnkl-icu4c-73.2/lib"
    #     #   "-I"
    #     #   "/nix/store/bw36c93myddknva88m6icspnx4jhc02m-icu4c-73.2-dev/include"
    #     #   "-pch"
    #     #   "-sse2"
    #     #   "-no-sse3"
    #     #   "-no-ssse3"
    #     #   "-no-sse4.1"
    #     #   "-no-sse4.2"
    #     #   "-no-avx"
    #     #   "-no-avx2"
    #     #   "-no-mips_dsp"
    #     #   "-no-mips_dspr2"
    #     #   "-system-zlib"
    #     #   "-L"
    #     #   "/nix/store/rrhw8p4hdrbh3pq7p2hlc1z2ixxzcxcb-zlib-1.3.1/lib"
    #     #   "-I"
    #     #   "/nix/store/vi5lphqwg9cj7xkaggvw5n0wqsmwdlq5-zlib-1.3.1-dev/include"
    #     #   "-system-libjpeg"
    #     #   "-L"
    #     #   "/nix/store/3xryfb3l0kvxkdf1c8g9x0wcn5i7y0g4-libjpeg-turbo-3.0.2/lib"
    #     #   "-I"
    #     #   "/nix/store/z4rjfh54kmj84h524pja9lj9dkl128kz-libjpeg-turbo-3.0.2-dev/include"
    #     #   "-system-harfbuzz"
    #     #   "-L"
    #     #   "/nix/store/cv50gzcn2jli6dn56lhkizi93px89zhj-harfbuzz-8.4.0/lib"
    #     #   "-I"
    #     #   "/nix/store/h2a0hvrmfzfxfggyfjgwnl3lmdhynm71-harfbuzz-8.4.0-dev/include"
    #     #   "-system-pcre"
    #     #   "-openssl-linked"
    #     #   "-L"
    #     #   "/nix/store/9xgpmwqw0881kxa9sl498qfmzy7z2ndn-openssl-3.0.13/lib"
    #     #   "-I"
    #     #   "/nix/store/aqaxrq9jyrjwsnsly12b2xkqmakcsawb-openssl-3.0.13-dev/include"
    #     #   "-system-sqlite"
    #     #   "-plugin-sql-mysql"
    #     #   "-plugin-sql-psql"
    #     #   "-make"
    #     #   "libs"
    #     #   "-make"
    #     #   "tools"
    #     #   "-nomake"
    #     #   "examples"
    #     #   "-nomake"
    #     #   "tests"
    #     #   "-rpath"
    #     #   "-xcb"
    #     #   "-qpa"
    #     #   "xcb"
    #     #   "-L"
    #     #   "/nix/store/x5wm1j2b9l9najwwpikh9wdykrldnspk-libX11-1.8.7/lib"
    #     #   "-I"
    #     #   "/nix/store/x5wm1j2b9l9najwwpikh9wdykrldnspk-libX11-1.8.7/include"
    #     #   "-L"
    #     #   "/nix/store/bqjivl23gjxrd9xqlnaj2wmb91lwk644-libXext-1.3.6/lib"
    #     #   "-I"
    #     #   "/nix/store/bqjivl23gjxrd9xqlnaj2wmb91lwk644-libXext-1.3.6/include"
    #     #   "-L"
    #     #   "/nix/store/zd6s0gyf3amm8rrak8gywn26v1rfv2hf-libXrender-0.9.11/lib"
    #     #   "-I"
    #     #   "/nix/store/zd6s0gyf3amm8rrak8gywn26v1rfv2hf-libXrender-0.9.11/include"
    #     #   "-libinput"
    #     #   "-cups"
    #     #   "-dbus-linked"
    #     #   "-glib"
    #     #   "-system-libpng"
    #     #   "-gtk"
    #     #   "-inotify"
    #     #   "-L"
    #     #   "/nix/store/crm5p4wvdfwg75r39784225aqhxi3xpx-cups-2.4.7-lib/lib"
    #     #   "-I"
    #     #   "/nix/store/jh4ddz1q5cfmik1cnr0al6fkv5gc9l3p-cups-2.4.7-dev/include"
    #     #   "-L"
    #     #   "/nix/store/appf34j78kmm7kabhg5bw9fj2mcnvjj6-mariadb-connector-c-3.3.5/lib"
    #     #   "-I"
    #     #   "/nix/store/appf34j78kmm7kabhg5bw9fj2mcnvjj6-mariadb-connector-c-3.3.5/include"
    #     #   "-translationdir"
    #     #   "/nix/store/5n30k22k8f451grwcmca3fc99lsi85l5-qttranslations-5.15.12/translations"
    #     #   "QMAKE_CXXFLAGS+=-std=c++17"
    #     # ];
    #   });


    # configure flags: -prefix /nix/store/3p1vzx851y02grn5fzmjf63qkqsrgsgq-qtbase-5.15.12 -plugindir \$\(out\)/\$\(qtPluginPrefix\) -qmldir \$\(out\)/\$\(qtQmlPrefix\) -docdir \$\(out\)/\$\(qtDocPrefix\) -verbose -confirm-license -opensource -shared -accessibility -optimized-qmake -no-strip -system-proxies -pkg-config -gui -widgets -opengl desktop -icu -L /nix/store/dpwk00dz15y9c0jx2zqa0xrwpjv3nnkl-icu4c-73.2/lib -I /nix/store/bw36c93myddknva88m6icspnx4jhc02m-icu4c-73.2-dev/include -pch -sse2 -no-sse3 -no-ssse3 -no-sse4.1 -no-sse4.2 -no-avx -no-avx2 -no-mips_dsp -no-mips_dspr2 -system-zlib -L /nix/store/rrhw8p4hdrbh3pq7p2hlc1z2ixxzcxcb-zlib-1.3.1/lib -I /nix/store/vi5lphqwg9cj7xkaggvw5n0wqsmwdlq5-zlib-1.3.1-dev/include -system-libjpeg -L /nix/store/3xryfb3l0kvxkdf1c8g9x0wcn5i7y0g4-libjpeg-turbo-3.0.2/lib -I /nix/store/z4rjfh54kmj84h524pja9lj9dkl128kz-libjpeg-turbo-3.0.2-dev/include -system-harfbuzz -L /nix/store/cv50gzcn2jli6dn56lhkizi93px89zhj-harfbuzz-8.4.0/lib -I /nix/store/h2a0hvrmfzfxfggyfjgwnl3lmdhynm71-harfbuzz-8.4.0-dev/include -system-pcre -openssl-linked -L /nix/store/9xgpmwqw0881kxa9sl498qfmzy7z2ndn-openssl-3.0.13/lib -I /nix/store/aqaxrq9jyrjwsnsly12b2xkqmakcsawb-openssl-3.0.13-dev/include -system-sqlite -plugin-sql-mysql -plugin-sql-psql -make libs -make tools -nomake examples -nomake tests -rpath -xcb -qpa xcb -L /nix/store/x5wm1j2b9l9najwwpikh9wdykrldnspk-libX11-1.8.7/lib -I /nix/store/x5wm1j2b9l9najwwpikh9wdykrldnspk-libX11-1.8.7/include -L /nix/store/bqjivl23gjxrd9xqlnaj2wmb91lwk644-libXext-1.3.6/lib -I /nix/store/bqjivl23gjxrd9xqlnaj2wmb91lwk644-libXext-1.3.6/include -L /nix/store/zd6s0gyf3amm8rrak8gywn26v1rfv2hf-libXrender-0.9.11/lib -I /nix/store/zd6s0gyf3amm8rrak8gywn26v1rfv2hf-libXrender-0.9.11/include -libinput -cups -dbus-linked -glib -system-libpng -gtk -inotify -L /nix/store/crm5p4wvdfwg75r39784225aqhxi3xpx-cups-2.4.7-lib/lib -I /nix/store/jh4ddz1q5cfmik1cnr0al6fkv5gc9l3p-cups-2.4.7-dev/include -L /nix/store/appf34j78kmm7kabhg5bw9fj2mcnvjj6-mariadb-connector-c-3.3.5/lib -I /nix/store/appf34j78kmm7kabhg5bw9fj2mcnvjj6-mariadb-connector-c-3.3.5/include -translationdir /nix/store/5n30k22k8f451grwcmca3fc99lsi85l5-qttranslations-5.15.12/translations QMAKE_CXXFLAGS+=-std=c++14
    # Creating qmake...
    # g++ -c -o main.o   -std = c ++ 11
  };
}


# configureFlags = [ "QMAKE_CXXFLAGS+=-std=c++17" ];
# configureFlags = old.configureFlags ++ [ "QMAKE_CXXFLAGS+=-std=c++14" ];
# configureFlags = old.configureFlags ++ [ "-DQT_NO_VERSION_TAGGING" ];
# configureFlags = old.configureFlags ++ [ "CXXFLAGS=-std=c++17" ];
# configureFlags = old.configureFlags ++ [ "QMAKE_CXXFLAGS+=-std=c++17" ];
# configureFlags = old.configureFlags ++ [ "QMAKE_CXXFLAGS=-std=c++17" ];
# configureFlags = old.configureFlags ++ [ "QMAKE_CXXFLAGS += -std=c++17" ];
# env.CXXFLAGS = "-std=c++17";
# env.NIX_CFLAGS_COMPILE = "-std=c++17";
