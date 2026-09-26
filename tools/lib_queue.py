"""The queue's file layout: reading the old single-file queue and writing it as one file per thing.

Shared by `tools/migrate-queue.py`, which moves `docs/DECISIONS.md`, `docs/TODO.md` and
`docs/REVIEW.md` into `docs/decisions/`, `docs/todo/` and `docs/review/`, and by
`tools/convert-queue-edits.py`, which replays an open pull request's edits to the old files as
operations on the new ones. Both need the same answer to "which file does this line become", so
the answer lives here once.

`migrate()` is a pure function from the three old texts to a tree (relative path -> content) and
a report; nothing here touches the disk or git except `git_line_dates()`, which a caller passes in
as the `dates` lookup. Every structural assumption is asserted and raises `QueueFormatError`
rather than being guessed past: a migration that quietly misfiled a record would be a lie in the
commit, which is what `CLAUDE.md`'s "An edit fails loudly" forbids.
"""

from __future__ import annotations

import re
import subprocess
import unicodedata
from collections.abc import Callable
from dataclasses import dataclass, field

DATE_RE = re.compile(r"\d{4}-\d{2}-\d{2}")
# A lookup for a line's date when its heading carries none: (path, 1-based line number) -> date.
DateLookup = Callable[[str, int], str]

DECISIONS = "docs/DECISIONS.md"
TODO = "docs/TODO.md"
REVIEW = "docs/REVIEW.md"
OLD_FILES = (DECISIONS, TODO, REVIEW)
DECISIONS_DIR = "docs/decisions"
TODO_DIR = "docs/todo"
REVIEW_DIR = "docs/review"
NEW_DIRS = (DECISIONS_DIR, TODO_DIR, REVIEW_DIR)
CONTEXT_FILE = "README.md"

CHECKBOX_RE = re.compile(r"^- \[( |~)\] ")
ANY_CHECKBOX_RE = re.compile(r"^\s*- \[[ ~xX]\]")
ENTRY_HEADING_RE = re.compile(r"^(#{2,3}) (M\d+[a-z]?) — (.+)$")
LINK_RE = re.compile(r"\]\(([^)\s]+)")
FENCE_RE = re.compile(r"^\s*```")


class QueueFormatError(Exception):
    """An old-format file is not the shape the migration was written against."""


# ---------------------------------------------------------------------------------- the new text

NEW_DECISIONS = """\
# Decisions

**Every decision is a file of its own, under [decisions/](decisions/).** A file is named
`<date>-<words>.md`, so sorting the folder puts the newest last, and two pull requests never edit
the same record. A decision that closes a queue entry takes the entry's name
(`<date>-<adjective>-<animal>.md`, or `<date>-M210.md` for an entry filed before names). A record
written before the queue was files is named by its date and its heading
(`2026-09-25-M201-a-ci-job-does-not-download-the-evidence.md`), and one milestone number can have
many of those.

**No index is checked in**, since an index every pull request edits is the same conflict again.
`tools/decisions.sh` lists the records by date and searches their titles and their text:

    tools/decisions.sh                  # every record, oldest first
    tools/decisions.sh M129             # every record whose title or text names M129
    tools/decisions.sh spent park       # every record that says both words

**A citation reads "`DECISIONS.md`, M129, a spent park is closed"** wherever it stands — a code
comment, a skill, a doc: a milestone and a record's title. `tools/decisions.sh M129` lists that
milestone's records, titles first, and the title picks one out.

A record says what was true when it was written, with what was measured and what was rejected;
none of it should be read as current. The open work is [TODO.md](TODO.md) and the entries under
[todo/](todo/); what waits on a person is [REVIEW.md](REVIEW.md) and the items under
[review/](review/).
"""

OLD_TODO_HEADER = """\
# TODO

**The queue. Open work only.** A ticked item is history the moment it is ticked, so completed
entries live in [DECISIONS.md](DECISIONS.md) with their measurements and rejected options intact —
search it for the noun before designing anything. Progress-tracking lives only there: no ticked
boxes, no "Done:" paragraphs, no branch names or status words in headings here.

Read [HANDOFF.md](HANDOFF.md) first for the state of the tree.

Each milestone is one git branch, squash-merged to `main` through its pull request. `[~]` marks an item somebody is
mid-way through.
"""

