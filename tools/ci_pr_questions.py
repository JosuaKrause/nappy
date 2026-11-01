#!/usr/bin/env python3
"""A pull request that changes code answers the architecture questions in its description.

The questions, and which pull requests answer them, are worded once, in
`.claude/skills/pr-review/references/architecture-questions.md`, and read from there: its section
`## The questions` is a numbered list, one question per item. When the branch changes anything
under `src/`, `tests/` or `tools/`, this fails unless the pull request's description has a heading
`## Architecture questions` (any level) and under it, before the next heading of the same level or
above, either

- an answer to every question: an item numbered as the question is (`1.`, `1)`, `**1.**`, `Q1:`),
  holding something more than the question's own words, or
- the one-line form, `No new piece or dependency: <what the change is>`, for a pull request that
  adds no piece and no dependency.

A line inside a code fence is not an answer, nor is an answer that is only the form's placeholder
in angle brackets. A pull request opened before this check reached the base branch is exempt: the
check's own file is looked up on the base's first-parent history, and the commit that added it is
when it arrived. The description is read through the API when the job runs, so an answer added
after a red check is seen by re-running the job.

What a script cannot see -- that an answer is true -- is the reviewer's (pr-review, "Then the
code"), against the diff and `tools/check_layers.py`.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib_ci
from lib_ci import Change

SCOPE = ("src", "tests", "tools")
QUESTIONS_FILE = lib_ci.ROOT / ".claude/skills/pr-review/references/architecture-questions.md"
QUESTIONS_SECTION = "## The questions"
SELF = "tools/ci_pr_questions.py"
HEADING = "Architecture questions"
ONE_LINE_FORM = "No new piece or dependency: <what the change is>"

HEADING_LINE = re.compile(r"^(?P<level>#{1,6})[ \t]+(?P<text>.*?)[ \t]*#*[ \t]*$")
ONE_LINE = re.compile(lib_ci.LIST_MARKER + r"No new piece or dependency:[ \t]*(?P<reason>\S.*?)[ \t]*$", re.MULTILINE)
# An answer's number: optional list bullet, optional emphasis, an optional Q, the number, then `.`, `)` or `:`.
ANSWER = re.compile(r"^[ \t]*(?:[-*+][ \t]+)?(?:\*\*|__)?(?:Q|q)?(?P<number>\d+)(?:[.):]|\*\*|__)+[ \t]*(?P<text>.*)$")
QUESTION_ITEM = re.compile(r"^(?P<number>\d+)\.[ \t]+(?P<text>.*)$")
PLACEHOLDER = re.compile(r"`?<[^>]*>`?")
WORD = re.compile(r"[a-z0-9']+")

EPILOG = """\
examples:
  uv run python tools/ci_pr_questions.py --pr 895
  uv run python tools/ci_pr_questions.py --base origin/main --description-file body.md
"""


@dataclass(frozen=True)
class PullRequest:
    """What the check reads of the pull request: its description and when it was opened."""

    description: str
    opened: datetime | None


def questions(text: str) -> list[str]:
    """The numbered questions under `## The questions`, each item's wrapped lines joined."""
    items: list[str] = []
    inside = False
    for line in text.splitlines():
        if line.startswith("## "):
            inside = line.strip() == QUESTIONS_SECTION
            continue
        if not inside:
            continue
        match = QUESTION_ITEM.match(line)
        if match:
            if int(match.group("number")) != len(items) + 1:
                raise lib_ci.CiError(f"{QUESTIONS_FILE.name}: question {match.group('number')} is out of order")
            items.append(match.group("text").strip())
        elif items and line.startswith("   ") and line.strip():
            items[-1] += " " + line.strip()
    if not items:
        raise lib_ci.CiError(f"{QUESTIONS_FILE.name} has no numbered questions under {QUESTIONS_SECTION!r}")
    return items


def section(description: str) -> str | None:
    """The text under the description's `Architecture questions` heading, outside code fences, or None."""
    lines = lib_ci.without_fences(description).split("\n")
    for index, line in enumerate(lines):
        match = HEADING_LINE.match(line)
        if not match or match.group("text").strip().lower() != HEADING.lower():
            continue
        level = len(match.group("level"))
        body: list[str] = []
        for later in lines[index + 1 :]:
            heading = HEADING_LINE.match(later)
            if heading and len(heading.group("level")) <= level:
                break
            body.append(later)
        return "\n".join(body)
    return None


def words(text: str) -> list[str]:
    return WORD.findall(text.lower())


def answer_left(answer: str, question: str) -> str:
    """The answer with its question's words dropped from its front, when it restates the question first."""
    asked = words(question)
    said = words(answer)
    if said[: len(asked)] == asked:
        return " ".join(said[len(asked) :])
    return " ".join(said)


