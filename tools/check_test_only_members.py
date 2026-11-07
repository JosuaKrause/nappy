#!/usr/bin/env python3
"""Fails when a test reads a public member of the game's code that no other file of the game reads.

A member only a test calls is state or a hook the game never reaches: a check on it holds nothing
the player can meet (inbox #1097 in curly-rabbit). For every public member -- a `func`, `var`, `const` or `signal`
at the top level of a `.gd` file under `src/`, its name not starting with `_` -- this finds:

- **read by a test**: a file under `tests/` calls a function as `.name(`, or reads a var, const or
  signal as `.name`, in code (comments and string contents blanked first, as `check_layers.py` blanks
  them). The names in `ENGINE_MEMBERS` (`enabled`, `size`, `text` and the like, which the engine's own
  classes carry and a test reads on a node it holds) are never taken as a read;
- **read by the game**: a word occurrence of the name in code in another file under `src/`, counting
  every other file's uses less its own definitions of the name. A caller under `src/dev` (the rigs and
  the scene-recipe runtime are the composition root) counts, so does an assignment to it or an emit of
  it. A use in the member's own defining file does not count (inbox #1098 in curly-rabbit), and in that file only a use
  that is not a member of another object counts: a call `other.name()` on a namesake is not a use of
  this member, a plain `name` or `self.name` or the file's own `ClassName.name` is.

A member read by a test is test-only, and belongs to one of two groups of the list: **no reader**
(no use in its own file either; inbox #1095 in curly-rabbit) or **own file only** (used by its own file, so
internal: it gets the underscore and its tests go through what the class does outward; inbox
#1098). The group, like the test, is a word count. The own-file rule applies to functions, vars and
signals, **not to constants**: the player's words on it are about functions, and a test reading a
constant to assert a relationship is what the testing policy wants, so a constant used in its own file is
exempt and one is test-only only with no use anywhere under `src/`. Reaching vars, signals and the exemption
of constants is a proposal of the orchestrator, not asked for, open to the player's correction.

`tools/test_only_members.txt` (one `<file> <member>` per line, `#` for a reason or a comment) lists the
members that stand, in groups, each opened by a header comment whose first word is its tag: `# [no reader]`,
`# [own file only]`, and any number of `# [kept]` (a member that stays public, each line carrying its reason
after a `#`: the player's exception, the information cannot be had another way and the test needs it to
confirm the behavior, inbox #1095 in curly-rabbit, or nothing outside can confirm what the function does,
inbox #1098 in curly-rabbit; a hand-in; a member the check misreads). The check enforces:

- a test-only member not on the list **fails**: give the game a reader, or test through what the
  class does outward, or (a kept member, with its reason) add the line to a kept group;
- a listed member that now has a reader in another file, no longer has a test reading it (or is a constant
  or an engine name, which are exempt), or no longer exists **fails** too, as a `REMOVE` line to delete from
  the list, so a stale line cannot re-admit a member later. A pull request that deletes or fixes a member
  deletes its line; one open beside it merges `main` and deletes its own lines;
- a `[kept]` line with no reason after its `#` **fails**;
- with `--base REV`, a line in the `[no reader]` or `[own file only]` group that `REV`'s list did not hold in
  either of them **fails**: those two groups only shrink, unless the same diff changes this checker (a better
  checker surfaces members the old one could not see). CI passes the pull request's base commit, and on a
  push to `main` the commit before it, so a builder cannot answer the check's failure by listing the
  member (only a kept line, with its reason, is added, and review reads the reason), unless the diff changes this
  checker, when review runs the base's checker on the head tree and reads each added line as a member it saw as read
  elsewhere. A line that moves with its
  member passes: an added line passes when a line of the same group that the pull request removes has the
  same member name and git reports the file as renamed from the removed line's file to the added line's file in the
  same diff (a file move carries its lines, each removed line pairing with one added line; a renamed member is
  fixed or kept, not carried). A `REV` without the list yet compares nothing.

**A name more than one file defines** (`CarStrategy.speed_range` and `WalkerStrategy.speed_range`) is judged by its
class, so another class's own uses do not hide it. A `.name` is qualified by its receiver where the file shows the
receiver's type: a name declared `x: Foo` or built `x := Foo.new()` (one class for the name in the file; `x: Foo.Inner`
and a one-line `if c: Foo.f()` declare nothing), `self`, or a `ClassName.name` static use. A reader typed as the
member's class, a class it extends or a class that extends it reaches it (a call dispatches on the object, so a reader
typed as the base reaches the override); one typed as another src class does not; one not typed (a call result, a
chain `a.b.name`, an autoload, an untyped parameter) reaches every class with the name, in the game's files and the
tests' alike. In a file that defines the name too, only such a `.name` counts, a plain use being that file's own
member, except in an ancestor's file, where a plain use is a call the override answers (a template method). A `[kept]`
line for such a member stands while every use of it elsewhere is untyped (the check cannot tell whose it is, and the
line says it is not the game's) and is a `REMOVE` line once a typed reader reads it. A name defined once is judged by
its word as before, which hides `ParkCordon.gap` (other files have a local `gap`) and `RouteTree.grow` (`Rect2.grow`
calls): a plain word in another file counts as a read, a local or an engine method of the name included. A
declaration is taken for the whole file, not per function, so a name typed in one function and rebound untyped in
another carries the first type.

**What it can miss and where it can accuse falsely.** A name defined once is judged by its word, never by its
class; `docs/todo/2026-10-18-minty-quail/tests-unseen-reads.md` section 3, whose method this
reproduces for a name defined once, spot-checked names by hand for the same reason. It can *miss* a test-only
member when an unrelated word of the same name is used in another file (a namesake, a local, a parameter) or is one
of `ENGINE_MEMBERS`, when a function is passed as a callable (`.name`) rather than called, and it
does not see members of an inner class. A base class's plain call of the name reads a subclass's override, so an
override whose subclass also overrides the base method that makes the call, without calling `super`, is read by
that plain call although the game never reaches it. Because the own-file count is a word count, a call `.name(` on a
namesake is not an own use either, so a member only that call and a test use lands in `[no reader]` although its
own class does call it (a call on another instance of the file's own class, `other.name()`); the remedy is then
the underscore of inbox #1098 (it is not dead code), not deleting it. It can *accuse falsely* in three ways:
a test calling `.name`
on its own fake (an inner class of the test with a method of that name) reads as a test reading the
member; a test reading an engine member of the same name that `ENGINE_MEMBERS` does not list (a
`.size` on a Control, a `.enabled` on a camera) does too, and a function is told apart only by the
call parenthesis; and a game reader that goes through a string (`call("name")`, `has_method("name")`,
`Callable(self, "name")`, a scene's `.tscn`) is blanked out and not seen. On such a false failure the
builder adds the line to a kept group with the reason as a comment (a member name an engine class carries,
which a test reads on an engine node it holds, is the only reason to add to `ENGINE_MEMBERS`; never a way to
exempt a game member).
`shared_state.gd` and `test_prediction_reuse.gd` read by reflection and are skipped, as the item skipped
them. `--rev` and `--root` read the tree of that commit or checkout, and the list file of that same tree. A local
`--base` run on a branch that is behind a checker change on main sees that change reversed (the diff to the base shows
it reversed, which counts as a change of the checker, so additions to the shrinking groups pass); merge main first.
"""

