#!/usr/bin/env python3
"""Fails when an override of a project class is unmarked, or a mark is false.

GDScript has no `@override` annotation, and a misspelled override is a new method that nothing
reports. So every method that overrides a method of a project ancestor class carries a line of its
doc comment, `## Overrides <Class>.<method>.`, and this check holds that true against the tree
(inbox #1154 in gray-dolphin):

- an override of a method a project ancestor declares, with no such line, **fails**;
- a line on a method that overrides nothing (a misspelled name that carries the line), one naming
  a class that is not the nearest ancestor declaring the method, any further line of the same method
  that is false, and any `##` line starting with `Overrides` (in any case) that is not exactly that
  form, **fails**. A misspelled method with no line at all is a new method to this check;
- an `extends` it cannot resolve (a `uid://` path, a path naming no file under `src/` or `tests/`, a
  `preload` constant naming none) **fails**; a bare name that is none of the project's is taken to be an
  engine class.

`<Class>` is the nearest ancestor that declares the method: its `class_name`, `Outer.Inner` for an
inner class, and the file's stem for a class extended by path that has no `class_name`. Only
project ancestors count (the `.gd` files under `src/` and `tests/`): an engine virtual such as
`_ready` or `_draw` that no project ancestor declares needs no line. `_init` is a constructor, not
an override, and takes none. The line sits among the doc-comment (`##`) lines directly above the
`func` (an annotation line such as `@abstract` may stand between).

`extends` is resolved by `class_name`, by path (`res://`, or relative to the file), through a `preload`
constant, and through inner classes (a sibling's or a base's, by its short name). The files are read
as text, so no engine is needed. `--root` reads another checkout, `--rev` the tree of a commit.

This runs under the host's own `python3` (tools/lint.sh calls it), so it stays 3.9-compatible.

  uv run python tools/check_overrides.py
  uv run python tools/check_overrides.py --rev origin/main
"""

from __future__ import annotations

import argparse
import posixpath
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FOLDERS = ("src", "tests")
CONSTRUCTORS = frozenset({"_init", "_static_init"})

ANNOTATIONS = r"(?:@\w+(?:\([^)]*\))?[ \t]+)*"
EXTENDS = r'("[^"]+"(?:\.\w+)*|[\w.]+)'
HEADER_CLASS_NAME = re.compile(r"^" + ANNOTATIONS + r"class_name[ \t]+(\w+)(?:[ \t]+extends[ \t]+" + EXTENDS + r")?")
HEADER_EXTENDS = re.compile(r"^" + ANNOTATIONS + r"extends[ \t]+" + EXTENDS)
INNER_CLASS = re.compile(
    r"^([ \t]*)" + ANNOTATIONS + r"class[ \t]+(\w+)(?:[ \t]+extends[ \t]+" + EXTENDS + r")?[ \t]*:"
)
FUNC = re.compile(r"^([ \t]*)" + ANNOTATIONS + r"(?:static[ \t]+)?func[ \t]+(\w+)")
ANNOTATION_ONLY = re.compile(r"^[ \t]*@\w+(?:\([^)]*\))?[ \t]*$")
MARK = re.compile(r"^##[ \t]*Overrides[ \t]+([\w.]+)\.(\w+)\.[ \t]*$")


CONST_LOAD = re.compile(
    r"^[ \t]*const[ \t]+(\w+)[ \t]*(?::[ \t]*\w*)?[ \t]*:?=[ \t]*(?:preload|load)\([ \t]*(\"[^\"]+\")"
)


@dataclass
class Marks:
    """What the `##` lines directly above a method say: the well-formed lines and the malformed ones."""

    good: list[str] = field(default_factory=list)
    malformed: list[str] = field(default_factory=list)


@dataclass
class GdClass:
    """One class: a file's top level or an inner class."""

    name: str
    path: str
    extends: str | None
    parent_scope: GdClass | None = None
    extends_line: int = 1
    inner: dict[str, GdClass] = field(default_factory=dict)
    consts: dict[str, str] = field(default_factory=dict)
    methods: dict[str, int] = field(default_factory=dict)
    marks: dict[str, Marks] = field(default_factory=dict)


def scan_line(line: str, in_triple: bool) -> tuple[str, bool]:
    """The code of one line, its comment and the inside of a `\"\"\"` string removed, and whether a
    triple-quoted string is still open at its end. Single-line strings stay as written."""
    if not in_triple and '"' not in line and "'" not in line and "#" not in line:
        return line, False
    out: list[str] = []
    i = 0
    while i < len(line):
        if in_triple:
            end = line.find('"""', i)
            if end < 0:
                return "".join(out), True
            i = end + 3
            in_triple = False
        elif line.startswith('"""', i):
            in_triple = True
            i += 3
        elif line[i] in "\"'":
            j = i + 1
            while j < len(line) and line[j] != line[i]:
                j += 2 if line[j] == "\\" else 1
            out.append(line[i : j + 1])
            i = j + 1
        elif line[i] == "#":
            break
        else:
            out.append(line[i])
            i += 1
    return "".join(out), in_triple