NEW_TODO_HEADER = """\
# TODO

**The queue. Open work only.** Each entry is a folder under [todo/](todo/), named
`<date filed>-<adjective>-<animal>` and spoken by its two words ("busy-badger"); an entry filed
before names keeps its milestone number (`2026-09-26-M210`). Its `README.md` holds the player's
words, the playtest links and the context, and each item is a file of its own beside it, written
in full prose. Finishing an item deletes its file; when the last one goes, the folder goes and the
entry's record is written to [decisions/](decisions/) under the same name, in the same commit.
Search the records (`tools/decisions.sh <noun>`) before designing anything. No ticked boxes, no
"Done:" paragraphs, no branch names or status words in headings, here or in an entry.

`tools/new-name.sh todo "<title>"` makes a new entry's folder and prints its name. Read
[HANDOFF.md](HANDOFF.md) first for the state of the tree.

Each entry is one git branch, squash-merged to `main` through its pull request. An item somebody
is mid-way through says so in its own text.
"""

OLD_ORDER_TAIL = """\
Everything below is in the order the gameplay queue above gives it, and was reassessed on
2026-09-09.
"""

NEW_ORDER_TAIL = "The entries, in the order the gameplay queue above gives them, reassessed on 2026-09-09:\n"

OLD_REVIEW_HEADER = """\
# Review

**What waits on a human.** Everything here is built, measured by a rig, and unfelt: a person has
to play it, look at it, or decide about it. *(2026-09-11: "keep a document with items that need
human review / test runs. That way you can keep working without having to stop. And test runs
can capture multiple items at once.")* The work goes on while this list waits, and one run
answers as many of these as it passes through.

**How it is kept.** An item enters when work lands that only a person can judge, in the same PR
as the work. It names what to do, where to look, and the question a run answers — not what was
built, which is `DECISIONS.md`'s. A playtest closes the items it covered: the finding goes in
that `PLAYTEST-NN.md`, the item leaves this file in the same commit, and what the player asked
for goes to `TODO.md`. Nothing here is a task; a task is `TODO.md`'s.

## Next run, in one sitting

Each line is a thing to try or look at and the question it settles. `tools/run.sh` plays the
desktop build; `--seed <n> --day <n>` puts a run where an item says; `1` to `5` in a debug build
toggle the field, shadow, bounding-box, readout and route-line layers (`docs/TELEMETRY.md`, "The
debug view"). `--invincible` is the way to walk this whole list in one sitting: nothing ends the day,
the clock stands still and the excitement meter never rises, so one run can stand next to every
item below for as long as looking takes.
"""

NEW_REVIEW = """\
# Review

**What waits on a human.** Everything here is built, measured by a rig, and unfelt: a person has
to play it, look at it, or decide about it. *(2026-09-11: "keep a document with items that need
human review / test runs. That way you can keep working without having to stop. And test runs
can capture multiple items at once.")* The work goes on while this list waits, and one run
answers as many of these as it passes through.

**How it is kept.** Each item is a file under [review/](review/), named after the queue entry
whose work it asks about (`<entry name>.md`, and `<entry name>-2.md` for a second item from the
same entry). It enters when work lands that only a person can judge, in the same PR as the work,
and names what to do, where to look, and the question a run answers — not what was built, which
is the record's under [decisions/](decisions/). A playtest closes the items it covered: the
finding goes in the playtest's file, the item's file is deleted in the same commit, and what the
player asked for goes to the queue. Nothing here is a task; a task is an item under
[todo/](todo/). What no person has tested yet, the list at the end of this file, stays a list
here.

## Next run, in one sitting

Each file under [review/](review/) is a thing to try or look at and the question it settles.
`tools/run.sh` plays the desktop build; `--seed <n> --day <n>` puts a run where an item says; `1`
to `5` in a debug build toggle the field, shadow, bounding-box, readout and route-line layers
(`docs/TELEMETRY.md`, "The debug view"). `--invincible` is the way to walk the whole list in one
sitting: nothing ends the day, the clock stands still and the excitement meter never rises, so one
run can stand next to every item for as long as looking takes.
"""

REVIEW_NEXT_RUN = "## Next run, in one sitting"
REVIEW_UNTESTED = "## What is untested by a human, listed so nobody mistakes arithmetic for a verdict"


# ------------------------------------------------------------------------------------ the result


