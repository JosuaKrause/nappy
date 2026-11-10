#!/usr/bin/env python3
"""Finds which typing warnings each `.gd` file still trips, and keeps each file's opt-out line to that.

`project.godot` makes `untyped_declaration`, `unsafe_property_access` and `unsafe_method_access` errors, and a
`.gd` file not yet typed opens with one line, `@warning_ignore_start("untyped_declaration",
"unsafe_method_access")`, naming the ones it still trips (the line has one form: `check_field_reads.py --help`,
"The line has one form"). Nothing but this tool finds again which a file trips, so a name left on a line after its
file stopped tripping it, or a missing one, is caught here.

**How the census is taken.** Every `.gd` file under `src/`, `tests/` and `tools/` is loaded once, as the scene
`tools/typing_census.tscn` (so the autoloads exist), under the engine's local debugger (`-d`), which is what prints a
warning with its file and line. For the run the three warnings are at the warn level in `project.godot` and every
other warning is ignored, and each file's own opt-out line is out of the way. At warn level a file's warning does
not fail the files that depend on it; at error level it does. A message is told to its warning by its wording, and
a message of none of the three is an error of this tool, never a miscount.

**What is put back.** `project.godot` is never left changed: it is restored on every exit, a signal included, and
the run refuses to start on a tree where it is already modified. Each `.gd` file that lost its line for the run is
written back byte for byte, `--write` rewriting it afterwards where its line is wrong. A killed process (SIGKILL)
cannot restore anything; `git checkout project.godot` and `git diff --stat` show what is left.

**Another warning.** A warning's name given as an argument (`standalone_expression`) is counted the same way in a
run of its own, per folder with a count, and per line with `--lines`; no file is touched for it.

**`--check`** fails naming file and warning where a file's line names a warning it does not trip or lacks one it
trips, and where a file trips something with no line at all. **`--write`** rewrites each file's first line to
exactly what it trips and deletes the line of a file that trips none; it adds no line to a file without one (such a
file fails the engine already, and is named).
"""

from __future__ import annotations

import argparse
import atexit
import os
import re
import signal
import subprocess
import sys
import tempfile
import time
from collections import Counter
from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from pathlib import Path
from types import FrameType

ROOT = Path(__file__).resolve().parent.parent
GODOT = os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot")
FOLDERS = ("src", "tests", "tools")
TYPING = ("untyped_declaration", "unsafe_property_access", "unsafe_method_access")
SCENE = "res://tools/typing_census.tscn"
# The census takes well under a minute; a run still going after this is stuck (a debugger waiting for input).
RUN_TIMEOUT_SECONDS = 300

OPT_OUT = re.compile(r"^@warning_ignore_start\((.*)\)\s*$")
NAME = re.compile(r'"([a-z_]+)"')
# The wording of each typing warning's message in the engine's output.
MESSAGES = (
    ("untyped_declaration", re.compile(r"has no static (return )?type")),
    ("unsafe_property_access", re.compile(r'^The property ".*" is not present on the inferred type')),
    ("unsafe_method_access", re.compile(r'^The method ".*" is not present on the inferred type')),
)
WARNING_LINE = re.compile(r"^(?:USER )?WARNING: (.*)$")
AT_LINE = re.compile(r"^\s+at: GDScript::reload \((res://.+?):(\d+)\)")
FAILED = re.compile(r"CENSUS_FAILED (res://\S+)")
SETTING = re.compile(r"^gdscript/warnings/([a-z_]+)=")


@dataclass(frozen=True)
class Hit:
    path: str  # relative to the project, `src/x.gd`
    line: int
    message: str


def opt_out_names(first_line: str) -> list[str] | None:
    """The names on a first line that is an opt-out line, in order, or None if it is not one.

    A first line is the opt-out line when it is `@warning_ignore_start(...)` naming any of the three typing
    warnings; any other ignore line is not this tool's.
    """
    m = OPT_OUT.match(first_line.rstrip("\n"))
    if m is None:
        return None
    names = NAME.findall(m.group(1))
    return names if any(n in TYPING for n in names) else None


def opt_out_line(names: Iterable[str]) -> str:
    """The line in its one form, for the warnings tripped, in the order of `TYPING`."""
    ordered = [n for n in TYPING if n in set(names)]
    return "@warning_ignore_start(" + ", ".join(f'"{n}"' for n in ordered) + ")\n"


def split_first_line(text: str) -> tuple[str, str]:
    head, sep, rest = text.partition("\n")
    return head + sep, rest


def without_line(text: str) -> str:
    """The text without its opt-out line, when the first line is one."""
    head, rest = split_first_line(text)
    return rest if opt_out_names(head) is not None else text


def with_line(text: str, tripped: set[str]) -> str:
    """The text with its first line rewritten to what the file trips (the line deleted when it trips none).

    A file with no opt-out line is returned as it is: nothing is added.
    """
    head, rest = split_first_line(text)
    if opt_out_names(head) is None:
        return text
    return opt_out_line(tripped) + rest if tripped else rest


