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

**What is put back.** `project.godot` is never left changed: it is restored byte for byte on every exit, and the
run refuses to start on a tree where it is already modified. Only a `.gd` file that carried an opt-out line is
touched for the run: its first line is replaced by an empty one (so the line numbers do not move), and afterwards
that empty line is replaced by the original first line, byte for byte (line endings kept). An edit saved to a
script during the run stays: only the first line is put back, and a file whose first line somebody else changed is
named on stderr, with the line not put back, and left as it is found. Every write goes to a file beside the
target, named before it is made, and is moved over it (`os.replace`), so an interrupt never leaves a file empty or
half written and leaves no file beside one: a file holds its old text or its new text. SIGINT, SIGTERM, SIGHUP and
SIGQUIT restore as well, ending with a message (a second signal during the restore is ignored, and the restore is
safe to enter twice); a SIGKILL cannot, and `git checkout project.godot` and `git status` show what is left (a file
beside a script is named `.<script>.<pid>.<n>.census`). `--write` rewrites the first lines after the restore, so
an interrupt during it leaves each file with its old line or its new one.

**A census is taken only from a run that finished and loaded everything it can trust.** The engine must exit 0 and
print `CENSUS_DONE` with the count of files it was handed and one `CENSUS_LOADED` or `CENSUS_FAILED` for each;
otherwise every mode stops with an error and changes no file. It needs the import cache (`.godot/`, made by
`./tools/check.sh`) and refuses to start without it, since without it no `class_name` resolves and most files
fail. A file that fails to load (a syntax error) is named, and `--check` fails for it. A failed file also changes
what the files that depend on it are counted to trip, so `--write` refuses, naming the failed files, when one
is under `src/` or another file names it (by `res://` path, by `class_name` or as an autoload); a failed file
nothing names (a probe that does not parse) is left out and does not stop `--write`. `--check` says the same
refusal in place of the per-file lines, which would be skewed. A file named by a path relative to the naming
file (`preload("sibling.gd")`) or by `uid://` is not seen as named; no script under `src/`, `tests/` or `tools/`
names one that way.

**Another warning.** A warning's name given as an argument (`standalone_expression`) is counted the same way in a
run of its own, per folder with a count, and per line with `--lines`; no file is touched for it.

**`--check`** fails naming file and warning where a file's line names a warning it does not trip or lacks one it
trips, and where a file trips something with no line at all. **`--write`** rewrites each file's first line to
exactly what it trips and deletes the line of a file that trips none; it adds no line to a file without one (such a
file fails the engine already, and is named). `--check` and `--write` together are refused.

