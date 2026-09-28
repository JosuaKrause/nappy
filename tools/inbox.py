#!/usr/bin/env python3
"""The player's inbox on GitHub Issues: capture a note, read it, ask on it, and close or reopen a filed batch.

GitHub Issues are the player's inbox and nothing else (leafy-finch; bouncy-heron, statements 5, 6
and 22): a note is an open issue carrying the label `inbox`, the player edits it until it is
filed, and when the player asks, an agent copies a batch of notes word for word into a playtest
file and files the queue from it in one pull request whose description names each note on a line
of its own, `Filed from #N`. The inbox skill (`.claude/skills/inbox/SKILL.md`) is the workflow;
this is its tool, and the one sanctioned way an agent writes an issue (statement 14: "if it goes
through a script it's safe ... an agent shouldn't use gh issue directly"), so
`.claude/hooks/github-write-guard.sh` denies a direct `gh issue` write, wrapped or not.

    capture                  opens a note holding the player's words verbatim, from --body-file or
                             standard input, labelled `inbox` and `captured` and, with --band, its
                             band, in one call (statements 2 and 13)
    list                     every open note, oldest first, with its band; every other issue
                             labelled `inbox` is skipped with a line saying why
    show N                   one note in full: its body as it stands now, then the comments in
                             order -- the player's, the agent's (a question, a filing note), and a
                             line for each skipped one
    ask N                    posts a question on note N (dotted-quail, statement 1), its text from
                             --body-file or standard input
    close --pr P             right after filing pull request P is pushed, closes every note its
                             description names, in one call (statement 22)
    reopen --pr P            reopens them when P was closed without merging

**Only the player's notes count** (statements 19 and 23): an issue the player (`PLAYER`) opened,
or one the capture script opened as one of `CAPTURE_BOTS` with its tag, the label `captured`. The
repository is public and the label alone admits anybody, so every other issue is skipped here and
fails `tools/ci_transcription.py`, the CI check that reads a filing pull request's `Filed from #N`
lines; these constants and that check's must agree, and `tools/test_inbox.py` compares them
whenever the check is present. A comment counts as the player's words only when the player wrote
it.

**A band is a label** (dotted-quail, statement 2): `queue_now`, `queue_next`, `queue_later` or
`queue_parked`, read by that exact pattern, so a label outside it is never taken for a band. A note
with two band labels is filed under neither and asked about.

**Every write goes out as an agent identity, never as the player**: the role comes from `--role`
or `NAPPY_AGENT_ROLE` (which `tools/agent-identity.py run <role> --` sets), and each write runs
through `tools/agent-identity.py run <role> -- gh ...` with a fresh token, the way
`tools/lib_agent_role.sh`'s `agent_run` does for the land and prune scripts. Unlike those, a write
here refuses to run with no role at all, rather than falling back to the invoking user's own
login: a note written under the player's account would read as the player's own words. The role is
`claude-orchestrator` in Claude Code and `codex-coder` in Codex, the two identities whose captures
count (committing, "Who a commit and a pull request are from"). Reads run on whatever `gh` is
logged in as.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import subprocess
import sys
from collections.abc import Callable, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

TOOLS = Path(__file__).resolve().parent
ROOT = TOOLS.parent

PLAYER = "JosuaKrause"
# The capture script's identities, and the tag only it sets: a label rather than a line in the
# body, so the body stays the player's words alone. `tools/ci_transcription.py` holds the same.
CAPTURE_BOTS = ("nappy-claude-orchestrator[bot]", "nappy-codex-coder[bot]")
CAPTURE_LABEL = "captured"
INBOX_LABEL = "inbox"
BANDS = ("now", "next", "later", "parked")
BAND_LABEL = re.compile(r"^queue_(now|next|later|parked)$")
# The roles an issue write may go out as, and the login each shows as.
WRITE_ROLES = {"claude-orchestrator": "nappy-claude-orchestrator[bot]", "codex-coder": "nappy-codex-coder[bot]"}
PLAYTESTS = "docs/playtests/"
PAGE = 100

# The `Filed from #N` line, read exactly as `tools/ci_transcription.py` reads it: after an optional
# list marker, outside fenced code blocks; a line that starts with "filed from" in any case but is
# not that form is a near miss, and fails rather than leaving its note unchecked.
LIST_MARKER = r"^[ \t]*(?:(?:[-*+]|\d+[.)])[ \t]+)?"
FILED = re.compile(LIST_MARKER + r"Filed from #(\d+)\b")
FILED_ANY = re.compile(r"^\W*(?:\d+[.)]\W*)?filed\s+from\b", re.IGNORECASE)
FENCE = re.compile(r"^[ \t]{0,3}(`{3,}|~{3,})")

EPILOG = """\
examples:
  uv run python tools/inbox.py --role claude-orchestrator capture --band next < /tmp/words.md
  uv run python tools/inbox.py list
  uv run python tools/inbox.py show 423
  uv run python tools/inbox.py --role claude-orchestrator ask 423 --body-file /tmp/question.md
  uv run python tools/inbox.py --role claude-orchestrator close --pr 430
  uv run python tools/inbox.py close --pr 430 --dry-run
