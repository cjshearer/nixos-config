{
  lib,
  writeShellApplication,
  git,
  python3,
}:
writeShellApplication {
  name = "notes-merge";

  runtimeInputs = [
    git
    python3
  ];

  text = ''
    exec python3 ${./notes_merge.py} "$@"
  '';

  meta = {
    description = "Merge Syncthing conflict copies in a notes folder";
    license = lib.licenses.mit;
    mainProgram = "notes-merge";
  };
}