@dataclass
class Report:
    """What the migration did, in the numbers its verification is stated in."""

    decision_headings: int = 0
    decision_files: int = 0
    decision_embedded_headings: int = 0
    decision_part_headings: int = 0
    decision_undated: int = 0
    decision_lines_old: int = 0
    decision_lines_records: int = 0
    decision_lines_header: int = 0
    decision_lines_separators: int = 0
    todo_entries: int = 0
    todo_items: int = 0
    todo_items_midway: int = 0
    todo_undated: int = 0
    review_items: int = 0
    review_lines_dropped: list[str] = field(default_factory=list)
    review_lines_kept: int = 0
    notes: list[str] = field(default_factory=list)

    def lines(self) -> list[str]:
        out = [
            f"DECISIONS.md: {self.decision_lines_old} lines, {self.decision_headings} record headings"
            f" (`## `, and `# ` after a `---`) -> {self.decision_files} files in {DECISIONS_DIR}/",
            f"  lines: {self.decision_lines_records} in records + {self.decision_lines_header} header"
            f" + {self.decision_lines_separators} blank/`---` separators between records"
            f" = {self.decision_lines_records + self.decision_lines_header + self.decision_lines_separators}",
            f"  {self.decision_embedded_headings} `#`/`##` headings of superseded documents quoted inside"
            f" a record stay in that record; {self.decision_part_headings} `# ` headings not after a `---`"
            " stay in the record they continue",
            f"  {self.decision_undated} headings carry no date and took the date of the commit that first wrote"
            " their heading line",
            f"TODO.md: {self.todo_entries} entries -> folders in {TODO_DIR}/, {self.todo_items} items -> files"
            f" ({self.todo_items_midway} mid-way); {self.todo_undated} headings carry no date",
            f"REVIEW.md: {self.review_items} items of the next run -> files in {REVIEW_DIR}/;"
            f" {len(self.review_lines_dropped)} blank lines between them dropped; the untested list,"
            f" {self.review_lines_kept} lines, kept in REVIEW.md as written",
        ]
        out.extend(f"note: {n}" for n in self.notes)
        return out


@dataclass
class Migration:
    tree: dict[str, str]
    report: Report


# --------------------------------------------------------------------------------------- helpers


def rewrite_links(text: str, prefix: str) -> str:
    """Prefix every relative Markdown link target, so a link keeps working from a deeper folder."""

    def one(match: re.Match[str]) -> str:
        target = match.group(1)
        if target.startswith(("#", "/")) or re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", target):
            return match.group(0)
        return "](" + prefix + target

    return LINK_RE.sub(one, text)


def unrewrite_links(text: str, prefix: str) -> str:
    """The inverse of `rewrite_links`, used only to verify that nothing but the links moved."""

    def one(match: re.Match[str]) -> str:
        target = match.group(1)
        if target.startswith(prefix):
            return "](" + target[len(prefix) :]
        return match.group(0)

    return LINK_RE.sub(one, text)


def rewrite_block(lines: list[str], prefix: str) -> list[str]:
    """`rewrite_links` over lines, leaving fenced code alone."""
    out: list[str] = []
    fenced = False
    for line in lines:
        if FENCE_RE.match(line):
            fenced = not fenced
            out.append(line)
            continue
        out.append(line if fenced else rewrite_links(line, prefix))
    return out


def ascii_words(text: str) -> list[str]:
    folded = unicodedata.normalize("NFKD", text)
    folded = "".join(c for c in folded if not unicodedata.combining(c))
    folded = folded.replace("'", "").replace("\u2019", "")
    return re.findall(r"[A-Za-z0-9]+", folded)


TRAILING_STATE_WORDS = {"built", "decided", "measured", "drawn", "read", "filed", "asked", "for", "found"}


def slugify(title: str, max_len: int = 80) -> str:
    """A file-name slug of a heading: its words, lower case except a milestone number, no date."""
    text = re.sub(r"`feature/[^`]*`", "", title)
    text = DATE_RE.sub("", text)
    words = [w if re.fullmatch(r"M\d+[a-z]?", w) else w.lower() for w in ascii_words(text)]
    while words and words[-1] in TRAILING_STATE_WORDS:
        words.pop()
    slug = ""
    for word in words:
        candidate = f"{slug}-{word}" if slug else word
        if len(candidate) > max_len:
            break
        slug = candidate
    return slug or "record"


def short_name(text: str, max_words: int = 6) -> str:
    """An item's short descriptive file name: its bold lead, or its first phrase, a few words long."""
    stripped = text.strip()
    bold = re.match(r"^\*\*(.+?)\*\*", stripped)
    lead = bold.group(1) if bold else re.split(r"[:,.;(—]", stripped, maxsplit=1)[0]
    words = [w.lower() for w in ascii_words(lead)]
    if len(words) > 1 and words[0] in {"a", "an", "the"}:
        words = words[1:]
    return "-".join(words[:max_words]) or "item"


def unique(name: str, taken: set[str]) -> str:
    candidate = name
    n = 2
    while candidate in taken:
        candidate = f"{name}-{n}"
        n += 1
    taken.add(candidate)
    return candidate