def parse_file(path: str, text: str) -> GdClass:
    """The class tree of one file: its top level (named by `class_name`, else the file's stem)."""
    lines = text.splitlines()
    top = GdClass(Path(path).stem, path, None)
    stack: list[tuple[int, GdClass]] = []
    in_string = False
    for number, raw in enumerate(lines, start=1):
        began_in_string = in_string
        code, in_string = scan_line(raw, in_string)
        if began_in_string or not code.strip():
            continue
        indent = len(code) - len(code.lstrip())
        while stack and indent <= stack[-1][0]:
            stack.pop()
        scope = stack[-1][1] if stack else top
        body = stack[-1][0] + 1 if stack else 0
        if scope is top and indent == 0:
            named = HEADER_CLASS_NAME.match(code)
            if named:
                top.name = named.group(1)
                if named.group(2):
                    top.extends = named.group(2)
                    top.extends_line = number
        ext = HEADER_EXTENDS.match(code.strip())
        if ext and scope.extends is None and indent == body:
            scope.extends = ext.group(1)
            scope.extends_line = number
        loaded = CONST_LOAD.match(code)
        if loaded and indent == body:
            scope.consts[loaded.group(1)] = loaded.group(2)
        inner = INNER_CLASS.match(code)
        if inner:
            made = GdClass(scope.name + "." + inner.group(2), path, inner.group(3), scope, number)
            scope.inner[inner.group(2)] = made
            stack.append((len(inner.group(1)), made))
            continue
        func = FUNC.match(code)
        if func and len(func.group(1)) == body:
            scope.methods.setdefault(func.group(2), number)
            scope.marks[func.group(2)] = doc_marks(lines, number - 1)
    return top


def doc_marks(lines: list[str], index: int) -> Marks:
    """The `Overrides X.f.` lines among the `##` lines directly above `lines[index]`, and any `##` line that
    starts with `Overrides` (in any case) but is not exactly that form."""
    found = Marks()
    i = index - 1
    while i >= 0:
        text = lines[i].strip()
        if text.startswith("##"):
            mark = MARK.match(text)
            if mark:
                found.good.append(mark.group(1) + "." + mark.group(2))
            elif text[2:].strip().lower().startswith("overrides"):
                found.malformed.append(text)
        elif not ANNOTATION_ONLY.match(lines[i]):
            break
        i -= 1
    return found


class Tree:
    """Every class under `src/` and `tests/`, found by `class_name` and by path."""

    def __init__(self, files: dict[str, str]) -> None:
        self.by_path: dict[str, GdClass] = {}
        self.by_name: dict[str, GdClass] = {}
        self.resolving: set[int] = set()
        for path in sorted(files):
            parsed = parse_file(path, files[path])
            self.by_path[path] = parsed
            if re.search(r"^[ \t]*(?:@\w+(?:\([^)]*\))?[ \t]+)*class_name[ \t]", files[path], re.M):
                self.by_name[parsed.name] = parsed

    def by_file(self, quoted: str, relative_to: str) -> tuple[GdClass | None, str]:
        """The top-level class of a quoted path (`res://`, or relative to the file naming it), or a problem."""
        path = quoted.strip('"')
        if path.startswith("uid://"):
            return None, f"extends {quoted}, a uid:// path this check cannot resolve; name the file by its path"
        if path.startswith("res://"):
            path = path[len("res://") :]
        else:
            path = posixpath.normpath(posixpath.join(posixpath.dirname(relative_to), path))
        found = self.by_path.get(path)
        if found is None:
            return None, f"extends {quoted}, which names no file under src/ or tests/"
        return found, ""

    def resolve(self, cls: GdClass) -> tuple[GdClass | None, str]:
        """The project class `cls` extends, or None when it extends an engine class or something this check
        cannot resolve; the second item is then the problem, '' for an engine class."""
        ext = cls.extends
        if not ext:
            return None, ""
        found: GdClass | None
        if ext.startswith('"'):
            split = re.match(r'("[^"]+")((?:\.\w+)*)$', ext)
            quoted, inner = (split.group(1), split.group(2)) if split else (ext, "")
            found, problem = self.by_file(quoted, cls.path)
            rest = [p for p in inner.split(".") if p]
        else:
            head, *rest = ext.split(".")
            found, problem = self.lexical(cls, head)
        for part in rest:
            if found is None:
                break
            found = found.inner.get(part)
            if found is None:
                problem = f"extends {ext}, whose inner class {part} is not found"
        return found, problem

    def lexical(self, cls: GdClass, head: str) -> tuple[GdClass | None, str]:
        """A bare `extends` name: an inner class of an enclosing class or of its ancestors, a `preload` constant,
        a global `class_name`; otherwise an engine class, which is not looked into."""
        self.resolving.add(id(cls))
        try:
            scope = cls.parent_scope
            while scope is not None:
                if head in scope.inner:
                    return scope.inner[head], ""
                if head in scope.consts:
                    return self.by_file(scope.consts[head], scope.path)
                if id(scope) not in self.resolving:
                    for ancestor in self.ancestors(scope):
                        if head in ancestor.inner:
                            return ancestor.inner[head], ""
                scope = scope.parent_scope
        finally:
            self.resolving.discard(id(cls))
        return self.by_name.get(head), ""

    def ancestors(self, cls: GdClass) -> list[GdClass]:
        chain: list[GdClass] = []
        seen = {id(cls)}
        parent, _ = self.resolve(cls)
        while parent is not None and id(parent) not in seen:
            chain.append(parent)
            seen.add(id(parent))
            parent, _ = self.resolve(parent)
        return chain

    def walk(self, cls: GdClass) -> list[GdClass]:
        out = [cls]
        for inner in cls.inner.values():
            out.extend(self.walk(inner))
        return out


