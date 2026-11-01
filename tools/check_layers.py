#!/usr/bin/env python3
"""Holds the game's code to its layers: nothing names a higher layer, and the world and simulation fetch nothing.

The layers and which file sits in which are `tools/layer_map.py`'s, as data. For every `.gd` file
under `src/` this reads its code -- comments and string contents blanked, so a class named in a
comment or a sentence is not a dependency -- and finds:

- **names**: a `class_name` or an autoload whose file is on a higher layer, or a `res://src/...gd`
  path to one, named anywhere in the code (a type, a call, an `extends`, a preload);
- in the world and simulation layers only, a fetch of what should be handed in:
  - **group**: `get_nodes_in_group`, `get_first_node_in_group`, `get_node_count_in_group` or
    `call_group` (`call_group_flags`, `notify_group`, `set_group` alike). `is_in_group` is not a
    lookup -- it asks about a node already in hand -- and is not counted;
  - **autoload**: an autoload named in code, except one `CONSTANT_AUTOLOADS` reads as data;
  - **static**: a static var or static func of a class that holds state in a `static var`
    (every one not in `STATIC_CACHES`), read from outside that class, or such a static var
    declared in the file itself;
  - **node**: a fetch by node path or from the root: `get_node`/`get_node_or_null`/`find_child`
    with a path starting `/`, `$"/..."`, `get_tree().root`/`get_root()`, `current_scene` and
    `Engine.get_main_loop()`. Her own children (`$Entities`, `get_node_or_null("Baby")`) are not.

Every use is a finding. Each is matched against `EXCEPTIONS` by its file, its rule and what it
names, and the file's listed count of that (one unless the exception says more). More uses than
listed fail, so a second use of a listed name in a listed file is seen; fewer fail too, so the list
only shrinks and is pruned in the pull request that fixes a break. A file in no layer fails, so a
new folder is placed the day it appears. A `res://src/...gd` or `uid://` path (resolved through the
`.uid` files) counts as the class it loads. `--rev` reads the tree of any commit instead of the
checkout, and `--list` prints every finding with its file's layer, listed or not, without failing.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from collections import Counter
from collections.abc import Iterable
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import layer_map

ROOT = Path(__file__).resolve().parent.parent
SRC = "src"

CLASS_NAME = re.compile(r"^class_name[ \t]+(\w+)", re.MULTILINE)
STATIC_VAR = re.compile(r"^static[ \t]+var[ \t]+(\w+)", re.MULTILINE)
STATIC_FUNC = re.compile(r"^static[ \t]+func[ \t]+(\w+)", re.MULTILINE)
AUTOLOAD = re.compile(r'^(\w+)="\*?res://([^"]+)"', re.MULTILINE)
# A capitalised word not reached through a dot, `$`, `%` or `@`.
NAME = re.compile(r"(?<![\w.$%@])([A-Z]\w*)\b")
MEMBER = re.compile(r"(?<![\w.$%@])([A-Z]\w*)\.([A-Za-z_]\w*)")
GROUP_CALL = re.compile(
    r"\b(get_nodes_in_group|get_first_node_in_group|get_node_count_in_group|call_group|call_group_flags|"
    r"notify_group|notify_group_flags|set_group|set_group_flags)\s*\("
)
SRC_PATH = re.compile(r"^res://(src/.+\.gd)$")
NODE_PATH_CALL = re.compile(r"\b(get_node|get_node_or_null|find_child|get_node_and_resource)\s*\(")
ROOT_FETCH = re.compile(
    r"get_tree\(\)\s*\.\s*(?:root\b|get_root\s*\()|\bEngine\s*\.\s*get_main_loop\s*\(|\bcurrent_scene\b"
)

EPILOG = """\
examples:
  uv run python tools/check_layers.py
  uv run python tools/check_layers.py --list
  uv run python tools/check_layers.py --rev origin/main~5 --list