def heading_date(heading: str) -> str | None:
    found = DATE_RE.search(heading)
    return found.group(0) if found else None


def title_without_date(title: str) -> str:
    """An entry's title without its `· asked for <date>` tail, for the order's link text."""
    return re.sub(r"\s+·\s+[^·]*\d{4}-\d{2}-\d{2}[^·]*$", "", title)


def join(lines: list[str]) -> str:
    return "\n".join(lines).rstrip("\n") + "\n"


def collapse_blank_runs(lines: list[str]) -> list[str]:
    out: list[str] = []
    for line in lines:
        if line.strip() == "" and (not out or out[-1].strip() == ""):
            continue
        out.append(line)
    while out and out[-1].strip() == "":
        out.pop()
    return out


def strip_separators(lines: list[str]) -> tuple[list[str], int]:
    """Drop trailing blank lines and one trailing `---` rule; return the rest and how many went."""
    end = len(lines)
    while end > 0 and lines[end - 1].strip() == "":
        end -= 1
    if end > 0 and lines[end - 1] == "---":
        end -= 1
        while end > 0 and lines[end - 1].strip() == "":
            end -= 1
    return lines[:end], len(lines) - end


# ------------------------------------------------------------------------------------- decisions


@dataclass
class Record:
    start: int  # 0-based index of the heading line in the old file
    lines: list[str]
    separators: int

    @property
    def title(self) -> str:
        return self.lines[0].lstrip("#").strip()


def split_decisions(text: str, report: Report) -> tuple[list[str], list[Record]]:
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines = lines[:-1]
    report.decision_lines_old = len(lines)
    if not lines or lines[0] != "# Decisions":
        raise QueueFormatError(f"{DECISIONS}: the first line is not `# Decisions` -- is it already migrated?")
    starts: list[int] = []
    fenced = False
    embedded = False
    previous = ""
    for index, line in enumerate(lines):
        if index == 0:
            continue
        if FENCE_RE.match(line):
            fenced = not fenced
        elif not fenced:
            after_rule = previous == "---"
            if line.startswith("### Superseded text from "):
                embedded = True
            elif line.startswith("## "):
                if not embedded or after_rule:
                    embedded = False
                    starts.append(index)
                else:
                    report.decision_embedded_headings += 1
            elif line.startswith("# "):
                if embedded:
                    report.decision_embedded_headings += 1
                elif after_rule:
                    starts.append(index)
                else:
                    report.decision_part_headings += 1
        if line.strip():
            previous = line
    if fenced:
        raise QueueFormatError(f"{DECISIONS}: a code fence is never closed")
    if not starts:
        raise QueueFormatError(f"{DECISIONS}: no `## ` record heading found")
    header = lines[: starts[0]]
    if any(line.strip() for line in header[1:]):
        raise QueueFormatError(f"{DECISIONS}: text between `# Decisions` and the first record: {header[1:]!r}")
    records: list[Record] = []
    for n, start in enumerate(starts):
        end = starts[n + 1] if n + 1 < len(starts) else len(lines)
        body, dropped = strip_separators(lines[start:end])
        records.append(Record(start, body, dropped))
    report.decision_headings = len(records)
    report.decision_lines_header = len(header)
    report.decision_lines_records = sum(len(r.lines) for r in records)
    report.decision_lines_separators = sum(r.separators for r in records)
    return header, records


def decision_tree(text: str, dates: DateLookup, report: Report) -> dict[str, str]:
    _, records = split_decisions(text, report)
    tree: dict[str, str] = {}
    taken: set[str] = set()
    # Oldest first, so a record added at the top of the old file later never moves an older
    # record's name: a same-day, same-title newcomer is the one that takes the suffix.
    for record in reversed(records):
        date = heading_date(record.lines[0])
        if date is None:
            date = dates(DECISIONS, record.start + 1)
            report.decision_undated += 1
        name = unique(f"{date}-{slugify(record.title)}", taken)
        tree[f"{DECISIONS_DIR}/{name}.md"] = join(rewrite_block(record.lines, "../"))
    report.decision_files = len(tree)
    verify_decisions(text, records, tree, report)
    return tree