**Blind spot.** The census loads files, so an opt-out line inside a string that a suite writes out as a script at
run time (`PROBE` in `tests/test_scene_recipe_runtime.gd` and `tests/test_scene_recipe_activity.gd`) is never read.
Line numbers in `--lines` are those of the file as it stands, the opt-out line counted.
"""

from __future__ import annotations

import argparse
import atexit
import itertools
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from collections import Counter
from collections.abc import Iterable, Iterator, Sequence
from contextlib import contextmanager
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
LOADED = re.compile(r"CENSUS_LOADED (res://\S+)")
DONE = re.compile(r"CENSUS_DONE (\d+)")
SETTING = re.compile(r"^gdscript/warnings/([a-z_]+)=")
CLASS_NAME = re.compile(r"^class_name\s+(\w+)", re.MULTILINE)
# The signals that put the tree back and end the run; SIGKILL cannot be caught.
SIGNALS = (signal.SIGINT, signal.SIGTERM, signal.SIGHUP, signal.SIGQUIT)
# Numbers the files `atomic_write` writes beside their targets, one per call.
_WRITES = itertools.count()


class CensusError(Exception):
    """A run that cannot be taken as a census; the message says why, and no file is changed."""


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
    """The text with its opt-out line replaced by an empty one, when the first line is one.

    The empty line keeps every later line at its number.
    """
    head, rest = split_first_line(text)
    return "\n" + rest if opt_out_names(head) is not None else text


def with_line(text: str, tripped: set[str]) -> str:
    """The text with its first line rewritten to what the file trips (the line deleted when it trips none).

    A file with no opt-out line is returned as it is: nothing is added.
    """
    head, rest = split_first_line(text)
    if opt_out_names(head) is None:
        return text
    if not tripped:
        return rest
    line = opt_out_line(tripped)
    return line.removesuffix("\n") + "\r\n" + rest if head.endswith("\r\n") else line + rest


def check_file(path: str, first_line: str, trips: set[str]) -> list[str]:
    """What `--check` finds in one file: its first line against the warnings it trips."""
    named = opt_out_names(first_line)
    if named is None:
        return [f"{path}: trips {', '.join(sorted(trips))} and has no opt-out line"] if trips else []
    bad: list[str] = []
    for w in TYPING:
        if w in named and w not in trips:
            bad.append(f"{path}: names {w}, which it does not trip")
        if w in trips and w not in named:
            bad.append(f"{path}: trips {w}, which its line does not name")
    if named != [w for w in TYPING if w in set(named)]:
        bad.append(f"{path}: its line is not in the one form")
    return bad


def classify(message: str) -> str | None:
    for name, pattern in MESSAGES:
        if pattern.search(message):
            return name
    return None


def finished(returncode: int, output: str, paths: Sequence[str]) -> str | None:
    """Why a run is not a census (None when it is): the engine's exit, its `CENSUS_DONE` and one line per path."""
    if returncode != 0:
        return f"the engine exited with {returncode}"
    done = DONE.findall(output)
    if len(done) != 1 or int(done[0]) != len(paths):
        return f"the scene did not print CENSUS_DONE {len(paths)}"
    answered = Counter(m.removeprefix("res://") for m in (*LOADED.findall(output), *FAILED.findall(output)))
    unanswered = [p for p in paths if answered[p] != 1]
    if unanswered:
        return f"{len(unanswered)} files were not loaded or failed exactly once, such as {unanswered[0]}"
    return None


def untrusted_failures(failed: Sequence[str], texts: dict[str, str], project_text: str) -> list[str]:
    """The failed files whose failing changes what other files are counted to trip.

    A failed file under `src/`, one named by another listed file (by its `res://` path or its `class_name`) or one
    that is an autoload. A failed file nothing names, such as a probe that does not parse, is not one.
    """
    out: list[str] = []
    for path in failed:
        text = texts.get(path, "")
        names = CLASS_NAME.findall(text)
        others = [t for p, t in texts.items() if p != path]
        named = any(f"res://{path}" in t for t in others) or any(
            re.search(rf"\b{re.escape(n)}\b", t) for n in names for t in others
        )
        if path.startswith("src/") or named or f"res://{path}" in project_text:
            out.append(path)
    return out


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


