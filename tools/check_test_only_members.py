#!/usr/bin/env python3
"""Fails when a test reads a public member of the game's code that no other file of the game reads.

A member only a test calls is state or a hook the game never reaches: a check on it holds nothing
the player can meet (inbox #1097). For every public member -- a `func`, `var`, `const` or `signal`
at the top level of a `.gd` file under `src/`, its name not starting with `_` -- this finds:

- **read by a test**: a file under `tests/` calls a function as `.name(`, or reads a var, const or
  signal as `.name`, in code (comments and string contents blanked first, as `check_layers.py` blanks
  them). The names in `ENGINE_MEMBERS` (`enabled`, `size`, `text` and the like, which the engine's own
  classes carry and a test reads on a node it holds) are never taken as a read;
- **read by the game**: a word occurrence of the name in code in another file under `src/`, counting
  every other file's uses less its own definitions of the name. A caller under `src/dev` (the rigs and
  the scene-recipe runtime are the composition root) counts, so does an assignment to it or an emit of
  it. A use in the member's own defining file does not count (inbox #1098), and in that file only a use
  that is not a member of another object counts: a call `other.name()` on a namesake is not a use of
  this member, a plain `name` or `self.name` or the file's own `ClassName.name` is.

A member read by a test is test-only, and belongs to one of two groups of the list: **no reader**
(no use in its own file either; inbox #1095) or **own file only** (used by its own file, so
internal: it gets the underscore and its tests go through what the class does outward; inbox
#1098). The group, like the test, is a word count. The own-file rule applies to functions, vars and
signals, **not to constants**: the player's words on it are about functions, and a test reading a
constant to assert a relationship is what the testing policy wants, so a constant is test-only only
with no use anywhere under `src/`. Reaching vars, signals and the exemption of constants is a
proposal of the orchestrator, not asked for, open to the player's correction.

`tools/test_only_members.txt` (one `<file> <member>` per line, `#` for comments) lists the members
that stand, in groups: no reader, own file only, and **kept**: a member that stays public, each line
carrying its reason after a `#` (the player's exception: the information cannot be had another way
and the test needs it to confirm the behavior, inbox #1095; a hand-in; a member the check misreads).
Every group but the kept one only shrinks, and the check enforces it both ways:

- a test-only member not on the list **fails**: give the game a reader, or test through what the
  class does outward, or (a kept member, with its reason) add the line to the kept group;
- a listed member that now has a reader in another file, no longer has a test reading it, or no
  longer exists **fails** too, as a `REMOVE` line to delete from the list, so a stale line cannot
  re-admit a member later. A pull request that deletes or fixes a member deletes its line; one open
  beside it merges `main` and deletes its own lines.

**What it can miss and where it can accuse falsely.** A member is judged by its word, never by its
class; `docs/todo/2026-10-18-minty-quail/tests-unseen-reads.md` section 3, whose method this
reproduces, spot-checked names by hand for the same reason. It can *miss* a test-only member when an
unrelated word of the same name is used in another file (a namesake, a local, a parameter) or is one
of `ENGINE_MEMBERS`, when a function is passed as a callable (`.name`) rather than called, and it
does not see members of an inner class. It can *accuse falsely* in three ways: a test calling `.name`
on its own fake (an inner class of the test with a method of that name) reads as a test reading the
member; a test reading an engine member of the same name that `ENGINE_MEMBERS` does not list (a
`.size` on a Control, a `.enabled` on a camera) does too, and a function is told apart only by the
call parenthesis; and a game reader that goes through a string (`call("name")`, `has_method("name")`,
`Callable(self, "name")`, a scene's `.tscn`) is blanked out and not seen. On such a false failure the
builder adds the line to the kept group with the reason as a comment (or the engine's name to
`ENGINE_MEMBERS`). `shared_state.gd` and `test_prediction_reuse.gd` read by reflection and are
skipped, as the item skipped them. `--rev` and `--root` read the tree of that commit or checkout,
and the list file of that same tree.
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
ALLOWLIST_NAME = "test_only_members.txt"
ALLOWLIST = f"tools/{ALLOWLIST_NAME}"
SRC = "src"
TESTS = "tests"
# Read every field by reflection, so a `.name` in them is not a reader of one member.
SKIPPED_TESTS = frozenset({"tests/shared_state.gd", "tests/test_prediction_reuse.gd"})

# A top-level member: at the margin, after any annotations (`@export`, `@onready var`).
DEFINITION = re.compile(r"^(?:@\w+(?:\([^)]*\))?[ \t]+)*(?:static[ \t]+)?(func|var|const|signal)[ \t]+([A-Za-z]\w*)")
WORD = re.compile(r"\w+")
READ = re.compile(r"\.\s*([A-Za-z]\w*)")
CALL = re.compile(r"\.\s*([A-Za-z]\w*)\s*\(")
# A word used in its own file other than as a member of another object: not after a `.`; `self.name` and the
# file's own `ClassName.name` are added where the file is read.
OWN_USE = re.compile(r"(?<![\w.])(\w+)")
# Names the engine's own classes carry, which a test reads on a node it holds (`camera.enabled`, a
# Control's `.size`): a `.name` read of these is taken as the engine's, never as the game's member.
ENGINE_MEMBERS: frozenset[str] = frozenset(
    {
        "color",
        "enabled",
        "modulate",
        "name",
        "offset",
        "position",
        "rotation",
        "scale",
        "size",
        "text",
        "texture",
        "value",
        "visible",
        "zoom",
    }
)

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
class Readings:
    """The names a test reads as `.name` (the first line and the count), and those it calls as `.name(`."""

    reads: dict[str, Reading]
    calls: frozenset[str]


@dataclass(frozen=True)
class Files:
    src: dict[str, str]
    tests: dict[str, str]
    allowlist: str = ""


def members_of(path: str, text: str) -> list[Member]:
    bare = check_layers.blank(text).bare
    found: list[Member] = []
    for index, line in enumerate(bare.split("\n"), start=1):
        match = DEFINITION.match(line)
        if match and not match.group(2).startswith("_"):
            found.append(Member(path, index, match.group(1), match.group(2)))
    return found


def readings_of(tests: dict[str, str]) -> Readings:
    """For each name a test reads as `.name`, the first such line (by path, then line) and the line count."""
    first: dict[str, tuple[str, int]] = {}
    counts: Counter[str] = Counter()
    calls: set[str] = set()
    for path in sorted(tests):
        if path in SKIPPED_TESTS:
            continue
        bare = check_layers.blank(tests[path]).bare
        for index, line in enumerate(bare.split("\n"), start=1):
            for name in set(READ.findall(line)):
                counts[name] += 1
                first.setdefault(name, (path, index))
            calls.update(CALL.findall(line))
    return Readings({name: Reading(*first[name], count) for name, count in counts.items()}, frozenset(calls))


@dataclass(frozen=True)
class Stand:
    """What a member stands on: word uses in the other files of `src/`, and uses in its own file other than as
    a member of another object (`other.name` is a call on a namesake, not a use of this member)."""

    elsewhere: int
    own: int


def scan(files: Files) -> tuple[list[Member], dict[tuple[str, str], Stand]]:
    """Every public member defined under `src/`, with the uses of its name in every other file (each file's
    count less its own definitions of the name) and in its own file (less its definitions there)."""
    members: list[Member] = []
    words: dict[str, Counter[str]] = {}
    own_words: dict[str, Counter[str]] = {}
    defined: dict[str, Counter[str]] = {}
    for path, text in sorted(files.src.items()):
        found = members_of(path, text)
        members.extend(found)
        bare = check_layers.blank(text).bare
        words[path] = Counter(WORD.findall(bare))
        own = Counter(OWN_USE.findall(bare))
        class_name = check_layers.CLASS_NAME.search(bare)
        qualifier = rf"(?<![\w.])(?:self{'|' + re.escape(class_name.group(1)) if class_name else ''})\s*\.\s*(\w+)"
        own.update(re.findall(qualifier, bare))
        own_words[path] = own
        defined[path] = Counter(member.name for member in found)
    uses = {path: {name: words[path][name] - defined[path][name] for name in defined[path]} for path in words}
    own_uses = {path: {name: own_words[path][name] - defined[path][name] for name in defined[path]} for path in words}
    totals: Counter[str] = Counter()
    for path in words:
        totals.update({name: words[path][name] - defined[path][name] for name in {m.name for m in members}})
    stands = {
        member.key: Stand(
            elsewhere=totals[member.name] - uses[member.path][member.name], own=own_uses[member.path][member.name]
        )
        for member in members
    }
    return members, stands


def is_test_only(member: Member, stand: Stand, readings: Readings) -> bool:
    """Read by a test and by no other file; a function is read as a call, a constant also needs no use in its own
    file, and a name the engine's classes carry is never taken as read."""
    if member.name in ENGINE_MEMBERS or stand.elsewhere > 0:
        return False
    if member.kind == "func" and member.name not in readings.calls:
        return False
    if member.name not in readings.reads:
        return False
    return stand.own == 0 or member.kind != "const"


