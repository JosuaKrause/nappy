#!/usr/bin/env python3
"""Puts a class's public fields behind methods: renames each field private and rewrites every use to the method call.

designing-classes' "Fields are not API": one object reaches another only through its methods. This is the rewrite
that turns `var map: CityMap` of a class into a private `_map` read through `map()`, in three steps:

1. In a scratch copy of the checkout (never in the checkout itself), each field is renamed to `_name` in its class's
   own file (which refuses a local, loop variable or parameter of the same name first, since the rename is by
   name), where the class declares it: every use on a line that is not a whole-line comment, bare or after
   `self.`, and never a call of a method of the same name. An inner class's block is left alone.
2. The scratch copy is loaded script by script in the engine (`tools/field_to_method_probe.tscn`), which refuses every
   use of the field it can type outside the class's file as "The property X is not present on the inferred type T".
   Each refused use is renamed to `._X` in the copy and the load repeated, until no refusal is left. A subclass of
   the class (a test's recording subclass, an inner class included) counts as the class. The result is one
   `file:line:index Class.field` per use, the index being which `.X` of the line it is, counting from 0.
3. In the checkout, each listed use `.X` becomes `.method()` (`.X()` when the method is named like the field), and the
   class's file is renamed as in step 1. Nothing is written until every use is placed: a use that is not there, or
   is already private, or a script the engine still refuses that it loaded before, stops the run with nothing written.

It does not write the method: it prints the stub `func name() -> Type:` for the class's file, with the type of the
declaration where the declaration names one, and the doc line, the placement and the tests are by hand. It prints
after the rewrite what it cannot see and a person has to read: every remaining use of the old name without
parentheses under `src/`, `tests/` and `tools/`, every `get("name")`-style use of it, and the lines of
`tools/field_reads.txt` and `tools/test_only_members.txt` that name the field. A property read through a receiver the
engine types as a Variant (a Dictionary's value, an untyped var) is not seen by the engine, and nor is a use inside a
string a suite writes out and boots; the remaining-uses list is how those are found.

A scratch copy needs the engine's class cache, so it runs `godot --headless --import` first. Godot is
`$GODOT`, or `/Applications/Godot.app/Contents/MacOS/Godot`; `--godot` names another.

usage: tools/field_to_method.py [--help|-h] [--dry-run] [--godot PATH] [--root DIR] CLASS_FILE FIELD[=METHOD] [...]

  CLASS_FILE   the file declaring the class (`class_name`), relative to the root, e.g. src/city/city.gd
  FIELD        a public `var` of that class; `FIELD=METHOD` names a method other than the field's own name
  --dry-run    list the uses and the count of rewrites; write nothing in the checkout
  --godot PATH the engine binary (default: $GODOT, or the macOS application's)
  --root DIR   the checkout to rewrite (default: the one this file is in)

  uv run python tools/field_to_method.py --dry-run src/city/city.gd map
  uv run python tools/field_to_method.py src/crowd/crowd.gd lanes=lane_set
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections.abc import Callable
from dataclasses import dataclass, field
from pathlib import Path

DEFAULT_GODOT = "/Applications/Godot.app/Contents/MacOS/Godot"
PROBE_SCENE = "res://tools/field_to_method_probe.tscn"
PROBE_FILES = ("field_to_method_probe.gd", "field_to_method_probe.tscn")
SCAN_ROOTS = ("src", "tests", "tools")
# The top-level entries of a checkout the scratch copy leaves out: they hold no script the parser loads.
SKIP_TOP = {".git", ".venv", ".claude", ".agents", ".codex", ".github", "docs", "art", "build"}

ERR = re.compile(
    r'Parse Error: (?:The property "(\w+)" is not present on the inferred type "([\w.]+)"'
    r'|Cannot find member "(\w+)" in base "([\w.]+)")'
)
AT = re.compile(r"\(res://(.+?):(\d+)\)")
CLASS = re.compile(r"^class_name\s+(\w+)", re.M)
NAME = re.compile(r"^[a-z][a-z0-9_]*$")


class Refusal(Exception):
    """A reason to stop before anything is written."""


@dataclass
class Spec:
    """One field to put behind a method."""

    name: str
    method: str


@dataclass
class Reader:
    """One use the engine refused: the index-th `.name` of a line, read through a class."""

    path: str
    line: int
    index: int
    cls: str
    name: str


@dataclass
class Probe:
    """What one load of every script said."""

    hits: list[tuple[str, int, str, str]] = field(default_factory=list)
    failed: set[str] = field(default_factory=set)
    done: bool = False


def dotted_use(name: str) -> re.Pattern[str]:
    """Every `.name` or `._name` use of a field that is not a call and not a longer name."""
    return re.compile(r"\.(_?)" + re.escape(name) + r"(?![A-Za-z0-9_(])")


def private_name(name: str) -> str:
    return "_" + name


def declares_public_var(text: str, name: str) -> bool:
    return re.search(r"^(static |@export |@onready )*var\s+" + re.escape(name) + r"\b", text, re.M) is not None


def declares_member(text: str, name: str) -> bool:
    pattern = r"^\s*(var|func|static func|const|signal)\s+" + re.escape(name) + r"\b"
    return re.search(pattern, text, re.M) is not None


def declared_type(text: str, name: str) -> str | None:
    """The type a public var's declaration names (`var map: CityMap`), or None where it names none."""
    m = re.search(r"^(?:static |@export |@onready )*var\s+" + re.escape(name) + r"\s*:\s*([\w.\[\]]+)", text, re.M)
    return m.group(1) if m else None


