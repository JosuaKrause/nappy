#!/usr/bin/env python3
"""Replay an open pull request's edits to the old single-file queue as edits to the new files.

Run on a PR branch in the middle of merging a `main` whose queue is already files
(`git merge --no-ff --no-commit origin/main`, which then conflicts in `docs/DECISIONS.md`,
`docs/TODO.md` or `docs/REVIEW.md`). It reads the three old files at the merge base and at the
branch tip, moves each through the same migration `tools/migrate-queue.py` runs, and compares the
two results file by file: a record the branch added becomes a decision file, an entry it closed
deletes the entry's folder, an item it closed deletes the item's file, a review item it added
becomes a review file, and an edit inside an entry, an item, a record or the order becomes the
same edit to that one file. Each of those is applied to `main`'s side -- three-way where `main`
changed the same file too -- and the three old files are resolved to `main`'s new text.

It refuses, naming every path, and changes nothing, when an edit cannot be mapped: the branch
changed a file `main` deleted, deleted one `main` changed, added one `main` has differently, or
made a change to the same file as `main` that does not merge. The semantic review of the merge
stays the reviewer's (the merging-main skill).
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib_queue as q

ROOT = Path(__file__).resolve().parent.parent

EPILOG = """\
examples:
  git merge --no-ff --no-commit origin/main
  uv run python tools/convert-queue-edits.py --dry-run
  uv run python tools/convert-queue-edits.py
"""


@dataclass
class Plan:
    writes: dict[str, str] = field(default_factory=dict)
    deletes: list[str] = field(default_factory=list)
    problems: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)


def git(cwd: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, check=False)
    if check and result.returncode != 0:
        raise SystemExit(f"refusing: git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout


def old_texts(cwd: Path, rev: str) -> dict[str, str] | None:
    texts: dict[str, str] = {}
    for path in q.OLD_FILES:
        text = q.git_show(rev, path, str(cwd))
        if text is None:
            return None
        texts[path] = text
    return texts


def merge_three(cwd: Path, current: str, base: str, other: str) -> tuple[str, bool]:
    """`git merge-file`'s answer: main's text with the branch's change applied, and whether it merged cleanly."""
    with tempfile.TemporaryDirectory() as tmp:
        paths = []
        for name, text in (("main", current), ("base", base), ("branch", other)):
            path = Path(tmp) / name
            path.write_text(text)
            paths.append(str(path))
        result = subprocess.run(
            ["git", "merge-file", "-p", "-L", "main", "-L", "base", "-L", "branch", *paths],
            cwd=cwd,
            capture_output=True,
            text=True,
            check=False,
        )
    if result.returncode < 0 or result.returncode > 127:
        raise SystemExit(f"refusing: git merge-file failed: {result.stderr.strip()}")
    return result.stdout, result.returncode == 0


def split_order_list(text: str) -> tuple[str, list[str]] | None:
    """TODO.md as its text with the generated list of entry links cut out, and that list."""
    lines = text.split("\n")
    tail = q.NEW_ORDER_TAIL.rstrip("\n")
    if lines.count(tail) != 1:
        return None
    start = lines.index(tail) + 2
    end = start
    while end < len(lines) and lines[end].startswith("- [") and "](todo/" in lines[end]:
        end += 1
    marker = "\0the entries\0"
    return "\n".join([*lines[:start], marker, *lines[end:]]), lines[start:end]


def merge_todo(cwd: Path, theirs: str, was: str, now: str) -> tuple[str, bool]:
    """TODO.md three ways, with the list of entry links merged as a list.

    The list is one line per entry, so a branch that closes one entry and main that filed three
    beside it touch neighbouring lines; merged as text that is a conflict, merged as a list it is
    not: the branch's removed lines leave main's list, and each line it added goes in after the
    line before it in the branch's own list.
    """
    parts = [split_order_list(t) for t in (theirs, was, now)]
    if parts[0] is None or parts[1] is None or parts[2] is None:
        return merge_three(cwd, theirs, was, now)
    (t_text, t_list), (w_text, w_list), (n_text, n_list) = parts[0], parts[1], parts[2]
    text, clean = merge_three(cwd, t_text, w_text, n_text)
    if not clean:
        return text, False
    result = [line for line in t_list if not (line in w_list and line not in n_list)]
    for index, line in enumerate(n_list):
        if line in w_list or line in result:
            continue
        before = next((n_list[i] for i in range(index - 1, -1, -1) if n_list[i] in result), None)
        result.insert(result.index(before) + 1 if before is not None else 0, line)
    return text.replace("\0the entries\0", "\n".join(result)), True