"""


class InboxError(Exception):
    """A read or a write failed, or the inbox is not in the state the command needs; nothing more is done."""


# Runs one command with an optional standard input and returns its standard output; raises
# InboxError when it fails. Tests pass a fake.
Runner = Callable[[Sequence[str], str | None], str]


def run_command(args: Sequence[str], stdin: str | None) -> str:
    result = subprocess.run(list(args), input=stdin, capture_output=True, text=True, check=False, cwd=ROOT)
    if result.returncode != 0:
        shown = " ".join(args[args.index("gh") :] if "gh" in args else args)
        raise InboxError(f"`{shown}` failed: {result.stderr.strip() or result.stdout.strip()}")
    return result.stdout


@dataclass(frozen=True)
class Note:
    number: int
    title: str
    author: str
    labels: tuple[str, ...]
    body: str
    state: str
    url: str
    is_pull_request: bool


@dataclass(frozen=True)
class Comment:
    author: str
    created: str
    body: str


def login(data: dict[str, Any]) -> str:
    user = data.get("user")
    return str(user.get("login", "")) if isinstance(user, dict) else ""


def note_from_api(data: dict[str, Any]) -> Note:
    labels = data.get("labels")
    body = data.get("body")
    return Note(
        number=int(data.get("number", 0)),
        title=str(data.get("title", "")),
        author=login(data),
        labels=tuple(
            str(label.get("name", ""))
            for label in (labels if isinstance(labels, list) else [])
            if isinstance(label, dict)
        ),
        body=body if isinstance(body, str) else "",
        state=str(data.get("state", "")),
        url=str(data.get("html_url", "")),
        is_pull_request="pull_request" in data,
    )


def comment_from_api(data: dict[str, Any]) -> Comment:
    body = data.get("body")
    return Comment(
        author=login(data), created=str(data.get("created_at", "")), body=body if isinstance(body, str) else ""
    )


def skip_reason(note: Note) -> str | None:
    """Why the issue is not one of the player's notes, or None when it is."""
    if note.is_pull_request:
        return "a pull request, not a note"
    if INBOX_LABEL not in note.labels:
        return f"not labelled `{INBOX_LABEL}`"
    if note.author.lower() == PLAYER.lower():
        return None
    if note.author in CAPTURE_BOTS:
        if CAPTURE_LABEL in note.labels:
            return None
        return f"opened by {note.author} without the `{CAPTURE_LABEL}` label the capture script sets"
    return (
        f"opened by {note.author or 'an unknown account'}, not by the player ({PLAYER}) or the capture script;"
        " an issue from anybody else is something to look at, never an inbox note"
    )


def bands(labels: Sequence[str]) -> list[str]:
    return [match.group(1) for label in labels if (match := BAND_LABEL.match(label))]


