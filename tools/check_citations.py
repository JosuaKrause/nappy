#!/usr/bin/env python3
"""Check the citations of the player's words in CLAUDE.md and the skills.

CLAUDE.md says once how a citation is found: a bare name such as `woolly-penguin` or `PLAYTEST-63`
is the file `docs/playtests/<date>-<name>.md` (or `<name>.md` for a numbered playtest), `#N` is the
statement under its `## #N` heading, and a record under `docs/decisions/` is named the same way.
Everywhere else a citation is that name in parentheses after the rule's own words, never a link, a
path or an anchor. This flags, as `file:line: label`:

- a Markdown link into `docs/playtests/` or `docs/decisions/`, anchor or not;
- a path naming one file there (`docs/playtests/2026-10-04-jolly-trout.md`);
- a citation whose name is no file there, or more than one;
- a `#N` with no `## #N` heading in the file its name is.

A citation is a parenthesis whose content, or one `;`-separated part of it, is a hyphenated name
with an optional ` #N`: `(woolly-penguin #759)`, `(PLAYTEST-145; olive-hedgehog #598)`. So a
hyphenated word alone in parentheses that is not a file is flagged too; reword it, or put
`<!-- lint-allow -->` on its line. Code spans and fenced blocks are not read.

Run by the host's own `python3` from tools/lint.sh, before CI installs uv, so it stays
3.9-compatible (pyproject.toml pins ruff's target for it).
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
POOLS = ("docs/playtests", "docs/decisions")
DATE = re.compile(r"^\d{4}-\d\d-\d\d-")
FENCE = re.compile(r"^[ \t]*```.*?^[ \t]*```[^\n]*$", re.MULTILINE | re.DOTALL)
CODE_SPAN = re.compile(r"`[^`\n]*(?:\n[^`\n]*)?`")
LINK = re.compile(r"\]\(([^)\s]*docs/(?:playtests|decisions)/[^)\s]*)\)")
PATH = re.compile(r"(?<![\w/.-])(?:\.\./)*docs/(?:playtests|decisions)/[A-Za-z0-9][A-Za-z0-9_.-]*\.md\b")
PAREN = re.compile(r"\(([^()]*)\)")
TOKEN = re.compile(r"^([A-Za-z0-9]+(?:-[A-Za-z0-9]+)+)(?: #(\d+))?$")
ALLOW = re.compile(r"<!--[^>]*lint-allow[^>]*-->")


def blank(match: re.Match[str]) -> str:
    """The match with every character but a newline replaced by a space, so offsets keep their lines."""
    return re.sub(r"[^\n]", " ", match.group(0))


def names(root: Path) -> dict[str, list[Path]]:
    """Every file under the two pools by its name: the file name without its date and `.md`."""
    found: dict[str, list[Path]] = {}
    for pool in POOLS:
        for file in sorted((root / pool).glob("*.md")):
            found.setdefault(DATE.sub("", file.stem), []).append(file)
    return found


def has_heading(file: Path, number: str) -> bool:
    return re.search(rf"^##[ \t]+#{number}\b", file.read_text(encoding="utf-8"), re.MULTILINE) is not None


def check_text(rel: str, text: str, pool: dict[str, list[Path]], root: Path) -> list[str]:
    """The hits in one file's text, each `rel:line: label`."""
    lines = text.split("\n")
    hits: list[str] = []

    def hit(offset: int, label: str) -> None:
        number = text.count("\n", 0, offset) + 1
        if not ALLOW.search(lines[number - 1]):
            hits.append(f"{rel}:{number}: {label}")

    prose = FENCE.sub(blank, text)
    for match in LINK.finditer(prose):
        hit(match.start(), f"a link into docs/playtests/ or docs/decisions/, cite the bare name: {match.group(1)}")
    prose = LINK.sub(blank, prose)  # a link is one hit, not a second one for the path inside it
    for match in PATH.finditer(prose):
        hit(match.start(), f"a path citation, cite the bare name: {match.group(0)}")
    prose = CODE_SPAN.sub(blank, prose)
    for match in PAREN.finditer(prose):
        for part in match.group(1).split(";"):
            token = TOKEN.match(re.sub(r"\s+", " ", part).strip())
            if token is None:
                continue
            name, number = token.group(1), token.group(2)
            files = pool.get(name, [])
            if not files:
                hit(match.start(), f"({name}) names no file under docs/playtests/ or docs/decisions/")
            elif len(files) > 1:
                where = ", ".join(str(f.relative_to(root)) for f in files)
                hit(match.start(), f"({name}) names more than one file: {where}")
            elif number is not None and not has_heading(files[0], number):
                hit(match.start(), f"({name} #{number}): {files[0].relative_to(root)} has no `## #{number}` heading")
    return hits


def governed(root: Path) -> list[Path]:
    files = [root / "CLAUDE.md"] if (root / "CLAUDE.md").is_file() else []
    return files + sorted((root / ".claude" / "skills").rglob("*.md"))


def in_scope(rel: str) -> bool:
    return rel == "CLAUDE.md" or (rel.startswith(".claude/skills/") and rel.endswith(".md"))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="tools/check_citations.py",
        description=(
            "Checks the citations of the player's words in CLAUDE.md and every .claude/skills/**/*.md:"
            " no Markdown link, path or anchor into docs/playtests/ or docs/decisions/; every cited name"
            " is exactly one file there; every #N has a `## #N` heading in it. Given files, checks those"
            " of them that are CLAUDE.md or under .claude/skills/ and ignores the rest."
            " Prints file:line: label per hit and exits 1 if there is one."
        ),
        epilog="example: tools/check_citations.py CLAUDE.md .claude/skills/pr-review/SKILL.md",
    )
    parser.add_argument("files", nargs="*", help="files to check (default: CLAUDE.md and every skill file)")
    parser.add_argument("--root", type=Path, default=ROOT, help="the repository root (default: this checkout)")
    args = parser.parse_args(argv)
    root: Path = args.root.resolve()
    if args.files:
        targets = []
        for name in args.files:
            path = Path(name)
            path = path if path.is_absolute() else root / path
            if not path.is_file():
                print(f"tools/check_citations.py: no such file: {name}", file=sys.stderr)
                return 2
            rel = path.resolve().relative_to(root).as_posix()
            if in_scope(rel):
                targets.append(path)
    else:
        targets = governed(root)
    pool = names(root)
    hits: list[str] = []
    for path in targets:
        rel = path.resolve().relative_to(root).as_posix()
        hits.extend(check_text(rel, path.read_text(encoding="utf-8"), pool, root))
    for line in hits:
        print(line)
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main())
