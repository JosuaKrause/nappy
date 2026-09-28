#!/usr/bin/env python3
"""No pull request merges with a handoff file in it.

Agents sharing a pull request may push a handoff file to its branch while the work is being made,
to pass it on, and remove it before the pull request is done (bouncy-heron, statement 11: "no PR is
allowed to have a handoff file (although it is okay to push handoff files during the process of
creating the PR -- it just needs to be cleaned up afterwards)"). So this fails a pull request whose
diff against where it started adds one, and goes green once it is gone.

A handoff file is a file the pull request adds -- a rename's new name included, since the diff
splits a rename into a deletion and an addition -- with `handoff` in any case in its name or in the
name of a folder it sits in. A file already on the base is never the pull request's to answer for,
which leaves the existing records under `docs/decisions/` with the word in their names alone.

The one exception is this script, whose own name carries the word: `NOT_HANDOFF` names it, so a
pull request that adds or moves the check is not failed by it.

It is a check of the repository, not of the game, so it runs on every pull request.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib_ci
from lib_ci import Change

EPILOG = """\
examples:
  uv run python tools/ci_no_handoff.py
  uv run python tools/ci_no_handoff.py --base origin/main
"""


# Files with the word in their names that are not handoff files: the check itself.
NOT_HANDOFF = ("tools/ci_no_handoff.py",)


def is_handoff(path: str) -> bool:
    return path not in NOT_HANDOFF and any("handoff" in part.lower() for part in path.split("/"))


def check(changes: list[Change]) -> list[str]:
    return [
        f"{change.path}: a handoff file; the pull request adds it, and no pull request merges with one"
        " (remove it once the work it passes on is done)"
        for change in changes
        if change.status == "A" and is_handoff(change.path)
    ]


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/ci_no_handoff.py",
        description=(
            "Fails if the branch adds, since it left BASE, a file with `handoff` (any case) in its name or in a"
            " folder's name on its path. A handoff file may be pushed while a pull request is being made; it is"
            " removed before it merges."
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
        changes = lib_ci.changed_files(args.base, args.head)
    except lib_ci.CiError as error:
        print(f"tools/ci_no_handoff.py: {error}", file=sys.stderr)
        return 1
    return lib_ci.report("tools/ci_no_handoff.py", check(changes), "the pull request adds no handoff file")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
