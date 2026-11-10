#!/usr/bin/env python3
"""A pull request that builds an item of a `fable-only` queue entry carries the `fable-only` label.

A queue entry whose `README.md` says `fable-only: true` in its opening block, beside `priority:`,
is one the player named as Fable's: Fable designs its code and reviews it, and writing the code may
go to another model (`docs/TODO.md`, "The order is `tools/queue.sh`"; the model table in the
orchestrating skill). The GitHub label `fable-only` is how a session that never read the entry
knows that about a pull request, so every pull request that builds one of the entry's items carries
it, and this fails one that does not.

- **Building an item is read from an added record.** A pull request builds an item of an entry when
  it adds a record of that entry under `docs/decisions/` (`<entry>.md`, `<entry>-<n>.md` or
  `<entry>-<adjective>-<animal>.md`, a new file): every pull request that builds an item adds one
  before it merges (the committing skill, "A pull request is self-contained"). A record the pull
  request only changes does not count, since an inbox filing rewrites `inbox #N` citations in
  existing records of an entry (`tools/inbox.py cite`) and no filing builds anything. The entry's
  own folder cannot tell a build from a filing either, since a filing adds, rewords, moves and
  drops items there too, so a pull request that only touches `docs/todo/<entry>/` owes no label.
  A pull request that closes an entry by adding its record owes the label too, whoever writes it:
  closing is a judgement about the work the player put under Fable.
- **The entry's line is read on both sides.** The pull request that builds an entry's last item
  deletes its folder, so the `README.md` is read at `--base` as well as at `--head`, and the line
  on either side counts: a pull request cannot shed the label by deleting the line it builds under.
  Only the line's presence is read here; `tools/queue.sh --check`, which `tools/lint.sh` runs,
  rejects every malformed one.
- **The labels are read through the API when the check runs**, as the description is for the other
  checks (`lib_ci.pr_labels`), so re-running the job sees a label added since. CI also starts a
  run when a label is added or removed, so taking the label off a green pull request turns it red.

What a script cannot see -- that Fable did design and review the work -- is the orchestrator's and
the reviewer's still.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib_ci
from lib_ci import Change

LABEL = "fable-only"
TODO = "docs/todo"
DECISIONS = "docs/decisions"
# The lines an entry's README.md may open with (tools/queue.sh owns the set and checks each one).
OPENING = re.compile(r"(?:priority|after|upnext|fable-only):")
MARK = re.compile(r"fable-only:[ \t]*true[ \t]*")
# A record's file name: its entry's folder name (a date, then a pair of words or a milestone
# number), then nothing, a number or a second pair of words (tools/new-name.sh decision --entry).
RECORD = re.compile(r"(?P<entry>\d{4}-\d{2}-\d{2}-(?:[a-z]+-[a-z]+|M\d+))(?:-\d+|-[a-z]+-[a-z]+)?\.md")

EPILOG = """\
examples:
  uv run python tools/ci_fable_only.py --pr 425
  uv run python tools/ci_fable_only.py --base origin/main
"""


def says_fable_only(readme: str) -> bool:
    """True when the entry's README.md carries `fable-only: true` in its opening block."""
    for line in readme.replace("\r\n", "\n").split("\n"):
        if not OPENING.match(line):
            return False
        if MARK.fullmatch(line):
            return True
    return False


def built_entries(changes: list[Change]) -> dict[str, str]:
    """Each entry name the pull request adds a record of, with the first record that shows it.

    A changed record is not one: a filing's citation rewrite changes existing records.

    A name is what the record's file name says its entry is; whether there is such an entry, and
    what its `README.md` says, is the caller's to read.
    """
    built: dict[str, str] = {}
    for change in changes:
        if not lib_ci.under(change.path, DECISIONS) or change.status != "A":
            continue
        match = RECORD.fullmatch(change.path[len(DECISIONS) + 1 :])
        if match is not None:
            built.setdefault(match.group("entry"), change.path)
    return built


def check(built: dict[str, str], fable_only: set[str], labels: set[str]) -> tuple[list[str], str]:
    """The failures, and a line saying what passed it; `fable_only` are the built entries that carry the line."""
    owed = sorted(entry for entry in built if entry in fable_only)
    if not owed:
        return [], f"the pull request adds no record of an entry whose README.md says `{LABEL}: true`"
    if LABEL in labels:
        return [], f"the pull request builds {', '.join(owed)} and carries the `{LABEL}` label"
    return [
        f"{built[entry]}: the pull request adds a record of {entry}, whose README.md says `{LABEL}: true`,"
        f" and does not carry the `{LABEL}` label; Fable designs and reviews this work, so add the label"
        " (which starts a new run)"
        for entry in owed
    ], ""


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/ci_fable_only.py",
        description=(
            "Fails when the branch adds a record under docs/decisions/ of a queue entry whose"
            " README.md, at BASE or at HEAD, says `fable-only: true` in its opening block, unless the pull"
            " request, read now through the API, carries the `fable-only` label."
        ),
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--base", default=lib_ci.DEFAULT_BASE, help="where the branch started (default origin/main)")
    parser.add_argument("--head", default="HEAD", help="the branch's tip (default HEAD)")
    parser.add_argument(
        "--pr", type=int, default=None, help="the pull request whose labels to read (default $PR_NUMBER)"
    )
    parser.add_argument("--repo", default=None, help="owner/name (default $GITHUB_REPOSITORY, or gh's own)")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse(argv)
    number = args.pr if args.pr is not None else lib_ci.default_pr()
    try:
        built = built_entries(lib_ci.changed_files(args.base, args.head))
        fable_only = {
            entry
            for entry in built
            for ref in (args.base, args.head)
            if says_fable_only(lib_ci.file_at(ref, f"{TODO}/{entry}/README.md") or "")
        }
        labels: set[str] = set()
        if fable_only and number is None:
            print("no pull request given (--pr or $PR_NUMBER), so it is read as carrying no label")
        elif fable_only and number is not None:
            labels = lib_ci.pr_labels(args.repo or lib_ci.default_repo(), number)
    except lib_ci.CiError as error:
        print(f"tools/ci_fable_only.py: {error}", file=sys.stderr)
        return 1
    failures, passed = check(built, fable_only, labels)
    return lib_ci.report("tools/ci_fable_only.py", failures, passed)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