def atomic_write(path: Path, data: bytes) -> None:
    """Writes `data` beside `path` and moves it over, so `path` holds its old bytes or the new ones, never none.

    The file beside is named before it is made and made inside the `try`, so the `finally` removes it whatever
    interrupts the write; a name made by the call that creates the file (`tempfile.mkstemp`) is not known yet when
    a signal handled during that call ends the write, and the file stays behind. The name is new on every call,
    since a restore run by the signal handler writes again while the write it interrupted is still open.
    """
    temp = path.with_name(f".{path.name}.{os.getpid()}.{next(_WRITES)}.census")
    try:
        fd = os.open(temp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        try:
            view = memoryview(data)
            while view:
                view = view[os.write(fd, view) :]
        finally:
            os.close(fd)
        shutil.copymode(path, temp)
        temp.replace(path)
    finally:
        temp.unlink(missing_ok=True)


class Tree:
    """The files read and the state to put back."""

    def __init__(self, root: Path) -> None:
        self.root = root
        self.project = root / "project.godot"
        self.original_project: bytes | None = None
        # The first line of each file whose line was replaced for the run, as read.
        self.first_lines: dict[Path, bytes] = {}

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
        """Puts back `project.godot` and the first lines taken out, and only those, byte for byte.

        Safe to enter twice: an entry leaves `first_lines` once its line is back, and a file already holding
        its line is not named. A file whose first line is no longer the empty one put there is named on stderr
        with the line not put back, and left as found.
        """
        if self.original_project is not None:
            atomic_write(self.project, self.original_project)
            self.original_project = None
        for path, head in list(self.first_lines.items()):
            current = path.read_bytes() if path.exists() else b""
            if current.startswith(b"\n"):
                atomic_write(path, head + current[1:])
            elif not current.startswith(head):
                shown = path.relative_to(self.root) if path.is_relative_to(self.root) else path
                print(
                    f"tools/typing_census.py: {shown} was changed during the run; left as it is "
                    f"(its first line was {head.decode('utf-8').rstrip()})",
                    file=sys.stderr,
                )
            self.first_lines.pop(path, None)

    def take_lines_out(self, files: Sequence[Path]) -> None:
        for path in files:
            raw = path.read_bytes()
            text = raw.decode("utf-8")
            if without_line(text) == text:
                continue
            head = split_first_line(text)[0].encode("utf-8")
            self.first_lines[path] = head
            atomic_write(path, b"\n" + raw[len(head) :])


def installed_warnings(root: Path, godot: str) -> list[str]:
    """Every warning name the project's settings file lists, read from the engine's own setting names."""
    r = subprocess.run(
        [godot, "--headless", "--path", str(root), "--script", "res://tools/typing_census_names.gd"],
        capture_output=True,
        text=True,
    )
    return [ln.removeprefix("CENSUS_WARNING ") for ln in r.stdout.splitlines() if ln.startswith("CENSUS_WARNING ")]


def run_census(
    tree: Tree, godot: str, paths: list[str], levels: dict[str, int], all_names: list[str]
) -> tuple[str, float]:
    """The engine's output of one census run; a run that is not one raises `CensusError`."""
    assert tree.original_project is not None
    full = dict.fromkeys(all_names, 0) | levels
    atomic_write(tree.project, settings_text(tree.original_project.decode("utf-8"), full).encode("utf-8"))
    with tempfile.TemporaryDirectory() as tmp:
        listing = Path(tmp) / "list.txt"
        listing.write_text("".join(f"res://{p}\n" for p in paths))
        start = time.monotonic()
        try:
            r = subprocess.run(
                [godot, "--headless", "-d", "--path", str(tree.root), SCENE, "--", str(listing)],
                capture_output=True,
                text=True,
                stdin=subprocess.DEVNULL,
                timeout=RUN_TIMEOUT_SECONDS,
            )
        except subprocess.TimeoutExpired:
            raise CensusError(f"the engine was stuck after {RUN_TIMEOUT_SECONDS} s; no file was changed") from None
        elapsed = time.monotonic() - start
    output = r.stdout + "\n" + r.stderr
    why = finished(r.returncode, output, paths)
    if why is not None:
        raise CensusError(f"the run did not finish ({why}); no file was changed")
    return output, elapsed


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
    args = p.parse_args(argv)
    if args.check and args.write:
        p.error("--check and --write are exclusive")
    return args


def folder_of(path: str) -> str:
    parts = path.split("/")
    return "/".join(parts[:2]) if parts[0] == "tests" and len(parts) > 2 else parts[0]


def main(argv: list[str], root: Path = ROOT, godot: str = GODOT) -> int:
    args = parse(argv)
    if not Path(godot).exists():
        print(f"godot not found at {godot} (override with GODOT=...)", file=sys.stderr)
        return 127
    if not (root / ".godot" / "global_script_class_cache.cfg").exists():
        print("tools/typing_census.py: no import cache (.godot/); run ./tools/check.sh first", file=sys.stderr)
        return 1
    tree = Tree(root)
    problem = tree.refuse_if_dirty()
    if problem is not None:
        print(f"tools/typing_census.py: {problem}", file=sys.stderr)
        return 1
    names = installed_warnings(root, godot)
    if not names:
        print("tools/typing_census.py: could not list the engine's warning names", file=sys.stderr)
        return 1
    unknown = [w for w in args.warnings if w not in names or w in TYPING]
    if unknown:
        print(f"tools/typing_census.py: not another warning of the engine's: {', '.join(unknown)}", file=sys.stderr)
        return 2

    with put_back_on_every_exit(tree):
        return census(args, tree, godot, names)


@contextmanager
def put_back_on_every_exit(tree: Tree) -> Iterator[None]:
    """Puts the tree back when the block ends, at exit, and on each of `SIGNALS`, which then ends the process.

    The handler ignores every further signal before it restores, so a second Ctrl-C cannot cut the restore short.
    """

    def _on_signal(signum: int, _frame: FrameType | None) -> None:
        for sig in SIGNALS:
            signal.signal(sig, signal.SIG_IGN)
        tree.restore()
        print(
            f"tools/typing_census.py: interrupted (signal {signum}); project.godot and the opt-out lines taken out "
            "for the run are put back",
            file=sys.stderr,
        )
        sys.exit(128 + signum)

    previous = {sig: signal.signal(sig, _on_signal) for sig in SIGNALS}
    atexit.register(tree.restore)
    try:
        yield
    finally:
        tree.restore()
        atexit.unregister(tree.restore)
        for sig, handler in previous.items():
            signal.signal(sig, handler)


def census(args: argparse.Namespace, tree: Tree, godot: str, names: list[str]) -> int:
    """Takes the census and answers the mode; the tree is put back by the caller on every way out."""
    files = tree.gd_files()
    paths = [str(f.relative_to(tree.root)) for f in files]
    tree.original_project = tree.project.read_bytes()
    tripped: dict[str, set[str]] = {p: set() for p in paths}
    lines: dict[str, set[tuple[int, str]]] = {w: set() for w in (*TYPING, *args.warnings)}
    elapsed_total = 0.0
    try:
        tree.take_lines_out(files)
        out, elapsed = run_census(tree, godot, paths, dict.fromkeys(TYPING, 1), names)
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
                lines[warning].add((h.line, h.path))
        for extra in args.warnings:
            out, elapsed = run_census(tree, godot, paths, {extra: 1}, names)
            elapsed_total += elapsed
            extra_hits, _ = parse_output(out)
            lines[extra] = {(h.line, h.path) for h in extra_hits if h.path in tripped}
    except CensusError as e:
        print(f"tools/typing_census.py: {e}", file=sys.stderr)
        return 1
    finally:
        tree.restore()

    texts = {path: f.read_bytes().decode("utf-8") for f, path in zip(files, paths, strict=True)}
    report(tripped, lines, args, failed, elapsed_total)
    untrusted = untrusted_failures(failed, texts, tree.project.read_bytes().decode("utf-8"))
    if untrusted and (args.write or args.check):
        mode = "--write refused, no file changed" if args.write else "--check cannot compare the lines"
        print(
            f"tools/typing_census.py: {mode}: a file others depend on failed to load "
            f"({', '.join(untrusted)}), so what the rest trip is not the census of a tree that loads",
            file=sys.stderr,
        )
        return 1
    bad: list[str] = []
    for path in paths:
        if path not in failed:
            bad.extend(check_file(path, split_first_line(texts[path])[0], tripped[path]))
    if args.write:
        for f, path in zip(files, paths, strict=True):
            new = texts[path] if path in failed else with_line(texts[path], tripped[path])
            if new != texts[path]:
                atomic_write(f, new.encode("utf-8"))
                print(f"rewrote {path}")
        for b in (x for x in bad if "no opt-out line" in x):
            print("NO LINE " + b)
        return 0
    if args.check:
        for b in bad:
            print("FAIL " + b)
        for path in failed:
            print(f"FAIL {path}: failed to load, so its line cannot be checked")
        return 1 if bad or failed else 0
    return 0


def report(
    tripped: dict[str, set[str]],
    lines: dict[str, set[tuple[int, str]]],
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