def shadowing_locals(text: str, name: str) -> list[str]:
    """The lines of a class's own text, outside inner classes and comments, where a local, a loop variable or a
    parameter is named like the field: the rename is by name, so it would rename that one too."""
    found: list[str] = []
    inner = False
    local = re.compile(r"^\s+(?:var|const)\s+" + re.escape(name) + r"\b|^\s+for\s+" + re.escape(name) + r"\b")
    param = re.compile(r"^\s*(?:static\s+)?func\s+\w+\s*\((?:.*,)?\s*" + re.escape(name) + r"\s*[:,)=]")
    for n, line in enumerate(text.split("\n"), start=1):
        if re.match(r"class\s+\w+", line):
            inner = True
        elif line and not line[0].isspace() and not line.startswith("#"):
            inner = False
        if inner or line.lstrip().startswith("#"):
            continue
        if local.search(line) or param.search(line):
            found.append(f"{n}: {line.strip()}")
    return found


def check_specs(path: str, text: str, specs: list[Spec]) -> None:
    """Refuses a class file that cannot take the rename: no class, a field not public, a name already taken."""
    if CLASS.search(text) is None:
        raise Refusal(f"{path} declares no class_name: only a file's own class can have its fields renamed")
    seen: set[str] = set()
    for spec in specs:
        if spec.name in seen:
            raise Refusal(f"{spec.name} is named twice")
        seen.add(spec.name)
        if spec.name.startswith("_"):
            raise Refusal(f"{spec.name} is already private")
        if not declares_public_var(text, spec.name):
            raise Refusal(f"{path} declares no public var {spec.name}")
        if declares_member(text, private_name(spec.name)):
            raise Refusal(f"{path} already declares {private_name(spec.name)}")
        if spec.method != spec.name and declares_member(text, spec.method):
            raise Refusal(f"{path} already declares {spec.method}")
        if re.search(r"^\s*(static )?func\s+" + re.escape(spec.method) + r"\b", text, re.M):
            raise Refusal(f"{path} already declares a method {spec.method}()")
        shadows = shadowing_locals(text, spec.name)
        if shadows:
            raise Refusal(
                f"{path} names a local or a parameter {spec.name} too, which the rename by name would rename"
                " with the field; rename it first:\n  " + "\n  ".join(shadows)
            )


def rename_fields(text: str, names: list[str]) -> str:
    """Renames each public field to its private name in the class's own text, outside inner classes and comments."""
    lines = text.split("\n")
    joined = text
    for name in names:
        if not declares_public_var(joined, name):
            continue
        new = private_name(name)
        bare = re.compile(r"(?<![\w.$&\"'@])" + re.escape(name) + r"\b(?!\s*\()")
        selfed = re.compile(r"\bself\." + re.escape(name) + r"\b(?!\s*\()")
        inner = False
        for i, line in enumerate(lines):
            if re.match(r"class\s+\w+", line):
                inner = True
            elif line and not line[0].isspace() and not line.startswith("#"):
                inner = False
            if inner or line.lstrip().startswith("#"):
                continue
            line = selfed.sub("self." + new, line)
            lines[i] = bare.sub(new, line)
        joined = "\n".join(lines)
    return joined


def subclasses(root: Path, names: dict[str, set[str]]) -> dict[str, set[str]]:
    """Adds every class that extends a renamed class, an inner class included, with its ancestor's fields."""
    parent: dict[str, str] = {}
    for top in SCAN_ROOTS:
        for path in sorted((root / top).rglob("*.gd")):
            text = path.read_text(encoding="utf-8")
            cn = CLASS.search(text)
            ex = re.search(r"^extends\s+(\w+)", text, re.M)
            if cn and ex:
                parent[cn.group(1)] = ex.group(1)
            for m in re.finditer(r"^\s*class\s+(\w+)\s+extends\s+(\w+)", text, re.M):
                parent.setdefault(m.group(1), m.group(2))
    changed = True
    while changed:
        changed = False
        for child, base in parent.items():
            if base in names and not names[base] <= names.get(child, set()):
                names.setdefault(child, set()).update(names[base])
                changed = True
    return names


