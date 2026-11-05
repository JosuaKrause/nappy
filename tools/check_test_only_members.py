#!/usr/bin/env python3
"""Fails when a test reads a public member of the game's code that nothing in the game reads.

A member only a test calls is state or a hook the game never reaches: a check on it holds nothing
the player can meet (inbox #1097). For every public member -- a `func`, `var`, `const` or `signal`
at the top level of a `.gd` file under `src/`, its name not starting with `_` -- this finds:

- **read by a test**: a file under `tests/` reads it as `.name`, in code (comments and string
  contents blanked first, as `check_layers.py` blanks them);
- **read by the game**: a word occurrence of the name in code in a file under `src/` that does not
  define a member of that name. A caller under `src/dev` (the rigs and the scene-recipe runtime are the
  composition root) counts, so does an assignment to it or an emit of it. A caller in the member's own
  defining file does not: a public member only its own class and the tests use is internal and gets
  the underscore, its tests going through what the class does outward (inbox #1098).

A member read by a test and by no other file under `src/` is test-only. Each is matched against
`tools/test_only_members.txt` (one `<file> <member>` per line), a list that only shrinks:

- a test-only member not on the list **fails**: give the game a reader, or test through what the game
  exposes, or (with the player's say) add the line;
- a listed member that now has a game reader, no longer has a test reading it, or no longer exists is
  printed as `REMOVE`, a line to delete from the list, and does **not** fail, so a pull request that
  deletes a member does not conflict with this one. Run with `--list` to print them all.

**Name collisions across classes.** A member is judged by its word, never by its class: a name defined
in two classes is test-only only when the word occurs in no file that does not define it, so a game
reader of either namesake hides the other. That can miss a test-only member, never accuse one falsely; the
item `docs/todo/2026-10-18-minty-quail/tests-unseen-reads.md` section 3, whose method this
reproduces, spot-checked its names by hand for the same reason. A name defined at two sites is
reported at each, and each is listed by its own file. Members of an inner class and a member read
only through a string (`get("name")`, `has_method("name")`, a scene's `.tscn`) are not seen.
`shared_state.gd` and `test_prediction_reuse.gd` read by reflection and are skipped, as the item
skipped them. `--rev` reads the tree of any commit instead of the checkout, and `--root` a checkout
elsewhere.
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_layers

ROOT = Path(__file__).resolve().parent.parent
ALLOWLIST = Path(__file__).resolve().parent / "test_only_members.txt"
SRC = "src"
TESTS = "tests"
# Read every field by reflection, so a `.name` in them is not a reader of one member.
SKIPPED_TESTS = frozenset({"tests/shared_state.gd", "tests/test_prediction_reuse.gd"})

# A top-level member: at the margin, after any annotations (`@export`, `@onready var`).
DEFINITION = re.compile(r"^(?:@\w+(?:\([^)]*\))?[ \t]+)*(?:static[ \t]+)?(func|var|const|signal)[ \t]+([A-Za-z]\w*)")
WORD = re.compile(r"\w+")

EPILOG = """\
examples:
  uv run python tools/check_test_only_members.py
  uv run python tools/check_test_only_members.py --list
  uv run python tools/check_test_only_members.py --rev origin/main
