#!/usr/bin/env python3
"""Lists candidates for code nothing reaches, across the game's code and the tools. It lists; it never deletes.

The dead-code survey is a sequence of six looks, each one a section of the output (--section names one):

- definitions: a func, var, const, signal, class or class_name defined at the top level of a file under
  src/ (or in one of its inner classes) whose name is a word nowhere else: not in src/, tests/, tools/, scenes/,
  scene-recipes/, assets/ or project.godot, comments blanked and strings kept (so a call("name") reaches it).
  A name used only by a file under tests/ is listed as such.
- members: the public members of a class under src/ that no file reaches (check_test_only_members.py's
  receiver typing: a .name is typed by its receiver, so another class's member of the same name does not hide
  one), and the private ones. UNSURE-ONLY is a member read only through a receiver the typing cannot tell.
  A call on another instance of the member's own class shows as dead: every hit wants one rg.
- enums: an enum value under src/ whose name is a word once in all of the files above.
- signals: a signal under src/ that nothing emits (name.emit(, emit_signal("name")) or nothing refers to
  (.name not followed by .emit, a "name" string, a [connection signal="name"] of a scene).
- files: a file under src/, tools/, scenes/ or scene-recipes/ that no other file names, by its file name or
  its path, or, for a script, by its class_name; read across the folders above, art/, project.godot,
  export_presets.cfg, pyproject.toml, CLAUDE.md, docs/*.md, .github/ and .claude/. A scene recipe is named by
  its folder, so recipes are not listed.
- tools: a Python, shell or GDScript definition under tools/ named once in tools/, .github/, .claude/,
  CLAUDE.md and pyproject.toml, and a Python definition only the test_*.py files use.

Every row says where it was looked for. A name in a comment is not a use, a name in a string is, and a name two
classes share is one word: a candidate is a place to look with rg, not a verdict.

  tools/dead_code.py
  tools/dead_code.py --section enums --section signals
  tools/dead_code.py --root /path/to/another/checkout
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from collections.abc import Iterator, Sequence
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_test_only_members as members

ROOT = Path(__file__).resolve().parent.parent
SECTIONS = ("definitions", "members", "enums", "signals", "files", "tools")
GAME_FOLDERS = ("src", "tests", "tools", "scenes", "scene-recipes", "assets")
GAME_EXTENSIONS = (".gd", ".tscn", ".tres", ".gdshader", ".json", ".py", ".sh", ".cfg", ".txt")
FILE_FOLDERS = (*GAME_FOLDERS, "art")
FILE_EXTENSIONS = (*GAME_EXTENSIONS, ".godot", ".yml", ".toml", ".md")
TOOL_EXTENSIONS = (".py", ".sh", ".gd", ".txt", ".json", ".md", ".yml")
SKIPPED_FOLDERS = frozenset({".godot", ".venv", "__pycache__", "node_modules"})
MAX_BYTES = 3_000_000
LOOKED_DEFINITIONS = "src tests tools scenes scene-recipes assets project.godot"
LOOKED_FILES = "src tests tools scenes scene-recipes assets art docs/*.md .github .claude project.godot"
LOOKED_TOOLS = "tools .github .claude CLAUDE.md pyproject.toml"

# What the engine calls by name: a definition nothing in the code mentions, and not dead.
ENGINE_CALLBACKS = frozenset(
    {
        "_init", "_ready", "_process", "_physics_process", "_draw", "_input", "_unhandled_input",
        "_unhandled_key_input", "_shortcut_input", "_gui_input", "_enter_tree", "_exit_tree", "_notification",
        "_to_string", "_get", "_set", "_get_property_list", "_property_can_revert", "_property_get_revert",
        "_validate_property", "_get_configuration_warnings", "_get_minimum_size", "_can_drop_data", "_drop_data",
        "_get_drag_data", "_has_point", "_make_custom_tooltip", "_run", "_initialize", "_finalize", "_clips_input",
        "_get_tooltip", "_parse_property", "_cleanup",
    }
)  # fmt: skip
WORD = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
# check_test_only_members.DEFINITION with the name starting with an underscore instead of a letter.
PRIVATE_DEFINITION = re.compile(members.DEFINITION.pattern.replace("[A-Za-z]", "_"))
GD_DEFINITION = re.compile(r"^(\s*)(?:static\s+)?(func|var|const|signal|class|enum)\s+([A-Za-z_]\w*)")
CLASS_NAME = re.compile(r"^class_name\s+(\w+)")
ENUM = re.compile(r"\benum\s*(\w*)\s*\{([^}]*)\}")
PYTHON_DEFINITION = re.compile(r"^\s*(?:async\s+)?(?:def|class)\s+(\w+)|^([A-Z][A-Z0-9_]+)\s*(?::[^=]+)?=", re.M)
SHELL_DEFINITION = re.compile(r"^(\w+)\(\)\s*\{", re.M)
GD_TOOL_DEFINITION = re.compile(r"^\s*(?:static\s+)?(?:func|const|var)\s+(\w+)", re.M)
SKIPPED_TOOL_NAMES = frozenset({"main", "setUp", "tearDown", "setUpClass", "tearDownClass"})


@dataclass(frozen=True)
class Candidate:
    """One place to look: where it is defined, what it is, and where it was looked for."""

    section: str
    path: str
    line: int
    kind: str
    name: str
    note: str
    looked: str

    def render(self) -> str:
        where = f"{self.path}:{self.line}" if self.line else self.path
        return f"{where}\t{self.kind} {self.name}\t{self.note}\t(looked: {self.looked})"


def blank_comments(text: str) -> str:
    """The text with each line's trailing '#' comment removed; strings are kept, so a name in one is a use."""
    return "\n".join(_blank_line(line) for line in text.split("\n"))