def band_text(labels: Sequence[str]) -> str:
    found = bands(labels)
    if not found:
        return "no band"
    if len(found) == 1:
        return f"band {found[0]}"
    return f"two bands ({', '.join(found)}): filed under neither until the player says which"


def without_fences(description: str) -> str:
    """The description with every fenced code block blanked, the same reading `tools/lib_ci.py` gives."""
    kept: list[str] = []
    fence = ""
    for line in description.replace("\r\n", "\n").split("\n"):
        match = FENCE.match(line)
        if not fence:
            if match:
                fence = match.group(1)
                kept.append("")
            else:
                kept.append(line)
            continue
        closes = match is not None and match.group(1)[0] == fence[0] and len(match.group(1)) >= len(fence)
        if closes and not line.strip().lstrip(fence[0]):
            fence = ""
        kept.append("")
    return "\n".join(kept)


def filed_numbers(description: str) -> tuple[list[int], list[str]]:
    """Every `Filed from #N` line's N, once each, in order, and every near miss."""
    numbers: list[int] = []
    malformed: list[str] = []
    for line in without_fences(description).split("\n"):
        match = FILED.match(line)
        if match is None:
            if FILED_ANY.match(line):
                malformed.append(line.strip())
            continue
        number = int(match.group(1))
        if number not in numbers:
            numbers.append(number)
    return numbers, malformed


def normalize(text: str) -> str:
    """Words only: blockquote markers dropped from each line's start, every run of whitespace one space.

    The same reading `tools/lib_ci.py`'s `normalize` gives, so a copy this accepts is one the
    transcription check accepts.
    """
    lines = [re.sub(r"^[ \t]*(?:>[ \t]?)+", "", line) for line in text.replace("\r\n", "\n").split("\n")]
    return " ".join(" ".join(lines).split())


@dataclass
class GitHub:
    repo: str
    runner: Runner = run_command

    def get(self, endpoint: str) -> Any:
        return json.loads(self.runner(["gh", "api", endpoint], None))

    def get_all(self, endpoint: str) -> list[dict[str, Any]]:
        """Every item of a list endpoint, a page of `PAGE` at a time."""
        items: list[dict[str, Any]] = []
        joiner = "&" if "?" in endpoint else "?"
        page = 1
        while True:
            batch = self.get(f"{endpoint}{joiner}per_page={PAGE}&page={page}")
            if not isinstance(batch, list):
                raise InboxError(f"gh api {endpoint} did not return a list")
            items.extend(item for item in batch if isinstance(item, dict))
            if len(batch) < PAGE:
                return items
            page += 1

    def note(self, number: int) -> Note:
        data = self.get(f"repos/{self.repo}/issues/{number}")
        if not isinstance(data, dict):
            raise InboxError(f"issue #{number} could not be read")
        return note_from_api(data)

    def comments(self, number: int) -> list[Comment]:
        return [comment_from_api(item) for item in self.get_all(f"repos/{self.repo}/issues/{number}/comments")]

    def write(self, role: str, args: Sequence[str], stdin: str | None = None) -> str:
        """One `gh` write as `role`, through `tools/agent-identity.py run`, with a token of its own."""
        wrapper = [sys.executable, str(TOOLS / "agent-identity.py"), "run", role, "--"]
        return self.runner([*wrapper, "gh", *args], stdin)


def write_role(explicit: str | None) -> str:
    role = explicit or os.environ.get("NAPPY_AGENT_ROLE", "")
    if not role:
        raise InboxError(
            "an issue write needs an agent identity: pass --role claude-orchestrator (Codex: codex-coder), or run"
            " this through `tools/agent-identity.py run <role> --`; it never writes as the player"
        )
    if role not in WRITE_ROLES:
        raise InboxError(
            f"an issue write goes out as {' or '.join(WRITE_ROLES)}, not {role}: only those identities' captures"
            " count as the player's notes (committing, 'Who a commit and a pull request are from')"
        )
    return role


