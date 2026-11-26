#!/usr/bin/env python3
"""Fails when a street closure is made anywhere but on the closure planner's path.

The city's rule (.claude/skills/city/SKILL.md, "Every day stays winnable"): anything that closes a
street goes through ClosurePlanner, which checks before it accepts each closure that two calm
areas stay reachable from home. The closure rigs hold only the days the planner plans, so a
closure made anywhere else is one no suite sees. This check is the static guard: it reads every
.gd file under src/ as text and fails each of these outside the sites ALLOWED lists below.

- **a call** of CityMap.close_streets(): the name close_streets in code other than its own func
  line, and the string "close_streets" (a call by name);
- **a construction** of a closure: <Class>.new for RoadClosure and every class under src/ that
  extends it, directly or through another (ParkClosure), and a bare new( in such a class's file;
- **a write of the closed ground**, the map's record of the tiles closed today: a call or the
  string of replace_closed_tiles; an assignment, an indexed assignment or a mutating method
  (clear, merge, erase, assign, set, get_or_add, sort) on _closed_tiles, on what
  closed_tile_set() or todays_closed_tiles() hands out (the record itself, not a copy), on a
  local name a function gives that record, and on _closed in src/world/blocked_layer.gd;
- **a closure listed for a recipe's city**: a call or the string of add_recipe_closure, whose
  list City.start_recipe_day() closes.

**An allowed site is a file and a function**, the func the line stands in, whatever class of the
file declares it; a property's get and set block is the site var <name>, and a line outside
every function is in none and cannot be allowed. **An entry of ALLOWED that no line uses fails
too**, so the table holds exactly the sites that exist. A new site that only hands on what the
planner planned is added there with its reason.

**What it reads:** a line's code, without its comment and with every string literal emptied (a
string counts only when it is exactly one of the names above); the inside of a triple-quoted
string is skipped. Files under tests/ are not read: a rig closes what its case needs.

**What it cannot see:** the record carried out of a function (returned, stored in a field, passed
to a function that writes its parameter); a closure class reached through preload or load and
not its class name; a name built at run time for call() or set(); and a new accessor that hands
out the record. It does not judge the allowed sites' own logic, which is the suites'.

This runs under the host's own python3 (tools/lint.sh calls it), so it stays 3.9-compatible.

  uv run python tools/check_closure_writers.py
  uv run python tools/check_closure_writers.py --root ../other-checkout
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SELF = "tools/check_closure_writers.py"
FOLDER = "src"

CALL = "call"
CONSTRUCT = "construct"
WRITE = "write"
LIST = "list"


@dataclass(frozen=True)
class Site:
    """One place a kind of line may stand: a file and the function (or var <name>) it is in."""

    kind: str
    path: str
    scope: str


ALLOWED = (
    # Hands the map the closures ClosurePlanner.plan_day() returned for the day, and nothing else.
    Site(CALL, "src/city/city.gd", "_close_streets"),
    # Hands the map the closures a scene recipe lists, each of which
    # RecipeCityBuilder._plan_closures() held to the planner's own invariant before listing it.
    Site(CALL, "src/city/city.gd", "start_recipe_day"),
    # The planner: builds a street's closure only after _invariant_holds() accepts the street.
    Site(CONSTRUCT, "src/routes/closure_planner.gd", "_close_streets"),
    # The fence of the fenced park, which ClosurePlanner.plan_day() asks for; the ground it stands
    # round is chosen at the repaint by ClosurePlanner.calm_to_shut().
    Site(CONSTRUCT, "src/routes/park_closure.gd", "fence"),
    # A scene recipe's own closures: each pin is refused unless it is one of the planner's
    # candidates and ClosurePlanner._invariant_holds() still holds with it closed.
    Site(CONSTRUCT, "src/city/recipe_city_builder.gd", "_plan_closures"),
    # Lists each closure the lines above accepted on the recipe's map.
    Site(LIST, "src/city/recipe_city_builder.gd", "_plan_closures"),
    # The property itself: its set hands the map's record to BlockedLayer.
    Site(WRITE, "src/city/city_map.gd", "var _closed_tiles"),
    # Writes the tiles the closures it is handed cut off, over the fenced park's ground.
    Site(WRITE, "src/city/city_map.gd", "close_streets"),
    # Clears yesterday's closed ground before today's is planned: it only opens ground.
    Site(WRITE, "src/city/city_map.gd", "repaint"),
    # Closes the fenced park's ground, the area ClosurePlanner.calm_to_shut() accepted.
    Site(WRITE, "src/city/city_map.gd", "_shut_the_spent_calm"),
    # The writer behind the property's set.
    Site(WRITE, "src/world/blocked_layer.gd", "replace_closed_tiles"),
    # Copies the record onto a twin record (CityMap.copy()): the same closed ground, on another map.
    Site(WRITE, "src/world/blocked_layer.gd", "copy"),
)

CLOSURE_ROOT = "RoadClosure"
# The file whose private field _closed is the record itself.
RECORD_FILE = "src/world/blocked_layer.gd"
# The names that are guarded wherever they stand: each one's kind and what a line using it does. A
# name in code is a use unless it follows func; a string that is exactly a name is a use by name.
NAMES = {
    "close_streets": (CALL, "calls CityMap.close_streets()"),
    "add_recipe_closure": (LIST, "lists a closure for a recipe's city (CityMap.add_recipe_closure())"),
    "replace_closed_tiles": (WRITE, "writes the closed ground (replace_closed_tiles())"),
}
# A string that is exactly the property's name is a write by name, as set() takes it.
PROPERTY_NAME = "_closed_tiles"
ADVICE = (
    "a street closure belongs in ClosurePlanner.plan_day(), which checks that two calm areas stay"
    ' reachable before it accepts one (the city skill, "Every day stays winnable")'
)

ANNOTATIONS = r"(?:@\w+(?:\([^)]*\))?[ \t]+)*"
FUNC = re.compile(r"^([ \t]*)" + ANNOTATIONS + r"(?:static[ \t]+)?func[ \t]+(\w+)")
PROPERTY = re.compile(r"^([ \t]*)" + ANNOTATIONS + r"(?:static[ \t]+)?var[ \t]+(\w+)\b.*:[ \t]*$")
CLASS_NAME = re.compile(r"^" + ANNOTATIONS + r"class_name[ \t]+(\w+)(?:[ \t]+extends[ \t]+([\w.]+))?")
EXTENDS = re.compile(r"^extends[ \t]+([\w.]+)")
INNER_CLASS = re.compile(r"^[ \t]*class[ \t]+(\w+)[ \t]+extends[ \t]+([\w.]+)[ \t]*:")
RECORD = r"\b_closed_tiles\b|\bclosed_tile_set[ \t]*\([ \t]*\)|\btodays_closed_tiles[ \t]*\([ \t]*\)"
RECORD_ALONE = re.compile(r"^(?:[\w.]+(?:\(\))?\.)*(?:" + RECORD + r")$")
GIVES_A_NAME = re.compile(r"^[ \t]*(?:var[ \t]+)?(\w+)[ \t]*(?::[ \t]*[\w\[\], ]*)?:?=[ \t]*(.+?)[ \t]*$")
MUTATION = re.compile(r"[ \t]*\.[ \t]*(clear|merge|erase|assign|set|get_or_add|sort)[ \t]*\(")
ASSIGNMENT = re.compile(r"[ \t]*(?:\*\*|<<|>>|[-+*/%&|^])?=(?!=)")
BARE_NEW = re.compile(r"(?<![\w.])new[ \t]*\(")
QUOTE_OR_COMMENT = re.compile(r"[\"'#]")
# What a line must hold for any pattern above to match it: lets scan() pass the other lines by.
GUARDED_WORD = re.compile(r"close_streets|add_recipe_closure|_closed|closed_tile|\bnew\b")


@dataclass(frozen=True)
class Found:
    """One line that does a guarded thing: its kind, where it stands, and what to say of it."""

    kind: str
    path: str
    line: int
    scope: str
    what: str


def code_of(line: str, open_quote: str) -> tuple[str, list[str], str]:
    """The code of one line with its comment removed and every string emptied to its quotes, the
    strings' contents, and the triple quote still open at its end ('' when none is)."""
    if not open_quote and not QUOTE_OR_COMMENT.search(line):
        return line, [], ""
    out: list[str] = []
    strings: list[str] = []
    i = 0
    while i < len(line):
        if open_quote:
            end = line.find(open_quote, i)
            if end < 0:
                break
            i = end + 3
            open_quote = ""
        elif line.startswith(('"""', "'''"), i):
            open_quote = line[i : i + 3]
            out.append('""')
            i += 3
        elif line[i] in "\"'":
            quote = line[i]
            j = i + 1
            while j < len(line) and line[j] != quote:
                j += 2 if line[j] == "\\" else 1
            strings.append(line[i + 1 : j])
            out.append('""')
            i = j + 1
        elif line[i] == "#":
            break
        else:
            out.append(line[i])
            i += 1
    return "".join(out), strings, open_quote


