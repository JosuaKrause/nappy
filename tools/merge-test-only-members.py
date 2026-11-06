#!/usr/bin/env python3
"""Resolves a merge conflict in `tools/test_only_members.txt`, and in no other file.

Mid-merge, with the list unmerged in the index, this keeps main's file and replays the branch's own
edits on it. The edits are read from the stages as a line diff of stage 1 (the base) against stage 2
(the branch), so a blank line counts. Start from stage 3 (main's file), remove each removed line (it
must occur exactly once there; a line main removed too is already gone and is skipped), insert each
added line right after the line that precedes it in stage 2 (that line must occur exactly once in
main's file or in what was inserted before it), write the file and `git add` it. Then
`git diff <main ref> -- <path>` must show exactly the added and the removed lines applied, and nothing else.

The list is a set of unique lines in groups, so a line is identified by its text. This is why the
tool is for this one file: on any other file a repeated line would be misplaced.

It changes nothing and exits 1 when the path is not unmerged, when a refusal fires, or when the
verification differs.

Usage: merge-test-only-members.py [--dry-run] [--main-ref REF] [PATH]
Example: uv run python tools/merge-test-only-members.py --dry-run
"""

from __future__ import annotations

import argparse
import difflib
import subprocess
import sys
from collections import Counter
from pathlib import Path

LIST_PATH = "tools/test_only_members.txt"


class Refusal(Exception):
    pass


def git(*args: str, cwd: Path | None = None) -> str:
    done = subprocess.run(["git", *args], capture_output=True, text=True, cwd=cwd, check=False)
    if done.returncode != 0:
        raise Refusal(f"git {' '.join(args)} failed: {done.stderr.strip()}")
    return done.stdout


def stage(path: str, number: int, cwd: Path) -> list[str]:
    return git("show", f":{number}:{path}", cwd=cwd).splitlines()


def replay(base: list[str], mine: list[str], theirs: list[str]) -> tuple[list[str], list[str], list[str]]:
    """The merged lines, the added lines and the removed lines that were applied.

    The branch's edits are a line diff of the base against the branch, so a blank line counts. A line
    both sides removed is not in main's file any more and is skipped, not applied.
    """
    added: list[tuple[int, str]] = []
    removed: list[str] = []
    for tag, b1, b2, m1, m2 in difflib.SequenceMatcher(None, base, mine, autojunk=False).get_opcodes():
        if tag in ("delete", "replace"):
            removed.extend(base[b1:b2])
        if tag in ("insert", "replace"):
            added.extend((at, mine[at]) for at in range(m1, m2))
    result = list(theirs)
    applied_removed: list[str] = []
    for line in removed:
        found = result.count(line)
        if found > 1:
            raise Refusal(f"removed line occurs {found} times in main's file, not once: {line!r}")
        if found == 1:
            result.remove(line)
            applied_removed.append(line)
    for at, line in added:
        if line.strip() and line in result:
            raise Refusal(f"added line is already in main's file: {line!r}")
        if at == 0:
            result.insert(0, line)
            continue
        before = mine[at - 1]
        if result.count(before) != 1:
            raise Refusal(
                f"the line before {line!r} occurs {result.count(before)} times in main's file, not once: {before!r}"
            )
        result.insert(result.index(before) + 1, line)
    return result, [line for _, line in added], applied_removed


def changed_lines(path: str, ref: str, cwd: Path) -> tuple[Counter[str], Counter[str]]:
    plus: Counter[str] = Counter()
    minus: Counter[str] = Counter()
    for line in git("diff", "-U0", ref, "--", path, cwd=cwd).splitlines():
        if line.startswith(("+++", "---")):
            continue
        if line.startswith("+"):
            plus[line[1:]] += 1
        elif line.startswith("-"):
            minus[line[1:]] += 1
    return plus, minus


def run(path: str, ref: str, dry_run: bool, cwd: Path) -> str:
    if path != LIST_PATH:
        raise Refusal(f"this tool resolves {LIST_PATH} only, not {path}")
    stages = {line.split()[2] for line in git("ls-files", "-u", "--", path, cwd=cwd).splitlines()}
    if stages != {"1", "2", "3"}:
        raise Refusal(f"{path} is not unmerged with a base, a branch and a main side (stages {sorted(stages)})")
    merged, added, removed = replay(stage(path, 1, cwd), stage(path, 2, cwd), stage(path, 3, cwd))
    summary = f"{path}: {len(added)} added, {len(removed)} removed on top of {ref}"
    if dry_run:
        return "dry run, nothing written; " + summary
    (cwd / path).write_text("\n".join(merged) + "\n")
    git("add", "--", path, cwd=cwd)
    plus, minus = changed_lines(path, ref, cwd)
    if plus != Counter(added) or minus != Counter(removed):
        git("checkout", "--merge", "--", path, cwd=cwd)
        found = f"+{dict(plus)} -{dict(minus)}"
        raise Refusal(f"verification differs: git diff {ref} shows {found}, expected +{added} -{removed}")
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(
        description=f"Resolve a merge conflict in {LIST_PATH} (this file only) from main's side.",
        epilog="Example: uv run python tools/merge-test-only-members.py --dry-run",
    )
    parser.add_argument("path", nargs="?", default=LIST_PATH, help=f"the unmerged list (only {LIST_PATH})")
    parser.add_argument("--main-ref", default="MERGE_HEAD", help="main's side of the merge (default MERGE_HEAD)")
    parser.add_argument("--dry-run", action="store_true", help="print what would be done and change nothing")
    args = parser.parse_args()
    try:
        top = Path(git("rev-parse", "--show-toplevel").strip())
        print(run(args.path, args.main_ref, args.dry_run, top))
    except Refusal as refusal:
        print(f"refused: {refusal}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