def open_note(github: GitHub, number: int) -> Note:
    """Note `number`, which must be one of the player's open notes."""
    note = github.note(number)
    reason = skip_reason(note)
    if reason is not None:
        raise InboxError(f"#{number} is not an inbox note: {reason}")
    if note.state != "open":
        raise InboxError(f"#{number} is {note.state}; a filed note is closed, and a later thought is a new note")
    return note


def cmd_list(github: GitHub) -> int:
    issues = github.get_all(f"repos/{github.repo}/issues?labels={INBOX_LABEL}&state=open&direction=asc&sort=created")
    notes = sorted((note_from_api(item) for item in issues), key=lambda note: note.number)
    kept = 0
    for note in notes:
        reason = skip_reason(note)
        if reason is not None:
            print(f"skipped #{note.number}: {reason}")
            continue
        kept += 1
        captured = f", captured by {note.author}" if note.author in CAPTURE_BOTS else ""
        print(f"#{note.number}  {band_text(note.labels)}  {note.title}  ({note.url}{captured})")
    if kept == 0:
        print("The inbox is empty: no open note from the player.")
    else:
        print(f"{kept} open note(s); `uv run python tools/inbox.py show N` prints one in full.")
    return 0


def cmd_show(github: GitHub, number: int) -> int:
    note = github.note(number)
    reason = skip_reason(note)
    if reason is not None:
        raise InboxError(f"#{number} is not an inbox note: {reason}")
    print(f"#{note.number} {note.title}")
    print(f"opened by {note.author} · {note.state} · {band_text(note.labels)} · labels {', '.join(note.labels)}")
    print(note.url)
    print()
    print("--- the note, as it stands now (the player's words) ---")
    print(note.body)
    for comment in github.comments(number):
        print()
        if comment.author.lower() == PLAYER.lower():
            print(f"--- comment by {comment.author}, {comment.created} (the player's words) ---")
            print(comment.body)
        elif comment.author in CAPTURE_BOTS:
            print(f"--- comment by {comment.author}, {comment.created} (the agent's side, not the player's words) ---")
            print(comment.body)
        else:
            print(f"skipped a comment by {comment.author or 'an unknown account'}, {comment.created}: not the player's")
    return 0


def read_text(body_file: str | None, what: str) -> str:
    text = Path(body_file).read_text(encoding="utf-8") if body_file else sys.stdin.read()
    if not text.strip():
        raise InboxError(f"{what} is empty; nothing was written")
    return text


TITLE_LENGTH = 70


def default_title(text: str) -> str:
    """The first line of the words, cut at a word boundary: the note's title when none is given."""
    first = next(line.strip() for line in text.splitlines() if line.strip())
    first = re.sub(r"^[>\s]+", "", first)
    if len(first) <= TITLE_LENGTH:
        return first
    cut = first.rfind(" ", 0, TITLE_LENGTH)
    return first[: cut if cut > 0 else TITLE_LENGTH] + "…"


ISSUE_URL = re.compile(r"/issues/(\d+)\s*$")


def cmd_capture(
    github: GitHub, role: str, text: str, title: str | None, band: str | None, context: str | None = None
) -> int:
    """Opens a note with the player's words as its body, tagged so it counts as the player's.

    The body is the words alone, so it can be copied word for word; what they answered, when given,
    goes on the note as its first comment, the agent's side, which `show` prints before any answer.
    """
    labels = [INBOX_LABEL, CAPTURE_LABEL] + ([f"queue_{band}"] if band else [])
    args = ["issue", "create", "-R", github.repo, "--title", title or default_title(text), "--body-file", "-"]
    for label in labels:
        args += ["--label", label]
    url = github.write(role, args, text).strip()
    print(url)
    if context is not None:
        match = ISSUE_URL.search(url)
        if match is None:
            raise InboxError(f"the note is open ({url}), but its number could not be read to post the context")
        github.write(role, ["issue", "comment", match.group(1), "-R", github.repo, "--body-file", "-"], context)
        print(f"posted the context on #{match.group(1)}")
    return 0