from __future__ import annotations

import argparse
import functools
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
GROUP_TAG = re.compile(r"^#\s*\[([a-z ]+)\]")
KEPT = "kept"
GROUPS = frozenset({"no reader", "own file only", KEPT})
# A `.name` use, and whether a call parenthesis follows.
USE = re.compile(r"\.\s*([A-Za-z]\w*)(\s*\()?")
# The word right before a dot, not itself a member of something (`a.b.name` has no known receiver).
RECEIVER = re.compile(r"(?<![\w.])(\w+)$")
# A name typed where it is declared (`var x: Foo`, a parameter, a `for x: Foo in`) or built (`x := Foo.new()`).
TYPED = re.compile(r"\b(\w+)\s*:\s*([A-Z]\w*)\b(?!\s*\.)")
BUILT = re.compile(r"\b(\w+)\s*:?=\s*([A-Z]\w*)\s*\.\s*new\s*\(")
EXTENDS = re.compile(r"^extends[ \t]+(\w+)", re.MULTILINE)
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
class Use:
    """One `.name` in a file: its line, the class its receiver is known to be (None when the receiver is not
    typed where the file shows it), and whether a call parenthesis follows."""

    path: str
    line: int
    klass: str | None
    call: bool


@dataclass(frozen=True)
class World:
    """What qualifies a member by its class: each `class_name` and what it extends, the class of each file, and the
    names that more than one file defines as a public member (the only names a reader's type is asked about)."""

    extends: dict[str, str | None]
    class_of: dict[str, str | None]
    colliding: frozenset[str]

    def ancestors(self, klass: str) -> list[str]:
        """`klass` and every class it extends, nearest first."""
        chain: list[str] = []
        current: str | None = klass
        while current and current not in chain:
            chain.append(current)
            current = self.extends.get(current)
        return chain

    def hits(self, klass: str | None, path: str) -> bool:
        """Whether a reader of static type `klass` can reach the member defined in `path`: an unknown type can;
        a known one can when it is that file's class, extends it, or is extended by it (a reader typed as the
        base reaches the override, since a call dispatches on the object)."""
        if klass is None:
            return True
        mine = self.class_of.get(path)
        return mine is not None and (mine in self.ancestors(klass) or klass in self.ancestors(mine))

    def is_ancestor_file(self, path: str, of: str) -> bool:
        """Whether the class defined in `path` is a proper ancestor of the class defined in `of`."""
        mine, theirs = self.class_of.get(path), self.class_of.get(of)
        return mine is not None and theirs is not None and mine in self.ancestors(theirs)[1:]


