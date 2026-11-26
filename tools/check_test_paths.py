#!/usr/bin/env python3
"""Fails a doc or a code comment that names a file under `tests/` that does not exist.

A sentence that names the suite holding a check is how a reader finds the check, and a suite that
was split, merged or renamed leaves every such sentence pointing at nothing, with no error
anywhere. This reads the governed docs and the comments of the game's scripts and fails every
`tests/<path>.gd` (with or without `res://`) and every bare `test_<name>.gd` that names no file:

- **the docs**: `AGENTS.md`, `CLAUDE.md`, `README.md`, every Markdown file under `.claude/skills/`
  and every top-level `docs/*.md` but `docs/DECISIONS.md`, read whole;
- **the comments** (`#` and `##`) of every `.gd` file under `src/`, `tests/` and `tools/`.

A path is resolved from the checkout's root; a bare name is any file of that name under
`tests/`, at any depth. A name holding a placeholder or a wildcard (`test_<x>.gd`,
`tests/test_zz_*.gd`) is no file name and is not read. A Markdown line carrying `lint-allow` in an
HTML comment is a deliberate exception, as in `tools/lint.sh`.

It does not read the decision records, the playtests, the queue (`docs/todo/`) or the review
items (`docs/review/`): a record or a playtest says what was true then, and a queue entry or a
review item may name a suite that is not written yet. A file is taken to exist when it is on disk
or tracked by git, so a sparse checkout reads the same as a full one.

This runs under the host's own `python3` (tools/lint.sh calls it), so it stays 3.9-compatible.

  uv run python tools/check_test_paths.py
  uv run python tools/check_test_paths.py docs/EVENTS.md src/field.gd
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOP_DOCS = ("AGENTS.md", "CLAUDE.md", "README.md")
SKIPPED_DOCS = frozenset({"docs/DECISIONS.md"})
CODE_FOLDERS = ("src", "tests", "tools")
NAME = re.compile(r"(?<![\w/.-])(?:res://)?(tests/[\w/.-]+?\.gd|test_\w+\.gd)(?![\w*<>]|\.\w)")
ALLOW = re.compile(r"<!--[^>]*lint-allow")


def comment_of(line: str) -> str:
    """The comment of a GDScript line, or "" when it has none outside a string literal."""
    quote = ""
    i = 0
    while i < len(line):
        ch = line[i]
        if quote:
            if ch == "\\":
                i += 2
                continue
            if ch == quote:
                quote = ""
        elif ch in "\"'":
            quote = ch
        elif ch == "#":
            return line[i:]
        i += 1
    return ""


def in_scope(rel: str) -> bool:
    """Whether the file at `rel` (relative to the root) is one this check reads."""
    if rel in TOP_DOCS:
        return True
    if rel.startswith(".claude/skills/") and rel.endswith(".md"):
        return True
    if rel.startswith("docs/") and rel.count("/") == 1 and rel.endswith(".md"):
        return rel not in SKIPPED_DOCS
    return rel.endswith(".gd") and rel.split("/", 1)[0] in CODE_FOLDERS


def scope(root: Path) -> list[str]:
    """Every file this check reads in the checkout at `root`, relative to it."""
    found: list[str] = [name for name in TOP_DOCS if (root / name).is_file()]
    skills = root / ".claude" / "skills"
    if skills.is_dir():
        found += sorted(p.relative_to(root).as_posix() for p in skills.rglob("*.md"))
    docs = root / "docs"
    if docs.is_dir():
        found += sorted(p.relative_to(root).as_posix() for p in docs.glob("*.md"))
    for folder in CODE_FOLDERS:
        base = root / folder
        if base.is_dir():
            found += sorted(p.relative_to(root).as_posix() for p in base.rglob("*.gd"))
    return [rel for rel in found if in_scope(rel)]


def test_files(root: Path) -> set[str]:
    """Every file under `tests/`, relative to the root: on disk, and tracked by git when there is one."""
    found: set[str] = set()
    tests = root / "tests"
    if tests.is_dir():
        found |= {p.relative_to(root).as_posix() for p in tests.rglob("*") if p.is_file()}
    try:
        listed = subprocess.run(
            ["git", "-C", str(root), "ls-files", "--", "tests"],
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError:
        return found
    if listed.returncode == 0:
        found |= {line for line in listed.stdout.splitlines() if line}
    return found


def check_file(root: Path, rel: str, known: set[str], bare: set[str]) -> list[str]:
    """Every name in the file at `rel` that is no file, as `path:line: message`."""
    failures: list[str] = []
    is_doc = rel.endswith(".md")
    text = (root / rel).read_text(encoding="utf-8")
    for number, line in enumerate(text.splitlines(), start=1):
        if is_doc:
            if ALLOW.search(line):
                continue
            read = line
        else:
            read = comment_of(line)
        for match in NAME.finditer(read):
            name = match.group(1)
            exists = name in known if name.startswith("tests/") else name in bare
            if not exists:
                failures.append(f"{rel}:{number}: {name} names no file under tests/")
    return failures


def check(root: Path, files: list[str] | None = None) -> list[str]:
    """Every failure in the checkout at `root`, in `files` (relative to it) or in the whole scope."""
    known = test_files(root)
    bare = {name.rsplit("/", 1)[-1] for name in known}
    failures: list[str] = []
    targets = scope(root) if files is None else [rel for rel in files if in_scope(rel)]
    for rel in targets:
        failures += check_file(root, rel, known, bare)
    return failures


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="tools/check_test_paths.py",
        description="Fails a tests/ path or a bare test_<name>.gd that names no file, in the governed "
        "docs (AGENTS.md, CLAUDE.md, README.md, the skills, the top-level docs/*.md but DECISIONS.md) "
        "and in the comments of every .gd file under src/, tests/ and tools/. Given files, reads only "
        "those of them it covers.",
        epilog="example: uv run python tools/check_test_paths.py docs/EVENTS.md",
        allow_abbrev=False,
    )
    parser.add_argument("--root", type=Path, default=ROOT, help="the checkout to read (default: this one)")
    parser.add_argument("files", nargs="*", help="files to read, relative to the root (default: all it covers)")
    args = parser.parse_args(argv)
    root = args.root.resolve()
    missing = [rel for rel in args.files if not (root / rel).is_file()]
    if missing:
        for rel in missing:
            print(f"tools/check_test_paths.py: no such file: {rel}", file=sys.stderr)
        return 2
    failures = check(root, args.files or None)
    for failure in failures:
        print(failure)
    if failures:
        print(f"tools/check_test_paths.py: {len(failures)} failure(s)", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