"""


class MembersError(Exception):
    """An input could not be read."""


@dataclass(frozen=True)
class Member:
    path: str
    line: int
    kind: str
    name: str

    @property
    def key(self) -> tuple[str, str]:
        return (self.path, self.name)


@dataclass(frozen=True)
class Reading:
    """The first test line reading a member as `.name`, and how many lines do."""

    path: str
    line: int
    count: int


@dataclass(frozen=True)
class Files:
    src: dict[str, str]
    tests: dict[str, str]


def members_of(path: str, text: str) -> list[Member]:
    bare = check_layers.blank(text).bare
    found: list[Member] = []
    for index, line in enumerate(bare.split("\n"), start=1):
        match = DEFINITION.match(line)
        if match and not match.group(2).startswith("_"):
            found.append(Member(path, index, match.group(1), match.group(2)))
    return found


def readings_of(tests: dict[str, str]) -> dict[str, Reading]:
    """For each name a test reads as `.name`, the first such line (by path, then line) and the line count."""
    first: dict[str, tuple[str, int]] = {}
    counts: Counter[str] = Counter()
    for path in sorted(tests):
        if path in SKIPPED_TESTS:
            continue
        bare = check_layers.blank(tests[path]).bare
        for index, line in enumerate(bare.split("\n"), start=1):
            for name in set(re.findall(r"\.\s*([A-Za-z]\w*)", line)):
                counts[name] += 1
                first.setdefault(name, (path, index))
    return {name: Reading(*first[name], count) for name, count in counts.items()}


def scan(files: Files) -> tuple[list[Member], dict[str, int], dict[str, int]]:
    """Every public member defined under `src/`, the word occurrences of each name in the files that do not
    define it, and those in the files that do (its definitions not counted)."""
    members: list[Member] = []
    words: dict[str, Counter[str]] = {}
    for path, text in sorted(files.src.items()):
        members.extend(members_of(path, text))
        words[path] = Counter(WORD.findall(check_layers.blank(text).bare))
    defining: dict[str, set[str]] = {}
    for member in members:
        defining.setdefault(member.name, set()).add(member.path)
    definitions = Counter(member.name for member in members)
    elsewhere: dict[str, int] = {}
    own: dict[str, int] = {}
    for name, paths in defining.items():
        elsewhere[name] = sum(count[name] for path, count in words.items() if path not in paths)
        own[name] = sum(words[path][name] for path in paths) - definitions[name]
    return members, elsewhere, own


def test_only(files: Files) -> tuple[list[Member], dict[str, Reading]]:
    """The members a test reads and no other word under `src/` does, with the readings of every name."""
    members, elsewhere, _ = scan(files)
    readings = readings_of(files.tests)
    return [m for m in members if elsewhere[m.name] == 0 and m.name in readings], readings


def listed(text: str) -> set[tuple[str, str]]:
    entries: set[tuple[str, str]] = set()
    for number, raw in enumerate(text.splitlines(), start=1):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) != 2:
            raise MembersError(f"{ALLOWLIST.name}:{number}: expected '<file> <member>', got {raw!r}")
        if (parts[0], parts[1]) in entries:
            raise MembersError(f"{ALLOWLIST.name}:{number}: {parts[0]} {parts[1]} is listed twice")
        entries.add((parts[0], parts[1]))
    return entries


def check(files: Files, allowed: set[tuple[str, str]]) -> tuple[list[str], list[str], list[Member]]:
    """The failures, the lines to remove from the list, and every test-only member."""
    only, readings = test_only(files)
    members, others, _ = scan(files)
    failures: list[str] = []
    for member in only:
        if member.key not in allowed:
            reading = readings[member.name]
            failures.append(
                f"{member.path}:{member.line}: {member.kind} {member.name} is read by tests "
                f"({reading.path}:{reading.line}, {reading.count} line(s)) and by no other file under "
                "src/; give the game a reader, or make it internal with an underscore and test through what the "
                "class does outward"
            )
    stale: list[str] = []
    defined = {member.key: member for member in members}
    standing = {member.key for member in only}
    for path, name in sorted(allowed):
        if (path, name) in standing:
            continue
        if (path, name) not in defined:
            why = "no longer defined"
        elif others[name] > 0:
            why = "now read by another file under src/"
        else:
            why = "no longer read by a test"
        stale.append(f"REMOVE from tools/{ALLOWLIST.name}: {path} {name} ({why})")
    return failures, stale, only


def read_checkout(root: Path) -> Files:
    def folder(name: str) -> dict[str, str]:
        return {
            path.relative_to(root).as_posix(): path.read_text(encoding="utf-8")
            for path in sorted((root / name).rglob("*.gd"))
        }

    return Files(src=folder(SRC), tests=folder(TESTS))


def read_rev(rev: str, root: Path = ROOT) -> Files:
    listing = check_layers.git("ls-tree", "-r", "-z", rev, "--", SRC, TESTS, cwd=root).decode()
    blobs: dict[str, str] = {}
    for record in listing.split("\0"):
        meta, _, path = record.partition("\t")
        if record and path.endswith(".gd"):
            blobs[path] = meta.split()[2]
    batch = check_layers.git(
        "cat-file", "--batch", cwd=root, data="".join(f"{blob}\n" for blob in blobs.values()).encode()
    )
    texts: dict[str, str] = {}
    position = 0
    for path in blobs:
        header_end = batch.index(b"\n", position)
        size = int(batch[position:header_end].split()[2])
        texts[path] = batch[header_end + 1 : header_end + 1 + size].decode("utf-8", errors="replace")
        position = header_end + 1 + size + 1
    return Files(
        src={p: t for p, t in texts.items() if p.startswith(SRC + "/")},
        tests={p: t for p, t in texts.items() if p.startswith(TESTS + "/")},
    )


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/check_test_only_members.py",
        description=(
            "Fails when a test reads a public func, var, const or signal defined under src/ that no other word under"
            " src/ names, unless tools/test_only_members.txt lists it; prints a listed member that now has a game"
            " reader, is no longer read by a test or is gone as a line to remove, without failing."
        ),
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--rev", default=None, help="read the tree of this commit instead of the checkout")
    source.add_argument("--root", type=Path, default=None, help="read the checkout at this path instead of this one")
    parser.add_argument(
        "--list", action="store_true", help="print every test-only member, listed or not, and every line to remove"
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse(argv)
    try:
        files = read_rev(args.rev) if args.rev else read_checkout(args.root or ROOT)
        allowed = listed(ALLOWLIST.read_text(encoding="utf-8") if ALLOWLIST.exists() else "")
        failures, stale, only = check(files, allowed)
    except (check_layers.LayerError, MembersError, OSError) as error:
        print(f"tools/check_test_only_members.py: {error}", file=sys.stderr)
        return 1
    if args.list:
        _, _, own = scan(files)
        for member in only:
            mark = "listed" if member.key in allowed else "NEW"
            group = "own file only" if own[member.name] else "no reader"
            print(f"{mark:6} {member.path}:{member.line}: {member.kind} {member.name} [{group}]")
        for line in stale:
            print(line)
        print(f"{len(only)} test-only member(s), {len(failures)} not listed, {len(stale)} line(s) to remove")
        return 0
    for line in stale:
        print(line)
    for failure in failures:
        print(f"FAILED: {failure}")
    if failures:
        print(f"tools/check_test_only_members.py: {len(failures)} failure(s)")
        return 1
    print(f"OK: no test reads a member the game does not; {len(only)} listed test-only member(s) still stand")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
