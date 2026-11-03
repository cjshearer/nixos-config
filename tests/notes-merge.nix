{ pkgs }:
let
  notes-merge = pkgs.callPackage ../pkgs/notes-merge/package.nix { };
in
pkgs.runCommand "notes-merge-test"
  {
    nativeBuildInputs = [ pkgs.gnugrep ];
  }
  ''
    set -euo pipefail

    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT

    # Non-overlapping edits merge and the conflict copy is removed.
    mkdir -p "$work/.stversions"
    printf 'A\nB\nC\n' > "$work/.stversions/notes~20261103-000000.md"
    # A version newer than the conflict is not a common ancestor.
    printf 'Z\n' > "$work/.stversions/notes~20261104-000000.md"
    printf 'A\nB\nC\nD\n' > "$work/notes.md"
    printf 'X\nA\nB\nC\n' \
      > "$work/notes.sync-conflict-20261103-000100-AAAAAAA.md"

    ${notes-merge}/bin/notes-merge --folder "$work"

    test ! -e "$work/notes.sync-conflict-20261103-000100-AAAAAAA.md"
    grep -qx X "$work/notes.md"
    grep -qx D "$work/notes.md"

    # Overlapping edits stay as a conflict for manual resolution.
    printf 'A\nB\n' > "$work/.stversions/other~20261103-000000.md"
    printf 'A\ncurrent\n' > "$work/other.md"
    printf 'A\nconflict\n' \
      > "$work/other.sync-conflict-20261103-000100-BBBBBBB.md"

    ${notes-merge}/bin/notes-merge --folder "$work"

    test -e "$work/other.sync-conflict-20261103-000100-BBBBBBB.md"
    grep -qx current "$work/other.md"

    # No versioned base means no three-way merge.
    printf 'A\n' > "$work/no-base.md"
    printf 'B\n' > "$work/no-base.sync-conflict-20261103-000100-CCCCCCC.md"

    ${notes-merge}/bin/notes-merge --folder "$work"

    test -e "$work/no-base.sync-conflict-20261103-000100-CCCCCCC.md"

    # Only note-like text files are considered.
    printf '{}' > "$work/data.json"
    printf '{"x":1}' \
      > "$work/data.sync-conflict-20261103-000100-DDDDDDD.json"

    ${notes-merge}/bin/notes-merge --folder "$work"

    test -e "$work/data.sync-conflict-20261103-000100-DDDDDDD.json"

    mkdir -p "$out"
  ''
