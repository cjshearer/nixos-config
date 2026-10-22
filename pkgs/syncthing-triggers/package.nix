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
    description = "Run commands when a Syncthing folder is ready to replicate";
    license = lib.licenses.mit;
    mainProgram = "syncthing-triggers";
  };
}
