#!/usr/bin/env python3
"""Fails when an override of a project class is unmarked, or a mark is false.

GDScript has no `@override` annotation, and a misspelled override is a new method that nothing
reports. So every method that overrides a method of a project ancestor class carries a line of its
doc comment, `## Overrides <Class>.<method>.`, and this check holds that true against the tree
(inbox #1154):

- an override of a method a project ancestor declares, with no such line, **fails**;
- a line on a method that overrides nothing (the misspelled name the line exists for), or one naming
  a class that is not the nearest ancestor declaring the method, **fails**.

`<Class>` is the nearest ancestor that declares the method: its `class_name`, `Outer.Inner` for an
inner class, and the file's stem for a class extended by path that has no `class_name`. Only
project ancestors count (the `.gd` files under `src/` and `tests/`): an engine virtual such as
`_ready` or `_draw` that no project ancestor declares needs no line. `_init` is a constructor, not
an override, and takes none. The line sits among the doc-comment (`##`) lines directly above the
`func` (an annotation line such as `@abstract` may stand between).

`extends` is resolved by `class_name`, by path (`extends "res://tests/rig.gd"`), and through inner
classes (`class Step extends Base:`, a sibling inner class by its short name). The files are read
as text, so no engine is needed. `--root` reads another checkout, `--rev` the tree of a commit.

This runs under the host's own `python3` (tools/lint.sh calls it), so it stays 3.9-compatible.

  uv run python tools/check_overrides.py
  uv run python tools/check_overrides.py --rev origin/main
"""

from __future__ import annotations

import argparse
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


@dataclass
class GdClass:
    """One class: a file's top level or an inner class."""

    name: str
    path: str
    extends: str | None
    parent_scope: GdClass | None = None
    inner: dict[str, GdClass] = field(default_factory=dict)
    methods: dict[str, int] = field(default_factory=dict)
    marks: dict[str, tuple[int, str]] = field(default_factory=dict)


def strip_comment(line: str) -> str:
    return line.split("#", 1)[0]


def parse_file(path: str, text: str) -> GdClass:
    """The class tree of one file: its top level (named by `class_name`, else the file's stem)."""
    lines = text.splitlines()
    top = GdClass(Path(path).stem, path, None)
    stack: list[tuple[int, GdClass]] = []
    in_string = False
    for number, raw in enumerate(lines, start=1):
        was_in_string = in_string
        if raw.count('"""') % 2 == 1:
            in_string = not in_string
        if was_in_string:
            continue
        code = strip_comment(raw)
        if not code.strip():
            continue
        indent = len(code) - len(code.lstrip())
        while stack and indent <= stack[-1][0]:
            stack.pop()
        scope = stack[-1][1] if stack else top
        if scope is top and indent == 0:
            named = HEADER_CLASS_NAME.match(code)
            if named:
                top.name = named.group(1)
                if named.group(2):
                    top.extends = named.group(2)
        ext = HEADER_EXTENDS.match(code.strip())
        if ext and scope.extends is None and indent == (stack[-1][0] + 1 if stack else 0):
            scope.extends = ext.group(1)
        inner = INNER_CLASS.match(code)
        if inner:
            made = GdClass(scope.name + "." + inner.group(2), path, inner.group(3), scope)
            scope.inner[inner.group(2)] = made
            stack.append((len(inner.group(1)), made))
            continue
        func = FUNC.match(code)
        if func and len(func.group(1)) == (stack[-1][0] + 1 if stack else 0):
            scope.methods.setdefault(func.group(2), number)
            mark = doc_mark(lines, number - 1)
            if mark:
                scope.marks[func.group(2)] = (number, mark)
    return top


def doc_mark(lines: list[str], index: int) -> str:
    """The `Overrides X.f.` text among the `##` lines directly above `lines[index]`, or ''."""
    i = index - 1
    while i >= 0:
        text = lines[i].strip()
        if text.startswith("##"):
            found = MARK.match(text)
            if found:
                return found.group(1) + "." + found.group(2)
        elif not ANNOTATION_ONLY.match(lines[i]):
            break
        i -= 1
    return ""


class Tree:
    """Every class under `src/` and `tests/`, found by `class_name` and by path."""

    def __init__(self, files: dict[str, str]) -> None:
        self.by_path: dict[str, GdClass] = {}
        self.by_name: dict[str, GdClass] = {}
        for path in sorted(files):
            parsed = parse_file(path, files[path])
            self.by_path[path] = parsed
            if re.search(r"^[ \t]*(?:@\w+(?:\([^)]*\))?[ \t]+)*class_name[ \t]", files[path], re.M):
                self.by_name[parsed.name] = parsed

    def resolve(self, cls: GdClass) -> GdClass | None:
        """The project class `cls` extends, or None when it extends an engine class."""
        ext = cls.extends
        if not ext:
            return None
        if ext.startswith('"'):
            path, _, inner = ext[1:].partition('"')
            found = self.by_path.get(path.removeprefix("res://"))
            for part in [p for p in inner.split(".") if p]:
                found = found.inner.get(part) if found else None
            return found
        head, *rest = ext.split(".")
        scope: GdClass | None = cls.parent_scope or cls
        found = None
        while scope is not None and found is None:
            found = scope.inner.get(head)
            scope = scope.parent_scope
        if found is None:
            found = self.by_name.get(head)
        for part in rest:
            found = found.inner.get(part) if found else None
        return found

    def ancestors(self, cls: GdClass) -> list[GdClass]:
        chain: list[GdClass] = []
        seen = {id(cls)}
        parent = self.resolve(cls)
        while parent is not None and id(parent) not in seen:
            chain.append(parent)
            seen.add(id(parent))
            parent = self.resolve(parent)
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
            for method, line in cls.methods.items():
                nearest = next((a for a in chain if method in a.methods), None)
                mark = cls.marks.get(method)
                if method in CONSTRUCTORS:
                    nearest = None
                if nearest is None:
                    if mark:
                        hits.append(
                            (
                                path,
                                mark[0],
                                f"{method} overrides nothing in a project class, but says `Overrides {mark[1]}.`",
                            )
                        )
                    continue
                want = f"{nearest.name}.{method}"
                if mark is None:
                    hits.append(
                        (path, line, f"{method} overrides {want} and does not say so: add `## Overrides {want}.`")
                    )
                elif mark[1] != want:
                    hits.append(
                        (
                            path,
                            mark[0],
                            f"{method} says `Overrides {mark[1]}.` but the nearest ancestor declaring it is {want}",
                        )
                    )
    return [f"{p}:{n}: {message}" for p, n, message in sorted(hits)]


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
            " or a line is false."
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