def _blank_line(line: str) -> str:
    out: list[str] = []
    quote: str | None = None
    index = 0
    while index < len(line):
        char = line[index]
        if quote:
            out.append(char)
            if char == "\\" and index + 1 < len(line):
                out.append(line[index + 1])
                index += 1
            elif char == quote:
                quote = None
        elif char in "\"'":
            quote = char
            out.append(char)
        elif char == "#":
            break
        else:
            out.append(char)
        index += 1
    return "".join(out)


def is_code(path: str) -> bool:
    return path.endswith((".gd", ".py", ".sh"))


class Corpus:
    """The text files of a checkout, by relative path, comments of code files blanked."""

    def __init__(
        self, root: Path, folders: Sequence[str], extensions: Sequence[str], extra: Sequence[str] = ()
    ) -> None:
        self.root = root
        self.text: dict[str, str] = {}
        for folder in folders:
            for path in sorted((root / folder).rglob("*")) if (root / folder).is_dir() else []:
                relative = path.relative_to(root)
                if SKIPPED_FOLDERS & set(relative.parts) or not path.is_file():
                    continue
                if path.name.endswith(tuple(extensions)):
                    self.add(relative.as_posix())
        for name in extra:
            if (root / name).is_file():
                self.add(name)
        self.words = {path: Counter(WORD.findall(text)) for path, text in self.text.items()}

    def add(self, relative: str) -> None:
        path = self.root / relative
        try:
            if path.stat().st_size > MAX_BYTES:
                return
            text = path.read_text(encoding="utf-8")
        except OSError, UnicodeDecodeError:
            return
        self.text[relative] = blank_comments(text) if is_code(relative) else text

    def count(self, name: str, where: Sequence[str] | None = None) -> int:
        return sum(c[name] for p, c in self.words.items() if where is None or p.startswith(tuple(where)))


def game_corpus(root: Path) -> Corpus:
    return Corpus(root, GAME_FOLDERS, GAME_EXTENSIONS, ("project.godot",))


@dataclass(frozen=True)
class Definition:
    path: str
    line: int
    kind: str
    name: str


def gd_definitions(corpus: Corpus) -> list[Definition]:
    """The definitions at the top level of a file under src/ and directly inside its inner classes."""
    found: list[Definition] = []
    for path, text in corpus.text.items():
        if not (path.startswith("src/") and path.endswith(".gd")):
            continue
        in_inner = False
        for number, line in enumerate(text.split("\n"), start=1):
            name_match = CLASS_NAME.match(line)
            if name_match:
                found.append(Definition(path, number, "class_name", name_match.group(1)))
            if line.strip() and not line[0].isspace():
                in_inner = line.startswith("class ")
            match = GD_DEFINITION.match(line)
            if not match or match.group(2) == "enum":
                continue
            indent = match.group(1)
            if indent == "" or (in_inner and indent == "\t"):
                found.append(Definition(path, number, match.group(2), match.group(3)))
    return found


