#!/usr/bin/env python3
"""Every inbox note a filing pull request names is the player's, and is copied word for word.

GitHub Issues are the player's inbox (leafy-finch): a note is an issue, and when the player asks, an
agent copies a batch of notes into a playtest file and files the queue from it in one pull request
whose description names each note on a line of its own, `Filed from #N`. This checks, for every
such line (bouncy-heron, statements 12, 19 and 23):

- **It is an inbox note.** Issue N carries the label `inbox`, as `tools/inbox.py` requires before it
  closes a filed batch: without the label that script refuses the whole batch after this check
  passed it.
- **The note is the player's.** Issue N was opened by the player (`JosuaKrause`), or by the capture
  script as `claude-orchestrator` or `codex-coder` with the script's own tag, the label `captured`,
  on it. An issue anyone else opens is welcome as something to look at and is never filed, whatever
  its labels: the repository is public, and this is what keeps people outside the project from
  putting work into the queue.
- **Its words are all there.** Issue N's body appears verbatim in a playtest file the pull request
  adds, after `lib_ci.normalize()`: blockquote markers at a line's start are dropped and every run
  of whitespace is one space, on both sides, since a playtest file quotes a note inside `> ` lines
  wrapped wherever it wraps and an issue wraps nowhere. Every word, letter case and punctuation mark
  still has to match.
- **So are the words added to it.** On a captured note, every comment by a capture identity whose
  first line is the marker `tools/inbox.py append` writes is the player's further words, and each
  appears the same way in a playtest file the pull request adds. The marker is not part of the words,
  and the same comment on a note the player opened counts for nothing. When the comment carries
  what the words answered, a `WORDS_MARKER` line ends it and only what follows is the words.
  This is looser than `tools/inbox.py close`, which needs the body and every appended comment in
  one and the same playtest file: here each may be in any file the pull request adds.

The issue is read through the API whatever its state, since the orchestrator closes a batch's notes
right after pushing the filing pull request, and the description is read when the job runs, never
from the event that started it, so a corrected description is re-checked by re-running the job. A
pull request with no `Filed from` line passes with nothing to check. A line that starts with the
words "filed from" in any case but is not the form `Filed from #N` fails, the way a malformed
`Dropped:` line fails `tools/ci_queue_update.py`, since a misspelled key would otherwise pass for a
pull request that files nothing.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, replace
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib_ci
from lib_ci import Change

PLAYTESTS = "docs/playtests"
FILED = re.compile(lib_ci.LIST_MARKER + r"Filed from #(\d+)\b")
# Any line that starts, after list markers, quote marks or emphasis, with the words "filed from" in
# any case. One that `FILED` does not parse is a near miss (`Filed from: #12`, `filed from #12`,
# `Filed from issue #12`) and fails, since a misspelled key would otherwise leave its note unchecked.
FILED_ANY = re.compile(r"^\W*(?:\d+[.)]\W*)?filed\s+from\b", re.IGNORECASE)
FILED_FORM = "Filed from #N"
PLAYER = "JosuaKrause"
# The capture script's identities: `claude-orchestrator` in Claude Code, `codex-coder` in Codex,
# which has no orchestrator identity. A bot's login is its GitHub App's slug with `[bot]`.
CAPTURE_BOTS = ("nappy-claude-orchestrator[bot]", "nappy-codex-coder[bot]")
# The tag only the capture script sets. A label rather than a line in the body, so it cannot be
# copied into a playtest by accident and the body stays the player's words alone.
CAPTURE_LABEL = "captured"
# What makes an issue an inbox note at all (leafy-finch: "the inbox is the open issues carrying an
# `inbox` label"); `tools/inbox.py` checks it before it closes a note.
INBOX_LABEL = "inbox"
# The first line of a comment `tools/inbox.py append` writes: the player's further words on a
# captured note. Only that script writes it, and it counts on a captured note alone.
APPEND_MARKER = "<!-- inbox-append: the player's further words, added by tools/inbox.py append -->"
# Separates what the words answered (above it) from the words (below it) in one append comment, so a
# failed post can never leave the context alone on the issue or duplicate it on a retry.
WORDS_MARKER = "<!-- inbox-append: the player's words follow -->"

EPILOG = """\
examples:
  uv run python tools/ci_transcription.py --pr 425
"""


@dataclass(frozen=True)
class Note:
    number: int
    author: str
    labels: tuple[str, ...]
    body: str
    is_pull_request: bool
    # The words `append` added, marker removed, one entry per comment in order; empty on a note that
    # is not captured, where no marked comment counts.
    appended: tuple[str, ...] = ()


def appended_words(author: str, labels: tuple[str, ...], comments: list[dict[str, object]]) -> tuple[str, ...]:
    """The words of every marked comment by a capture identity on a note it opened, marker removed."""
    if author not in CAPTURE_BOTS or CAPTURE_LABEL not in labels:
        return ()
    words: list[str] = []
    for comment in comments:
        user = comment.get("user")
        login = str(user.get("login", "")) if isinstance(user, dict) else ""
        body = comment.get("body")
        first, _, rest = (body if isinstance(body, str) else "").replace("\r\n", "\n").partition("\n")
        if login not in CAPTURE_BOTS or first.strip() != APPEND_MARKER:
            continue
        lines = rest.split("\n")
        for index, line in enumerate(lines):
            if line.strip() == WORDS_MARKER:
                lines = lines[index + 1 :]
                break
        said = "\n".join(lines).strip()
        if said:
            words.append(said)
    return tuple(words)


def filed_numbers(description: str) -> tuple[list[int], list[str]]:
    """Every `Filed from #N` line's N, once each, in order, and a failure for each near miss."""
    numbers: list[int] = []
    malformed: list[str] = []
    for line in lib_ci.without_fences(description).split("\n"):
        match = FILED.match(line)
        if match is None:
            if FILED_ANY.match(line):
                malformed.append(
                    f"the description's line {line.strip()!r} does not have the form {FILED_FORM},"
                    " so the note it means is not checked"
                )
            continue
        number = int(match.group(1))
        if number not in numbers:
            numbers.append(number)
    return numbers, malformed