def cmd_ask(github: GitHub, role: str, number: int, text: str) -> int:
    open_note(github, number)
    print(github.write(role, ["issue", "comment", str(number), "-R", github.repo, "--body-file", "-"], text).strip())
    return 0


@dataclass(frozen=True)
class Batch:
    pr: int
    state: str
    merged: bool
    notes: list[Note]


def read_batch(github: GitHub, pr: int) -> Batch:
    """Filing pull request `pr` and every note its description names, each checked to be the player's."""
    data = github.get(f"repos/{github.repo}/pulls/{pr}")
    if not isinstance(data, dict):
        raise InboxError(f"pull request #{pr} could not be read")
    body = data.get("body")
    numbers, malformed = filed_numbers(body if isinstance(body, str) else "")
    if malformed:
        raise InboxError(
            f"#{pr}'s description has lines that are not the form `Filed from #N`: {malformed}; fix them first"
        )
    if not numbers:
        raise InboxError(f"#{pr}'s description names no note: it has no `Filed from #N` line")
    notes = [github.note(number) for number in numbers]
    failures = [f"#{note.number}: {reason}" for note in notes if (reason := skip_reason(note)) is not None]
    if failures:
        raise InboxError("not every note the description names is the player's: " + "; ".join(failures))
    return Batch(pr=pr, state=str(data.get("state", "")), merged=bool(data.get("merged")), notes=notes)


def added_playtests(github: GitHub, pr: int) -> dict[str, str]:
    """The text of every file under docs/playtests/ that pull request `pr` adds, at its head."""
    data = github.get(f"repos/{github.repo}/pulls/{pr}")
    head = data.get("head", {}).get("sha", "") if isinstance(data, dict) else ""
    texts: dict[str, str] = {}
    for item in github.get_all(f"repos/{github.repo}/pulls/{pr}/files"):
        path = str(item.get("filename", ""))
        if item.get("status") != "added" or not path.startswith(PLAYTESTS):
            continue
        content = github.get(f"repos/{github.repo}/contents/{path}?ref={head}")
        encoded = content.get("content", "") if isinstance(content, dict) else ""
        texts[path] = base64.b64decode(str(encoded)).decode("utf-8")
    return texts


def cmd_close(github: GitHub, role: str | None, pr: int, dry_run: bool) -> int:
    batch = read_batch(github, pr)
    if batch.state != "open":
        raise InboxError(
            f"#{pr} is {'merged' if batch.merged else batch.state}; a batch is closed right after its filing"
            " pull request is pushed, while it is open"
        )
    pending = [note for note in batch.notes if note.state == "open"]
    for note in batch.notes:
        if note.state != "open":
            print(f"#{note.number} is already {note.state}")
    playtests = {path: normalize(text) for path, text in added_playtests(github, pr).items()}
    missing = [note.number for note in pending if not any(normalize(note.body) in text for text in playtests.values())]
    if missing:
        where = ", ".join(sorted(playtests)) or f"no file under {PLAYTESTS}"
        raise InboxError(
            f"not closing anything: the current text of {', '.join(f'#{n}' for n in missing)} is not word for word in"
            f" what #{pr} adds ({where}); the note changed since it was copied, or the copy is wrong"
        )
    comment = f"Filed in #{pr}. From here on the playtest file is the record; a later thought is a new note."
    for note in pending:
        if dry_run:
            print(f"would close #{note.number} ({note.title}), its text found word for word in #{pr}")
            continue
        github.write(
            write_role(role),
            ["issue", "close", str(note.number), "-R", github.repo, "--reason", "completed", "--comment", comment],
        )
        print(f"closed #{note.number} ({note.title})")
    return 0