def group_of(stand: Stand) -> str:
    return "own file only" if stand.own else "no reader"


def test_only(files: Files) -> tuple[list[Member], Readings]:
    """The test-only members, with the readings of every name a test reads."""
    members, stands = scan(files)
    readings = readings_of(files.tests)
    return [m for m in members if is_test_only(m, stands[m.key], readings)], readings


def listed(text: str) -> set[tuple[str, str]]:
    entries: set[tuple[str, str]] = set()
    for number, raw in enumerate(text.splitlines(), start=1):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) != 2:
            raise MembersError(f"{ALLOWLIST_NAME}:{number}: expected '<file> <member>', got {raw!r}")
        if (parts[0], parts[1]) in entries:
            raise MembersError(f"{ALLOWLIST_NAME}:{number}: {parts[0]} {parts[1]} is listed twice")
        entries.add((parts[0], parts[1]))
    return entries


def check(files: Files, allowed: set[tuple[str, str]]) -> tuple[list[str], list[Member]]:
    """The failures (a test-only member not listed, a listed line gone stale) and every test-only member."""
    members, stands = scan(files)
    readings = readings_of(files.tests)
    only = [m for m in members if is_test_only(m, stands[m.key], readings)]
    failures: list[str] = []
    for member in only:
        if member.key not in allowed:
            reading = readings.reads[member.name]
            failures.append(
                f"{member.path}:{member.line}: {member.kind} {member.name} is read by tests "
                f"({reading.path}:{reading.line}, {reading.count} line(s)) and by no other file under "
                "src/; give the game a reader, or make it internal with an underscore and test through what the "
                "class does outward"
            )
    defined = {member.key for member in members}
    standing = {member.key for member in only}
    for path, name in sorted(allowed):
        if (path, name) in standing:
            continue
        if (path, name) not in defined:
            why = "no longer defined"
        elif stands[(path, name)].elsewhere > 0:
            why = "now read by another file under src/"
        else:
            why = "no longer read by a test"
        failures.append(f"REMOVE from tools/{ALLOWLIST_NAME}: {path} {name} ({why})")
    return failures, only