def listed_test_only(root: Path) -> set[str]:
    listing = root / members.ALLOWLIST
    if not listing.is_file():
        return set()
    names: set[str] = set()
    for line in listing.read_text(encoding="utf-8").splitlines():
        parts = line.split("#")[0].split()
        if len(parts) == 2:
            names.add(parts[1])
    return names


def definition_candidates(root: Path) -> list[Candidate]:
    corpus = game_corpus(root)
    defined = gd_definitions(corpus)
    sites = Counter(d.name for d in defined)
    # A name's definitions in test files and tools are not definitions of src/; they are uses of the word here.
    listed = listed_test_only(root)
    found: list[Candidate] = []
    for d in defined:
        if d.name in ENGINE_CALLBACKS:
            continue
        outside_tests = corpus.count(d.name) - corpus.count(d.name, ("tests/",)) - sites[d.name]
        in_tests = corpus.count(d.name, ("tests/",))
        if outside_tests > 0 or (d.kind == "class_name" and outside_tests + sites[d.name] > 1):
            continue
        if in_tests:
            tag = "listed in tools/test_only_members.txt" if d.name in listed else "not listed"
            note = f"used only by tests ({in_tests} words), {tag}"
        else:
            note = "no use anywhere"
        found.append(Candidate("definitions", d.path, d.line, d.kind, d.name, note, LOOKED_DEFINITIONS))
    return found


def member_candidates(root: Path) -> list[Candidate]:
    files = members.read_checkout(root)
    scanned = members.scan(files)
    world = members.world_of(files)
    looked = "src (receivers typed), tests, own file"
    found: list[Candidate] = []
    for member in scanned.members:
        stand = scanned.stands[member.key]
        reading, _ = scanned.readings.of(member)
        if member.name in members.ENGINE_MEMBERS or member.name in ENGINE_CALLBACKS:
            continue
        if stand.elsewhere == 0 and stand.own == 0 and reading is None:
            found.append(Candidate("members", member.path, member.line, member.kind, member.name, "DEAD", looked))
        elif stand.elsewhere == stand.unsure > 0 and stand.own == 0 and reading is None:
            note = f"UNSURE-ONLY, {stand.elsewhere} reads through an untyped receiver"
            found.append(Candidate("members", member.path, member.line, member.kind, member.name, note, looked))
    found.extend(private_candidates(files, world))
    return found


def private_candidates(files: members.Files, world: members.World) -> list[Candidate]:
    """The private (underscore) members no other file reaches and the file itself does not use."""
    declared: list[members.Member] = []
    for path in sorted(files.src):
        for number, line in enumerate(world.tree.bare[path].split("\n"), start=1):
            match = PRIVATE_DEFINITION.match(line)
            if match:
                kind, name, static = match.group("kind"), match.group("name"), bool(match.group("static"))
                declared.append(members.Member(path, number, kind, name, static))
    names = frozenset(m.name for m in declared)
    own = {path: Counter(re.findall(r"\b_\w+\b", world.tree.bare[path])) for path in files.src}
    defined = Counter((m.path, m.name) for m in declared)
    dotted: dict[str, list[members.Use]] = {}
    for path in files.src:
        for name, use in members.found_in(path, world, names).uses:
            dotted.setdefault(name, []).append(use)
    found: list[Candidate] = []
    for m in declared:
        if m.name in ENGINE_CALLBACKS:
            continue
        inside = own[m.path][m.name] - defined[(m.path, m.name)]
        elsewhere = [u for u in dotted.get(m.name, []) if u.path != m.path and world.reaches(u, m)]
        if inside <= 0 and not elsewhere:
            other = sum(own[p][m.name] for p in own if p != m.path)
            note = f"PRIVATE-DEAD, the word is in {other} words of other files"
            found.append(Candidate("members", m.path, m.line, m.kind, m.name, note, "src (receivers typed), own file"))
    return found


