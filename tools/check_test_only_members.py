#!/usr/bin/env python3
"""Fails when a test reads a public member of the game's code that no other file of the game reads.

A member only a test calls is state or a hook the game never reaches: a check on it holds nothing
the player can meet (inbox #1097 in curly-rabbit). For every public member -- a `func`, `var`, `const` or `signal`
at the top level of a `.gd` file under `src/`, its name not starting with `_` -- this finds:

- **read by a test**: a file under `tests/` calls a function as `.name(`, or reads a var, const or
  signal as `.name`, in code (comments and string contents blanked first, as `check_layers.py` blanks
  them), on a receiver that can be the member's class (below). The names in `ENGINE_MEMBERS` (`enabled`,
  `size`, `text` and the like, which the engine's own classes carry and a test reads on a node it holds) are
  never taken as a read;
- **read by the game**: a use in code in another file under `src/` that reaches the member (below). A caller
  under `src/dev` (the rigs and the scene-recipe runtime are the composition root) counts, so does an
  assignment to it or an emit of it. A use in the member's own defining file does not count (inbox #1098 in
  curly-rabbit), and in that file only a use that is not a member of another object counts: a call
  `other.name()` on a namesake is not a use of this member, a plain `name` or `self.name` or the file's own
  `ClassName.name` is.

A member read by a test is test-only, and belongs to one of two groups of the list: **no reader**
(no use in its own file either; inbox #1095 in curly-rabbit) or **own file only** (used by its own file, so
internal: it gets the underscore and its tests go through what the class does outward; inbox
#1098). The group is a word count in the member's own file. The own-file rule applies to functions, vars and
signals, **not to constants**: the player's words on it are about functions, and a test reading a
constant to assert a relationship is what writing-tests wants, so a constant used in its own file is
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

**Every member is judged by its class**, so another class's member of the same name, a local of the name and an
engine method of the name do not hide it (`ParkCordon.gap` beside other files' locals named `gap`, `RouteTree.grow`
beside `Rect2.grow`). A `.name` is typed by its receiver with the receiver typing of `tools/check_field_reads.py` (its
`Tree`), run over the game's and the tests' files: a chain resolved from its head through declared types, a method's
declared `-> Type`, a preloaded script, an autoload's script or a `ClassName`, with one type for a name in its top-level
block (a function, or an inner class whole), so a declaration in one function does not type a name in another. Here a
suite's parent named by its path (`extends "res://tests/rig.gd"`) is followed too, a preloaded script with no
`class_name` is its file, through another class's constant too (`Boot.MainScript`), and `self` and `super` are the
line's own class, an inner class's included. A receiver typed as the member's class, a class it extends or a class
that extends it reaches it (a call dispatches on the object, so a reader typed as the base reaches the override). One
typed as another class, or as a value of no class under `src/` (an engine class, a builtin, an array: `Rect2(...)`, a
`Rect2` a method returns), does not, except in a file whose opt-out line names the engine's warning for that access
(`unsafe_method_access` for a call, `unsafe_property_access` for a read), where an engine-typed value may still hold a
game object. One the typing cannot tell (an untyped parameter, a Variant) reaches every class with the name, in the
game's files and the tests' alike. A static function is reached only through its class (`RouteTree.grow()`, a
preloaded script), never through a value, since the engine warns on a static function called on a value and no
warning it prints is left standing (woolly-finch 19). A plain word in another file reads a member only where the
line's class extends the member's class and does not define the name again, and no local of the name is declared on
the line or in scope there: an inherited member used bare. In an ancestor's file that defines the name too, a plain
use is a call the override answers (a template method). A `[kept]` line stands while every use of its member elsewhere
is a `.name` on a receiver the typing cannot tell (the check cannot tell whose it is, and the line says it is not the
game's), and is a `REMOVE` line once a told reader reads it.

**What it can miss and where it can accuse falsely.** It can *miss* a test-only member when a game reader the typing
cannot tell uses a word of its name (a namesake reached through an untyped value or a Variant), when a file's opt-out
line lets an engine-typed value count, when its name is one of `ENGINE_MEMBERS`, when a function is passed as a
callable (`.name`) rather than called, and it does not see members of an inner class. A base class's plain call of the
name reads a subclass's override, so an override whose subclass also overrides the base method that makes the call,
without calling `super`, is read by that plain call although the game never reaches it. Because the own-file count is a
word count, a call `.name(` on a namesake is not an own use either, so a member only that call and a test use lands in
`[no reader]` although its own class does call it (a call on another instance of the file's own class,
`other.name()`); the remedy is then the underscore of inbox #1098 (it is not dead code), not deleting it. It can
*accuse falsely* in four ways: a test calling `.name` on its own fake (an inner class of the test with a method of that
name) reads as a test reading the member; a test reading an engine member of the same name on a receiver the typing
cannot tell, a name `ENGINE_MEMBERS` does not list, does too, and a function is told apart only by the call
parenthesis; a game reader that goes through a string (`call("name")`, `has_method("name")`, `Callable(self, "name")`,
a scene's `.tscn`) is blanked out and not seen; and a reader the typing tells wrongly is not seen: a name a block never
declares is taken for an engine property of the file's own class, as `check_field_reads` takes it, a chain from
`self` inside an inner class (`self.a.name`) for an engine value, and a static function called on a value (a warning
left standing) for no read. On such a false failure the builder adds the line to a kept group with the reason as a
comment (a member name an engine class carries, which a test reads on an engine node it holds, is the only reason to
add to `ENGINE_MEMBERS`; never a way to exempt a game member).
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
from typing import TYPE_CHECKING

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_layers

if TYPE_CHECKING:
    import check_field_reads

ROOT = Path(__file__).resolve().parent.parent
ALLOWLIST_NAME = "test_only_members.txt"
ALLOWLIST = f"tools/{ALLOWLIST_NAME}"
SRC = "src"
TESTS = "tests"
PROJECT = "project.godot"
# Read every field by reflection, so a `.name` in them is not a reader of one member.
SKIPPED_TESTS = frozenset({"tests/shared_state.gd", "tests/test_prediction_reuse.gd"})

# A top-level member: at the margin, after any annotations (`@export`, `@onready var`).
DEFINITION = re.compile(
    r"^(?:@\w+(?:\([^)]*\))?[ \t]+)*(?P<static>static[ \t]+)?(?P<kind>func|var|const|signal)[ \t]+(?P<name>[A-Za-z]\w*)"
)
WORD = re.compile(r"\w+")
GROUP_TAG = re.compile(r"^#\s*\[([a-z ]+)\]")
KEPT = "kept"
GROUPS = frozenset({"no reader", "own file only", KEPT})
# A `.name` use, and whether a call parenthesis follows.
USE = re.compile(r"\.\s*([A-Za-z]\w*)(\s*\()?")
# A word used other than as a member of another object: not after a `.`. In a member's own file `self.name` and the
# file's own `ClassName.name` are added where the file is read.
OWN_USE = re.compile(r"(?<![\w.])(\w+)")
# A file's parent named by its path (`extends "res://tests/rig.gd"`, as the suites extend their rigs), which the
# receiver typing of check_field_reads, written for `src/`, does not follow.
EXTENDS_PATH = re.compile(r'^extends[ \t]+"res://([^"]+)"', re.MULTILINE)
INNER_HEAD = re.compile(r"^class[ \t]+([A-Za-z_]\w*)")
# A receiver that names a class rather than a value: a word, or words joined by dots (`Boot.MainScript`).
CLASS_REFERENCE = re.compile(r"([A-Za-z_]\w*)(?:[ \t]*\.[ \t]*[A-Za-z_]\w*)*")
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
what a line of tools/test_only_members.txt owes (this file's header comment says the rest):
  - a [kept] line with no reason after its # fails;
  - a moved file carries its lines only where git reports the rename, so the moved file is
    tracked first (git mv, or git add it); untracked, its lines read under --base as added;
  - a renamed member is not carried: it is fixed, or given a [kept] line with its reason;
  - a member the game reaches only through a string (call("name"), has_method("name")) is a
    false failure, and takes a [kept] line with its reason.

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
    static: bool = False

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
    """One `.name` in a file: its line, the kind of its receiver as `check_field_reads` tells it (a class's file, an
    inner class, a value of no class here such as an engine one, or None where it cannot tell), whether a call
    parenthesis follows, and whether the receiver names the class itself."""

    path: str
    line: int
    kind: str | None
    call: bool
    on_class: bool = False  # the receiver names a class (`RouteTree.grow()`), not a value of it


@dataclass(frozen=True)
class World:
    """What tells a member from another class's member of the same name: the receiver typing of `check_field_reads`
    over the game's and the tests' files (each class, what it extends, the kind of a receiver), and the names each
    file and inner class defines."""

    tree: check_field_reads.Tree
    defines: dict[str, frozenset[str]]

    def hits(self, kind: str | None, path: str) -> bool:
        """Whether a receiver of `kind` can reach the member defined in `path`: one not told can; a class can when it
        is that file's class, extends it, or is extended by it (a reader typed as the base reaches the override, since
        a call dispatches on the object); a value of no class here (an engine class, a builtin, an array) cannot."""
        return kind is None or (kind in self.tree.files and self.tree.related(kind, path))

    def reaches(self, use: Use, member: Member) -> bool:
        """Whether a `.name` use reaches `member`: its receiver can be the member's class (`hits`), and for a static
        function the receiver names that class, since the engine warns on a static function called on a value and no
        warning is left standing."""
        return self.hits(use.kind, member.path) and (use.on_class or not (member.static and member.kind == "func"))

    def definer(self, owner: str, name: str) -> str | None:
        """The nearest of `owner` and the classes it extends that defines `name`."""
        return next((a for a in self.tree.ancestors(owner) if name in self.defines.get(a, frozenset())), None)


@dataclass(frozen=True)
class Readings:
    """Every `.name` use in the tests by name, read by a member only through the uses whose receiver can be its class
    (`World.hits`)."""

    uses: dict[str, tuple[Use, ...]]
    world: World

    def of(self, member: Member) -> tuple[Reading | None, bool]:
        """The first test line reading `member` as `.name` and how many lines do, and whether one calls it."""
        uses = tuple(u for u in self.uses.get(member.name, ()) if self.world.reaches(u, member))
        if not uses:
            return None, False
        lines = sorted({(u.path, u.line) for u in uses})
        return Reading(*lines[0], len(lines)), any(u.call for u in uses)


@dataclass(frozen=True)
class Files:
    src: dict[str, str]
    tests: dict[str, str]
    allowlist: str = ""
    project: str = ""


def members_of(path: str, text: str, bare: str | None = None) -> list[Member]:
    """The public members `text` defines at its top level, read from its blanked code (`bare`, where already made)."""
    bare = bare if bare is not None else bare_of(text)
    found: list[Member] = []
    for index, line in enumerate(bare.split("\n"), start=1):
        match = DEFINITION.match(line)
        if match and not match.group("name").startswith("_"):
            found.append(Member(path, index, match.group("kind"), match.group("name"), bool(match.group("static"))))
    return found


@functools.cache
def bare_of(text: str) -> str:
    return check_layers.blank(text).bare


def world_of(files: Files) -> World:
    """The receiver typing over the game's and the tests' files. It is `check_field_reads.Tree`, a suite's parent
    named by its path followed too, and a preloaded script taken as its file where it has no `class_name`, through
    another class's constant too; imported here rather than at the top, since `check_field_reads` imports this
    file's `read_renames`."""
    import check_field_reads

    class Typing(check_field_reads.Tree):
        def parent_of(self, path: str) -> str | None:
            named = super().parent_of(path)
            by_path = EXTENDS_PATH.search(self.src[path])
            return named or (by_path.group(1) if by_path and by_path.group(1) in self.src else None)

        def script_kind(self, target: str) -> str:
            # A script a `const` preloads is its file, a class or not (`main.gd` has no `class_name`).
            return target if target in self.files else check_field_reads.UNTRACKED

        def annotation(self, text: str, path: str) -> str | None:
            # A type through another class's preload (`Boot.MainScript`) is the preloaded script.
            kind = super().annotation(text, path)
            first, _, rest = text.strip().partition(".")
            outer = path.split(check_field_reads.INNER)[0]
            owner = self.by_name.get(first) or self.preloads.get(outer, {}).get(first)
            if kind == check_field_reads.UNTRACKED and owner and rest in self.preloads.get(owner, {}):
                return self.preloads[owner][rest]
            return kind

    tree = Typing(files.src | files.tests, check_field_reads.autoloads_of(files.project))
    defines: dict[str, frozenset[str]] = {}
    for key, klass in tree.files.items():
        if check_field_reads.INNER in key:
            defines[key] = frozenset(klass.methods | set(klass.fields))
        else:
            defines[key] = frozenset(m.group("name") for m in map(DEFINITION.match, tree.bare[key].split("\n")) if m)
    return World(tree, defines)


