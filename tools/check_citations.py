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
- an `inbox #N in name` whose name is no playtest with a `## #N` heading for each number. The name
  is hyphenated, like every playtest's, so prose such as "inbox #12 in March" is not read as one.

A number that is both a numbered heading and a numbered statement in its file (`## Finding 3` and a
`3.` list item) means the heading; the check only asks that the number exists, so it accepts either.

What is read where: fenced code blocks are never read. Links and paths are flagged everywhere
else, inside code spans too, since a path in backticks is still a path. Parenthesised citations
and `inbox #N in name` are read outside code spans only, so an example in backticks is not checked.

A parenthesis is read one `;`-separated part at a time, in two ways.

A name with a number (`woolly-penguin #759`, `PLAYTEST-16 7`) is a citation wherever it stands in a
part, after words too: `(the rule is gentle-owl #1255)`, `(woolly-penguin #759 too)`. A name needs a
letter, so a range or a date (`3-5`, `2026-09-26`) is never one.

A bare name (`polite-marten`) is read only as a piece of a part: it starts the part (also after a
leading `and`) or follows `, `, `, and `, `, see `, `, also ` or ` and `, and is followed by a comma, the
part's end, or `and` and another such piece: `(polite-marten)`, `(PLAYTEST-145; olive-hedgehog #598)`,
`(woolly-penguin #999, the rule)` (#999 is flagged), `(the filer's proposal, curly-rabbit #1094)`,
`(woolly-finch 35, see woolly-finch 36)`, `(woolly-finch 35 and brisk-heron 1)`. A number list belongs
to its citation (`brisk-heron 1, 13`, `woolly-penguin #758, #759`). Two bare names that `and` joins
(`(well-known and long-standing)`) are prose and not read; a bare name that `and` joins to a numbered
one is read. What a writer must avoid, or reword, or mark with `<!-- lint-allow -->`: a hyphenated
word alone between the separators that names no file (`(polite-marten, long-standing)`), since a
misspelt name has to be flagged without resolving it, and one alone in parentheses. A bare name after
any other word (`or`, `&`, free text before it) is not read, and neither is a bare name followed by words
(`(polite-marten, well-known rules apply)`).

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
NAME = r"(?=[0-9-]*[A-Za-z])[A-Za-z0-9]+(?:-[A-Za-z0-9]+)+"
NOTES = r"#\d+(?:, #\d+)*"
NUMBERS = r"\d+(?:[-\u2013]\d+)?(?:, \d+(?:[-\u2013]\d+)?)*"
SPEC = rf"(?: ({NOTES}|{NUMBERS}))?"
# A piece of a part that is shaped like a citation: after the part's start or a separator, a name and an
# optional number, then a separator, an `and` before another such piece, or the part's end.
PIECE = re.compile(
    rf"(?:^(?:and )?|, and |, see |, also |, | and )({NAME}){SPEC}"
    rf"(?=, |$| and (?:{NAME}){SPEC}(?:, | and |$))"
)
# A name with a number reads as a citation wherever it stands in a part, after words too.
NUMBERED = re.compile(rf"(?<![\w-])({NAME}) ({NOTES}|{NUMBERS})(?![\w#])")
INBOX_IN = re.compile(rf"\binbox (#\d+(?:(?:, and |, | and )#\d+)*) in ({NAME})\b")
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

    def cite(offset: int, name: str, spec: str | None) -> None:
        target = one(offset, name)
        if target is None:
            return
        where = target.path.relative_to(root).as_posix()
        if spec is None:
            if target.several():
                form = "#N" if target.notes else "the statement's number"
                hit(offset, f"({name}): {where} has several statements, cite one with {form}")
        elif spec.startswith("#"):
            for number in re.findall(r"#(\d+)", spec):
                if number not in target.notes:
                    hit(offset, f"({name} #{number}): {where} has no `## #{number}` heading")
        elif target.notes:
            hit(offset, f"({name} {spec}): {where} has `## #N` headings, cite the note as #N")
        else:
            for number in numbers_in(spec):
                if number not in target.numbers:
                    hit(offset, f"({name} {spec}): {where} has no statement {number}")

    for match in PAREN.finditer(prose):
        for part in match.group(1).split(";"):
            text_part = re.sub(r"\s+", " ", part).strip()
            found = list(PIECE.finditer(text_part))
            starts = {piece.start(1) for piece in found}
            for i, piece in enumerate(found):
                # Two bare names joined by "and" are prose (`well-known and long-standing`), not citations:
                # what the "and" joins is the name after it (the lookahead's own number, group 3) and the
                # piece before it when that ends where this one starts.
                if piece.group(2) is None:
                    joined = []
                    if text_part.startswith(" and ", piece.end()):
                        joined.append(piece.group(3))
                    if i and found[i - 1].end() == piece.start() and text_part[: piece.start(1)].endswith(" and "):
                        joined.append(found[i - 1].group(2))
                    if joined and all(spec is None for spec in joined):
                        continue
                cite(match.start(), piece.group(1), piece.group(2))
            for numbered in NUMBERED.finditer(text_part):
                if numbered.start(1) not in starts:
                    cite(match.start(), numbered.group(1), numbered.group(2))
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
