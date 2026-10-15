# Adapted from https://github.com/NixOS/nixpkgs/pull/569770 at revision 6ae089813f2b23f67bcfb70271deb789df3c7646.
{
  lib,
  stdenv,
  bun,
  darwin,
  fetchFromGitHub,
  installShellFiles,
  makeBinaryWrapper,
  models-dev,
  nodejs,
  nix-update-script,
  ripgrep,
  sysctl,
  versionCheckHook,
  wayland,
  writableTmpDirAsHomeHook,
}:
let
  platform = stdenv.hostPlatform;
  bunCpu = if platform.isAarch64 then "arm64" else "x64";
  bunOs = if platform.isLinux then "linux" else "darwin";

  node_modules =
    finalAttrs:
    stdenv.mkDerivation {
      pname = "${finalAttrs.pname}-node_modules";
      inherit (finalAttrs) version src;

      __structuredAttrs = true;
      strictDeps = true;

      impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
        "GIT_PROXY_COMMAND"
        "SOCKS_SERVER"
      ];

      nativeBuildInputs = [
        bun
        writableTmpDirAsHomeHook
      ];

      dontConfigure = true;

      buildPhase = ''
        runHook preBuild

        export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
        bun install \
          --cpu="${bunCpu}" \
          --os="${bunOs}" \
          --filter '!./' \
          --filter './packages/cli' \
          --filter './packages/desktop' \
          --filter './packages/app' \
          --frozen-lockfile \
          --ignore-scripts \
          --no-progress

        bun --bun ./nix/scripts/canonicalize-node-modules.ts
        bun --bun ./nix/scripts/normalize-bun-binaries.ts

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        find . -type d -name node_modules -exec cp -R --parents {} $out \;

        runHook postInstall
      '';

      # NOTE: Required else we get errors that our fixed-output derivation references store paths
      dontFixup = true;

      outputHash =
        {
          x86_64-linux = "sha256-KxeLuCby1hAuivKR2fm28w4yARbfSNAawoWQmSyC2qw=";
          aarch64-linux = "sha256-XYhu1rRzKgWn7e81Tb9UEWnynfufcWts3mbVfhNnlB4=";
          aarch64-darwin = "sha256-9ono+6xUAXAwykZ0s2k+usO4R654exY2JBy3PPhTVbk=";
        }
        .${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "opencode2";
  version = "2.0.27";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${finalAttrs.version}";
    hash = "sha256-C+MOdj8CPcP6cLWJl/KBg8/oR/XVOkn0+d7/54YKuU4=";
  };

  postPatch =
    # Relax Bun version check to be a warning instead of an error
    ''
      substituteInPlace packages/script/src/index.ts \
        --replace-fail \
        'throw new Error(`This script requires bun@''${expectedBunVersionRange}' \
        'console.warn(`Warning: This script requires bun@''${expectedBunVersionRange}'
    ''
    # Avoid requiring prettier just to format the schema JSON
    + ''
      substituteInPlace packages/cli/script/schema.ts \
        --replace-fail 'import { format } from "prettier"' 'const format = (s: string) => JSON.stringify(JSON.parse(s), null, 2)'
    '';

  node_modules = node_modules finalAttrs;

  nativeBuildInputs = [
    bun
    installShellFiles
    makeBinaryWrapper
    nodejs
    writableTmpDirAsHomeHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.autoSignDarwinBinariesHook
  ];

  env.MODELS_DEV_API_JSON = "${models-dev}/dist/_api.json";
  env.OPENCODE_DISABLE_MODELS_FETCH = true;
  env.OPENCODE_VERSION = finalAttrs.version;
  env.OPENCODE_CHANNEL = "prod";
  env.NODE_OPTIONS = "--max-old-space-size=4096";

  configurePhase = ''
    runHook preConfigure

    cp -R "$node_modules"/. .
    patchShebangs node_modules
    patchShebangs packages/*/node_modules

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    cd ./packages/cli
    bun --bun ./script/build.ts --single --skip-install
    bun --bun ./script/schema.ts cli.json

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 dist/cli-*/bin/opencode $out/bin/opencode

    wrapProgram $out/bin/opencode \
      --set OPENCODE_DISABLE_AUTOUPDATE true \
      --prefix PATH : ${
        lib.makeBinPath (
          [
            ripgrep
          ]
          ++ lib.optionals stdenv.hostPlatform.isDarwin [
            sysctl
          ]
        )
      }${lib.optionalString stdenv.hostPlatform.isLinux ''
        \
               --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ wayland ]}''}

    ln -s opencode $out/bin/opencode2

    install -Dm644 cli.json $out/share/cli.json
    install -Dm644 ../console/app/public/config.json $out/share/config.json
    install -Dm644 ../web/public/theme.json $out/share/theme.json

    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd opencode \
      --bash <($out/bin/opencode --completions bash) \
      --zsh <($out/bin/opencode --completions zsh) \
      --fish <($out/bin/opencode --completions fish)

    installShellCompletion --cmd opencode2 \
      --bash <($out/bin/opencode2 --completions bash) \
      --zsh <($out/bin/opencode2 --completions zsh) \
      --fish <($out/bin/opencode2 --completions fish)
  '';

  dontStrip = true;

  nativeInstallCheckInputs = [
    versionCheckHook
    writableTmpDirAsHomeHook
  ];
  doInstallCheck = true;
  versionCheckKeepEnvironment = [
    "HOME"
    "OPENCODE_DISABLE_MODELS_FETCH"
  ];
  versionCheckProgramArg = "--version";

  passthru = {
    jsonschema = {
      cli = "${finalAttrs.finalPackage}/share/cli.json";
      config = "${finalAttrs.finalPackage}/share/config.json";
      theme = "${finalAttrs.finalPackage}/share/theme.json";
    };
    inherit (finalAttrs) node_modules;
    updateScript = nix-update-script {
      extraArgs = [
        "--subpackage"
        "node_modules"
        "--version-regex"
        "^v(2\\..*)$"
      ];
    };
  };

  meta = {
    description = "AI coding agent built for the terminal (v2)";
    homepage = "https://github.com/anomalyco/opencode";
    changelog = "https://github.com/anomalyco/opencode/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      delafthi
      DuskyElf
      graham33
    ];
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
    ];
    mainProgram = "opencode";
  };
})
