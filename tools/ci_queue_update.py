#!/usr/bin/env python3
"""The mechanical half of a queue update's review, run by CI before the reviewer reads it.

A queue update is a pull request whose every file is under `docs/todo/`, `docs/review/` or
`docs/playtests/` (`tools/ci_classify.py` calls it queue-only, which is how CI knows to run this).
These are the checks a script can make of what the pr-review skill's review of a queue update
verifies, made first, so the review spends its time on faithfulness: the player asked for "a CI
check that does what the reviewer currently does automatically ... the reviewer still needs to
verify the correctness of those changes anyway. the CI is only a help" (bouncy-heron, statement 9).

- **No existing playtest file changes.** A playtest is a primary source and is never rewritten, so
  anything under `docs/playtests/` but an added file fails -- a rename too, since the diff splits a
  rename into a deletion and an addition.
- **Nothing open disappears unaccounted for.** A deleted file under `docs/todo/<entry>/` needs one
  of: a record for its entry on the base already (`docs/decisions/<entry>.md` or
  `<entry>-<n>.md`), a line in the pull request's description
  `Dropped: <path> — "<the player's words>"` naming the file or its entry's folder, whose quoted
  words appear verbatim (`lib_ci.normalize`) in a file under `docs/playtests/`, or the same content
  added again elsewhere under `docs/todo/` (a move). A deleted review item needs a playtest file
  that names it (its file name without `.md`).
- **The queue still reads.** `tools/lint.sh` runs as a step of its own on every pull request; this
  puts `tools/queue.sh`'s line for every entry the pull request touched into the job's summary, for
  the reviewer to compare with the band the description names.

Every failure names the file and the rule. A `Dropped:` line that does not parse, or that names a
path the pull request does not delete, fails too, since a drop that points nowhere is a typo that
would otherwise pass for an account. What a script cannot see -- that the record which exists
covers the item deleted, that the quote says what the drop claims -- is the reviewer's still.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib_ci
from lib_ci import Change

TODO = "docs/todo"
REVIEW = "docs/review"
PLAYTESTS = "docs/playtests"
DECISIONS = "docs/decisions"

DROPPED_ANY = re.compile(lib_ci.LIST_MARKER + r"Dropped:", re.MULTILINE)
# The separator is an em dash, an en dash, or one or two hyphens; the quote marks straight or curly.
DROPPED = re.compile(
    lib_ci.LIST_MARKER
    + r"Dropped:[ \t]*`?(?P<path>[^\s`]+)`?[ \t]+(?:\u2014|\u2013|--?)[ \t]+"
    + r"[\"\u201c](?P<quote>.+)[\"\u201d][ \t]*$"
)
DROPPED_FORM = 'Dropped: <path> — "<the player\'s words>"'

EPILOG = """\
examples:
  uv run python tools/ci_queue_update.py --pr 425
  uv run python tools/ci_queue_update.py --base origin/main
"""


@dataclass(frozen=True)
class Dropped:
    path: str
    quote: str


def parse_dropped(description: str) -> tuple[list[Dropped], list[str]]:
    """The description's `Dropped:` lines, and a failure for each one that does not have the form."""
    drops: list[Dropped] = []
    malformed: list[str] = []
    for line in lib_ci.without_fences(description).split("\n"):
        if not DROPPED_ANY.match(line):
            continue
        match = DROPPED.match(line)
        if match is None:
            malformed.append(f"the description's line {line.strip()!r} does not have the form {DROPPED_FORM}")
            continue
        drops.append(Dropped(path=match.group("path").rstrip("/"), quote=match.group("quote")))
    return drops, malformed


def entry_of(path: str) -> str:
    return path.split("/")[2]


def has_record(entry: str, records: set[str]) -> bool:
    return f"{entry}.md" in records or any(re.fullmatch(re.escape(entry) + r"-\d+\.md", name) for name in records)