def read_checkout(root: Path) -> Files:
    def folder(name: str) -> dict[str, str]:
        return {
            path.relative_to(root).as_posix(): path.read_text(encoding="utf-8")
            for path in sorted((root / name).rglob("*.gd"))
        }

    listing = root / ALLOWLIST
    return Files(
        src=folder(SRC),
        tests=folder(TESTS),
        allowlist=listing.read_text(encoding="utf-8") if listing.exists() else "",
    )


def read_rev(rev: str, root: Path = ROOT) -> Files:
    listing = check_layers.git("ls-tree", "-r", "-z", rev, "--", SRC, TESTS, ALLOWLIST, cwd=root).decode()
    blobs: dict[str, str] = {}
    for record in listing.split("\0"):
        meta, _, path = record.partition("\t")
        if record and (path.endswith(".gd") or path == ALLOWLIST):
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
        allowlist=texts.get(ALLOWLIST, ""),
    )


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/check_test_only_members.py",
        description=(
            "Fails when a test reads a public func, var, const or signal defined under src/ that no other word under"
            " src/ names, unless tools/test_only_members.txt lists it, and fails on a listed line that has gone"
            " stale (the member has a reader in another file, no test reads it, or it is gone). A caller in the"
            " member's own file is not a reader; constants are exempt unless used nowhere."
        ),
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    source = parser.add_mutually_exclusive_group()
    source.add_argument(
        "--rev", default=None, help="read the tree of this commit, and its list, instead of the checkout"
    )
    source.add_argument(
        "--root", type=Path, default=None, help="read the checkout at this path, and its list, instead of this one"
    )
    parser.add_argument(
        "--list", action="store_true", help="print every test-only member, listed or not, and every line to remove"
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse(argv)
    try:
        files = read_rev(args.rev) if args.rev else read_checkout(args.root or ROOT)
        allowed = listed(files.allowlist)
        failures, only = check(files, allowed)
        _, stands = scan(files)
    except (check_layers.LayerError, MembersError, OSError) as error:
        print(f"tools/check_test_only_members.py: {error}", file=sys.stderr)
        return 1
    if args.list:
        for member in only:
            mark = "listed" if member.key in allowed else "NEW"
            print(f"{mark:6} {member.path}:{member.line}: {member.kind} {member.name} [{group_of(stands[member.key])}]")
        for line in failures:
            if line.startswith("REMOVE"):
                print(line)
        print(f"{len(only)} test-only member(s), {len(failures)} failure(s)")
        return 0
    for failure in failures:
        print(failure if failure.startswith("REMOVE") else f"FAILED: {failure}")
    if failures:
        print(f"tools/check_test_only_members.py: {len(failures)} failure(s)")
        return 1
    print(f"OK: no test reads a member the game does not; {len(only)} listed test-only member(s) still stand")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