@dataclass(frozen=True)
class Readings:
    """Every `.name` use in the tests by name. A name that more than one file defines is read by a member only
    through the uses whose receiver can be its class (`World.hits`)."""

    uses: dict[str, tuple[Use, ...]]
    world: World

    def of(self, member: Member) -> tuple[Reading | None, bool]:
        """The first test line reading `member` as `.name` and how many lines do, and whether one calls it."""
        uses = self.uses.get(member.name, ())
        if member.name in self.world.colliding:
            uses = tuple(u for u in uses if self.world.hits(u.klass, member.path))
        if not uses:
            return None, False
        lines = sorted({(u.path, u.line) for u in uses})
        return Reading(*lines[0], len(lines)), any(u.call for u in uses)


@dataclass(frozen=True)
class Files:
    src: dict[str, str]
    tests: dict[str, str]
    allowlist: str = ""


def members_of(path: str, text: str) -> list[Member]:
    bare = bare_of(text)
    found: list[Member] = []
    for index, line in enumerate(bare.split("\n"), start=1):
        match = DEFINITION.match(line)
        if match and not match.group(2).startswith("_"):
            found.append(Member(path, index, match.group(1), match.group(2)))
    return found


@functools.cache
def bare_of(text: str) -> str:
    return check_layers.blank(text).bare


def world_of(src: dict[str, str]) -> World:
    extends: dict[str, str | None] = {}
    class_of: dict[str, str | None] = {}
    defining: Counter[str] = Counter()
    for path, text in src.items():
        bare = bare_of(text)
        named = check_layers.CLASS_NAME.search(bare)
        class_of[path] = named.group(1) if named else None
        if named:
            parent = EXTENDS.search(bare)
            extends[named.group(1)] = parent.group(1) if parent else None
        defining.update({m.name for m in members_of(path, text)})
    return World(extends, class_of, frozenset(name for name, count in defining.items() if count > 1))


def declared_types(bare: str) -> dict[str, set[str]]:
    declared: dict[str, set[str]] = {}
    for pattern in (TYPED, BUILT):
        for name, klass in pattern.findall(bare):
            declared.setdefault(name, set()).add(klass)
    return declared


def uses_of(path: str, text: str, world: World) -> list[tuple[int, str, Use]]:
    """Every `.name` use in a file, the class of its receiver where a typed name, `self` or a `ClassName` shows it."""
    bare = bare_of(text)
    own = world.class_of.get(path)
    found: list[tuple[int, str, Use]] = []
    declared = declared_types(bare) if any(name in bare for name in world.colliding) else {}
    for index, line in enumerate(bare.split("\n"), start=1):
        if "." not in line:
            continue
        for match in USE.finditer(line):
            if match.group(1) not in world.colliding:
                found.append((index, match.group(1), Use(path, index, None, bool(match.group(2)))))
                continue
            receiver = RECEIVER.search(line[: match.start()].rstrip())
            klass: str | None = None
            if receiver:
                word = receiver.group(1)
                if word == "self":
                    klass = own
                elif word in world.extends:
                    klass = word
                elif len(declared.get(word, ())) == 1:
                    (typed,) = declared[word]
                    klass = typed if typed in world.extends else None
            found.append((index, match.group(1), Use(path, index, klass, bool(match.group(2)))))
    return found