@dataclass(frozen=True)
class Found:
    """What one file says of the members of other files: each `.name` use, and each plain word of a member's name
    that reaches it because the line's class extends the member's (counted by the member's file and name)."""

    uses: list[tuple[str, Use]]
    plain: Counter[tuple[str, str]]


def found_in(path: str, world: World, names: frozenset[str]) -> Found:
    """Every `.name` use of a member's name in a file, typed by its receiver (`self` and `super` being the line's own
    class), and every plain word of one that the line's class inherits from a class it extends and does not define
    again, where no local of the name is declared on the line or in scope there."""
    import check_field_reads

    tree = world.tree
    bare = tree.bare[path]
    blocks = check_field_reads.block_index(bare)
    inner = check_field_reads.inner_lines(bare)
    opt_out = check_field_reads.opt_out_of(tree.src[path])
    ignored = opt_out.warnings if opt_out else ()
    classes = set(tree.by_name) | set(tree.preloads.get(path, {}))
    uses: list[tuple[str, Use]] = []
    plain: Counter[tuple[str, str]] = Counter()
    for index, line in enumerate(bare.split("\n")):
        if not any(word in names for word in WORD.findall(line)):
            continue
        owner = path
        if inner[index]:
            head = INNER_HEAD.match(tree.blocks[path][blocks[index]])
            owner = f"{path}{check_field_reads.INNER}{head.group(1)}" if head else path
        scope = check_field_reads.Scope(tree, path, blocks[index], index)
        for match in USE.finditer(line):
            name = match.group(1)
            if name not in names:
                continue
            receiver = check_field_reads.receiver_text(line, match.start())
            call = bool(match.group(2))
            kind: str | None
            if receiver is None:
                kind = None
            elif receiver.strip() in ("self", "super"):
                kind = owner
            else:
                kind = tree.chain_class(receiver, path, scope, inner[index])
            # A value of no class here, which in a file whose opt-out line silences the engine's warning for the access
            # (`var _hud: CanvasLayer`, then `_hud.configure()`) may still hold a game object.
            silenced = ("unsafe_method_access" if call else "unsafe_property_access") in ignored
            if kind is not None and kind not in tree.files and silenced:
                kind = None
            reference = CLASS_REFERENCE.fullmatch(receiver.strip()) if receiver else None
            on_class = bool(reference and reference.group(1) in classes and kind in tree.files)
            uses.append((name, Use(path, index + 1, kind, call, on_class)))
        for match in OWN_USE.finditer(line):
            name = match.group(1)
            if name not in names:
                continue
            definer = world.definer(owner, name)
            if definer is None or definer in (path, owner) or name in scope:
                continue
            # The word that declares a local of the name (`var gap := 2`) is the local, not the member.
            if not any(d.line == index for d in tree.decls[path][blocks[index]].get(name, [])):
                plain[(definer, name)] += 1
    return Found(uses, plain)


