#!/usr/bin/env python3
"""Fails when a doc or a comment names a file under tests/ that does not exist.

A sentence that names a suite ("tests/test_blocks.gd asserts it") is a claim that a check stands
there. When the file is renamed, split or deleted, the sentence keeps its confident shape and
points at nothing, and nothing rereads it. This check holds every such name against the tree.

It reads:

- CLAUDE.md and README.md, every .md file under .claude/skills/ (at any depth), and the top-level
  docs/*.md, whole, code blocks included;
- the comments of every .gd file under src/, tests/ and tools/.

It does not read docs/decisions/, docs/playtests/, docs/todo/, docs/review/ or docs/evidence/
(a record, the player's words and open work may name a file that is gone or not written yet), nor
any .py or .sh file (their fixtures invent test names), nor the code of a .gd file.

**A comment in a .gd file** runs from a # that starts one to the end of its line, ## included. A
# inside a string literal starts none: the scan follows "..." and '...' strings with their
backslash escapes along the line, and a triple-quoted string from the line that opens it to the
line that closes it.

**A reference** is one of two shapes, read from a run of path characters (letters, digits and
_ . / -) with the emphasis asterisks round it and the sentence's own closing full stop taken off:

- a path that starts tests/ and ends in a file extension (EXTENSIONS below), such as
  tests/test_blocks.gd or tests/runner_fixtures/unparseable_suite.gd.src. A leading res://, ./ or
  ../ is read through, and a trailing .word that is no extension (a method named after the file) is
  dropped. The file is looked for at that path from the repository's root;
- a bare suite name test_<name>.gd with no folder before it, which is looked for by name at any
  depth under tests/.

**Not a reference:** a run with a placeholder or a glob in it (any of * < > { } %, as in
tests/test_zz_*.gd or test_<x>.gd); a path that starts anywhere else (tools/test_cli_help.sh,
src/x/test_y.gd); a folder (tests/probes/); a name without its extension (test_blocks).

**What it cannot see:** a suite named without .gd, as tools/test.sh takes it; a path given from
inside tests/ (probes/m64_density.gd); a list written with braces or a shared stem
(test_routes_closures_a.gd, _b and _c reads the first name only); a name inside an HTML tag; and
whether the file named still holds the check the sentence says it does.

This runs under the host's own python3 (tools/lint.sh calls it), so it stays 3.9-compatible.

  uv run python tools/check_test_paths.py
  uv run python tools/check_test_paths.py --root ../other-checkout
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SELF = "tools/check_test_paths.py"

# The governed docs read whole: these files, every .md under each folder of DOC_TREES at any
# depth, and the .md files directly inside each folder of DOC_FOLDERS.
DOC_FILES = ("CLAUDE.md", "README.md")
DOC_TREES = (".claude/skills",)
DOC_FOLDERS = ("docs",)
# The folders whose .gd files have their comments read.
CODE_TREES = ("src", "tests", "tools")
# What a path under tests/ may end in to be a file's name and not a folder's or a method's.
EXTENSIONS = frozenset(
    {"gd", "tscn", "py", "sh", "mjs", "json", "txt", "md", "src", "uid", "cfg", "tres", "png", "svg"}
)

PLACEHOLDERS = frozenset("*<>{}%")
TOKEN = re.compile(r"(?:res://)?[\w./\-*<>{}%]+", re.ASCII)
PREFIX = re.compile(r"^(?:res://)?(?:\.\.?/)*")
BARE_SUITE = re.compile(r"^(test_[\w\-]+\.gd)(?:\.\w+)*$", re.ASCII)
ADVICE = "name the suite that holds the check, or say that none does"


def comment_of(line: str, open_quote: str) -> tuple[str, str]:
    """The comment of one line of GDScript ('' when it has none), and the triple quote still open
    at the line's end ('' when none is). open_quote is the triple quote open at its start."""
    # No comment to find, and no triple quote to change what the next line is.
    if not open_quote and "#" not in line and '"""' not in line and "'''" not in line:
        return "", ""
    i = 0
    while i < len(line):
        if open_quote:
            end = line.find(open_quote, i)
            if end < 0:
                return "", open_quote
            i = end + 3
            open_quote = ""
        elif line.startswith(('"""', "'''"), i):
            open_quote = line[i : i + 3]
            i += 3
        elif line[i] in "\"'":
            quote = line[i]
            i += 1
            while i < len(line) and line[i] != quote:
                i += 2 if line[i] == "\\" else 1
            i += 1
        elif line[i] == "#":
            return line[i:], ""
        else:
            i += 1
    return "", open_quote