def check(
    changes: list[Change],
    records: set[str],
    playtests: dict[str, str],
    description: str,
) -> list[str]:
    """Failures, each naming the file and the rule; `records` are the file names under docs/decisions/ on the base."""
    failures: list[str] = []
    drops, malformed = parse_dropped(description)
    failures.extend(malformed)
    normalized_playtests = {path: lib_ci.normalize(text) for path, text in playtests.items()}
    added_to_queue = {change.new_blob for change in changes if change.status == "A" and lib_ci.under(change.path, TODO)}
    deleted_paths = {change.path for change in changes if change.status == "D"}

    for drop in drops:
        covers = [path for path in deleted_paths if path == drop.path or path.startswith(drop.path + "/")]
        if not covers:
            failures.append(f"Dropped: {drop.path}: the pull request deletes no such file or folder")
        quote = lib_ci.normalize(drop.quote)
        if not any(quote in text for text in normalized_playtests.values()):
            failures.append(
                f"Dropped: {drop.path}: the quoted words appear in no file under {PLAYTESTS}/ "
                "(a drop quotes the player's words verbatim from a playtest file)"
            )

    for change in changes:
        path = change.path
        if lib_ci.under(path, PLAYTESTS) and change.status != "A":
            failures.append(
                f"{path}: an existing playtest file {'deleted' if change.status == 'D' else 'changed'}; "
                "a playtest is a primary source and a queue update only adds one"
            )
        elif lib_ci.under(path, TODO) and change.status == "D":
            entry = entry_of(path)
            if change.old_blob in added_to_queue:
                continue
            if has_record(entry, records):
                continue
            if any(path == drop.path or path.startswith(drop.path + "/") for drop in drops):
                continue
            failures.append(
                f"{path}: deleted with no record for {entry} under {DECISIONS}/ on the base and no line "
                f"{DROPPED_FORM} in the description naming it or its entry's folder"
            )
        elif lib_ci.under(path, REVIEW) and change.status == "D":
            name = Path(path).stem
            if not any(name in text for text in playtests.values()):
                failures.append(f"{path}: a review item deleted, and no file under {PLAYTESTS}/ names {name}")
    return failures


def touched_entries(changes: list[Change]) -> list[str]:
    return sorted({entry_of(change.path) for change in changes if lib_ci.under(change.path, TODO)})


def queue_summary(entries: list[str], queue_lines: list[str]) -> str:
    """The queue's own line for each entry touched, or a note that the entry is no longer in the queue."""
    if not entries:
        return "### The queue\n\nThis pull request touches no entry under docs/todo/.\n"
    by_entry: dict[str, str] = {}
    for line in queue_lines:
        fields = line.split()
        if len(fields) >= 2:
            by_entry[fields[1]] = line
    rows = [
        f"    {by_entry[entry]}" if entry in by_entry else f"    {entry}: no longer in the queue (its folder is gone)"
        for entry in entries
    ]
    return "### The queue, every entry this pull request touches\n\n" + "\n".join(rows) + "\n"


def base_records(base: str) -> set[str]:
    listing = lib_ci.git("ls-tree", "--name-only", f"{base}:{DECISIONS}")
    return {name for name in listing.splitlines() if name}


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/ci_queue_update.py",
        description=(
            "The queue update's mechanical checks, against the branch's changes since BASE and the pull"
            " request's description as it stands now: no existing playtest file changed; every deleted queue"
            " file accounted for by a record on BASE, a `Dropped:` line quoting a playtest verbatim, or a move;"
            " every deleted review item named by a playtest. Prints tools/queue.sh's line for every entry"
            " touched, to the job summary in CI."
        ),
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--base", default=lib_ci.DEFAULT_BASE, help="where the branch started (default origin/main)")
    parser.add_argument("--head", default="HEAD", help="the branch's tip (default HEAD)")
    parser.add_argument(
        "--pr", type=int, default=None, help="the pull request whose description to read (default $PR_NUMBER)"
    )
    parser.add_argument("--repo", default=None, help="owner/name (default $GITHUB_REPOSITORY, or gh's own)")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse(argv)
    number = args.pr if args.pr is not None else lib_ci.default_pr()
    try:
        changes = lib_ci.changed_files(args.base, args.head)
        records = base_records(args.base)
        if number is None:
            print("no pull request given (--pr or $PR_NUMBER), so the description is read as empty")
            description = ""
        else:
            description = lib_ci.pr_description(args.repo or lib_ci.default_repo(), number)
    except lib_ci.CiError as error:
        print(f"tools/ci_queue_update.py: {error}", file=sys.stderr)
        return 1
    queue = subprocess.run(
        [str(lib_ci.ROOT / "tools" / "queue.sh")], cwd=lib_ci.ROOT, capture_output=True, text=True, check=False
    )
    lib_ci.write_summary(queue_summary(touched_entries(changes), queue.stdout.splitlines()))
    failures = check(changes, records, lib_ci.playtest_texts(), description)
    if queue.returncode != 0:
        failures.append(f"tools/queue.sh: the queue does not read: {queue.stderr.strip()}")
    return lib_ci.report("tools/ci_queue_update.py", failures, "every mechanical check of a queue update passed")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