def check(files: dict[str, str]) -> list[str]:
    tree = Tree(files)
    hits: list[tuple[str, int, str]] = []
    for path, top in tree.by_path.items():
        for cls in tree.walk(top):
            chain = tree.ancestors(cls)
            problem = tree.resolve(cls)[1]
            if problem:
                hits.append((path, cls.extends_line, problem))
            for method, line in cls.methods.items():
                nearest = next((a for a in chain if method in a.methods), None)
                if method in CONSTRUCTORS:
                    nearest = None
                marks = cls.marks[method]
                for text in marks.malformed:
                    hits.append(
                        (
                            path,
                            line,
                            f"{method}: `{text}` starts with Overrides but is not a mark: reword the prose,"
                            " or write the mark in its exact form `## Overrides Class.method.`",
                        )
                    )
                if nearest is None:
                    for mark in marks.good:
                        hits.append(
                            (path, line, f"{method} overrides nothing in a project class, but says `Overrides {mark}.`")
                        )
                    continue
                want = f"{nearest.name}.{method}"
                if not marks.good and not marks.malformed:
                    hits.append(
                        (path, line, f"{method} overrides {want} and does not say so: add `## Overrides {want}.`")
                    )
                for mark in marks.good:
                    if mark != want:
                        hits.append(
                            (
                                path,
                                line,
                                f"{method} says `Overrides {mark}.` but the nearest ancestor declaring it is {want}",
                            )
                        )
    return [f"{p}:{n}: {message}" for p, n, message in sorted(set(hits))]


def read_checkout(root: Path) -> dict[str, str]:
    files: dict[str, str] = {}
    for folder in FOLDERS:
        for path in sorted((root / folder).rglob("*.gd")):
            files[path.relative_to(root).as_posix()] = path.read_text(encoding="utf-8")
    return files


def read_rev(root: Path, rev: str) -> dict[str, str]:
    listing = subprocess.run(
        ["git", "ls-tree", "-r", "--name-only", rev, "--", *FOLDERS],
        cwd=root,
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split("\n")
    files: dict[str, str] = {}
    for path in listing:
        if path.endswith(".gd"):
            files[path] = subprocess.run(
                ["git", "show", f"{rev}:{path}"], cwd=root, capture_output=True, text=True, check=True, encoding="utf-8"
            ).stdout
    return files


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Fail when an override of a project class lacks its `## Overrides Class.method.` doc line,"
            " or a line is false. The line names the nearest project ancestor declaring the method; a malformed"
            " `Overrides` line and an `extends` it cannot resolve fail too; engine virtuals no project class"
            " declares and `_init` take no line. Runs under the host's `python3`."
        ),
        epilog="example: uv run python tools/check_overrides.py --rev origin/main",
    )
    parser.add_argument("--root", type=Path, default=ROOT, help="the checkout to read (default: this repository)")
    parser.add_argument("--rev", help="read the tree of this commit (of --root's repository) instead of the checkout")
    args = parser.parse_args(argv)
    try:
        files = read_rev(args.root, args.rev) if args.rev else read_checkout(args.root)
    except (OSError, subprocess.CalledProcessError) as error:
        print(f"tools/check_overrides.py: {error}", file=sys.stderr)
        return 1
    hits = check(files)
    for hit in hits:
        print(hit)
    if hits:
        print(f"tools/check_overrides.py: {len(hits)} override(s) unmarked or marked falsely")
        return 1
    print("OK: every override of a project class says so, and every such line is true")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