def readings_of(tests: dict[str, str], world: World) -> Readings:
    """For each name a test reads as `.name`, its uses (a test's own `self` is no known class)."""
    uses: dict[str, list[Use]] = {}
    for path in sorted(tests):
        if path in SKIPPED_TESTS:
            continue
        for _, name, use in uses_of(path, tests[path], world):
            uses.setdefault(name, []).append(use)
    return Readings({name: tuple(found) for name, found in uses.items()}, world)


@dataclass(frozen=True)
class Stand:
    """What a member stands on: word uses in the other files of `src/`, and uses in its own file other than as
    a member of another object (`other.name` is a call on a namesake, not a use of this member)."""

    elsewhere: int
    own: int
    unsure: int = 0  # of `elsewhere`, the `.name` uses whose receiver is not typed, so may be another class's


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
        bare = bare_of(text)
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
    world = world_of(files.src)
    dotted: dict[str, dict[str, list[str | None]]] = {path: {} for path in words}
    for path in words:
        for _, name, use in uses_of(path, files.src[path], world):
            if name in world.colliding:
                dotted[path].setdefault(name, []).append(use.klass)
    stands: dict[tuple[str, str], Stand] = {}
    for member in members:
        own_count = own_uses[member.path][member.name]
        if member.name not in world.colliding:
            elsewhere = totals[member.name] - uses[member.path][member.name]
            stands[member.key] = Stand(elsewhere=elsewhere, own=own_count)
            continue
        # A name more than one file defines: in a file that defines it too, a plain use is that file's own member,
        # and only a `.name` whose receiver can be this class counts (a plain use in an ancestor's file counts too:
        # it is a call the override answers); elsewhere a `.name` on a known other class is taken off the word
        # count. A receiver not typed counts, and is counted as unsure.
        elsewhere = unsure = 0
        for path in words:
            if path == member.path:
                continue
            dots = dotted[path].get(member.name, [])
            reaching = [klass for klass in dots if world.hits(klass, member.path)]
            unsure += sum(1 for klass in reaching if klass is None)
            if member.name in defined[path]:
                elsewhere += len(reaching)
                if world.is_ancestor_file(path, member.path):
                    # A plain use in an ancestor's own file dispatches to this override (a template method).
                    elsewhere += own_uses[path][member.name]
            else:
                elsewhere += words[path][member.name] - (len(dots) - len(reaching))
        stands[member.key] = Stand(elsewhere=elsewhere, own=own_count, unsure=unsure)
    return members, stands


def is_test_only(member: Member, stand: Stand, readings: Readings) -> bool:
    """Read by a test and by no other file; a function is read as a call, a constant also needs no use in its own
    file, and a name the engine's classes carry is never taken as read."""
    if member.name in ENGINE_MEMBERS or stand.elsewhere > 0:
        return False
    reading, called = readings.of(member)
    if reading is None or (member.kind == "func" and not called):
        return False
    return stand.own == 0 or member.kind != "const"


def group_of(stand: Stand) -> str:
    return "own file only" if stand.own else "no reader"


def test_only(files: Files) -> tuple[list[Member], Readings]:
    """The test-only members, with the readings of every name a test reads."""
    members, stands = scan(files)
    readings = readings_of(files.tests, world_of(files.src))
    return [m for m in members if is_test_only(m, stands[m.key], readings)], readings


@dataclass(frozen=True)
class Entry:
    """One `<file> <member>` line of the list, the group its header put it in, and the reason after its `#`."""

    path: str
    name: str
    group: str
    reason: str
    number: int

    @property
    def key(self) -> tuple[str, str]:
        return (self.path, self.name)