def enum_candidates(root: Path) -> list[Candidate]:
    corpus = game_corpus(root)
    totals: Counter[str] = Counter()
    for counter in corpus.words.values():
        totals.update(counter)
    found: list[Candidate] = []
    for path, text in corpus.text.items():
        if not (path.startswith("src/") and path.endswith(".gd")):
            continue
        for match in ENUM.finditer(text):
            line = text.count("\n", 0, match.start()) + 1
            owner = match.group(1) or "(anonymous)"
            for item in match.group(2).split(","):
                name = item.strip().split("=")[0].strip()
                if not re.fullmatch(r"[A-Za-z_]\w*", name):
                    continue
                if totals[name] <= 1:
                    note = "named once"
                elif only_keys(corpus, name, match.group(0)):
                    note = "only a table key or match arm anywhere: nothing produces it"
                else:
                    continue
                found.append(Candidate("enums", path, line, "enum value", f"{owner}.{name}", note, LOOKED_DEFINITIONS))
    return found


def only_keys(corpus: Corpus, name: str, enum_text: str) -> bool:
    """Whether every use of the word, but its own place in the enum, opens a line as a dictionary key or a match arm."""
    key = re.compile(rf"^\s*(?:\w+\.)*{re.escape(name)}\s*:")
    word = re.compile(rf"\b{re.escape(name)}\b")
    uses = 0
    for text in corpus.text.values():
        if name not in text:
            continue
        for line in text.replace(enum_text, "").split("\n"):
            if word.search(line):
                if not key.match(line):
                    return False
                uses += 1
    return uses > 0


def signal_candidates(root: Path) -> list[Candidate]:
    corpus = game_corpus(root)
    big = "\n".join(corpus.text.values())
    src = "\n".join(t for p, t in corpus.text.items() if p.startswith("src/"))
    found: list[Candidate] = []
    for d in gd_definitions(corpus):
        if d.kind != "signal":
            continue
        name = re.escape(d.name)
        emit = re.compile(rf"\b{name}\s*\.\s*emit\s*\(|emit_signal\s*\(\s*[\"']{name}[\"']")
        refer = re.compile(rf"\.\s*{name}\b(?!\s*\.\s*emit\b)|[\"']{name}[\"']|signal=\"{name}\"")
        emitted_in_src = len(emit.findall(src))
        emitted = len(emit.findall(big))
        referred = len(refer.findall(big))
        looked = LOOKED_DEFINITIONS
        if emitted == 0:
            found.append(Candidate("signals", d.path, d.line, "signal", d.name, "never emitted", looked))
        elif emitted_in_src == 0:
            found.append(Candidate("signals", d.path, d.line, "signal", d.name, "emitted only outside src/", looked))
        if referred == 0:
            found.append(
                Candidate("signals", d.path, d.line, "signal", d.name, "never connected or referred to", looked)
            )
    return found


def file_candidates(root: Path) -> list[Candidate]:
    extra = ["project.godot", "export_presets.cfg", "pyproject.toml", "CLAUDE.md"]
    corpus = Corpus(root, FILE_FOLDERS, FILE_EXTENSIONS, extra)
    for folder in (".github", ".claude"):
        for path in sorted((root / folder).rglob("*")) if (root / folder).is_dir() else []:
            if path.is_file() and not SKIPPED_FOLDERS & set(path.parts):
                corpus.add(path.relative_to(root).as_posix())
    for path in sorted((root / "docs").glob("*.md")):
        corpus.add(path.relative_to(root).as_posix())
    big = "\n".join(corpus.text.values())
    words: Counter[str] = Counter()
    for counter in corpus.words.values():
        words.update(counter)
    found: list[Candidate] = []
    for relative in sorted(corpus.text):
        if not relative.startswith(("src/", "tools/", "scenes/")):
            continue
        base = relative.rsplit("/", 1)[-1]
        own = corpus.text[relative]
        if big.count(base) - own.count(base) > 0 or big.count(relative) - own.count(relative) > 0:
            continue
        class_name = CLASS_NAME.search(own) if relative.endswith(".gd") else None
        if class_name and words[class_name.group(1)] - corpus.words[relative][class_name.group(1)] > 0:
            continue
        note = "named by no other file" + (f", class {class_name.group(1)} used nowhere" if class_name else "")
        found.append(Candidate("files", relative, 0, "file", base, note, LOOKED_FILES))
    return found


