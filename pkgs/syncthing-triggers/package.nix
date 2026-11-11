{
  lib,
  writeShellApplication,
  python3,
}:
writeShellApplication {
  name = "syncthing-triggers";

  runtimeInputs = [ python3 ];

  text = ''
    exec python3 ${./triggers.py} "$@"
  '';

  meta = {
    description = "Run ordered commands when a Syncthing folder is ready";
    license = lib.licenses.mit;
    mainProgram = "syncthing-triggers";
  };
}