def parse_run(output: str) -> Probe:
    """Reads the engine's output of one load of every script."""
    lines = output.splitlines()
    probe = Probe()
    for i, line in enumerate(lines):
        m = ERR.search(line)
        at = AT.search(lines[i + 1]) if i + 1 < len(lines) else None
        if m and at:
            probe.hits.append((at.group(1), int(at.group(2)), m.group(2) or m.group(4), m.group(1) or m.group(3)))
        if line.startswith("PROBE_FAILED "):
            probe.failed.add(line.split(" ", 1)[1].strip().removeprefix("res://"))
        if line.startswith("PROBE_DONE "):
            probe.done = True
    return probe


def run_probe(godot: str, copy: Path) -> Probe:
    out = subprocess.run(
        [godot, "--headless", "--path", str(copy), PROBE_SCENE], capture_output=True, text=True, check=False
    )
    probe = parse_run(out.stdout + out.stderr)
    if not probe.done:
        raise Refusal("the engine did not finish loading the scripts:\n" + (out.stdout + out.stderr)[-1500:])
    return probe


def find_readers(
    copy: Path, names: dict[str, set[str]], probe_again: Callable[[], Probe], log: Callable[[str], None]
) -> tuple[list[Reader], Probe]:
    """The fix loop: each use the engine refuses is renamed in the copy, until the engine refuses nothing it can place.

    Where a refused name is a renamed field on a class that was not renamed (two classes' same-named fields on one
    line), the last occurrence renamed on that line goes back and is marked not this class's."""
    all_fields = set().union(*names.values())
    state: dict[tuple[str, int, str], dict[int, tuple[str, int] | None]] = {}
    rounds = 0
    while True:
        rounds += 1
        probe = probe_again()
        acted = False
        by_file: dict[str, list[tuple[int, int, str, str]]] = {}
        for f, ln, cls, name in sorted(set(probe.hits)):
            by_file.setdefault(f, []).append((0 if name.startswith("_") else 1, ln, cls, name))
        for f, items in by_file.items():
            path = copy / f
            text = path.read_text(encoding="utf-8").split("\n")
            for _order, ln, cls, name in sorted(items):
                if cls in names and name in names[cls] and not dotted_use(name).search(text[ln - 1]):
                    # a chain broken over lines is reported at the line its statement's call opens on
                    for ahead in range(ln + 1, min(ln + 4, len(text) + 1)):
                        if dotted_use(name).search(text[ahead - 1]):
                            ln = ahead
                            break
                line = text[ln - 1]
                if cls in names and name in names[cls]:
                    marks = state.setdefault((f, ln, name), {})
                    spans = [(m.start(), m.group(1) == "_") for m in dotted_use(name).finditer(line)]
                    free = [i for i, (_pos, renamed) in enumerate(spans) if not renamed and i not in marks]
                    if not free:
                        continue
                    i = free[0]
                    pos = spans[i][0]
                    line = line[:pos] + "._" + line[pos + 1 :]
                    marks[i] = (cls, rounds)
                    acted = True
                elif name.startswith("_") and name[1:] in all_fields:
                    marks = state.get((f, ln, name[1:]), {})
                    earlier = [(c[1], i) for i, c in marks.items() if c is not None and c[1] < rounds]
                    if earlier:
                        i = max(earlier)[1]
                        spans = [(m.start(), m.group(1) == "_") for m in dotted_use(name[1:]).finditer(line)]
                        pos = spans[i][0]
                        line = line[:pos] + "." + line[pos + 2 :]
                        marks[i] = None
                        acted = True
                text[ln - 1] = line
            path.write_text("\n".join(text), encoding="utf-8")
        log(f"  round {rounds}: the engine refused {len(probe.hits)} uses")
        if not acted:
            break
    readers: list[Reader] = []
    for (f, ln, name), marks in sorted(state.items()):
        for i, mark in sorted(marks.items()):
            if mark is not None:
                readers.append(Reader(f, ln, i, mark[0], name))
    return readers, probe