def tool_corpus(root: Path) -> Corpus:
    corpus = Corpus(root, ("tools",), TOOL_EXTENSIONS, ("CLAUDE.md", "pyproject.toml"))
    for folder in (".github", ".claude/hooks", ".claude/skills"):
        for path in sorted((root / folder).rglob("*")) if (root / folder).is_dir() else []:
            if path.is_file() and not SKIPPED_FOLDERS & set(path.parts):
                corpus.add(path.relative_to(root).as_posix())
    return corpus


def tool_definitions(path: str, text: str) -> Iterator[tuple[int, str]]:
    if path.endswith(".py"):
        pattern = PYTHON_DEFINITION
    elif path.endswith(".sh"):
        pattern = SHELL_DEFINITION
    elif path.endswith(".gd"):
        pattern = GD_TOOL_DEFINITION
    else:
        return
    for match in pattern.finditer(text):
        name = next((g for g in match.groups() if g), "")
        if name and not (name.startswith(("test_", "__")) or name in SKIPPED_TOOL_NAMES):
            yield text.count("\n", 0, match.start()) + 1 + (1 if text[match.start()] == "\n" else 0), name


def is_test(path: str) -> bool:
    return path.rsplit("/", 1)[-1].startswith("test_")


def tool_candidates(root: Path) -> list[Candidate]:
    corpus = tool_corpus(root)
    defined: Counter[tuple[str, str]] = Counter()
    sites: list[tuple[str, int, str]] = []
    for path, text in corpus.text.items():
        if not path.startswith("tools/"):
            continue
        for line, name in tool_definitions(path, text):
            defined[(path, name)] += 1
            sites.append((path, line, name))
    found: list[Candidate] = []
    seen: set[tuple[str, str]] = set()
    for path, line, name in sites:
        if is_test(path) or (path, name) in seen:
            continue
        seen.add((path, name))
        definitions_here = sum(n for (p, nm), n in defined.items() if nm == name and is_test(p) == is_test(path))
        elsewhere_tests = sum(n for (p, nm), n in defined.items() if nm == name and is_test(p))
        outside_tests = sum(c[name] for p, c in corpus.words.items() if not is_test(p)) - definitions_here
        in_tests = sum(c[name] for p, c in corpus.words.items() if is_test(p)) - elsewhere_tests
        kind = "def" if path.endswith(".py") else "function"
        if outside_tests > 0:
            continue
        if in_tests > 0 and path.endswith(".py"):
            found.append(
                Candidate("tools", path, line, kind, name, f"used only by tests ({in_tests} words)", LOOKED_TOOLS)
            )
        elif in_tests == 0:
            found.append(Candidate("tools", path, line, kind, name, "no use anywhere", LOOKED_TOOLS))
    return found


FINDERS = {
    "definitions": definition_candidates,
    "members": member_candidates,
    "enums": enum_candidates,
    "signals": signal_candidates,
    "files": file_candidates,
    "tools": tool_candidates,
}


def parse(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/dead_code.py",
        description="Lists candidates for code nothing reaches in src/ and tools/. It lists and never deletes.",
        epilog=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--section", action="append", choices=SECTIONS, help="a section to run (default: all)")
    parser.add_argument("--root", type=Path, default=ROOT, help="the checkout to survey (default: this one)")
    return parser.parse_args(argv)


def main(argv: Sequence[str]) -> int:
    args = parse(argv)
    root = args.root.resolve()
    if not (root / "src").is_dir():
        print(f"{root} has no src/ folder", file=sys.stderr)
        return 2
    chosen = [s for s in SECTIONS if not args.section or s in args.section]
    for section in chosen:
        found = sorted(FINDERS[section](root), key=lambda c: (c.path, c.line, c.name))
        print(f"== {section}: {len(found)} candidates")
        for candidate in found:
            print(candidate.render())
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