def after_index(text: str) -> str:
    """text with any [index] it opens with taken off, however the brackets nest."""
    rest = text.lstrip()
    while rest.startswith("["):
        depth = 0
        for at, char in enumerate(rest):
            depth += (char == "[") - (char == "]")
            if depth == 0:
                rest = rest[at + 1 :].lstrip()
                break
        else:
            return ""
    return rest


def written(code: str, record: str) -> str | None:
    """How code writes the thing the pattern record matches, or None when it only reads it."""
    for match in re.finditer(record, code):
        rest = code[match.end() :]
        mutation = MUTATION.match(rest)
        if mutation:
            return f"{match.group(0)}.{mutation.group(1)}()"
        indexed = after_index(rest)
        if ASSIGNMENT.match(indexed):
            return f"an assignment to {match.group(0)}" + ("[...]" if indexed != rest.lstrip() else "")
    return None


def closure_classes(files: dict[str, str]) -> dict[str, str]:
    """RoadClosure and every class under src/ that extends it, by name: the file that declares it."""
    declared: list[tuple[str, str, str]] = []
    for path, text in files.items():
        name, base = "", ""
        open_quote = ""
        for raw in text.splitlines():
            code, _, open_quote = code_of(raw, open_quote)
            header = CLASS_NAME.match(code)
            if header:
                name, base = header.group(1), header.group(2) or base
            extends = EXTENDS.match(code)
            if extends:
                base = extends.group(1)
            inner = INNER_CLASS.match(code)
            if inner:
                declared.append((inner.group(1), inner.group(2), path))
        if name:
            declared.append((name, base, path))
    found = {name: path for name, _, path in declared if name == CLOSURE_ROOT}
    found.setdefault(CLOSURE_ROOT, "")
    grew = True
    while grew:
        grew = False
        for name, base, path in declared:
            if name not in found and base.split(".")[-1] in found:
                found[name] = path
                grew = True
    return found