def answers(body: str) -> dict[int, str]:
    """Each numbered item's text under the heading, its continuation lines joined, by number."""
    found: dict[int, str] = {}
    current: int | None = None
    for line in body.split("\n"):
        match = ANSWER.match(line)
        if match:
            current = int(match.group("number"))
            found[current] = found.get(current, "") + " " + match.group("text")
        elif current is not None and line.strip():
            found[current] += " " + line.strip()
    return found


def check_answers(description: str, asked: list[str]) -> tuple[list[str], str]:
    body = section(description)
    if body is None:
        return [
            f"the description has no `## {HEADING}` heading; answer the questions in "
            f"{QUESTIONS_FILE.relative_to(lib_ci.ROOT)} under it, or say `{ONE_LINE_FORM}` there"
        ], ""
    for match in ONE_LINE.finditer(body):
        reason = match.group("reason")
        if not PLACEHOLDER.fullmatch(reason):
            return [], f"the pull request adds no piece and no dependency, for the reviewer to judge: {reason}"
    given = answers(body)
    failures: list[str] = []
    for number, question in enumerate(asked, start=1):
        text = given.get(number)
        if text is None:
            failures.append(f"question {number} has no answer under `## {HEADING}`: {question}")
            continue
        left = answer_left(text, question)
        if not left or PLACEHOLDER.fullmatch(text.strip()):
            failures.append(f"question {number} is restated but not answered: {question}")
    if failures:
        return failures, ""
    return [], f"every one of the {len(asked)} questions is answered under `## {HEADING}`, for the reviewer to verify"


def arrival(base: str, cwd: Path = lib_ci.ROOT) -> datetime | None:
    """When this check's file reached the base branch: the first-parent commit that added it, or None if it has not."""
    log = lib_ci.git("log", "--first-parent", "--diff-filter=A", "--format=%cI", base, "--", SELF, cwd=cwd).split()
    return datetime.fromisoformat(log[-1]) if log else None


def check(
    changes: list[Change], pull: PullRequest, asked: list[str], arrived: datetime | None
) -> tuple[list[str], str]:
    """The failures, and a line saying what passed it for the reviewer to read."""
    code = [change.path for change in changes if lib_ci.under(change.path, *SCOPE)]
    if not code:
        return [], "the pull request changes nothing under src/, tests/ or tools/"
    if arrived is not None and pull.opened is not None and pull.opened < arrived:
        return [], f"the pull request was opened before {SELF} reached the base branch, so it answers nothing"
    failures, passed = check_answers(pull.description, asked)
    if failures:
        failures = [f"{code[0]}: the pull request changes code ({len(code)} file(s)) and {failures[0]}", *failures[1:]]
    return failures, passed


def read_pull(repo: str, number: int) -> PullRequest:
    data = lib_ci.gh_api(f"repos/{repo}/pulls/{number}")
    body = data.get("body")
    created = data.get("created_at")
    opened = datetime.fromisoformat(created) if isinstance(created, str) else None
    return PullRequest(description=body if isinstance(body, str) else "", opened=opened)


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/ci_pr_questions.py",
        description=(
            "Fails when the branch changes a file under src/, tests/ or tools/ since BASE and the pull request's"
            f" description, read now through the API, has no `## {HEADING}` heading answering every question in"
            " .claude/skills/pr-review/references/architecture-questions.md, nor the one-line form"
            f" `{ONE_LINE_FORM}` under it. A pull request opened before this check reached BASE is exempt."
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
    parser.add_argument(
        "--description-file",
        type=Path,
        default=None,
        help="read the description from this file instead of the API, as a pull request not yet opened",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse(argv)
    number = args.pr if args.pr is not None else lib_ci.default_pr()
    try:
        asked = questions(QUESTIONS_FILE.read_text(encoding="utf-8"))
        changes = lib_ci.changed_files(args.base, args.head)
        if args.description_file is not None:
            pull = PullRequest(description=args.description_file.read_text(encoding="utf-8"), opened=None)
        elif number is None:
            print("no pull request given (--pr, $PR_NUMBER or --description-file), so the description is read as empty")
            pull = PullRequest(description="", opened=None)
        else:
            pull = read_pull(args.repo or lib_ci.default_repo(), number)
        arrived = arrival(args.base)
    except (lib_ci.CiError, OSError) as error:
        print(f"tools/ci_pr_questions.py: {error}", file=sys.stderr)
        return 1
    failures, passed = check(changes, pull, asked, arrived)
    return lib_ci.report("tools/ci_pr_questions.py", failures, passed)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