"""


class LayerError(Exception):
    """An input could not be read: git failed, or the tree is not what the check expects."""


@dataclass(frozen=True)
class Literal:
    offset: int
    text: str


@dataclass(frozen=True)
class Code:
    """One file's code with comments and string contents blanked (line breaks kept), and its string literals."""

    bare: str
    literals: tuple[Literal, ...]


@dataclass(frozen=True)
class Finding:
    path: str
    line: int
    rule: str
    name: str
    detail: str

    @property
    def key(self) -> tuple[str, str, str]:
        return (self.path, self.rule, self.name)


def blank(text: str) -> Code:
    """Blanks comments and the contents of every string, keeping each line break where it was."""
    out: list[str] = []
    literals: list[Literal] = []
    index = 0
    length = len(text)
    while index < length:
        char = text[index]
        if char == "#":
            while index < length and text[index] != "\n":
                out.append(" ")
                index += 1
            continue
        if char in "\"'":
            quote = char * 3 if text.startswith(char * 3, index) else char
            start = index
            out.append(" " * len(quote))
            index += len(quote)
            body: list[str] = []
            while index < length and not text.startswith(quote, index):
                if text[index] == "\\" and index + 1 < length:
                    body.append(text[index : index + 2])
                    out.append("  " if text[index + 1] != "\n" else " \n")
                    index += 2
                    continue
                if len(quote) == 1 and text[index] == "\n":
                    break
                body.append(text[index])
                out.append("\n" if text[index] == "\n" else " ")
                index += 1
            if text.startswith(quote, index):
                out.append(" " * len(quote))
                index += len(quote)
            literals.append(Literal(offset=start, text="".join(body)))
            continue
        out.append(char)
        index += 1
    return Code(bare="".join(out), literals=tuple(literals))