def references(text: str) -> list[tuple[str, bool]]:
    """Every reference in one line of prose: the name, and whether it is a bare suite name (looked
    for at any depth) and not a path from the root."""
    found: list[tuple[str, bool]] = []
    if "test" not in text:
        return found
    for match in TOKEN.finditer(text):
        token = match.group(0).lstrip("*").rstrip("*.-")
        token = PREFIX.sub("", token)
        if not token or PLACEHOLDERS.intersection(token):
            continue
        if token.startswith("tests/"):
            name = token
            while "." in name.rsplit("/", 1)[-1] and name.rsplit(".", 1)[-1] not in EXTENSIONS:
                name = name.rsplit(".", 1)[0]
            if "." in name.rsplit("/", 1)[-1]:
                found.append((name, False))
        elif "/" not in token:
            bare = BARE_SUITE.match(token)
            if bare:
                found.append((bare.group(1), True))
    return found


def prose_lines(root: Path) -> list[tuple[str, int, str]]:
    """Every line this check reads, as (path, line number, text): a doc's lines whole, and a .gd
    file's comments."""
    docs = [root / name for name in DOC_FILES]
    for tree in DOC_TREES:
        docs.extend(sorted((root / tree).rglob("*.md")))
    for folder in DOC_FOLDERS:
        docs.extend(sorted((root / folder).glob("*.md")))
    lines: list[tuple[str, int, str]] = []
    for path in docs:
        if not path.is_file():
            continue
        shown = path.relative_to(root).as_posix()
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            lines.append((shown, number, line))
    for tree in CODE_TREES:
        for path in sorted((root / tree).rglob("*.gd")):
            shown = path.relative_to(root).as_posix()
            open_quote = ""
            for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
                comment, open_quote = comment_of(line, open_quote)
                if comment:
                    lines.append((shown, number, comment))
    return lines


def check(root: Path) -> list[str]:
    tests = root / "tests"
    names = {path.name for path in tests.rglob("*") if path.is_file()} if tests.is_dir() else set()
    hits: list[str] = []
    for shown, number, text in prose_lines(root):
        for name, bare in references(text):
            if bare and name not in names:
                hits.append(f"{shown}:{number}: names {name}, and no file under tests/ has that name: {ADVICE}")
            elif not bare and not (root / name).is_file():
                hits.append(f"{shown}:{number}: names {name}, which does not exist: {ADVICE}")
    return hits


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Fail when a doc or a comment names a file under tests/ that does not exist. Reads CLAUDE.md,"
            " README.md, every .md under .claude/skills/, docs/*.md, and the comments of every .gd file"
            " under src/, tests/ and tools/ (a comment runs from a # that starts one to the end of the"
            " line; a # inside a string literal, triple-quoted ones included, starts none). A reference"
            " is a path starting tests/ that ends in a file extension, looked for from the root, or a"
            " bare test_<name>.gd, looked for at any depth under tests/. A name with a placeholder or a"
            " glob in it (* < > { } %) is not a reference. It does not read docs/decisions/,"
            " docs/playtests/, docs/todo/, docs/review/, docs/evidence/, or any .py or .sh file. Runs"
            " under the host's python3."
        ),
        epilog="example: uv run python tools/check_test_paths.py --root ../other-checkout",
    )
    parser.add_argument("--root", type=Path, default=ROOT, help="the checkout to read (default: this repository)")
    args = parser.parse_args(argv)
    try:
        hits = check(args.root)
    except (OSError, UnicodeDecodeError) as error:
        print(f"{SELF}: {error}", file=sys.stderr)
        return 1
    for hit in hits:
        print(hit)
    if hits:
        print(f"{SELF}: {len(hits)} name(s) of a tests/ file that does not exist")
        return 1
    print("OK: every tests/ file a doc or a comment names exists")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
