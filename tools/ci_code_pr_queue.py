#!/usr/bin/env python3
"""A pull request that changes code also changes the queue and the decision records.

The committing skill's standing rule is that "a work item never merges while its queue item is
unresolved": the item's file is gone from its entry's folder and its record is filed under
`docs/decisions/`, both on the branch. This makes that rule a check rather than only a reviewer's
memory (bouncy-heron, statement 10: "okay if the standing rule is both then let's do that"). When
the branch changes anything under `src/` or `tests/`, it fails unless the branch also

- deletes or rewrites a file under `docs/todo/` (an item finished, or rewritten to hold what is
  still open), and
- adds or changes a file under `docs/decisions/` (the record of what was built),

or the pull request's description carries a line `No queue item: <reason>`, for work with no queue
item behind it, such as a repair to CI or the tooling. The escape passes the check, and its reason
is printed for the reviewer, who judges it. The description is read through the API when the job
runs, so a line added after a red check is seen by re-running the job.

What a script cannot see -- that the file deleted is the item this work finished, that the record
says what was built -- is the reviewer's still (pr-review, "Does the finished work leave the queue
inside this PR?").
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib_ci
from lib_ci import Change

CODE_FOLDERS = ("src", "tests")
TODO = "docs/todo"
DECISIONS = "docs/decisions"
ESCAPE = re.compile(lib_ci.LIST_MARKER + r"No queue item:[ \t]*(?P<reason>\S.*?)[ \t]*$", re.MULTILINE)
ESCAPE_FORM = "No queue item: <reason>"

EPILOG = """\
examples:
  uv run python tools/ci_code_pr_queue.py --pr 425
  uv run python tools/ci_code_pr_queue.py --base origin/main
"""


def escape_reason(description: str) -> str | None:
    match = ESCAPE.search(description.replace("\r\n", "\n"))
    return match.group("reason") if match else None


def check(changes: list[Change], description: str) -> tuple[list[str], str]:
    """The failures, and a line saying what passed it for the reviewer to read."""
    code = [change.path for change in changes if lib_ci.under(change.path, *CODE_FOLDERS)]
    if not code:
        return [], "the pull request changes nothing under src/ or tests/"
    resolves_item = any(lib_ci.under(c.path, TODO) and c.status in ("D", "M", "T") for c in changes)
    files_record = any(lib_ci.under(c.path, DECISIONS) and c.status in ("A", "M", "T") for c in changes)
    if resolves_item and files_record:
        return [], "the pull request changes code, resolves a file under docs/todo/ and files under docs/decisions/"
    reason = escape_reason(description)
    if reason is not None:
        return [], f"the pull request changes code with no queue item behind it, for the reviewer to judge: {reason}"
    missing: list[str] = []
    if not resolves_item:
        missing.append(f"deletes or rewrites no file under {TODO}/")
    if not files_record:
        missing.append(f"adds or changes no file under {DECISIONS}/")
    return [
        f"{code[0]}: the pull request changes code ({len(code)} file(s) under src/ or tests/) and "
        + " and ".join(missing)
        + f"; resolve the item it builds and file its record, or say `{ESCAPE_FORM}` in the description"
    ], ""


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/ci_code_pr_queue.py",
        description=(
            "Fails when the branch changes a file under src/ or tests/ since BASE without also deleting or"
            " rewriting a file under docs/todo/ and adding or changing a file under docs/decisions/, unless the"
            " pull request's description, read now through the API, carries a line `No queue item: <reason>`."
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
        if number is None:
            print("no pull request given (--pr or $PR_NUMBER), so the description is read as empty")
            description = ""
        else:
            description = lib_ci.pr_description(args.repo or lib_ci.default_repo(), number)
    except lib_ci.CiError as error:
        print(f"tools/ci_code_pr_queue.py: {error}", file=sys.stderr)
        return 1
    failures, passed = check(changes, description)
    return lib_ci.report("tools/ci_code_pr_queue.py", failures, passed)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