def classify(message: str) -> str | None:
    for name, pattern in MESSAGES:
        if pattern.search(message):
            return name
    return None


def parse_output(output: str) -> tuple[list[Hit], list[str]]:
    """The warnings (deduplicated, in order) and the files that failed to load, from a run's output."""
    hits: list[Hit] = []
    seen: set[Hit] = set()
    failed: list[str] = []
    pending: str | None = None
    for raw in output.splitlines():
        m = WARNING_LINE.match(raw)
        if m is not None:
            pending = m.group(1)
            continue
        a = AT_LINE.match(raw)
        if a is not None and pending is not None:
            hit = Hit(a.group(1).removeprefix("res://"), int(a.group(2)), pending)
            if hit not in seen:
                seen.add(hit)
                hits.append(hit)
            pending = None
            continue
        f = FAILED.search(raw)
        if f is not None:
            failed.append(f.group(1).removeprefix("res://"))
    return hits, failed


def settings_text(original: str, levels: dict[str, int]) -> str:
    """`project.godot`'s text with its `[debug]` warning settings replaced by `levels` (name -> 0, 1 or 2)."""
    out: list[str] = []
    for line in original.splitlines(keepends=True):
        if SETTING.match(line):
            continue
        out.append(line)
        if line.strip() == "[debug]":
            out.extend(f"gdscript/warnings/{n}={lv}\n" for n, lv in levels.items())
    return "".join(out)


class Tree:
    """The files read and the state to put back."""

    def __init__(self, root: Path) -> None:
        self.root = root
        self.project = root / "project.godot"
        self.original_project: str | None = None
        self.originals: dict[Path, str] = {}

    def gd_files(self) -> list[Path]:
        files: list[Path] = []
        for folder in FOLDERS:
            files.extend(sorted((self.root / folder).rglob("*.gd")))
        return files

    def refuse_if_dirty(self) -> str | None:
        r = subprocess.run(
            ["git", "status", "--porcelain", "--", "project.godot"], cwd=self.root, capture_output=True, text=True
        )
        if r.returncode != 0:
            return "git status failed: " + r.stderr.strip()
        if r.stdout.strip():
            return "project.godot is already modified; commit or revert it first"
        return None

    def restore(self) -> None:
        if self.original_project is not None:
            self.project.write_text(self.original_project)
            self.original_project = None
        for path, text in self.originals.items():
            path.write_text(text)
        self.originals = {}

    def take_lines_out(self, files: Sequence[Path]) -> None:
        for path in files:
            text = path.read_text()
            self.originals[path] = text
            stripped = without_line(text)
            if stripped != text:
                path.write_text(stripped)


def installed_warnings() -> list[str]:
    """Every warning name the project's settings file lists, read from the engine's own setting names."""
    r = subprocess.run(
        [GODOT, "--headless", "--path", str(ROOT), "--script", "res://tools/typing_census_names.gd"],
        capture_output=True,
        text=True,
    )
    return [ln.removeprefix("CENSUS_WARNING ") for ln in r.stdout.splitlines() if ln.startswith("CENSUS_WARNING ")]


def run_census(tree: Tree, paths: list[str], levels: dict[str, int], all_names: list[str]) -> tuple[str, float]:
    assert tree.original_project is not None
    full = dict.fromkeys(all_names, 0) | levels
    tree.project.write_text(settings_text(tree.original_project, full))
    with tempfile.TemporaryDirectory() as tmp:
        listing = Path(tmp) / "list.txt"
        listing.write_text("".join(f"res://{p}\n" for p in paths))
        start = time.monotonic()
        r = subprocess.run(
            [GODOT, "--headless", "-d", "--path", str(tree.root), SCENE, "--", str(listing)],
            capture_output=True,
            text=True,
            stdin=subprocess.DEVNULL,
            timeout=RUN_TIMEOUT_SECONDS,
        )
        elapsed = time.monotonic() - start
    return r.stdout + "\n" + r.stderr, elapsed


def warning_name(word: str) -> str:
    if re.fullmatch(r"[a-z_]+", word) is None:
        raise argparse.ArgumentTypeError(f"not a warning's name: {word}")
    return word


