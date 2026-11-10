{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  nodejs,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "chrome-devtools-mcp";
  version = "1.12.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-${finalAttrs.version}.tgz";
    hash = "sha256-Sq3jFnw+eBx5fWEJ7WA6DKW4yzY6KJ4uqsqpsMXSo2A=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/chrome-devtools-mcp
    cp -r . $out/lib/chrome-devtools-mcp

    mkdir -p $out/bin
    for bin in chrome-devtools-mcp chrome-devtools; do
      makeWrapper ${lib.getExe nodejs} $out/bin/$bin \
        --add-flags $out/lib/chrome-devtools-mcp/build/src/bin/$bin.js
    done

    runHook postInstall
  '';

  meta = {
    description = "MCP server and CLI for Chrome DevTools";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    license = lib.licenses.asl20;
    mainProgram = "chrome-devtools-mcp";
    platforms = lib.platforms.all;
  };
})