def scan(path: str, text: str, classes: dict[str, str]) -> tuple[list[Found], dict[str, int]]:
    """The guarded lines of one file, and the line each function (or var <name>) of it starts on."""
    found: list[Found] = []
    scopes: dict[str, int] = {}
    stack: list[tuple[int, str]] = []
    names: list[str] = []
    construction = re.compile(r"\b(" + "|".join(sorted(classes)) + r")[ \t]*\.[ \t]*new\b")
    own_class = next((name for name, where in sorted(classes.items()) if where == path), "")
    open_quote = ""
    for number, raw in enumerate(text.splitlines(), start=1):
        began_in_string = bool(open_quote)
        code, strings, open_quote = code_of(raw, open_quote)
        if began_in_string or not code.strip():
            continue
        indent = len(code) - len(code.lstrip())
        while stack and indent <= stack[-1][0]:
            stack.pop()
        if not stack:
            names = []
        opened = FUNC.match(code)
        block = PROPERTY.match(code)
        if opened:
            stack.append((indent, opened.group(2)))
        elif block:
            stack.append((indent, "var " + block.group(2)))
        scope = stack[0][1] if stack else ""
        if scope:
            scopes.setdefault(scope, number)
        if not names and not GUARDED_WORD.search(raw):
            continue

        def add(kind: str, what: str, number: int = number, scope: str = scope) -> None:
            found.append(Found(kind, path, number, scope, what))

        for name, (kind, what) in NAMES.items():
            if name in strings:
                add(kind, f'{what} by its name in a string ("{name}")')
            for match in re.finditer(r"\b" + name + r"\b", code):
                if not code[: match.start()].rstrip().endswith("func"):
                    add(kind, what)
        if PROPERTY_NAME in strings:
            add(WRITE, f'writes the closed ground by its name in a string ("{PROPERTY_NAME}")')
        for match in construction.finditer(code):
            add(CONSTRUCT, f"builds a closure ({match.group(1)}.new())")
        if own_class and BARE_NEW.search(code):
            add(CONSTRUCT, f"builds a closure (new() in {own_class}'s own file)")
        records = [RECORD] + [r"(?<![\w.])" + name + r"\b" for name in names]
        if path == RECORD_FILE:
            records.append(r"\b_closed\b")
        for record in records:
            how = written(code, record)
            if how:
                add(WRITE, f"writes the closed ground ({how})")
        given = GIVES_A_NAME.match(code)
        if given and stack and RECORD_ALONE.match(given.group(2)):
            names.append(given.group(1))
    return found, scopes


