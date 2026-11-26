#!/usr/bin/env python3
"""Fails when a street is shut, or the closed ground written, anywhere the closure planner does not reach.

The city's rule is that anything that closes a street goes through the closure planner
(`ClosurePlanner`), which checks every candidate against the guarantees that keep a day winnable
before it accepts it. The closure rigs (`tests/routes_closures_rig.gd`) hold every day the
planner plans, so a closure made outside it is a closure nothing checks. This reads every `.gd`
file under `src/` as text and fails four kinds of line anywhere but the sites `ALLOWED` lists,
each with its reason:

- **close**: a call of `close_streets()`, the map's one writer of today's closures;
- **build**: a `RoadClosure` built (`.new()`), or a class that extends it, at any depth;
- **recipe**: a closure listed for a recipe (`add_recipe_closure()`), which the city closes at
  the recipe's dawn;
- **ground**: the closed ground written, `CityMap`'s `_closed_tiles` assigned or changed, the
  blocked layer's `replace_closed_tiles()` called, the blocked layer's own dictionary `_closed`
  (`src/world/blocked_layer.gd`, where the closed ground lives) assigned or changed, or the
  dictionary `closed_tile_set()` or `todays_closed_tiles()` returns changed in the same expression.

A site is a file and the function (or the property) the line stands in. **An allowed site that
no longer holds its kind of line fails too**, so the table cannot outlive the code it describes.
Comments and string literals are not read.

What it cannot see: a closure handed to an allowed site from somewhere else (the argument of
`close_streets()` is not traced), the closed ground changed through a name that holds the
dictionary `closed_tile_set()` returned, and anything outside `src/`, where the tests close
streets on purpose.

This runs under the host's own `python3` (tools/lint.sh calls it), so it stays 3.9-compatible.

  uv run python tools/check_closure_writers.py
  uv run python tools/check_closure_writers.py --root /path/to/a/copy
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# (file under the root, function or property it stands in, kind) -> the reason it may stand there.
ALLOWED = {
    ("src/city/city.gd", "_close_streets", "close"): (
        "the day's dawn closes what ClosurePlanner.plan_day() planned for it"
    ),
    ("src/city/city.gd", "start_recipe_day", "close"): (
        "a recipe's dawn closes the closures its recipe listed, each checked by the planner's own "
        "invariant when it was listed"
    ),
    ("src/routes/closure_planner.gd", "_close_streets", "build"): ("the planner builds each closure it accepts"),
    ("src/routes/park_closure.gd", "fence", "build"): (
        "the fenced park's runs, which the planner adds to the day's closures and the park cordon reads for its line"
    ),
    ("src/city/recipe_city_builder.gd", "_plan_closures", "build"): (
        "a recipe's closure, built once the planner's invariant holds with it"
    ),
    ("src/city/recipe_city_builder.gd", "_plan_closures", "recipe"): (
        "a recipe's closure, listed once the planner's invariant holds with it"
    ),
    ("src/city/city_map.gd", "close_streets", "ground"): ("the map's one writer of today's closures"),
    ("src/city/city_map.gd", "repaint", "ground"): (
        "the dawn clears yesterday's closures before the planner plans today's"
    ),
    ("src/city/city_map.gd", "_shut_the_spent_calm", "ground"): (
        "closes the fenced park, the first used calm area ClosurePlanner.calm_to_shut() accepts"
    ),
    ("src/city/city_map.gd", "_closed_tiles", "ground"): (
        "the property that holds the closed ground on the map's blocked layer"
    ),
    ("src/world/blocked_layer.gd", "replace_closed_tiles", "ground"): (
        "the blocked layer's one writer of its closed ground, which the map's allowed sites call"
    ),
    ("src/world/blocked_layer.gd", "copy", "ground"): ("a copy of the layer takes its own copy of the closed ground"),
}

BASE_CLASS = "RoadClosure"
FUNC = re.compile(r"^[ \t]*(?:@\w+(?:\([^)]*\))?[ \t]+)*(?:static[ \t]+)?func[ \t]+(\w+)")
TOP_VAR = re.compile(r"^(?:@\w+(?:\([^)]*\))?[ \t]+)*(?:static[ \t]+)?var[ \t]+(\w+)")
CLASS_NAME = re.compile(r"^class_name[ \t]+(\w+)(?:[ \t]+extends[ \t]+(\w+))?")
EXTENDS = re.compile(r"^extends[ \t]+(\w+)")
INNER_CLASS = re.compile(r"^[ \t]*class[ \t]+(\w+)[ \t]+extends[ \t]+([\w.]+)[ \t]*:")
CLOSE = re.compile(r"(?<![\w.])(?:[\w.]*\.)?close_streets[ \t]*\(")
RECIPE = re.compile(r"\badd_recipe_closure[ \t]*\(")
GROUND = (
    re.compile(r"\b_closed_tiles\b[ \t]*(?:\[[^\]]*\][ \t]*)?(?:=(?!=)|\+=|-=)"),
    re.compile(r"\b_closed_tiles[ \t]*\.[ \t]*(?:clear|merge|erase|assign|append)[ \t]*\("),
    re.compile(r"\breplace_closed_tiles[ \t]*\("),
    re.compile(r"\b_closed\b[ \t]*(?:\[[^\]]*\][ \t]*)?(?:=(?!=)|\+=|-=)"),
    re.compile(r"\b_closed[ \t]*\.[ \t]*(?:clear|merge|erase|assign|append)[ \t]*\("),
    re.compile(
        r"\b(?:closed_tile_set|todays_closed_tiles)[ \t]*\([ \t]*\)[ \t]*"
        r"(?:\.[ \t]*(?:clear|merge|erase|assign)[ \t]*\(|\[[^\]]*\][ \t]*=(?!=))"
    ),
)


def strip_code(line: str) -> str:
    """The line with its comment cut and the inside of every string literal blanked."""
    out: list[str] = []
    quote = ""
    i = 0
    while i < len(line):
        ch = line[i]
        if quote:
            if ch == "\\":
                out.append("  ")
                i += 2
                continue
            if ch == quote:
                quote = ""
                out.append(ch)
            else:
                out.append(" ")
        elif ch in "\"'":
            quote = ch
            out.append(ch)
        elif ch == "#":
            break
        else:
            out.append(ch)
        i += 1
    return "".join(out)


def closure_classes(sources: dict[str, list[str]]) -> set[str]:
    """RoadClosure and every class under src/ that extends it, at any depth."""
    parents: dict[str, str] = {}
    for lines in sources.values():
        own = ""
        for line in lines:
            match = CLASS_NAME.match(line)
            if match:
                own = match.group(1)
                if match.group(2):
                    parents[own] = match.group(2)
                continue
            match = EXTENDS.match(line)
            if match and own:
                parents[own] = match.group(1)
                continue
            inner = INNER_CLASS.match(line)
            if inner:
                parents[inner.group(1)] = inner.group(2).split(".")[-1]
    found = {BASE_CLASS}
    grew = True
    while grew:
        grew = False
        for child, parent in parents.items():
            if parent in found and child not in found:
                found.add(child)
                grew = True
    return found


def scan(root: Path, allowed: dict[tuple[str, str, str], str] | None = None) -> list[str]:
    """Every failure, as `path:line: message`, for the tree at `root` against `allowed` (`ALLOWED`)."""
    if allowed is None:
        allowed = ALLOWED
    src = root / "src"
    if not src.is_dir():
        # A checkout with no game code (a fixture of the doc lint) has nothing to close a street.
        return []
    sources: dict[str, list[str]] = {}
    for path in sorted(src.rglob("*.gd")):
        sources[path.relative_to(root).as_posix()] = path.read_text(encoding="utf-8").splitlines()
    classes = closure_classes(sources)
    build = re.compile(r"\b(?:" + "|".join(sorted(classes)) + r")[ \t]*\.[ \t]*new[ \t]*\(")
    failures: list[str] = []
    seen: set[tuple[str, str, str]] = set()
    for rel, lines in sources.items():
        site = ""
        for number, raw in enumerate(lines, start=1):
            func = FUNC.match(raw)
            if func:
                site = func.group(1)
            else:
                var = TOP_VAR.match(raw)
                if var:
                    site = var.group(1)
            code = strip_code(raw)
            if func:
                # A definition is not a call: `func close_streets(` names the writer, it is not one.
                code = code[func.end() :]
            kinds = []
            if CLOSE.search(code):
                kinds.append("close")
            if build.search(code):
                kinds.append("build")
            if RECIPE.search(code):
                kinds.append("recipe")
            if any(pattern.search(code) for pattern in GROUND):
                kinds.append("ground")
            for kind in kinds:
                key = (rel, site, kind)
                if key in allowed:
                    seen.add(key)
                    continue
                failures.append(
                    f"{rel}:{number}: {describe(kind)} in {site or 'the file body'}, "
                    "which the closure planner does not reach (ClosurePlanner; "
                    "tools/check_closure_writers.py --help)"
                )
    for key in sorted(set(allowed) - seen):
        rel, site, kind = key
        failures.append(
            f"{rel}: the allowed site {site} holds no {describe(kind)} any more; "
            "delete its line from ALLOWED in tools/check_closure_writers.py"
        )
    return failures


def describe(kind: str) -> str:
    return {
        "close": "a call of close_streets()",
        "build": "a RoadClosure built",
        "recipe": "a recipe closure listed",
        "ground": "the closed ground written",
    }[kind]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="tools/check_closure_writers.py",
        description="Fails a street closed, a closure built or the closed ground written anywhere "
        "under src/ but the sites the closure planner reaches. Each allowed site is listed in the "
        "script's ALLOWED table with its reason, and an allowed site that is gone fails too.",
        epilog="example: uv run python tools/check_closure_writers.py",
        allow_abbrev=False,
    )
    parser.add_argument("--root", type=Path, default=ROOT, help="the checkout to read (default: this one)")
    args = parser.parse_args(argv)
    failures = scan(args.root.resolve())
    for failure in failures:
        print(failure)
    if failures:
        print(f"tools/check_closure_writers.py: {len(failures)} failure(s)", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
