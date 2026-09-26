#!/usr/bin/env python3
"""Move the single-file queue into one file per entry, per item, per decision and per review item.

Reads `docs/DECISIONS.md`, `docs/TODO.md` and `docs/REVIEW.md` in their old format from a git
revision, and writes `docs/decisions/`, `docs/todo/` and `docs/review/` beside short new versions
of the three files. The layout, what each old line becomes and every assertion it makes are in
`tools/lib_queue.py`; this is the command around it.

Re-runnable on a fresh `main`: a branch that merges a `main` still on the old format takes
`main`'s old-format files and runs this again (`--rev MERGE_HEAD --replace` mid-merge) rather
than merging the three files by hand.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib_queue as q

ROOT = Path(__file__).resolve().parent.parent

EPILOG = """\
examples:
  uv run python tools/migrate-queue.py --dry-run
  uv run python tools/migrate-queue.py --rev origin/main
  uv run python tools/migrate-queue.py --rev MERGE_HEAD --replace
"""


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/migrate-queue.py",
        description=(
            "Reads the old-format docs/DECISIONS.md, docs/TODO.md and docs/REVIEW.md from REV and writes"
            " them as docs/decisions/, docs/todo/ and docs/review/ plus the three short files, then"
            " prints its verification. Writes nothing when any assertion fails. Never touches the index."
        ),
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--rev", default="HEAD", help="the revision to read the old files from (default HEAD)")
    parser.add_argument(
        "--replace",
        action="store_true",
        help="delete docs/decisions/, docs/todo/ and docs/review/ first (they must not exist otherwise)",
    )
    parser.add_argument("--dry-run", action="store_true", help="verify and report, write nothing")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse(argv)
    texts: dict[str, str] = {}
    for path in q.OLD_FILES:
        text = q.git_show(args.rev, path, str(ROOT))
        if text is None:
            print(f"refusing: {args.rev} has no {path}", file=sys.stderr)
            return 1
        texts[path] = text
    if not q.is_old_format(texts):
        print(f"refusing: {q.DECISIONS} at {args.rev} is not in the old format -- nothing to migrate", file=sys.stderr)
        return 1
    try:
        migration = q.migrate(texts, q.git_line_dates(args.rev, str(ROOT)))
    except q.QueueFormatError as error:
        print(f"refusing: {error}", file=sys.stderr)
        print("nothing was written.", file=sys.stderr)
        return 1
    for line in migration.report.lines():
        print(line)
    existing = [d for d in q.NEW_DIRS if (ROOT / d).exists() and any((ROOT / d).iterdir())]
    if existing and not args.replace:
        print(f"refusing: {', '.join(existing)} already exist; --replace deletes them first", file=sys.stderr)
        return 1
    if args.dry_run:
        print(f"dry run: {len(migration.tree)} files would be written")
        return 0
    for folder in q.NEW_DIRS:
        shutil.rmtree(ROOT / folder, ignore_errors=True)
    for path, content in sorted(migration.tree.items()):
        target = ROOT / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)
    # Verify after: every file is on disk with the content the migration made, and nothing else is.
    on_disk = {str(p.relative_to(ROOT)) for folder in q.NEW_DIRS for p in (ROOT / folder).rglob("*") if p.is_file()}
    expected = {p for p in migration.tree if p.startswith(tuple(d + "/" for d in q.NEW_DIRS))}
    if on_disk != expected:
        print(f"FAILED: on disk and expected differ: {sorted(on_disk ^ expected)[:10]}", file=sys.stderr)
        return 1
    for path, content in migration.tree.items():
        if (ROOT / path).read_text() != content:
            print(f"FAILED: {path} does not hold what was written", file=sys.stderr)
            return 1
    status = subprocess.run(["git", "status", "--short", "--", "docs"], cwd=ROOT, capture_output=True, text=True)
    print(f"wrote {len(migration.tree)} files; `git status` lists {len(status.stdout.splitlines())} paths under docs/")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