def line_of(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def layer_of(path: str) -> str | None:
    if path in layer_map.FILES:
        return layer_map.FILES[path]
    folder = path.rsplit("/", 1)[0]
    while folder:
        if folder in layer_map.FOLDERS:
            return layer_map.FOLDERS[folder]
        if "/" not in folder:
            return None
        folder = folder.rsplit("/", 1)[0]
    return None


def rank(layer: str) -> int:
    return layer_map.LAYERS.index(layer)


@dataclass(frozen=True)
class Tree:
    """The `.gd` files under `src/` by path, and the autoloads `project.godot` declares, by name."""

    files: dict[str, str]
    autoloads: dict[str, str]
    uids: dict[str, str] = field(default_factory=dict)  # `uid://...` -> the `.gd` path it names


def git(*args: str, cwd: Path = ROOT, data: bytes | None = None) -> bytes:
    result = subprocess.run(["git", *args], cwd=cwd, input=data, capture_output=True, check=False)
    if result.returncode != 0:
        raise LayerError(f"git {' '.join(args)} failed: {result.stderr.decode(errors='replace').strip()}")
    return result.stdout


def read_rev(rev: str, cwd: Path = ROOT) -> Tree:
    """The tree of `rev`, read from git rather than the checkout."""
    listing = git("ls-tree", "-r", "-z", rev, "--", SRC, "project.godot", cwd=cwd).decode()
    blobs: dict[str, str] = {}
    for record in listing.split("\0"):
        if not record:
            continue
        meta, _, path = record.partition("\t")
        if path.endswith((".gd", ".gd.uid")) or path == "project.godot":
            blobs[path] = meta.split()[2]
    batch = git("cat-file", "--batch", cwd=cwd, data="".join(f"{blob}\n" for blob in blobs.values()).encode())
    texts: dict[str, str] = {}
    position = 0
    for path in blobs:
        header_end = batch.index(b"\n", position)
        size = int(batch[position:header_end].split()[2])
        start = header_end + 1
        texts[path] = batch[start : start + size].decode("utf-8", errors="replace")
        position = start + size + 1
    project = texts.pop("project.godot", "")
    uids = uids_of({path[: -len(".uid")]: texts.pop(path) for path in [p for p in texts if p.endswith(".gd.uid")]})
    return Tree(files=texts, autoloads=autoloads_of(project), uids=uids)


def read_checkout(root: Path = ROOT) -> Tree:
    files = {
        path.relative_to(root).as_posix(): path.read_text(encoding="utf-8")
        for path in sorted((root / SRC).rglob("*.gd"))
    }
    project = (root / "project.godot").read_text(encoding="utf-8")
    sidecars = {
        path.relative_to(root).as_posix()[: -len(".uid")]: path.read_text(encoding="utf-8")
        for path in sorted((root / SRC).rglob("*.gd.uid"))
    }
    return Tree(files=files, autoloads=autoloads_of(project), uids=uids_of(sidecars))


def uids_of(sidecars: dict[str, str]) -> dict[str, str]:
    """Each `uid://` a `.gd.uid` sidecar holds, by the script's path."""
    return {text.strip(): path for path, text in sidecars.items() if text.strip().startswith("uid://")}


def autoloads_of(project: str) -> dict[str, str]:
    section = project.split("[autoload]", 1)[1].split("\n[", 1)[0] if "[autoload]" in project else ""
    return dict(AUTOLOAD.findall(section))


@dataclass(frozen=True)
class Classes:
    """What every file declares: its class's file, and each stateful class's state and what reaches it."""

    file_of: dict[str, str]
    stateful: dict[str, set[str]]  # class -> its stateful static vars
    reaching: dict[str, set[str]]  # class -> those vars and every static func that reads one, however indirectly


def static_funcs(bare: str) -> dict[str, str]:
    """Each top-level static func's body, from its `static func` line to the next line at the margin."""
    bodies: dict[str, str] = {}
    lines = bare.split("\n")
    for index, line in enumerate(lines):
        found = STATIC_FUNC.match(line)
        if not found:
            continue
        end = index + 1
        while end < len(lines) and (not lines[end].strip() or lines[end][0] in " \t"):
            end += 1
        bodies[found.group(1)] = "\n".join(lines[index:end])
    return bodies


def reaching_state(bare: str, state: set[str]) -> set[str]:
    """The state vars and the static funcs that read one, directly or through another static func of the class."""
    bodies = static_funcs(bare)
    reach = set(state)
    changed = True
    while changed:
        changed = False
        for func, body in bodies.items():
            if func not in reach and any(re.search(rf"(?<![\w.]){re.escape(name)}\b", body) for name in reach):
                reach.add(func)
                changed = True
    return reach


def classes(tree: Tree) -> Classes:
    file_of: dict[str, str] = {}
    stateful: dict[str, set[str]] = {}
    reaching: dict[str, set[str]] = {}
    for path, text in tree.files.items():
        found = CLASS_NAME.search(text)
        if not found:
            continue
        name = found.group(1)
        file_of[name] = path
        bare = blank(text).bare
        state = {var for var in STATIC_VAR.findall(bare) if f"{name}.{var}" not in layer_map.STATIC_CACHES}
        if state:
            stateful[name] = state
            reaching[name] = reaching_state(bare, state)
    return Classes(file_of=file_of, stateful=stateful, reaching=reaching)


def scan(tree: Tree) -> tuple[list[Finding], list[str]]:
    """Every break of the map in the tree, and every file in no layer."""
    known = classes(tree)
    targets: dict[str, str] = dict(known.file_of)
    for name, path in tree.autoloads.items():
        targets.setdefault(name, path)
    findings: list[Finding] = []
    unplaced: list[str] = []
    for path, text in sorted(tree.files.items()):
        layer = layer_of(path)
        if layer is None:
            unplaced.append(path)
            continue
        code = blank(text)
        own = CLASS_NAME.search(text)
        own_name = own.group(1) if own else ""
        findings.extend(names_upward(path, layer, code, targets, own_name, tree.uids))
        if layer in layer_map.HANDED:
            findings.extend(fetches(path, code, tree.autoloads, known, own_name))
    return findings, unplaced


def names_upward(
    path: str, layer: str, code: Code, targets: dict[str, str], own_name: str, uids: dict[str, str]
) -> Iterable[Finding]:
    for match in NAME.finditer(code.bare):
        name = match.group(1)
        if name == own_name or name not in targets:
            continue
        target_layer = layer_of(targets[name])
        if target_layer is not None and rank(target_layer) > rank(layer):
            yield Finding(path, line_of(code.bare, match.start()), "names", name, f"{layer} names {target_layer}")
    for literal in code.literals:
        loaded = uids.get(literal.text)
        if loaded is None:
            found = SRC_PATH.match(literal.text)
            loaded = found.group(1) if found else None
        if loaded is None or loaded == path:
            continue
        target_layer = layer_of(loaded)
        if target_layer is not None and rank(target_layer) > rank(layer):
            line = line_of(code.bare, literal.offset)
            yield Finding(path, line, "names", loaded, f"{layer} loads {target_layer}")


def fetches(path: str, code: Code, autoloads: dict[str, str], known: Classes, own_name: str) -> Iterable[Finding]:
    for match in GROUP_CALL.finditer(code.bare):
        group = first_argument(code, match.end())
        yield Finding(path, line_of(code.bare, match.start()), "group", group, match.group(1))
    for match in NAME.finditer(code.bare):
        name = match.group(1)
        if name in autoloads and name not in layer_map.CONSTANT_AUTOLOADS:
            yield Finding(path, line_of(code.bare, match.start()), "autoload", name, "an autoload")
    for match in MEMBER.finditer(code.bare):
        owner, member = match.group(1), match.group(2)
        if owner != own_name and member in known.reaching.get(owner, set()):
            yield Finding(path, line_of(code.bare, match.start()), "static", owner, f"{owner}.{member}")
    if own_name in known.stateful:
        first = STATIC_VAR.search(code.bare)
        line = line_of(code.bare, first.start()) if first else 1
        yield Finding(path, line, "static", own_name, f"holds {', '.join(sorted(known.stateful[own_name]))}")
    yield from node_fetches(path, code)


def node_fetches(path: str, code: Code) -> Iterable[Finding]:
    """A node fetched by an absolute path, from the root, or as the current scene."""
    for match in NODE_PATH_CALL.finditer(code.bare):
        target = first_argument(code, match.end())
        if target.startswith("/"):
            yield Finding(path, line_of(code.bare, match.start()), "node", target, match.group(1))
    for literal in code.literals:
        if literal.text.startswith("/") and code.bare[max(literal.offset - 1, 0)] == "$":
            yield Finding(path, line_of(code.bare, literal.offset), "node", literal.text, "$ path")
    for match in ROOT_FETCH.finditer(code.bare):
        expression = " ".join(match.group(0).split())
        yield Finding(path, line_of(code.bare, match.start()), "node", expression, "the root or the current scene")


def first_argument(code: Code, start: int) -> str:
    """A call's first argument from just inside its parenthesis: a string's text, or the expression as written."""
    depth = 0
    end = start
    while end < len(code.bare):
        char = code.bare[end]
        if char in "([{":
            depth += 1
        elif char in ")]}":
            if depth == 0:
                break
            depth -= 1
        elif char == "," and depth == 0:
            break
        end += 1
    literal = next((lit for lit in code.literals if start <= lit.offset < end), None)
    if literal is not None and not code.bare[start : literal.offset].strip(" \t\n&^"):
        return literal.text
    return " ".join(code.bare[start:end].split())


def listed() -> dict[tuple[str, str, str], tuple[int, str]]:
    """Each listed (file, rule, name) with how many uses stand, and the reason."""
    keys: dict[tuple[str, str, str], tuple[int, str]] = {}
    for exception in layer_map.EXCEPTIONS:
        more = dict(exception.more)
        for path in exception.files:
            key = (path, exception.rule, exception.name)
            if key in keys:
                raise LayerError(f"tools/layer_map.py lists {path} {exception.rule} {exception.name} twice")
            keys[key] = (more.get(path, 1), exception.reason)
        for path in more:
            if path not in exception.files:
                raise LayerError(f"tools/layer_map.py gives {path} a count for {exception.name} without listing it")
    return keys


def map_errors(tree: Tree) -> list[str]:
    """What is wrong with the map itself: a layer that does not exist, an entry for a file that is gone."""
    errors: list[str] = []
    for where, layer in [*layer_map.FOLDERS.items(), *layer_map.FILES.items()]:
        if layer not in layer_map.LAYERS:
            errors.append(f"tools/layer_map.py: {where} is put in {layer!r}, which is no layer")
    for path in layer_map.FILES:
        if path not in tree.files:
            errors.append(f"tools/layer_map.py: FILES places {path}, which does not exist; delete its line")
    return errors


def check(tree: Tree) -> tuple[list[str], list[Finding]]:
    """The failures, and every finding (listed or not) for a report."""
    failures = map_errors(tree)
    if any("which is no layer" in failure for failure in failures):
        return failures, []
    findings, unplaced = scan(tree)
    failures += [f"{path}: in no layer; place it, or its folder, in tools/layer_map.py" for path in unplaced]
    allowed = listed()
    counts = Counter(finding.key for finding in findings)
    for key, used in sorted(counts.items()):
        stands = allowed[key][0] if key in allowed else 0
        if used <= stands:
            continue
        uses = [finding for finding in findings if finding.key == key]
        extra = uses[stands]
        detail = uses[0].detail if stands == 0 else f"{used} uses, {stands} listed"
        failures.append(
            f"{extra.path}:{extra.line}: {extra.rule} {extra.name} ({detail}); hand it in, move "
            "it to its layer, or say in the pull request why the map is wrong"
        )
    for key, (stands, _) in sorted(allowed.items()):
        path, rule, name = key
        used = counts.get(key, 0)
        if used == 0:
            failures.append(
                f"{path}: tools/layer_map.py lists {rule} {name} as an exception, and it is gone; "
                "delete it from the list"
            )
        elif used < stands:
            failures.append(
                f"{path}: tools/layer_map.py lists {stands} uses of {rule} {name}, and {used} stand; lower its count"
            )
    return failures, findings


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/check_layers.py",
        description=(
            "Fails when a file under src/ names a class or autoload of a higher layer, or a file in the world or"
            " simulation layers fetches through a group, an autoload or a static holding state, unless"
            " tools/layer_map.py lists it as an exception; fails too when a listed exception is gone, or a file is"
            " in no layer."
        ),
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--rev", default=None, help="read the tree of this commit instead of the checkout")
    parser.add_argument(
        "--list", action="store_true", help="print every finding, listed or not, with its file's layer; never fail"
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse(argv)
    try:
        tree = read_rev(args.rev) if args.rev else read_checkout()
        failures, findings = check(tree)
    except (LayerError, OSError) as error:
        print(f"tools/check_layers.py: {error}", file=sys.stderr)
        return 1
    if args.list:
        allowed = listed()
        seen: Counter[tuple[str, str, str]] = Counter()
        new = 0
        for finding in sorted(findings, key=lambda found: (found.path, found.line)):
            seen[finding.key] += 1
            stands = allowed[finding.key][0] if finding.key in allowed else 0
            new += seen[finding.key] > stands
            mark = "NEW" if seen[finding.key] > stands else "listed"
            where = f"{finding.path}:{finding.line} [{layer_of(finding.path)}]"
            print(f"{mark:6} {where}: {finding.rule} {finding.name} ({finding.detail})")
        print(f"{len(findings)} finding(s), {new} not listed")
        return 0
    for failure in failures:
        print(f"FAILED: {failure}")
    if failures:
        print(f"tools/check_layers.py: {len(failures)} failure(s)")
        return 1
    standing = len({finding.key for finding in findings})
    print(
        f"OK: every file under src/ is in its layer; {standing} listed exception(s) still stand ({len(findings)} uses)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