def parse(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        prog="tools/typing_census.py",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""examples:
  uv run python tools/typing_census.py
  uv run python tools/typing_census.py --check
  uv run python tools/typing_census.py --write
  uv run python tools/typing_census.py --lines standalone_expression
""",
    )
    p.add_argument(
        "warnings",
        nargs="*",
        metavar="WARNING",
        type=warning_name,
        help="another warning's name to count (standalone_expression); a name the engine lacks is refused",
    )
    p.add_argument("--check", action="store_true", help="fail where a file's opt-out line is stale or missing a name")
    p.add_argument("--write", action="store_true", help="rewrite each file's opt-out line to what it trips")
    p.add_argument("--lines", action="store_true", help="print the lines themselves, not only the files")
    return p.parse_args(argv)


def folder_of(path: str) -> str:
    parts = path.split("/")
    return "/".join(parts[:2]) if parts[0] == "tests" and len(parts) > 2 else parts[0]


def main(argv: list[str]) -> int:
    args = parse(argv)
    if args.check and args.write:
        print("tools/typing_census.py: --check and --write are exclusive", file=sys.stderr)
        return 2
    if not Path(GODOT).exists():
        print(f"godot not found at {GODOT} (override with GODOT=...)", file=sys.stderr)
        return 127
    tree = Tree(ROOT)
    problem = tree.refuse_if_dirty()
    if problem is not None:
        print(f"tools/typing_census.py: {problem}", file=sys.stderr)
        return 1
    names = installed_warnings()
    if not names:
        print("tools/typing_census.py: could not list the engine's warning names", file=sys.stderr)
        return 1
    unknown = [w for w in args.warnings if w not in names or w in TYPING]
    if unknown:
        print(f"tools/typing_census.py: not another warning of the engine's: {', '.join(unknown)}", file=sys.stderr)
        return 2

    def _on_signal(signum: int, _frame: FrameType | None) -> None:
        tree.restore()
        sys.exit(128 + signum)

    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, _on_signal)
    atexit.register(tree.restore)

    files = tree.gd_files()
    paths = [str(f.relative_to(ROOT)) for f in files]
    tree.original_project = tree.project.read_text()
    tripped: dict[str, set[str]] = {p: set() for p in paths}
    lines: dict[str, list[tuple[int, str]]] = {w: [] for w in (*TYPING, *args.warnings)}
    failed: list[str] = []
    elapsed_total = 0.0
    try:
        tree.take_lines_out(files)
        out, elapsed = run_census(tree, paths, dict.fromkeys(TYPING, 1), names)
        elapsed_total += elapsed
        hits, failed = parse_output(out)
        for h in hits:
            warning = classify(h.message)
            if warning is None:
                print(
                    f"tools/typing_census.py: a warning of none of the three: {h.path}:{h.line}: {h.message}",
                    file=sys.stderr,
                )
                return 1
            if h.path in tripped:
                tripped[h.path].add(warning)
                lines[warning].append((h.line, h.path))
        for extra in args.warnings:
            out, elapsed = run_census(tree, paths, {extra: 1}, names)
            elapsed_total += elapsed
            extra_hits, _ = parse_output(out)
            lines[extra] = [(h.line, h.path) for h in extra_hits if h.path in tripped]
    finally:
        tree.restore()

    bad: list[str] = []
    for f, path in zip(files, paths, strict=True):
        if path in failed:
            continue
        text = f.read_text()
        head, _ = split_first_line(text)
        named = opt_out_names(head)
        trips = tripped[path]
        if named is None:
            if trips:
                bad.append(f"{path}: trips {', '.join(sorted(trips))} and has no opt-out line")
            continue
        for w in TYPING:
            if w in named and w not in trips:
                bad.append(f"{path}: names {w}, which it does not trip")
            if w in trips and w not in named:
                bad.append(f"{path}: trips {w}, which its line does not name")
        if named != [w for w in TYPING if w in set(named)] or len(named) != len(set(named)):
            bad.append(f"{path}: its line is not in the one form")
    if args.write:
        for f, path in zip(files, paths, strict=True):
            text = f.read_text()
            new = text if path in failed else with_line(text, tripped[path])
            if new != text:
                f.write_text(new)
                print(f"rewrote {path}")
    report(tripped, lines, args, failed, elapsed_total)
    if args.check and bad:
        for b in bad:
            print("FAIL " + b)
        return 1
    if args.write:
        for b in (x for x in bad if "no opt-out line" in x):
            print("NO LINE " + b)
    return 0


def report(
    tripped: dict[str, set[str]],
    lines: dict[str, list[tuple[int, str]]],
    args: argparse.Namespace,
    failed: list[str],
    elapsed: float,
) -> None:
    if not args.check and not args.write:
        for path, trips in tripped.items():
            if trips:
                print(f"{path}: {', '.join(w for w in TYPING if w in trips)}")
                if args.lines:
                    for w in TYPING:
                        for line, p in sorted(lines[w]):
                            if p == path:
                                print(f"    {line}: {w}")
    count = Counter(w for trips in tripped.values() for w in trips)
    print(f"{sum(1 for t in tripped.values() if t)} of {len(tripped)} files trip one or more")
    for w in TYPING:
        print(f"  {w}: {count[w]} files, {len(lines[w])} lines")
    for w in args.warnings:
        by_folder = Counter(folder_of(p) for _, p in lines[w])
        print(f"{w}: {len(lines[w])} lines")
        for folder, n in sorted(by_folder.items()):
            print(f"  {folder}: {n}")
        if args.lines:
            for line, p in sorted(lines[w], key=lambda x: (x[1], x[0])):
                print(f"    {p}:{line}")
    if failed:
        print(f"{len(failed)} files failed to load: {', '.join(failed)}")
    print(f"census took {elapsed:.0f}s")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
