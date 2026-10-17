#!/usr/bin/env python3
"""Check the citations of the player's words in CLAUDE.md and the skills.

CLAUDE.md says once how a citation is found. A name such as `woolly-penguin` or `PLAYTEST-16` is
the file `docs/playtests/<date>-<name>.md` (or `<name>.md` for a numbered playtest), and a record
under `docs/decisions/` is named the same way. A file with several statements is cited with the
statement's number: `#N` where the file has `## #N` headings (`(woolly-penguin #759)`), otherwise
the file's own number for it, a numbered heading or a numbered statement (`(PLAYTEST-16 7)`,
`(PLAYTEST-145 18-23)`). Everywhere else a citation is that name in parentheses after the rule's
own words, never a link, a path or an anchor; `tools/inbox.py cite`'s `inbox #N in name` is the
one other form. This flags, as `file:line: label`:

- a Markdown link into `docs/playtests/` or `docs/decisions/`, anchor or not;
- a path naming one file there (`docs/playtests/2026-10-04-jolly-trout.md`);
- a cited name that is no file there, or more than one;
- a bare name for a file with several numbered statements;
- a `#N` with no `## #N` heading in its file, or a plain number for a file that has them;
- a plain number its file does not have;
- an `inbox #N in name` whose name is no playtest with a `## #N` heading for each number.

What is read where: fenced code blocks are never read. Links and paths are flagged everywhere
else, inside code spans too, since a path in backticks is still a path. Parenthesised citations
and `inbox #N in name` are read outside code spans only, so an example in backticks is not checked.

A parenthesised citation is a parenthesis whose content, or one `;`-separated part of it, starts
with a hyphenated name, an optional number and nothing else but, after a comma, free text:
`(woolly-penguin #759)`, `(PLAYTEST-145; olive-hedgehog #598)`, `(woolly-penguin #999, the rule)`
(checked: #999 is flagged). So a hyphenated word alone in parentheses that names no file is
flagged too; reword it, or put `<!-- lint-allow -->` on its line.

Run by the host's own `python3` from tools/lint.sh, before CI installs uv, so it stays
3.9-compatible (pyproject.toml pins ruff's target for it). `X | None` appears only in annotations,
which `from __future__ import annotations` leaves unevaluated on 3.9.
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
NAME = r"[A-Za-z0-9]+(?:-[A-Za-z0-9]+)+"
NOTES = r"#\d+(?:, #\d+)*"
NUMBERS = r"\d+(?:[-\u2013]\d+)?(?:, \d+(?:[-\u2013]\d+)?)*"
CITATION = re.compile(rf"^({NAME})(?: ({NOTES}|{NUMBERS}))?(?:, .*)?$", re.DOTALL)
INBOX_IN = re.compile(r"\binbox (#\d+(?:(?:, and |, | and )#\d+)*) in ([A-Za-z0-9]+(?:-[A-Za-z0-9]+)*)\b")
NOTE_HEADING = re.compile(r"^##[ \t]+#(\d+)\b", re.MULTILINE)
NUMBER_HEADING = re.compile(r"^#{2,3}[ \t]+(?:Finding |Statement )?(\d+)\b(?![-/])", re.MULTILINE)
NUMBER_ITEM = re.compile(r"^ {0,3}(\d+)\. ", re.MULTILINE)
ALLOW = re.compile(r"<!--[^>]*lint-allow[^>]*-->")


def blank(match: re.Match[str]) -> str:
    """The match with every character but a newline replaced by a space, so offsets keep their lines."""
    return re.sub(r"[^\n]", " ", match.group(0))


class Cited:
    """What a cited file offers: its `## #N` notes and its other numbered statements."""

    def __init__(self, path: Path) -> None:
        text = path.read_text(encoding="utf-8")
        self.path = path
        self.notes = set(NOTE_HEADING.findall(text))
        self.numbers = set(NUMBER_HEADING.findall(text)) | set(NUMBER_ITEM.findall(text))

    def several(self) -> bool:
        return len(self.notes) >= 2 or len(self.numbers) >= 2


def names(root: Path) -> dict[str, list[Path]]:
    """Every file under the two pools by its name: the file name without its date and `.md`."""
    found: dict[str, list[Path]] = {}
    for pool in POOLS:
        for file in sorted((root / pool).glob("*.md")):
            found.setdefault(DATE.sub("", file.stem), []).append(file)
    return found


def numbers_in(spec: str) -> list[str]:
    """`18-23, 25` as the numbers whose existence is checked: each one, and each end of a range."""
    out: list[str] = []
    for piece in spec.split(", "):
        out.extend(re.split(r"[-\u2013]", piece))
    return out


def check_text(rel: str, text: str, pool: dict[str, list[Path]], root: Path) -> list[str]:
    """The hits in one file's text, each `rel:line: label`."""
    lines = text.split("\n")
    hits: list[str] = []
    cited: dict[Path, Cited] = {}

    def hit(offset: int, label: str) -> None:
        number = text.count("\n", 0, offset) + 1
        if not ALLOW.search(lines[number - 1]):
            hits.append(f"{rel}:{number}: {label}")

    def one(offset: int, name: str) -> Cited | None:
        files = pool.get(name, [])
        if not files:
            hit(offset, f"({name}) names no file under docs/playtests/ or docs/decisions/")
            return None
        if len(files) > 1:
            where = ", ".join(f.relative_to(root).as_posix() for f in files)
            hit(offset, f"({name}) names more than one file: {where}")
            return None
        if files[0] not in cited:
            cited[files[0]] = Cited(files[0])
        return cited[files[0]]

    prose = FENCE.sub(blank, text)
    for match in LINK.finditer(prose):
        hit(match.start(), f"a link into docs/playtests/ or docs/decisions/, cite the bare name: {match.group(1)}")
    prose = LINK.sub(blank, prose)  # a link is one hit, not a second one for the path inside it
    for match in PATH.finditer(prose):
        hit(match.start(), f"a path citation, cite the bare name: {match.group(0)}")
    prose = CODE_SPAN.sub(blank, prose)

    for match in INBOX_IN.finditer(prose):
        target = one(match.start(), match.group(2))
        if target is None:
            continue
        for number in re.findall(r"#(\d+)", match.group(1)):
            if number not in target.notes:
                hit(match.start(), f"(inbox #{number} in {match.group(2)}): it has no `## #{number}` heading")

    for match in PAREN.finditer(prose):
        for part in match.group(1).split(";"):
            citation = CITATION.match(re.sub(r"\s+", " ", part).strip())
            if citation is None:
                continue
            name, spec = citation.group(1), citation.group(2)
            target = one(match.start(), name)
            if target is None:
                continue
            where = target.path.relative_to(root).as_posix()
            if spec is None:
                if target.several():
                    form = "#N" if target.notes else "the statement's number"
                    hit(match.start(), f"({name}): {where} has several statements, cite one with {form}")
            elif spec.startswith("#"):
                for number in re.findall(r"#(\d+)", spec):
                    if number not in target.notes:
                        hit(match.start(), f"({name} #{number}): {where} has no `## #{number}` heading")
            elif target.notes:
                hit(match.start(), f"({name} {spec}): {where} has `## #N` headings, cite the note as #N")
            else:
                for number in numbers_in(spec):
                    if number not in target.numbers:
                        hit(match.start(), f"({name} {spec}): {where} has no statement {number}")
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
            " is exactly one file there; a file with several statements is cited with one, #N for a"
            " `## #N` heading or the file's own statement number otherwise, and that statement exists;"
            " `inbox #N in name` names a playtest with that `## #N`. Given files, checks those of them"
            " that are CLAUDE.md or under .claude/skills/ and ignores the rest."
            " Prints file:line: label per hit and exits 1 if there is one."
        ),
        epilog="example: tools/check_citations.py CLAUDE.md .claude/skills/pr-review/SKILL.md",
    )
    parser.add_argument("files", nargs="*", help="files to check (default: CLAUDE.md and every skill file)")
    parser.add_argument("--root", type=Path, default=ROOT, help="the repository root (default: this checkout)")
    args = parser.parse_args(argv)
    root: Path = args.root.resolve()
    targets: list[tuple[str, Path]] = []
    if args.files:
        for name in args.files:
            path = Path(name)
            path = (path if path.is_absolute() else root / path).resolve()
            if not path.is_file():
                print(f"tools/check_citations.py: no such file: {name}", file=sys.stderr)
                return 2
            try:
                rel = path.relative_to(root).as_posix()
            except ValueError:
                print(f"tools/check_citations.py: not in the repository at {root}: {name}", file=sys.stderr)
                return 2
            if in_scope(rel):
                targets.append((rel, path))
    else:
        targets = [(path.resolve().relative_to(root).as_posix(), path) for path in governed(root)]
    pool = names(root)
    hits: list[str] = []
    for rel, path in targets:
        hits.extend(check_text(rel, path.read_text(encoding="utf-8"), pool, root))
    for line in hits:
        print(line)
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main())