def verify_decisions(text: str, records: list[Record], tree: dict[str, str], report: Report) -> None:
    if len(tree) != len(records):
        raise QueueFormatError(f"{len(records)} record headings but {len(tree)} decision files")
    total = report.decision_lines_records + report.decision_lines_header + report.decision_lines_separators
    if total != report.decision_lines_old:
        raise QueueFormatError(f"{DECISIONS}: {report.decision_lines_old} lines, but {total} are accounted for")
    written = {content.split("\n", 1)[0] for content in tree.values()}
    for record in records:
        if rewrite_links(record.lines[0], "../") not in written:
            raise QueueFormatError(f"{DECISIONS}: heading {record.lines[0]!r} was not written to any file")
    by_heading: dict[str, list[str]] = {}
    for content in tree.values():
        by_heading.setdefault(content.split("\n", 1)[0], []).append(content)
    for record in records:
        candidates = by_heading[rewrite_links(record.lines[0], "../")]
        original = join(record.lines)
        if not any(unrewrite_links(c, "../") == original for c in candidates):
            raise QueueFormatError(f"{DECISIONS}: the file for {record.lines[0]!r} differs from its lines")
    old_lines = text.rstrip("\n").split("\n")
    for record in records:
        for offset, line in enumerate(record.lines):
            if old_lines[record.start + offset] != line:
                raise QueueFormatError(f"{DECISIONS}: line {record.start + offset + 1} moved inside its record")


# ------------------------------------------------------------------------------------------ todo


@dataclass
class Item:
    start: int
    lines: list[str]  # as written, checkbox included

    @property
    def midway(self) -> bool:
        return self.lines[0].startswith("- [~]")


@dataclass
class Entry:
    start: int
    number: str
    heading: str
    context: list[str]
    items: list[Item]
    in_order: bool

    @property
    def title(self) -> str:
        return self.heading.lstrip("#").strip()


def item_text(item: Item) -> list[str]:
    """An item's lines without its checkbox, dedented by the checkbox's width."""
    width = len("- [ ] ")
    out = [item.lines[0][width:]]
    for line in item.lines[1:]:
        if line.strip() == "":
            out.append("")
            continue
        indent = len(line) - len(line.lstrip(" "))
        if indent < width:
            raise QueueFormatError(f"{TODO}: item line {line!r} is indented less than its checkbox")
        out.append(line[width:])
    return out


def split_items(lines: list[str], offset: int) -> tuple[list[str], list[Item]]:
    """Separate an entry's lines into its context (everything but items) and its items."""
    context: list[str] = []
    items: list[Item] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        if CHECKBOX_RE.match(line):
            end = index + 1
            while end < len(lines):
                nxt = lines[end]
                if nxt.strip() == "":
                    # A blank line stays inside the item only when an indented line follows it.
                    look = end
                    while look < len(lines) and lines[look].strip() == "":
                        look += 1
                    if look < len(lines) and lines[look].startswith("  ") and not CHECKBOX_RE.match(lines[look]):
                        end = look
                        continue
                    break
                if not nxt.startswith("  "):
                    break
                if ANY_CHECKBOX_RE.match(nxt):
                    raise QueueFormatError(f"{TODO}: a checkbox inside an item, line {offset + end + 1}")
                end += 1
            items.append(Item(offset + index, lines[index:end]))
            index = end
            continue
        if ANY_CHECKBOX_RE.match(line):
            raise QueueFormatError(f"{TODO}: line {offset + index + 1}, a checkbox the migration cannot map: {line!r}")
        context.append(line)
        index += 1
    return context, items


def parse_todo(text: str, strict: bool, report: Report) -> tuple[list[str], list[Entry]]:
    """Return the order section's lines (entries inside it replaced by markers) and every entry."""
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines = lines[:-1]
    if not lines or lines[0] != "# TODO":
        raise QueueFormatError(f"{TODO}: the first line is not `# TODO` -- is it already migrated?")
    try:
        order_at = lines.index("## The order")
    except ValueError as error:
        raise QueueFormatError(f"{TODO}: no `## The order` heading") from error
    header = lines[:order_at]
    while header and header[-1].strip() in ("", "---"):
        header.pop()
    if strict and join(header) != OLD_TODO_HEADER:
        raise QueueFormatError(
            f"{TODO}: the header above `## The order` is not the text tools/lib_queue.py rewrites"
            " (OLD_TODO_HEADER); it changed on main -- carry the change into NEW_TODO_HEADER first"
        )
    # Split the rest into top-level sections at `## ` headings.
    sections: list[tuple[int, int]] = []
    starts = [i for i in range(order_at, len(lines)) if lines[i].startswith("## ")]
    for n, start in enumerate(starts):
        sections.append((start, starts[n + 1] if n + 1 < len(starts) else len(lines)))
    entries: list[Entry] = []
    order: list[str] = []
    for start, end in sections:
        body, _ = strip_separators(lines[start:end])
        heading = body[0]
        if heading == "## The order":
            order = parse_order(body, start, entries)
            continue
        match = ENTRY_HEADING_RE.match(heading)
        if match is None or match.group(1) != "##":
            raise QueueFormatError(f"{TODO}: line {start + 1} is a section that is not an entry: {heading!r}")
        context, items = split_items(body[1:], start + 1)
        entries.append(Entry(start, match.group(2), heading, [heading, *context], items, False))
    return order, entries