def plan(cwd: Path, base: str, branch: str, main: str) -> Plan:
    out = Plan()
    base_texts = old_texts(cwd, base)
    branch_texts = old_texts(cwd, branch)
    if base_texts is None or branch_texts is None:
        out.problems.append("the merge base or the branch lacks one of the three old queue files")
        return out
    if not q.is_old_format(base_texts):
        out.notes.append("the merge base already has the queue as files: there is nothing to convert")
        return out
    if not q.is_old_format(branch_texts):
        out.problems.append(f"{q.DECISIONS} at the branch tip is not in the old format; convert by hand")
        return out
    main_decisions = q.git_show(main, q.DECISIONS, str(cwd))
    if main_decisions is None or main_decisions.startswith("# Decisions\n\n## "):
        out.problems.append(
            f"{main} still has the old single-file queue: merge it normally, there is nothing to convert"
        )
        return out
    try:
        before = q.migrate(base_texts, q.git_first_dates(base, str(cwd)), strict=False).tree
        after = q.migrate(branch_texts, q.git_first_dates(branch, str(cwd)), strict=False).tree
    except q.QueueFormatError as error:
        out.problems.append(f"the old files do not migrate: {error}")
        return out
    for path in sorted(set(before) | set(after)):
        was = before.get(path)
        now = after.get(path)
        if was == now:
            continue
        theirs = q.git_show(main, path, str(cwd))
        if was is None and now is not None:
            if theirs is None:
                out.writes[path] = now
            elif theirs != now:
                out.problems.append(f"{path}: the branch adds it, and main already has a different one")
        elif now is None and was is not None:
            if theirs is None:
                out.notes.append(f"{path}: the branch removes it, and main no longer has it")
            elif theirs == was:
                out.deletes.append(path)
            else:
                out.problems.append(f"{path}: the branch removes it, and main changed it since")
        elif was is not None and now is not None:
            if theirs is None:
                out.problems.append(f"{path}: the branch changes it, and main removed it")
            elif theirs == was:
                out.writes[path] = now
            elif theirs != now:
                merge = merge_todo if path == q.TODO else merge_three
                merged, clean = merge(cwd, theirs, was, now)
                if clean:
                    out.writes[path] = merged
                else:
                    out.problems.append(f"{path}: the branch's change and main's to the same lines do not merge")
    # The three old files resolve to main's side, with whatever the branch changed in them merged in.
    for path in q.OLD_FILES:
        if path not in out.writes:
            theirs = q.git_show(main, path, str(cwd))
            if theirs is None:
                out.problems.append(f"{main} has no {path}")
            else:
                out.writes[path] = theirs
    return out


def describe(cwd: Path, p: Plan, main: str) -> list[str]:
    lines = []
    for path in sorted(p.writes):
        verb = "resolve" if path in q.OLD_FILES else ("write" if q.git_show(main, path, str(cwd)) is None else "update")
        lines.append(f"{verb:8} {path}")
    lines.extend(f"delete   {path}" for path in sorted(p.deletes))
    lines.extend(f"note:    {n}" for n in p.notes)
    return lines


def apply(cwd: Path, p: Plan) -> None:
    for path, content in p.writes.items():
        target = cwd / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)
    for path in p.deletes:
        target = cwd / path
        target.unlink(missing_ok=True)
        parent = target.parent
        while parent != cwd and parent.is_dir() and not any(parent.iterdir()):
            parent.rmdir()
            parent = parent.parent
    if p.writes:
        git(cwd, "add", "--", *sorted(p.writes))
    if p.deletes:
        git(cwd, "rm", "-q", "--cached", "--ignore-unmatch", "--", *sorted(p.deletes))
    # Verify after: every path holds what was planned, and none of the three is left unmerged.
    for path, content in p.writes.items():
        if (cwd / path).read_text() != content:
            raise SystemExit(f"FAILED: {path} does not hold what was written")
    for path in p.deletes:
        if (cwd / path).exists():
            raise SystemExit(f"FAILED: {path} is still there")
    unmerged = git(cwd, "diff", "--name-only", "--diff-filter=U").split()
    left = [path for path in q.OLD_FILES if path in unmerged]
    if left:
        raise SystemExit(f"FAILED: still unmerged: {', '.join(left)}")


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/convert-queue-edits.py",
        description=(
            "Mid-merge of a main whose queue is files into a PR branch still on the old single files:"
            " replays what the branch did to docs/DECISIONS.md, docs/TODO.md and docs/REVIEW.md since"
            " the merge base as file operations on main's side, stages them, and resolves the three"
            " files to main's text. Refuses, naming every path, and changes nothing when an edit"
            " cannot be mapped."
        ),
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--dry-run", action="store_true", help="print the plan, change nothing")
    parser.add_argument("--branch", default="HEAD", help="the PR branch's tip (default HEAD)")
    parser.add_argument("--main", default="MERGE_HEAD", help="main's side of the merge (default MERGE_HEAD)")
    parser.add_argument("--base", help="the merge base (default: git merge-base BRANCH MAIN)")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse(argv)
    cwd = ROOT
    merging = subprocess.run(["git", "rev-parse", "-q", "--verify", "MERGE_HEAD"], cwd=cwd, capture_output=True)
    if merging.returncode != 0:
        print(
            "refusing: no merge in progress -- run `git merge --no-ff --no-commit origin/main` first", file=sys.stderr
        )
        return 1
    branch = git(cwd, "rev-parse", args.branch).strip()
    main_rev = git(cwd, "rev-parse", args.main).strip()
    base = args.base or git(cwd, "merge-base", branch, main_rev).strip()
    p = plan(cwd, base, branch, main_rev)
    for line in p.notes:
        print(f"note: {line}")
    if p.problems:
        print("refusing: these edits cannot be mapped onto the new files; nothing was changed:", file=sys.stderr)
        for problem in p.problems:
            print(f"  {problem}", file=sys.stderr)
        return 1
    if not p.writes and not p.deletes:
        print("nothing to convert")
        return 0
    for line in describe(cwd, p, main_rev):
        print(line)
    if args.dry_run:
        print("dry run: nothing changed")
        return 0
    apply(cwd, p)
    print(f"converted: {len(p.writes)} written, {len(p.deletes)} deleted, all staged")
    print("the semantic review of the merge is still yours (the merging-main skill)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
