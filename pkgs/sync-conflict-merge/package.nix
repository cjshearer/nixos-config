{
  lib,
  writeShellApplication,
  git,
  python3,
}:
writeShellApplication {
  name = "sync-conflict-merge";

  runtimeInputs = [
    git
    python3
  ];

  text = ''
    exec python3 ${./sync_conflict_merge.py} "$@"
  '';

  meta = {
    description = "Merge Syncthing conflict copies with a three-way merge";
    license = lib.licenses.mit;
    mainProgram = "sync-conflict-merge";
  };
}