def cmd_reopen(github: GitHub, role: str | None, pr: int, dry_run: bool) -> int:
    batch = read_batch(github, pr)
    if batch.merged or batch.state != "closed":
        raise InboxError(
            f"#{pr} is {'merged' if batch.merged else batch.state}; notes are reopened only when their filing pull"
            " request was closed without merging"
        )
    comment = f"Reopened: #{pr}, which filed this note, was closed without merging, so the note is back in the inbox."
    for note in batch.notes:
        if note.state == "open":
            print(f"#{note.number} is already open")
        elif dry_run:
            print(f"would reopen #{note.number} ({note.title})")
        else:
            github.write(
                write_role(role), ["issue", "reopen", str(note.number), "-R", github.repo, "--comment", comment]
            )
            print(f"reopened #{note.number} ({note.title})")
    return 0


def default_repo(runner: Runner) -> str:
    repo = os.environ.get("GITHUB_REPOSITORY", "")
    if repo:
        return repo
    repo = runner(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"], None).strip()
    if not repo:
        raise InboxError("could not tell which repository this is; pass --repo OWNER/NAME")
    return repo


def add_role(parser: argparse.ArgumentParser, *, top: bool) -> None:
    """`--role`, before the subcommand or after it; the subcommand's own leaves the top one's value alone."""
    parser.add_argument(
        "--role",
        default=None if top else argparse.SUPPRESS,
        choices=sorted(WRITE_ROLES),
        help="the identity a write goes out as (default $NAPPY_AGENT_ROLE); a write refuses to run without one",
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="tools/inbox.py",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=EPILOG,
    )
    parser.add_argument("--repo", default=None, metavar="OWNER/NAME", help="default $GITHUB_REPOSITORY, or gh's own")
    add_role(parser, top=True)
    commands = parser.add_subparsers(dest="command", required=True, metavar="{capture,list,show,ask,close,reopen}")
    capture = commands.add_parser("capture", help="open a note holding the player's words verbatim")
    capture.add_argument("--body-file", default=None, help="the player's words (default: standard input)")
    capture.add_argument("--title", default=None, help="the note's title (default: the words' first line, cut short)")
    capture.add_argument("--band", default=None, choices=BANDS, help="the band the player named, as its queue_ label")
    capture.add_argument(
        "--context-file",
        default=None,
        help="what the words answered, posted as the note's first comment, the agent's side (default: none)",
    )
    add_role(capture, top=False)
    commands.add_parser("list", help="every open note, and a line for each issue skipped")
    show = commands.add_parser("show", help="one note in full, with its comments in order")
    show.add_argument("number", type=int)
    ask = commands.add_parser("ask", help="post a question on a note")
    ask.add_argument("number", type=int)
    ask.add_argument("--body-file", default=None, help="the question's text (default: standard input)")
    add_role(ask, top=False)
    for name, text in (
        ("close", "close every note a filing pull request names, right after it is pushed"),
        ("reopen", "reopen them when the filing pull request was closed without merging"),
    ):
        sub = commands.add_parser(name, help=text)
        sub.add_argument("--pr", type=int, required=True, help="the filing pull request")
        sub.add_argument("--dry-run", action="store_true", help="check and print what would change; write nothing")
        add_role(sub, top=False)
    return parser


def main(argv: Sequence[str], runner: Runner = run_command) -> int:
    args = build_parser().parse_args(list(argv))
    try:
        github = GitHub(args.repo or default_repo(runner), runner)
        if args.command == "capture":
            writer = write_role(args.role)
            words = read_text(args.body_file, "the player's words")
            context = read_text(args.context_file, "the context") if args.context_file else None
            return cmd_capture(github, writer, words, args.title, args.band, context)
        if args.command == "list":
            return cmd_list(github)
        if args.command == "show":
            return cmd_show(github, args.number)
        if args.command == "ask":
            return cmd_ask(github, write_role(args.role), args.number, read_text(args.body_file, "the question"))
        if args.command == "close":
            role = None if args.dry_run else write_role(args.role)
            return cmd_close(github, role, args.pr, args.dry_run)
        role = None if args.dry_run else write_role(args.role)
        return cmd_reopen(github, role, args.pr, args.dry_run)
    except InboxError as error:
        print(f"tools/inbox.py: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