def entries_of(text: str) -> list[Entry]:
    """The lines of the list. A comment line starting `# [group]` opens a group (`no reader`, `own file only` or
    `kept`) that the lines under it belong to; a line before the first one, or under an unknown one, is an error."""
    entries: list[Entry] = []
    seen: set[tuple[str, str]] = set()
    group = ""
    for number, raw in enumerate(text.splitlines(), start=1):
        tag = GROUP_TAG.match(raw.strip())
        if tag:
            group = tag.group(1)
            if group not in GROUPS:
                raise MembersError(
                    f"{ALLOWLIST_NAME}:{number}: unknown group [{group}]; expected one of {sorted(GROUPS)}"
                )
            continue
        body, _, reason = raw.partition("#")
        if not body.strip():
            continue
        parts = body.split()
        if len(parts) != 2:
            raise MembersError(f"{ALLOWLIST_NAME}:{number}: expected '<file> <member>', got {raw!r}")
        if not group:
            raise MembersError(
                f"{ALLOWLIST_NAME}:{number}: {parts[0]} {parts[1]} is above the first '# [group]' header"
            )
        if (parts[0], parts[1]) in seen:
            raise MembersError(f"{ALLOWLIST_NAME}:{number}: {parts[0]} {parts[1]} is listed twice")
        seen.add((parts[0], parts[1]))
        entries.append(Entry(parts[0], parts[1], group, reason.strip(), number))
    return entries


def listed(text: str) -> set[tuple[str, str]]:
    return {entry.key for entry in entries_of(text)}


def list_failures(
    entries: list[Entry],
    base: list[Entry] | None,
    renames: dict[str, str] | None = None,
    checker_changed: bool = False,
) -> list[str]:
    """What the list's own lines fail: a kept line with no reason, and, against the base's list, a line added to
    the no reader or own file only group (those only shrink). A line in a shrinking group that the base's list
    held in either of them is not an addition, so a member that moves from one to the other is not one; nor is
    one that moves with its file: `renames` maps a path git reports as renamed to its new path, and an added line
    pairs with one removed line of the same group with the same member name in the old path, each removed line
    with at most one added line. A diff that also changes this checker (`checker_changed`) may add lines to the
    two shrinking groups: a better checker surfaces members the old one could not see."""
    failures = [
        f"{ALLOWLIST_NAME}:{e.number}: {e.path} {e.name} is in a kept group with no reason after a '#'"
        for e in entries
        if e.group == KEPT and not e.reason
    ]
    if base is not None and not checker_changed:
        before = {e.key for e in base if e.group != KEPT}
        now = {e.key for e in entries}
        gone = [e for e in base if e.group != KEPT and e.key not in now]
        paired: set[tuple[str, str]] = set()

        def moved(e: Entry) -> bool:
            for g in gone:
                if (
                    g.key not in paired
                    and g.group == e.group
                    and g.name == e.name
                    and (renames or {}).get(g.path) == e.path
                ):
                    paired.add(g.key)
                    return True
            return False

        failures.extend(
            f"{ALLOWLIST_NAME}:{e.number}: {e.path} {e.name} is added to the [{e.group}] group, which only shrinks; "
            "give the game a reader, or test through what the class does outward, or, where it must stay public, "
            "put the line in a kept group with its reason"
            for e in entries
            if e.group != KEPT and e.key not in before and not moved(e)
        )
    return failures


def check(
    files: Files,
    allowed: set[tuple[str, str]],
    kept: frozenset[tuple[str, str]] = frozenset(),
    scanned: tuple[list[Member], dict[tuple[str, str], Stand]] | None = None,
) -> tuple[list[str], list[Member]]:
    """The failures (a test-only member not listed, a listed line gone stale) and every test-only member. A listed
    line in `kept` for a name more than one file defines stands while every other use of it is a `.name` whose
    receiver is not typed: the check cannot tell whose it is, and the line says it is not the game's."""
    members, stands = scanned or scan(files)
    readings = readings_of(files.tests, world_of(files.src))
    only = [m for m in members if is_test_only(m, stands[m.key], readings)]
    failures: list[str] = []
    for member in only:
        if member.key not in allowed:
            reading, _ = readings.of(member)
            assert reading is not None
            failures.append(
                f"{member.path}:{member.line}: {member.kind} {member.name} is read by tests "
                f"({reading.path}:{reading.line}, {reading.count} line(s)) and by no other file under "
                "src/; give the game a reader, or make it internal with an underscore and test through what the "
                "class does outward"
            )
    standing = {member.key for member in only}
    for path, name in sorted(allowed):
        if (path, name) in standing:
            continue
        listed_member = next((m for m in members if m.key == (path, name)), None)
        if listed_member is None:
            why = "no longer defined"
        elif stands[(path, name)].elsewhere > 0:
            if (
                (path, name) in kept
                and stands[(path, name)].elsewhere == stands[(path, name)].unsure
                and readings.of(listed_member)[0] is not None
            ):
                continue
            why = "now read by another file under src/"
        elif name in ENGINE_MEMBERS:
            why = f"{name} is an engine member name in ENGINE_MEMBERS, never taken as a read"
        elif listed_member.kind == "const" and stands[(path, name)].own > 0:
            why = "a constant used in its own file is exempt"
        elif listed_member.kind == "func" and readings.of(listed_member)[0] and not readings.of(listed_member)[1]:
            why = "no test calls it, only reads or passes it"
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