def parse_order(body: list[str], offset: int, entries: list[Entry]) -> list[str]:
    """The order section, with each `### M<n>` entry inside it lifted out and a marker left behind."""
    out: list[str] = []
    index = 0
    while index < len(body):
        line = body[index]
        match = ENTRY_HEADING_RE.match(line)
        if match and match.group(1) == "###":
            end = index + 1
            while end < len(body) and not body[end].startswith(("## ", "### ")) and body[end] != "---":
                end += 1
            section, _ = strip_separators(body[index:end])
            context, items = split_items(section[1:], offset + index + 1)
            entries.append(Entry(offset + index, match.group(2), line, [line, *context], items, True))
            out.append(f"\0entry:{len(entries) - 1}")
            out.append("")
            index = end
            continue
        if ANY_CHECKBOX_RE.match(line):
            raise QueueFormatError(f"{TODO}: a checkbox in the order outside any entry, line {offset + index + 1}")
        out.append(line)
        index += 1
    return out


def todo_tree(text: str, dates: DateLookup, strict: bool, report: Report) -> dict[str, str]:
    order, entries = parse_todo(text, strict, report)
    tree: dict[str, str] = {}
    names: list[str] = []
    taken: set[str] = set()
    for entry in entries:
        date = heading_date(entry.heading)
        if date is None:
            date = dates(TODO, entry.start + 1)
            report.todo_undated += 1
        name = f"{date}-{entry.number}"
        if name in taken:
            raise QueueFormatError(f"{TODO}: two entries would both be {name}")
        taken.add(name)
        names.append(name)
        folder = f"{TODO_DIR}/{name}"
        tree[f"{folder}/{CONTEXT_FILE}"] = join(rewrite_block(collapse_blank_runs(entry.context), "../../"))
        item_names: set[str] = {"readme"}
        for item in entry.items:
            file_name = unique(short_name(item_text(item)[0]), item_names)
            tree[f"{folder}/{file_name}.md"] = join(rewrite_block(item_file_lines(item), "../../"))
            report.todo_items += 1
            report.todo_items_midway += int(item.midway)
        verify_entry(entry, folder, tree)
    report.todo_entries = len(entries)
    tree[TODO] = render_todo(order, entries, names, strict)
    return tree


MIDWAY = "*Somebody is mid-way through this item.*"


def item_file_lines(item: Item) -> list[str]:
    own = item_text(item)
    return [MIDWAY, "", *own] if item.midway else own


def verify_entry(entry: Entry, folder: str, tree: dict[str, str]) -> None:
    files = {p: c for p, c in tree.items() if p.startswith(folder + "/") and not p.endswith("/" + CONTEXT_FILE)}
    if len(files) != len(entry.items):
        raise QueueFormatError(f"{entry.number}: {len(entry.items)} items but {len(files)} item files")
    remaining = list(files.values())
    for item in entry.items:
        expected = join(rewrite_block(item_file_lines(item), "../../"))
        if expected not in remaining:
            raise QueueFormatError(f"{entry.number}: item at line {item.start + 1} was not written as a file")
        remaining.remove(expected)
        own = unrewrite_links(expected, "../../").rstrip("\n").split("\n")
        if item.midway:
            own = own[2:]
        restored = [item.lines[0][:6] + own[0]] + [("      " + line) if line else "" for line in own[1:]]
        original = [line if line.strip() else "" for line in item.lines]
        if restored != original:
            raise QueueFormatError(f"{entry.number}: item at line {item.start + 1} does not round-trip")