def check(files: dict[str, str]) -> list[str]:
    classes = closure_classes(files)
    hits: list[tuple[str, int, str]] = []
    used: set[Site] = set()
    scopes: dict[str, dict[str, int]] = {}
    for path in sorted(files):
        found, scopes[path] = scan(path, files[path], classes)
        for one in found:
            site = Site(one.kind, one.path, one.scope)
            if site in ALLOWED:
                used.add(site)
                continue
            where = "outside every function"
            if one.scope:
                where = f"in {one.scope}" + ("" if one.scope.startswith("var ") else "()")
            hits.append((one.path, one.line, f"{one.what} {where}: {ADVICE}"))
    for site in ALLOWED:
        if site in used:
            continue
        if site.path not in files:
            why = "the file is not there"
        elif site.scope not in scopes[site.path]:
            why = f"the file has no {site.scope}"
        else:
            why = f"{site.scope} holds no such line"
        hits.append(
            (
                site.path,
                scopes.get(site.path, {}).get(site.scope, 1),
                f"ALLOWED in {SELF} lets {site.scope} of this file {site.kind} and {why}:"
                " take the entry out, or name the site that does it now",
            )
        )
    return [f"{path}:{line}: {message}" for path, line, message in sorted(set(hits))]


def read_checkout(root: Path) -> dict[str, str]:
    files: dict[str, str] = {}
    for path in sorted((root / FOLDER).rglob("*.gd")):
        files[path.relative_to(root).as_posix()] = path.read_text(encoding="utf-8")
    return files


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Fail when a .gd file under src/ closes a street, builds a closure or writes the map's closed"
            " ground anywhere but the sites the ALLOWED table of this script lists: a call of"
            " CityMap.close_streets(), a RoadClosure.new() (or of a class extending it), a write of"
            " _closed_tiles or of what closed_tile_set() hands out, a call of replace_closed_tiles() or"
            " add_recipe_closure(). A site is a file and the function the line stands in; an entry no line"
            " uses fails too. Comments are ignored, and a string counts only when it is exactly one of"
            " those names. Runs under the host's python3."
        ),
        epilog="example: uv run python tools/check_closure_writers.py --root ../other-checkout",
    )
    parser.add_argument("--root", type=Path, default=ROOT, help="the checkout to read (default: this repository)")
    args = parser.parse_args(argv)
    try:
        files = read_checkout(args.root)
    except (OSError, UnicodeDecodeError) as error:
        print(f"{SELF}: {error}", file=sys.stderr)
        return 1
    hits = check(files)
    for hit in hits:
        print(hit)
    if hits:
        print(
            f"{SELF}: {len(hits)} line(s) off the closure planner's path, or allowed sites that are gone"
            " (ALLOWED in this script lists each site that may, with its reason)"
        )
        return 1
    print("OK: every street closure comes from the closure planner or a recipe's checked list")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
