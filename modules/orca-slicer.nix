{
  home-manager.sharedModules = [
    (
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        options.programs.orca-slicer.enable = lib.mkEnableOption "orca-slicer";
        options.programs.orca-slicer.package = lib.mkOption {
          type = lib.types.package;
          default = (
            let
              wxGTK' = (
                pkgs.wxwidgets_3_3.overrideAttrs (old: {
                  configureFlags = old.configureFlags ++ [
                    "--enable-debug=no"
                  ];
                })
              );

              src = pkgs.fetchFromGitHub {
                owner = "OrcaSlicer";
                repo = "OrcaSlicer";
                rev = "88806ac63e1b8a28f5ed6b46c876ff6952ffd6f0";
                hash = "sha256-d2/o8bfarct6BXvtcuPFYf6eky4zw8mwhx8BeY/1bWQ=";
              };

              # Required by the GUI (the nixpkgs package builds it from source),
              # not packaged in nixpkgs
              wxinspector = pkgs.stdenv.mkDerivation {
                pname = "wxinspector";
                version = "1.0.0";
                src = pkgs.fetchzip {
                  url = "https://github.com/Noisyfox/wxInspector/archive/refs/tags/v1.0.0.zip";
                  hash = "sha256-AQbV2vAGJXatAXwLAxhWVXTdKqxj2v0THexQyKbroJw=";
                };
                nativeBuildInputs = [
                  pkgs.cmake
                  pkgs.pkg-config
                ];
                buildInputs = [
                  wxGTK'
                  pkgs.gtk3
                ];
              };

              # Needed by the Design tab, but not packaged in nixpkgs
              libslvs = pkgs.stdenv.mkDerivation {
                pname = "libslvs";
                version = "3.0";
                src = pkgs.fetchzip {
                  url = "https://github.com/JacobStoren/SolveSpaceLib/archive/4d8704523e4bf212fadf5189f92484244f670fea.zip";
                  hash = "sha256-xe6J+cnOUWLo5561CskQlR+3Co8FriCupc8l1lhhocA=";
                };
                nativeBuildInputs = [ pkgs.cmake ];
                postPatch = ''
                  cp ${src}/deps/SLVS/CMakeLists.txt.in CMakeLists.txt
                '';
              };
            in
            pkgs.orca-slicer.overrideAttrs (
              finalAttrs: previousAttrs: {
                version = "2.5.0-dev";
                inherit src;
                patches = builtins.filter (
                  p:
                  !(
                    lib.any (name: lib.hasInfix name (toString p)) [
                      # I don't mind the update check enough to make it work with this branch
                      "configurable-update-check.patch"
                      # This branch reordered libslic3r's CMakeLists, so do it in postPatch instead
                      "dont-link-opencv-world-orca.patch"
                      # Already fixed in this branch
                      "pr-15873-fix-slice-crash.patch"
                      "pr-16109-fix-toolpath-freeze.patch"
                    ]
                  )
                ) previousAttrs.patches;
                postPatch = (previousAttrs.postPatch or "") + ''
                  substituteInPlace src/libslic3r/CMakeLists.txt \
                    --replace-fail "opencv_world" "opencv_core opencv_imgproc opencv_imgcodecs"
                  # nixpkgs installs libnoise headers under noise/ instead of libnoise/
                  substituteInPlace src/libslic3r/Feature/FuzzySkin/FuzzySkin.cpp \
                    --replace-fail '#include <libnoise/module/modulebase.h>' '#include <noise/module/modulebase.h>'
                  # Standard_Failure::what() only exists in OCCT 8
                  substituteInPlace src/libslic3r/CAD/GeometryEngine.cpp \
                    --replace-fail 'err = *e.what() ? e.what() : _u8L("OCCT failed to read STEP");' \
                    'const char *msg = e.GetMessageString(); err = msg && *msg ? msg : _u8L("OCCT failed to read STEP");'
                  # GC_MakeSegment2d only exists in OCCT 8
                  substituteInPlace src/libslic3r/CAD/CadDocument.cpp \
                    --replace-fail "GC_MakeSegment2d" "GCE2d_MakeSegment"
                  substituteInPlace src/slic3r/GUI/CAD/McpControl.cpp \
                    --replace-fail 'std::string("OCCT: ") + (*ex.what() ? ex.what() : "failure")' \
                    'std::string("OCCT: ") + (ex.GetMessageString() && *ex.GetMessageString() ? ex.GetMessageString() : "failure")'
                  # This branch looks for its bundled Python under a fixed version
                  substituteInPlace CMakeLists.txt \
                    --replace-fail 'set(_bundled_python_version "3.12.13")' \
                    'set(_bundled_python_version "${pkgs.python312.version}")' \
                    --replace-fail 'set(_bundled_python_root "''${CMAKE_PREFIX_PATH}/libpython")' \
                    'set(_bundled_python_root "${pkgs.python312}")'
                  # ...and stages the bundled ffmpeg libraries next to the binary
                  substituteInPlace src/CMakeLists.txt \
                    --replace-fail 'orcaslicer_copy_sos(OrcaSlicerSosCopy "Release" "" output_sos_Release)' \
                    'set(output_sos_Release "")' \
                    --replace-fail 'orcaslicer_copy_sos(OrcaSlicerSosCopy "Debug" "d" output_sos_Debug)' \
                    'set(output_sos_Debug "")' \
                    --replace-fail "\''${CMAKE_PREFIX_PATH}/libpython" "\''${_bundled_python_root}"
                  # ...and installs them into bin/
                  substituteInPlace CMakeLists.txt \
                    --replace-fail 'install(FILES ''${LIBRARY_FILES} DESTINATION "''${CMAKE_INSTALL_PREFIX}/bin")' \
                    'set(LIBRARY_FILES "")'
                '';
                buildInputs = map (
                  p:
                  if (p.pname or "") == "eigen" then
                    pkgs.eigen_5
                  else if (p.pname or "") == "wxwidgets" then
                    wxGTK'
                  else if (p.pname or "") == "cgal" then
                    pkgs.cgal
                  else if (p.pname or "") == "opencascade-occt" then
                    pkgs.opencascade-occt
                  else
                    p
                ) previousAttrs.buildInputs
                ++ [
                  pkgs.assimp
                  pkgs.libdatachannel
                  pkgs.python312
                  libslvs
                  wxinspector
                ];
                nativeBuildInputs = map (
                  p: if (p.pname or "") == "wxwidgets" then wxGTK' else p
                ) previousAttrs.nativeBuildInputs;
              }
            )
          );
        };

        config = lib.mkIf config.programs.orca-slicer.enable {
          home.packages = [ config.programs.orca-slicer.package ];
        };
      }
    )
  ];
}