def render_todo(order: list[str], entries: list[Entry], names: list[str], strict: bool) -> str:
    out: list[str] = [*NEW_TODO_HEADER.rstrip("\n").split("\n"), "", "---", ""]
    tail = OLD_ORDER_TAIL.rstrip("\n").split("\n")
    body = list(order)
    at = next((i for i in range(len(body) - len(tail) + 1) if body[i : i + len(tail)] == tail), None)
    if at is None:
        if strict:
            raise QueueFormatError(f"{TODO}: the order no longer ends with OLD_ORDER_TAIL; update tools/lib_queue.py")
        while body and body[-1].strip() == "":
            body.pop()
        body.append("")
        at = len(body)
        body.extend([NEW_ORDER_TAIL.rstrip("\n")])
        del_len = 0
    else:
        body[at : at + len(tail)] = [NEW_ORDER_TAIL.rstrip("\n")]
        del_len = 1
    listing = [""]
    for entry, name in zip(entries, names, strict=True):
        if not entry.in_order:
            listing.append(f"- [{title_without_date(entry.title)}](todo/{name}/)")
    body[at + del_len : at + del_len] = listing
    for line in body:
        if line.startswith("\0entry:"):
            entry = entries[int(line.split(":", 1)[1])]
            name = names[int(line.split(":", 1)[1])]
            hashes = entry.heading.split(" ", 1)[0]
            out.append(f"{hashes} [{title_without_date(entry.title)}](todo/{name}/)")
        else:
            out.append(line)
    return join(collapse_blank_runs(out))


# ---------------------------------------------------------------------------------------- review


@dataclass
class Bullet:
    start: int
    lines: list[str]


def parse_review(text: str, strict: bool, report: Report) -> tuple[list[Bullet], list[str]]:
    """The next run's items, and the untested list's lines, which stay in REVIEW.md as written."""
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines = lines[:-1]
    if not lines or lines[0] != "# Review":
        raise QueueFormatError(f"{REVIEW}: the first line is not `# Review` -- is it already migrated?")
    first = next((i for i, line in enumerate(lines) if line.startswith("- ")), None)
    if first is None:
        raise QueueFormatError(f"{REVIEW}: no item")
    header = lines[:first]
    while header and header[-1].strip() == "":
        header.pop()
    if strict and join(header) != OLD_REVIEW_HEADER:
        raise QueueFormatError(
            f"{REVIEW}: the text above the first item is not OLD_REVIEW_HEADER in tools/lib_queue.py;"
            " it changed on main -- carry the change into NEW_REVIEW first"
        )
    untested_at = lines.index(REVIEW_UNTESTED) if REVIEW_UNTESTED in lines else len(lines)
    if strict and untested_at == len(lines):
        raise QueueFormatError(f"{REVIEW}: no {REVIEW_UNTESTED!r} heading")
    kept = lines[untested_at:]
    report.review_lines_kept = len(kept)
    bullets: list[Bullet] = []
    index = first
    while index < untested_at:
        line = lines[index]
        if line.startswith("- "):
            end = index + 1
            while end < untested_at:
                nxt = lines[end]
                if nxt.strip() == "":
                    look = end
                    while look < untested_at and lines[look].strip() == "":
                        look += 1
                    if look < untested_at and lines[look].startswith("  "):
                        end = look
                        continue
                    break
                if not nxt.startswith("  "):
                    break
                end += 1
            bullets.append(Bullet(index, lines[index:end]))
            index = end
            continue
        if line.strip() == "":
            report.review_lines_dropped.append(line)
            index += 1
            continue
        raise QueueFormatError(f"{REVIEW}: line {index + 1} is neither an item nor a blank line: {line!r}")
    return bullets, kept


def bullet_text(bullet: Bullet) -> list[str]:
    out = [bullet.lines[0][2:]]
    for line in bullet.lines[1:]:
        if line.strip() == "":
            out.append("")
        elif line.startswith("  "):
            out.append(line[2:])
        else:
            raise QueueFormatError(f"{REVIEW}: item line {line!r} is not indented under its bullet")
    return out


def review_tree(text: str, dates: DateLookup, strict: bool, report: Report) -> dict[str, str]:
    bullets, kept = parse_review(text, strict, report)
    tree: dict[str, str] = {REVIEW: join([*NEW_REVIEW.rstrip("\n").split("\n"), "", *kept])}
    taken: set[str] = set()
    for bullet in reversed(bullets):
        date = dates(REVIEW, bullet.start + 1)
        text_lines = bullet_text(bullet)
        name = unique(f"{date}-{short_name(text_lines[0])}", taken)
        content = join(rewrite_block(text_lines, "../"))
        tree[f"{REVIEW_DIR}/{name}.md"] = content
        restored = "\n".join(["- " + text_lines[0]] + [("  " + t) if t else "" for t in text_lines[1:]])
        if restored.rstrip() != "\n".join(bullet.lines).rstrip() or unrewrite_links(content, "../") != join(text_lines):
            raise QueueFormatError(f"{REVIEW}: item at line {bullet.start + 1} does not round-trip")
    report.review_items = len(bullets)
    if len(tree) - 1 != len(bullets):
        raise QueueFormatError(f"{REVIEW}: {len(bullets)} items but {len(tree) - 1} files")
    return tree