def read_base(rev: str, cwd: Path) -> list[Entry] | None:
    """The list as `rev` held it, or None when `rev` has no list yet (the check is not on that commit)."""
    check_layers.git("rev-parse", "--verify", "--quiet", f"{rev}^{{commit}}", cwd=cwd)
    if not check_layers.git("ls-tree", "--name-only", rev, "--", ALLOWLIST, cwd=cwd).strip():
        return None
    return entries_of(check_layers.git("show", f"{rev}:{ALLOWLIST}", cwd=cwd).decode("utf-8"))


def read_renames(base: str, cwd: Path, rev: str | None = None) -> dict[str, str]:
    """The files git reports as renamed (old path to new) from `base` to `rev`, or to the checkout."""
    args = ["diff", "--find-renames", "--name-status", "-z", base] + ([rev] if rev else [])
    fields = check_layers.git(*args, cwd=cwd).decode("utf-8").split("\0")
    renames: dict[str, str] = {}
    position = 0
    while position < len(fields) and fields[position]:
        status = fields[position]
        if status.startswith(("R", "C")) and position + 2 < len(fields):
            if status.startswith("R"):
                renames[fields[position + 1]] = fields[position + 2]
            position += 3
        else:
            position += 2
    return renames


def read_checker_changed(base: str, cwd: Path, rev: str | None = None) -> bool:
    """Whether the diff from `base` to `rev` (or the checkout) changes this checker."""
    args = ["diff", "--name-only", base] + ([rev] if rev else []) + ["--", f"tools/{Path(__file__).name}"]
    return bool(check_layers.git(*args, cwd=cwd).strip())


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/check_test_only_members.py",
        description=(
            "Fails when a test reads a public func, var, const or signal defined under src/ that no other word under"
            " src/ names, unless tools/test_only_members.txt lists it, and fails on a listed line that has gone"
            " stale (the member has a reader in another file, no test reads it, or it is gone). A caller in the"
            " member's own file is not a reader; a name more than one file defines is told by the reader's type where"
            " it is known; constants are exempt unless used nowhere."
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
        "--base",
        default=None,
        metavar="REV",
        help=(
            "also fail a line added since REV's list to the no reader or own file only group (CI passes the pull"
            " request's base commit, and on main the previous one), unless the diff also changes this checker; a REV"
            " with no list yet compares nothing"
        ),
    )
    parser.add_argument(
        "--list", action="store_true", help="print every test-only member, listed or not, and every line to remove"
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse(argv)
    try:
        files = read_rev(args.rev) if args.rev else read_checkout(args.root or ROOT)
        entries = entries_of(files.allowlist)
        allowed = {entry.key for entry in entries}
        scanned = scan(files)
        kept = frozenset(e.key for e in entries if e.group == KEPT)
        failures, only = check(files, allowed, kept, scanned)
        base = read_base(args.base, args.root or ROOT) if args.base else None
        root = args.root or ROOT
        renames = read_renames(args.base, root, args.rev) if args.base and base is not None else None
        changed = read_checker_changed(args.base, root, args.rev) if args.base and base is not None else False
        failures.extend(list_failures(entries, base, renames, changed))
        stands = scanned[1]
    except (check_layers.LayerError, MembersError, OSError) as error:
        print(f"tools/check_test_only_members.py: {error}", file=sys.stderr)
        return 1
    if args.list:
        for member in only:
            mark = "listed" if member.key in allowed else "NEW"
            print(f"{mark:6} {member.path}:{member.line}: {member.kind} {member.name} [{group_of(stands[member.key])}]")
        for line in failures:
            if line.startswith(("REMOVE", ALLOWLIST_NAME)):
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
