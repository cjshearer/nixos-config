{ opencode, ... }:
opencode.overrideAttrs ({
  postPatch = (opencode.postPatch or "") + ''
    # fix for bun 1.4.x
    substituteInPlace packages/opencode/script/build.ts \
      --replace-fail 'splitting: true,' 'splitting: false,'
  '';
})