# ------------------------------------------------------------------------------------ everything


def migrate(texts: dict[str, str], dates: DateLookup, strict: bool = True) -> Migration:
    """The whole new layout, as relative path -> content, from the three old files' texts."""
    report = Report()
    tree: dict[str, str] = {DECISIONS: NEW_DECISIONS}
    for part in (
        decision_tree(texts[DECISIONS], dates, report),
        todo_tree(texts[TODO], dates, strict, report),
        review_tree(texts[REVIEW], dates, strict, report),
    ):
        clash = set(part) & set(tree)
        if clash:
            raise QueueFormatError(f"two things would be written to {sorted(clash)}")
        tree.update(part)
    return Migration(tree, report)


def is_old_format(texts: dict[str, str]) -> bool:
    return texts[DECISIONS].startswith("# Decisions\n\n## ")


def git_first_dates(rev: str, cwd: str | None = None) -> DateLookup:
    """A `DateLookup` answering with the author date of the commit that first wrote the line's text.

    Not the commit that last touched it, which is what `git blame` gives: a record moved from
    `HANDOFF.md` into `DECISIONS.md`, or an entry whose heading was reworded in place, would take
    the date of the move. The history of every top-level `docs/*.md` reachable from `rev` is read
    once, oldest first, and a text's first addition anywhere in it is its date; a line never seen
    added (which only a history rewrite could cause) falls back to `git blame`.
    """
    result = subprocess.run(
        [
            *("git", "log", "--reverse", "--no-renames", "--format=%x00%ad", "--date=short", "-p", "-U0"),
            *(rev, "--", ":(glob)docs/*.md"),
        ],
        cwd=cwd,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise QueueFormatError(f"git log {rev} failed: {result.stderr.strip()}")
    first: dict[str, str] = {}
    date = ""
    for line in result.stdout.split("\n"):
        if line.startswith("\0"):
            date = line[1:].strip()
        elif line.startswith("+") and not line.startswith("+++"):
            first.setdefault(line[1:], date)
    texts: dict[str, list[str]] = {}
    blamed = git_line_dates(rev, cwd)

    def lookup(path: str, line: int) -> str:
        if path not in texts:
            shown = git_show(rev, path, cwd)
            if shown is None:
                raise QueueFormatError(f"{rev} has no {path}")
            texts[path] = shown.split("\n")
        lines = texts[path]
        if not 1 <= line <= len(lines):
            raise QueueFormatError(f"{rev}:{path} has no line {line}")
        return first.get(lines[line - 1]) or blamed(path, line)

    return lookup


def git_line_dates(rev: str, cwd: str | None = None) -> DateLookup:
    """A `DateLookup` answering from `git blame <rev>`: the author date of the commit that wrote the line."""
    cache: dict[str, list[str]] = {}

    def lookup(path: str, line: int) -> str:
        if path not in cache:
            cache[path] = blame_dates(rev, path, cwd)
        dates = cache[path]
        if not 1 <= line <= len(dates):
            raise QueueFormatError(f"git blame {rev} -- {path} has no line {line}")
        return dates[line - 1]

    return lookup


def blame_dates(rev: str, path: str, cwd: str | None = None) -> list[str]:
    result = subprocess.run(
        ["git", "blame", "--line-porcelain", rev, "--", path],
        cwd=cwd,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise QueueFormatError(f"git blame {rev} -- {path} failed: {result.stderr.strip()}")
    dates: list[str] = []
    stamp = 0
    zone = "+0000"
    for line in result.stdout.split("\n"):
        if line.startswith("author-time "):
            stamp = int(line.split(" ", 1)[1])
        elif line.startswith("author-tz "):
            zone = line.split(" ", 1)[1]
        elif line.startswith("\t"):
            dates.append(local_date(stamp, zone))
    return dates


def local_date(stamp: int, zone: str) -> str:
    import datetime

    sign = -1 if zone.startswith("-") else 1
    offset = sign * (int(zone[1:3]) * 3600 + int(zone[3:5]) * 60)
    moment = datetime.datetime.fromtimestamp(stamp + offset, tz=datetime.UTC)
    return moment.strftime("%Y-%m-%d")


def git_show(rev: str, path: str, cwd: str | None = None) -> str | None:
    result = subprocess.run(["git", "show", f"{rev}:{path}"], cwd=cwd, capture_output=True, text=True, check=False)
    return result.stdout if result.returncode == 0 else None