def rewrite_text(path: str, text: str, uses: list[Reader], methods: dict[str, str]) -> tuple[str, int]:
    """Turns each listed use into its method call; raises Refusal at a use that is not there or already private."""
    lines = text.split("\n")
    done = 0
    by_line: dict[int, list[Reader]] = {}
    for use in uses:
        by_line.setdefault(use.line, []).append(use)
    for ln, line_uses in sorted(by_line.items()):
        if ln > len(lines):
            raise Refusal(f"{path}:{ln}: the line is not there")
        line = lines[ln - 1]
        for use in sorted(line_uses, key=lambda u: (u.name, -u.index)):
            spans = list(dotted_use(use.name).finditer(line))
            if use.index >= len(spans):
                raise Refusal(f"{path}:{ln}: no use {use.index} of .{use.name} to place: {line.strip()}")
            span = spans[use.index]
            if span.group(1) == "_":
                raise Refusal(f"{path}:{ln}: the use {use.index} of .{use.name} is already private: {line.strip()}")
            line = line[: span.start()] + "." + methods[use.name] + "()" + line[span.end() :]
            done += 1
        lines[ln - 1] = line
    return "\n".join(lines), done


def gd_files(root: Path) -> list[Path]:
    out: list[Path] = []
    for top in SCAN_ROOTS:
        out.extend(sorted((root / top).rglob("*.gd")))
    return out


def remaining_hits(root: Path, texts: dict[str, str], specs: list[Spec]) -> list[str]:
    """The uses of an old name without parentheses and the string forms of it, read from the planned texts."""
    hits: list[str] = []
    for path in gd_files(root):
        rel = path.relative_to(root).as_posix()
        text = texts.get(rel)
        if text is None:
            text = path.read_text(encoding="utf-8")
        for n, line in enumerate(text.split("\n"), start=1):
            for spec in specs:
                bare = re.search(r"\." + re.escape(spec.name) + r"\b(?!\()", line)
                strung = re.search(
                    r"\b(?:get|set|get_indexed|set_indexed|has_method|call)\(\s*[\"']"
                    + re.escape(spec.name)
                    + r"[\"']",
                    line,
                )
                if bare or strung:
                    hits.append(f"{rel}:{n}: {line.strip()}")
                    break
    return hits


def list_lines(root: Path, class_name: str, class_path: str, specs: list[Spec]) -> list[str]:
    """The lines of the two lists that name one of the fields, for the person to delete or re-explain."""
    found: list[str] = []
    names = {s.name for s in specs}
    reads = root / "tools" / "field_reads.txt"
    if reads.exists():
        inside = False
        for line in reads.read_text(encoding="utf-8").split("\n"):
            if line.startswith("# ["):
                inside = line.startswith(f"# [{class_name}]")
            elif inside and line and not line.startswith("#") and line.split()[-1] in names:
                found.append(f"tools/field_reads.txt: {line}")
    only = root / "tools" / "test_only_members.txt"
    if only.exists():
        for line in only.read_text(encoding="utf-8").split("\n"):
            parts = line.split()
            if len(parts) >= 2 and parts[0] == class_path and parts[1] in names:
                found.append(f"tools/test_only_members.txt: {line[:120]}")
    return found


def make_scratch(root: Path, dest: Path) -> None:
    """Copies what the engine parses: the project's top-level entries but the ones that hold no script."""
    for entry in sorted(root.iterdir()):
        if entry.name in SKIP_TOP:
            continue
        if entry.is_dir():
            shutil.copytree(entry, dest / entry.name, symlinks=True)
        else:
            shutil.copy2(entry, dest / entry.name)
    # the probe is this tool's own, so a checkout older than the tool is probed as well
    (dest / "tools").mkdir(exist_ok=True)
    for name in PROBE_FILES:
        shutil.copy2(Path(__file__).resolve().parent / name, dest / "tools" / name)


