"""Merge Syncthing conflict copies with a three-way merge.

Syncthing keeps the losing side of a conflict as
<name>.sync-conflict-<date>-<time>-<device><ext>.  This pairs each copy with
its original, uses the newest staggered-versioning copy in .stversions as the
common ancestor, and runs `git merge-file`.  The copy is removed only when the
merge is clean; anything else is left for a human.
"""

import argparse
import os
import re
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

CONFLICT_SUFFIX = re.compile(r"\.sync-conflict-(\d{8})-(\d{6})-[A-Z0-9]{7}(?=\.|$)")
TEXT_SUFFIXES = {".md", ".txt"}
SKIP_DIRS = {".stversions", ".stfolder", ".trash", ".git"}
MAX_SIZE = 5 * 1024 * 1024


def strip_conflicts(name: str) -> str:
    previous = None
    while previous != name:
        previous = name
        name = CONFLICT_SUFFIX.sub("", name, count=1)
    return name


def conflict_stamp(name: str) -> str | None:
    matches = CONFLICT_SUFFIX.findall(name)
    if not matches:
        return None
    date, time = matches[-1]
    return f"{date}-{time}"


def version_candidates(original: Path, folder: Path, before: str) -> list[Path]:
    relative = original.relative_to(folder)
    directory = folder / ".stversions" / relative.parent
    if not directory.is_dir():
        return []

    stem, extension = os.path.splitext(relative.name)
    pattern = re.compile(
        rf"^{re.escape(stem)}~(\d{{8}}-\d{{6}}){re.escape(extension)}$"
    )

    found = []
    for candidate in directory.iterdir():
        match = pattern.fullmatch(candidate.name)
        if match and candidate.is_file() and not candidate.is_symlink():
            found.append((match.group(1), candidate))
    return [
        candidate for stamp, candidate in sorted(found, reverse=True) if stamp <= before
    ]


def read_text(path: Path) -> bytes | None:
    if path.stat().st_size > MAX_SIZE:
        return None
    data = path.read_bytes()
    if b"\0" in data:
        return None
    return data


def merge(original: Path, base: Path, conflict: Path) -> bytes | None:
    process = subprocess.run(
        ["git", "merge-file", "-p", str(original), str(base), str(conflict)],
        capture_output=True,
        check=False,
    )
    if process.returncode != 0:
        return None
    return process.stdout


def write_atomic(path: Path, data: bytes) -> None:
    mode = stat.S_IMODE(path.stat().st_mode)
    descriptor, temporary = tempfile.mkstemp(
        prefix=".syncthing.notes-merge-", suffix=".tmp", dir=path.parent
    )
    try:
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--folder", required=True, type=Path)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    folder = args.folder.resolve()

    conflicts = []
    for root, directories, files in os.walk(folder):
        directories[:] = sorted(d for d in directories if d not in SKIP_DIRS)
        for name in sorted(files):
            if ".sync-conflict-" in name:
                conflicts.append(Path(root) / name)

    for conflict in conflicts:
        original_name = strip_conflicts(conflict.name)
        if original_name == conflict.name:
            continue
        original = conflict.with_name(original_name)
        if not original.is_file() or original.is_symlink() or conflict.is_symlink():
            print(
                f"skip {conflict.relative_to(folder)}: original missing",
                file=sys.stderr,
            )
            continue
        if original.suffix.lower() not in TEXT_SUFFIXES:
            continue

        current = read_text(original)
        incoming = read_text(conflict)
        if current is None or incoming is None:
            print(f"skip {conflict.relative_to(folder)}: not text", file=sys.stderr)
            continue

        stamp = conflict_stamp(conflict.name)
        if stamp is None:
            continue
        bases = version_candidates(original, folder, stamp)
        if not bases:
            print(
                f"skip {conflict.relative_to(folder)}: no version base", file=sys.stderr
            )
            continue

        merged = merge(original, bases[0], conflict)
        if merged is None:
            print(
                f"leave {conflict.relative_to(folder)}: merge needs review",
                file=sys.stderr,
            )
            continue

        print(f"merge {conflict.relative_to(folder)}")
        if args.dry_run:
            continue
        if merged != current:
            write_atomic(original, merged)
        conflict.unlink()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
