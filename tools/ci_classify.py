#!/usr/bin/env python3
"""Sorts a pull request by the files it changes: queue-only, docs-only, or touching code.

CI's first job runs this and every later job reads the three flags it sets, so which checks a pull
request gets is decided once, from its files, never from its title:

- **queue-only**: every file is under `docs/todo/`, `docs/review/` or `docs/playtests/`. It gets
  the queue update's mechanical checks (`tools/ci_queue_update.py`), and is docs-only as well.
- **docs-only**: every file is Markdown or under `docs/`, and none of it is under `src/` or
  `tests/` or one of the files under `docs/` the game itself reads -- `docs/TELEMETRY.md` (its
  table of telemetry kinds is compared with the code), `docs/COSTS.md` (`tools/cost-table.sh
  --check` regenerates it and compares), `docs/ARCHITECTURE.md` (`tools/check.sh` watches it for
  the import pass's rewrite) and `docs/.gdignore`, which keeps Godot from importing `docs/` at
  all, so an edit to it changes what the boot check and the suite load. A `.gdignore` anywhere is
  read the same way. It skips every test of the game and runs every check of the repository's own
  consistency. Nothing else under `docs/` reaches Godot: the scripts and scenes under
  `docs/evidence/` are behind that `.gdignore` and run only when somebody names them by hand.
- **touches-code**: some file is under `src/` or `tests/`. It is never docs-only, so a pull request
  that changes the game can never skip the game's tests, and it owes the queue its item
  (`tools/ci_code_pr_queue.py`).

An empty diff is none of the three, so it runs everything. In CI the flags go to `GITHUB_OUTPUT` as
`queue_only`, `docs_only` and `touches_code`, each `true` or `false`; anywhere else they print.
"""

from __future__ import annotations

import argparse
import os
import sys
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib_ci

QUEUE_FOLDERS = ("docs/todo", "docs/review", "docs/playtests")
CODE_FOLDERS = ("src", "tests")
# Files under docs/ that the game or a check of it reads, so a change to one runs everything.
GAME_READS = ("docs/TELEMETRY.md", "docs/COSTS.md", "docs/ARCHITECTURE.md", "docs/.gdignore")
# Godot's own marker for a folder it does not import, read wherever it stands.
GODOT_IGNORE = ".gdignore"

EPILOG = """\
examples:
  uv run python tools/ci_classify.py
  uv run python tools/ci_classify.py --base origin/main --head feature-branch
"""


@dataclass(frozen=True)
class Flags:
    queue_only: bool
    docs_only: bool
    touches_code: bool


def is_doc(path: str) -> bool:
    if path in GAME_READS or path.split("/")[-1] == GODOT_IGNORE:
        return False
    return path.lower().endswith(".md") or lib_ci.under(path, "docs")


def classify(paths: list[str]) -> Flags:
    touches_code = any(lib_ci.under(path, *CODE_FOLDERS) for path in paths)
    docs_only = bool(paths) and not touches_code and all(is_doc(path) for path in paths)
    queue_only = docs_only and all(lib_ci.under(path, *QUEUE_FOLDERS) for path in paths)
    return Flags(queue_only=queue_only, docs_only=docs_only, touches_code=touches_code)


def kind(path: str) -> str:
    if lib_ci.under(path, *CODE_FOLDERS):
        return "code"
    if lib_ci.under(path, *QUEUE_FOLDERS):
        return "queue"
    if path in GAME_READS or path.split("/")[-1] == GODOT_IGNORE:
        return "read by the game"
    if is_doc(path):
        return "docs"
    return "other"


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/ci_classify.py",
        description=(
            "Lists the files a branch changes since it left BASE and sorts it: queue-only (every file under"
            " docs/todo/, docs/review/ or docs/playtests/), docs-only (every file Markdown or under docs/,"
            " none under src/ or tests/, none of docs/TELEMETRY.md, docs/COSTS.md, docs/ARCHITECTURE.md, and no"
            " .gdignore)"
            " and touches-code (a file under src/ or tests/). Writes queue_only, docs_only and touches_code"
            " to GITHUB_OUTPUT when CI sets it, and prints them."
        ),
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--base", default=lib_ci.DEFAULT_BASE, help="where the branch started (default origin/main)")
    parser.add_argument("--head", default="HEAD", help="the branch's tip (default HEAD)")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse(argv)
    try:
        paths = [change.path for change in lib_ci.changed_files(args.base, args.head)]
    except lib_ci.CiError as error:
        print(f"tools/ci_classify.py: {error}", file=sys.stderr)
        return 1
    flags = classify(paths)
    values = {
        "queue_only": flags.queue_only,
        "docs_only": flags.docs_only,
        "touches_code": flags.touches_code,
    }
    for path in paths:
        print(f"{kind(path):<26} {path}")
    lines = [f"{name}={'true' if value else 'false'}" for name, value in values.items()]
    print("\n".join(lines))
    output = os.environ.get("GITHUB_OUTPUT", "")
    if output:
        with Path(output).open("a", encoding="utf-8") as handle:
            handle.write("\n".join(lines) + "\n")
    verdict = (
        "queue-only: the game's tests are skipped and the queue update's checks run"
        if flags.queue_only
        else "docs-only: the game's tests are skipped"
        if flags.docs_only
        else "every check runs"
    )
    lib_ci.write_summary(f"### What this pull request changes\n\n{len(paths)} file(s); {verdict}.\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