def plan(
    root: Path, class_path: str, specs: list[Spec], godot: str, log: Callable[[str], None]
) -> tuple[dict[str, str], list[Reader], str, str]:
    """Runs the three steps' reading half; returns the new text of each file to write, the uses, the class name and
    the class file's text as it was before the rename (the stub's types are read from it)."""
    class_file = root / class_path
    if not class_file.is_file():
        raise Refusal(f"{class_path} is not a file under {root}")
    original = class_file.read_text(encoding="utf-8")
    check_specs(class_path, original, specs)
    cn = CLASS.search(original)
    assert cn is not None
    class_name = cn.group(1)
    methods = {s.name: s.method for s in specs}
    with tempfile.TemporaryDirectory(prefix="field-to-method-") as scratch_dir:
        copy = Path(scratch_dir)
        log("copying the project to a scratch directory")
        make_scratch(root, copy)
        log("importing the scratch copy")
        subprocess.run([godot, "--headless", "--import", "--path", str(copy)], capture_output=True, check=False)
        log("loading every script before the rename")
        baseline = run_probe(godot, copy)
        scratch_class = copy / class_path
        scratch_class.write_text(rename_fields(original, [s.name for s in specs]), encoding="utf-8")
        names = subclasses(copy, {class_name: {s.name for s in specs}})
        log("loading every script after the rename")
        readers, last = find_readers(copy, names, lambda: run_probe(godot, copy), log)
    broken = sorted(last.failed - baseline.failed)
    if broken:
        raise Refusal(
            "scripts the engine refuses after the rename and loaded before, with no use it could place:\n  "
            + "\n  ".join(broken)
        )
    by_file: dict[str, list[Reader]] = {}
    for use in readers:
        by_file.setdefault(use.path, []).append(use)
    texts: dict[str, str] = {}
    for rel, uses in sorted(by_file.items()):
        text = (root / rel).read_text(encoding="utf-8")
        texts[rel], _ = rewrite_text(rel, text, uses, methods)
    base = texts.get(class_path, original)
    texts[class_path] = rename_fields(base, [s.name for s in specs])
    return texts, readers, class_name, original


def stubs(original: str, specs: list[Spec]) -> list[str]:
    out: list[str] = []
    for spec in specs:
        typ = declared_type(original, spec.name)
        out.append(f"func {spec.method}() -> {typ or 'Variant'}:\n\treturn {private_name(spec.name)}")
    return out


def parse_args(argv: list[str]) -> argparse.Namespace:
    examples = (__doc__ or "").split("\n\n  CLASS_FILE", 1)[1].split("\n\n", 1)[1]
    parser = argparse.ArgumentParser(
        prog="tools/field_to_method.py",
        description="Puts a class's public fields behind methods: renames each private, rewrites every use.",
        epilog="examples:\n" + examples,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--dry-run", action="store_true", help="list the uses and the count; write nothing")
    parser.add_argument("--godot", default=os.environ.get("GODOT", DEFAULT_GODOT), help="the engine binary")
    parser.add_argument("--root", default=str(Path(__file__).resolve().parent.parent), help="the checkout")
    parser.add_argument("class_file", help="the file declaring the class, relative to the root")
    parser.add_argument("fields", nargs="+", metavar="FIELD[=METHOD]", help="a public var to put behind a method")
    return parser.parse_args(argv)


def parse_specs(words: list[str]) -> list[Spec]:
    specs: list[Spec] = []
    for word in words:
        name, _, method = word.partition("=")
        if not NAME.match(name) or (method and not NAME.match(method)):
            raise Refusal(f"{word!r} is not FIELD or FIELD=METHOD, each a lowercase name")
        specs.append(Spec(name, method or name))
    return specs


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    root = Path(args.root).resolve()
    given = Path(args.class_file)
    class_path = os.path.relpath(given if given.is_absolute() else root / given, root)
    try:
        specs = parse_specs(args.fields)
        if not Path(args.godot).is_file() or not os.access(args.godot, os.X_OK):
            raise Refusal(f"no engine at {args.godot} (GODOT=... or --godot)")
        texts, readers, class_name, original = plan(
            root, class_path, specs, args.godot, lambda s: print(s, file=sys.stderr)
        )
    except Refusal as why:
        print(f"refused, nothing written: {why}", file=sys.stderr)
        return 1
    by_file: dict[str, int] = {}
    for use in readers:
        by_file[use.path] = by_file.get(use.path, 0) + 1
    for rel, count in sorted(by_file.items()):
        print(f"{count:5d}  {rel}")
    lines = len({(u.path, u.line) for u in readers})
    print(f"{len(readers)} uses on {lines} lines in {len(by_file)} files (the class's own file renamed as well)")
    if args.dry_run:
        for use in readers:
            print(f"{use.path}:{use.line}:{use.index} {use.cls}.{use.name}")
        print("dry run: nothing written")
    else:
        for rel, text in sorted(texts.items()):
            (root / rel).write_text(text, encoding="utf-8")
        print(f"wrote {len(texts)} files")
    print("\nadd to " + class_path + " (with its doc line):")
    for stub in stubs(original, specs):
        print("\n" + stub)
    left = remaining_hits(root, texts, specs)
    print(f"\nremaining uses of the old name without parentheses, or by string ({len(left)}); say why each stays:")
    for hit in left:
        print("  " + hit)
    kept = list_lines(root, class_name, class_path, specs)
    print(f"\nlines of the two lists that name the fields ({len(kept)}); delete or re-explain each:")
    for line in kept:
        print("  " + line)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