def readings_of(tests: dict[str, str], world: World, names: frozenset[str]) -> Readings:
    """For each member's name a test reads as `.name`, its uses."""
    uses: dict[str, list[Use]] = {}
    for path in sorted(tests):
        if path in SKIPPED_TESTS:
            continue
        for name, use in found_in(path, world, names).uses:
            uses.setdefault(name, []).append(use)
    return Readings({name: tuple(found) for name, found in uses.items()}, world)


@dataclass(frozen=True)
class Stand:
    """What a member stands on: uses in the other files of `src/` that reach it, and uses in its own file other than
    as a member of another object (`other.name` is a call on a namesake, not a use of this member)."""

    elsewhere: int
    own: int
    unsure: int = 0  # of `elsewhere`, the `.name` uses whose receiver is not told, so may be another class's


@dataclass(frozen=True)
class Scanned:
    """Every public member defined under `src/`, what each stands on, and what the tests read."""

    members: list[Member]
    stands: dict[tuple[str, str], Stand]
    readings: Readings


def scan(files: Files) -> Scanned:
    """Every public member defined under `src/`, with the uses in other files that reach it (`found_in`) and the uses
    in its own file (less its definitions there), and the tests' readings."""
    world = world_of(files)
    members: list[Member] = []
    own_uses: dict[str, dict[str, int]] = {}
    for path, text in sorted(files.src.items()):
        bare = world.tree.bare[path]
        found = members_of(path, text, bare)
        members.extend(found)
        own = Counter(OWN_USE.findall(bare))
        class_name = check_layers.CLASS_NAME.search(bare)
        qualifier = rf"(?<![\w.])(?:self{'|' + re.escape(class_name.group(1)) if class_name else ''})\s*\.\s*(\w+)"
        own.update(re.findall(qualifier, bare))
        defined = Counter(member.name for member in found)
        own_uses[path] = {name: own[name] - defined[name] for name in defined}
    names = frozenset(member.name for member in members)
    dotted: dict[str, list[Use]] = {}
    plain: Counter[tuple[str, str]] = Counter()
    for path in files.src:
        found_here = found_in(path, world, names)
        for name, use in found_here.uses:
            dotted.setdefault(name, []).append(use)
        plain.update(found_here.plain)
    stands: dict[tuple[str, str], Stand] = {}
    for member in members:
        # A `.name` in another file reaches the member where its receiver can be the member's class, a receiver not
        # told counting (as unsure); a plain word reaches it in a class that extends the member's and does not define
        # it again (`found_in` counts those), and in an ancestor's file that defines it too (a call the override
        # answers: a template method).
        reaching = [u for u in dotted.get(member.name, []) if u.path != member.path and world.reaches(u, member)]
        elsewhere = len(reaching) + plain[member.key]
        for ancestor in world.tree.ancestors(member.path)[1:]:
            elsewhere += own_uses.get(ancestor, {}).get(member.name, 0)
        unsure = sum(1 for use in reaching if use.kind is None)
        stands[member.key] = Stand(elsewhere=elsewhere, own=own_uses[member.path][member.name], unsure=unsure)
    return Scanned(members, stands, readings_of(files.tests, world, names))


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
    scanned = scan(files)
    return [m for m in scanned.members if is_test_only(m, scanned.stands[m.key], scanned.readings)], scanned.readings


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
    scanned: Scanned | None = None,
) -> tuple[list[str], list[Member]]:
    """The failures (a test-only member not listed, a listed line gone stale) and every test-only member. A listed
    line in `kept` stands while every use of it in another file is a `.name` whose receiver is not told: the check
    cannot tell whose it is, and the line says it is not the game's."""
    scanned = scanned or scan(files)
    members, stands, readings = scanned.members, scanned.stands, scanned.readings
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
    project = root / PROJECT
    return Files(
        src=folder(SRC),
        tests=folder(TESTS),
        allowlist=listing.read_text(encoding="utf-8") if listing.exists() else "",
        project=project.read_text(encoding="utf-8") if project.exists() else "",
    )


def read_rev(rev: str, root: Path = ROOT) -> Files:
    listing = check_layers.git("ls-tree", "-r", "-z", rev, "--", SRC, TESTS, ALLOWLIST, PROJECT, cwd=root).decode()
    blobs: dict[str, str] = {}
    for record in listing.split("\0"):
        meta, _, path = record.partition("\t")
        if record and (path.endswith(".gd") or path in (ALLOWLIST, PROJECT)):
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
        project=texts.get(PROJECT, ""),
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
            "Fails when a test reads a public func, var, const or signal defined under src/ that no other file under"
            " src/ reaches, unless tools/test_only_members.txt lists it, and fails on a listed line that has gone"
            " stale (the member has a reader in another file, no test reads it, or it is gone). A caller in the"
            " member's own file is not a reader; a reader is told by its receiver's type where it is known (another"
            " class, a local, an engine value or a static function called on a value is no reader); constants are"
            " exempt unless used nowhere."
            " A caller under src/dev counts as a reader; a function is read only as a call, not passed as a"
            " callable; a short set of engine member names (ENGINE_MEMBERS) is never taken as a read. The list's"
            " [no reader] and [own file only] groups only shrink."
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
        stands = scanned.stands
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