def note_from_api(number: int, data: dict[str, object]) -> Note:
    user = data.get("user")
    author = str(user.get("login", "")) if isinstance(user, dict) else ""
    raw_labels = data.get("labels")
    labels = tuple(
        str(label.get("name", ""))
        for label in (raw_labels if isinstance(raw_labels, list) else [])
        if isinstance(label, dict)
    )
    body = data.get("body")
    return Note(
        number=number,
        author=author,
        labels=labels,
        body=body if isinstance(body, str) else "",
        is_pull_request="pull_request" in data,
    )


def author_failure(note: Note) -> str | None:
    if note.is_pull_request:
        return f"#{note.number}: a pull request, not an inbox note"
    if INBOX_LABEL not in note.labels:
        return f"#{note.number}: not labelled `{INBOX_LABEL}`, so it is not an inbox note"
    if note.author.lower() == PLAYER.lower():
        return None
    if note.author in CAPTURE_BOTS:
        if CAPTURE_LABEL in note.labels:
            return None
        return (
            f"#{note.number}: opened by {note.author} without the `{CAPTURE_LABEL}` label the capture script"
            " sets, so it is not a captured note"
        )
    return (
        f"#{note.number}: opened by {note.author or 'an unknown account'}, not by the player ({PLAYER}) or by"
        f" the capture script ({' or '.join(CAPTURE_BOTS)} with the `{CAPTURE_LABEL}` label); it is never filed"
    )


def mismatch(body: str, playtests: dict[str, str]) -> str:
    """Where the copy stops matching: how many of the note's words a playtest file holds in order, and what follows."""
    words = body.split(" ")
    matched = 0
    while matched < len(words) and any(" ".join(words[: matched + 1]) in text for text in playtests.values()):
        matched += 1
    following = " ".join(words[matched : matched + 8])
    return (
        f"the added playtest files hold its first {matched} of {len(words)} words in order; then it reads {following!r}"
    )


def check(notes: list[Note], added_playtests: dict[str, str]) -> list[str]:
    failures: list[str] = []
    normalized = {path: lib_ci.normalize(text) for path, text in added_playtests.items()}
    for note in notes:
        failure = author_failure(note)
        if failure is not None:
            failures.append(failure)
            continue
        body = lib_ci.normalize(note.body)
        if not body:
            failures.append(f"#{note.number}: the note has no body to transcribe")
        elif not normalized:
            failures.append(f"#{note.number}: the pull request adds no file under {PLAYTESTS}/ to transcribe it into")
        elif not any(body in text for text in normalized.values()):
            names = ", ".join(sorted(normalized))
            failures.append(f"#{note.number}: its body is not in {names} word for word: {mismatch(body, normalized)}")
        else:
            for words in note.appended:
                said = lib_ci.normalize(words)
                if not any(said in text for text in normalized.values()):
                    names = ", ".join(sorted(normalized))
                    failures.append(
                        f"#{note.number}: the words appended to it are not in {names} word for word:"
                        f" {mismatch(said, normalized)}"
                    )
    return failures


def added_playtests(changes: list[Change], cwd: Path = lib_ci.ROOT) -> dict[str, str]:
    """The text of each playtest file the pull request adds, read from its blob at the head."""
    return {
        change.path: lib_ci.read_blob(change.new_blob, cwd)
        for change in changes
        if change.status == "A" and lib_ci.under(change.path, PLAYTESTS)
    }


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/ci_transcription.py",
        description=(
            "For every `Filed from #N` line in the pull request's description, read now through the API: issue N"
            f" must carry the `{INBOX_LABEL}` label and be opened by {PLAYER}, or by {' or '.join(CAPTURE_BOTS)}"
            f" with the `{CAPTURE_LABEL}` label, and"
            " its body must appear word for word (blockquote markers and line wrapping aside) in a playtest file"
            " the branch adds since BASE, and so must the words `tools/inbox.py append` added to a captured note."
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
    if number is None:
        print("tools/ci_transcription.py: no pull request given (--pr or $PR_NUMBER)", file=sys.stderr)
        return 2
    try:
        repo = args.repo or lib_ci.default_repo()
        numbers, failures = filed_numbers(lib_ci.pr_description(repo, number))
        if not numbers and not failures:
            print("OK: the description names no note (no `Filed from #N` line), so there is nothing to check")
            return 0
        playtests = added_playtests(lib_ci.changed_files(args.base, args.head))
        notes: list[Note] = []
        for issue in numbers:
            try:
                note = note_from_api(issue, lib_ci.gh_api(f"repos/{repo}/issues/{issue}"))
                if note.author in CAPTURE_BOTS and CAPTURE_LABEL in note.labels:
                    comments = lib_ci.gh_api_list(f"repos/{repo}/issues/{issue}/comments")
                    note = replace(note, appended=appended_words(note.author, note.labels, comments))
                notes.append(note)
            except lib_ci.CiError as error:
                failures.append(f"#{issue}: could not be read ({error})")
    except lib_ci.CiError as error:
        print(f"tools/ci_transcription.py: {error}", file=sys.stderr)
        return 1
    failures.extend(check(notes, playtests))
    filed = ", ".join(f"#{issue}" for issue in numbers) or "no note"
    return lib_ci.report(
        "tools/ci_transcription.py", failures, f"{filed}: the player's, and copied word for word into a playtest file"
    )


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
