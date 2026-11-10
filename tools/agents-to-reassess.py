#!/usr/bin/env python3
"""Says which sub-agents of a session to reassess, from their transcripts alone.

One line per sub-agent: its id, model, context size, turns and the minutes since its transcript
was last written, then why to reassess it. Reassessing asks whether the model suits the work or
whether the agent is stuck or in a loop (inbox #1298); nothing here stops, resumes or messages an
agent, and work that moves to another model starts from a new brief, never the old context.

It reads ~/.claude/projects/<project>/<session>/subagents/agent-<id>.jsonl, where <project> is the
main checkout's path with every character that is no letter or digit turned into "-". The default
session is the one whose sub-agent transcripts were written most recently.

What is measured, per transcript:
  context   input + cache-read + cache-creation tokens of the last assistant usage reporting any
  turns     requests to the model: distinct assistant message ids, one turn being several lines
  idle      minutes since the file was last written
  state     finished: the last assistant message ended its turn or handed its report back
            (SubagentHandback), and no new prompt came after it.
            stopped: the transcript's last word is the harness's interrupt marker, a user entry
            reading "[Request interrupted by user]" or "[Request interrupted by user for tool
            use]", which is what stopping an agent writes; a later prompt or assistant message
            means it was resumed.
            running: anything else. A harness notice (isMeta) is no prompt and changes nothing.

Which agents are printed: the running ones, and a finished or stopped one written in the last
--recent minutes. --all prints every agent; --quiet keeps only the lines that carry a flag or a
note.

What a transcript cannot say: an agent whose session was cut off in the middle of a call leaves
no marker, so it shows as running and is flagged quiet until another session is the one looked at.

Reassess flags:
  size            context at or past 500k tokens (inbox #1298)
  auto-compacted  the harness compacted the context itself (a compact_boundary whose trigger
                  is "auto"; one asked for by hand does not count)
  quiet           running and no write for 45 minutes, the interval at which the
                  orchestrating skill has a running agent looked at
  looping         one tool call, same tool and same input, made 5 or more times within the
                  agent's last 20 tool calls. The same call made several times in parallel in
                  one turn counts once, since a loop is a repeat from turn to turn. The window
                  and the count are this tool's own
                  choice, nobody's rule: wide enough to catch a repeat with other calls between,
                  high enough that reading a status three times is not a loop.

Note, informational and below the reassess line:
  past-guide      more turns or more context than the limit in "Sizing the task" of
                  .claude/skills/orchestrating/references/writing-a-brief.md, read from that
                  file's own sentence; this tool exits 2 if the sentence can no longer be read.

Read-only and offline. Of a message it reads the model, the usage, the stop reason and each tool
call's name and input (the input only to compare calls, never printed); no other content.

Exit status: 0 for any report, flags or none; 2 for a bad argument, a session or project folder
that is not there, or an unreadable limit.

  uv run python tools/agents-to-reassess.py
  uv run python tools/agents-to-reassess.py --session c021c586 --all
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
import time
from collections import Counter, deque
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / ".claude" / "skills" / "orchestrating" / "references" / "writing-a-brief.md"
# The sentence of "Sizing the task" that owns the limit; the numbers are written nowhere else.
LIMIT_LINE = re.compile(r"about ([\d,]+) turns or ([\d,]+)k tokens of context")

REASSESS_CONTEXT = 500_000  # the player's number (inbox #1298)
QUIET_MINUTES = 45  # orchestrating, "What the orchestrator keeps": a wait is checked every 45 minutes
LOOP_WINDOW = 20  # this tool's choice: the last tool calls looked at
LOOP_COUNT = 5  # this tool's choice: identical calls in the window that make a loop
RECENT_MINUTES = 10  # the default of --recent

# What the harness writes as a user entry when an agent is stopped.
INTERRUPT_MARKERS = ("[Request interrupted by user]", "[Request interrupted by user for tool use]")
RUNNING, FINISHED, STOPPED = "running", "finished", "stopped"

CONTEXT_KEYS = ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")
HANDBACK = "SubagentHandback"


class ReassessError(Exception):
    """Something the report cannot be made without; main() prints it and exits 2."""


@dataclass(frozen=True)
class Limits:
    turns: int
    context: int


@dataclass
class Measure:
    """What one transcript says about its agent."""

    turns: int = 0
    context: int = 0
    model: str = "?"
    auto_compactions: int = 0
    state: str = RUNNING
    recent_calls: deque[tuple[str, str]] = field(default_factory=lambda: deque(maxlen=LOOP_WINDOW))

    def loop(self) -> tuple[str, int] | None:
        """The tool repeated most in the window and how often, when that makes a loop."""
        if not self.recent_calls:
            return None
        (name, _), count = Counter(self.recent_calls).most_common(1)[0]
        return (name, count) if count >= LOOP_COUNT else None


def read_limits(reference: Path = REFERENCE) -> Limits:
    """The brief guide's limit, from the reference's own sentence."""
    try:
        found = LIMIT_LINE.search(reference.read_text())
    except OSError as e:
        raise ReassessError(f"cannot read the limit: {e}") from e
    if not found:
        raise ReassessError(
            f"no line of {reference} matches {LIMIT_LINE.pattern!r}: "
            "the limit's sentence changed, so LIMIT_LINE in this tool changes with it"
        )
    turns, thousands = (int(group.replace(",", "")) for group in found.groups())
    return Limits(turns=turns, context=thousands * 1000)


def _is_prompt(message: dict[str, Any]) -> bool:
    """Whether a user entry is a new prompt and not the result of a tool call."""
    content = message.get("content")
    if not isinstance(content, list):
        return True
    return not any(isinstance(block, dict) and block.get("type") == "tool_result" for block in content)


def _is_interrupt(message: dict[str, Any]) -> bool:
    """Whether a user entry is the harness's marker of a stopped agent: one text block, or a string."""
    content = message.get("content")
    if isinstance(content, list) and len(content) == 1 and isinstance(content[0], dict):
        content = content[0].get("text") if content[0].get("type") == "text" else None
    return isinstance(content, str) and content.strip() in INTERRUPT_MARKERS


def measure(transcript: Path) -> Measure:
    """Reads one transcript once, line by line, since one can be tens of megabytes."""
    result = Measure()
    turn_ids: set[str] = set()
    call_ids: set[str] = set()
    calls_of_turn: set[tuple[str, str, str]] = set()
    unnamed_turns = 0
    with transcript.open(errors="replace") as lines:
        for line in lines:
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if not isinstance(entry, dict):
                continue
            if entry.get("subtype") == "compact_boundary":
                if (entry.get("compactMetadata") or {}).get("trigger") == "auto":
                    result.auto_compactions += 1
                continue
            message = entry.get("message")
            if not isinstance(message, dict):
                continue
            if entry.get("type") == "user":
                if entry.get("isMeta"):
                    continue
                if _is_interrupt(message):
                    result.state = STOPPED
                elif _is_prompt(message):
                    result.state = RUNNING
                continue
            if entry.get("type") != "assistant":
                continue
            if message.get("id"):
                turn_ids.add(str(message["id"]))
            else:
                unnamed_turns += 1
            model = message.get("model")
            if isinstance(model, str) and model and not model.startswith("<"):
                result.model = model
            usage = message.get("usage") or {}
            used = sum(int(usage.get(key) or 0) for key in CONTEXT_KEYS)
            if used:
                result.context = used
            handed_back = False
            content = message.get("content")
            for block in content if isinstance(content, list) else []:
                if not isinstance(block, dict) or block.get("type") != "tool_use":
                    continue
                name = str(block.get("name") or "?")
                handed_back = handed_back or name == HANDBACK
                call_id = block.get("id")
                if isinstance(call_id, str) and call_id:
                    if call_id in call_ids:
                        continue
                    call_ids.add(call_id)
                canonical = json.dumps(block.get("input"), sort_keys=True, default=str)
                digest = hashlib.sha256(canonical.encode()).hexdigest()
                if message.get("id"):
                    in_turn = (str(message["id"]), name, digest)
                    if in_turn in calls_of_turn:
                        continue
                    calls_of_turn.add(in_turn)
                result.recent_calls.append((name, digest))
            stop = message.get("stop_reason")
            if handed_back or (isinstance(stop, str) and stop != "tool_use"):
                result.state = FINISHED
            elif stop == "tool_use" or result.state == STOPPED:
                result.state = RUNNING
    result.turns = len(turn_ids) + unnamed_turns
    return result


def thousands(tokens: int) -> str:
    return f"{tokens // 1000}k"


def reasons(found: Measure, idle_minutes: int, limits: Limits) -> tuple[list[str], list[str]]:
    """(the reassess flags, the informational notes) of one agent."""
    reassess: list[str] = []
    if found.context >= REASSESS_CONTEXT:
        reassess.append(f"size ({thousands(found.context)} >= {thousands(REASSESS_CONTEXT)})")
    if found.auto_compactions:
        reassess.append(f"auto-compacted (x{found.auto_compactions})")
    if found.state == RUNNING and idle_minutes >= QUIET_MINUTES:
        reassess.append(f"quiet ({idle_minutes}m >= {QUIET_MINUTES}m, not finished)")
    loop = found.loop()
    if loop:
        reassess.append(f"looping ({loop[0]} x{loop[1]} in the last {len(found.recent_calls)} calls)")
    notes: list[str] = []
    over: list[str] = []
    if found.turns > limits.turns:
        over.append(f"{found.turns} > {limits.turns} turns")
    if found.context > limits.context:
        over.append(f"{thousands(found.context)} > {thousands(limits.context)}")
    if over:
        notes.append(f"past-guide ({', '.join(over)})")
    return reassess, notes


def default_project_dir() -> Path:
    """Claude Code's folder for the main checkout, which a linked worktree's sessions share."""
    checkout = ROOT
    try:
        common = subprocess.run(
            ["git", "-C", str(ROOT), "rev-parse", "--path-format=absolute", "--git-common-dir"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
        if common:
            checkout = Path(common).parent
    except OSError, subprocess.CalledProcessError:
        pass
    return Path.home() / ".claude" / "projects" / re.sub(r"[^A-Za-z0-9]", "-", str(checkout))


def transcripts_of(session_dir: Path) -> list[Path]:
    return sorted((session_dir / "subagents").glob("agent-*.jsonl"))


def find_session(project_dir: Path, session: str | None) -> Path:
    """The session's folder: the one named, by id or an unambiguous prefix, or the newest."""
    if not project_dir.is_dir():
        raise ReassessError("no Claude Code project folder for this checkout; name one with --project-dir")
    sessions = [path for path in project_dir.iterdir() if (path / "subagents").is_dir()]
    if session is not None:
        matches = [path for path in sessions if path.name.startswith(session)]
        if len(matches) != 1:
            what = "no session with sub-agents" if not matches else f"{len(matches)} sessions"
            raise ReassessError(f"{what} matching --session {session}")
        return matches[0]
    newest: tuple[float, Path] | None = None
    for path in sessions:
        written = max((t.stat().st_mtime for t in transcripts_of(path)), default=None)
        if written is not None and (newest is None or written > newest[0]):
            newest = (written, path)
    if newest is None:
        raise ReassessError("no session of this project has a sub-agent transcript")
    return newest[1]


def report(session_dir: Path, limits: Limits, *, show_all: bool, only_flagged: bool, recent: int) -> list[str]:
    now = time.time()
    rows: list[tuple[str, ...]] = []
    transcripts = transcripts_of(session_dir)
    flagged = 0
    for transcript in transcripts:
        idle = max(0, int((now - transcript.stat().st_mtime) // 60))
        found = measure(transcript)
        if not show_all and found.state != RUNNING and idle >= recent:
            continue
        reassess, notes = reasons(found, idle, limits)
        flagged += bool(reassess)
        if only_flagged and not reassess and not notes:
            continue
        why = "; ".join([*(["REASSESS: " + ", ".join(reassess)] if reassess else []), *(f"note: {n}" for n in notes)])
        agent = transcript.stem.removeprefix("agent-")
        cells = (agent, found.model, thousands(found.context), str(found.turns), f"{idle}m", found.state, why or "-")
        rows.append(cells)
    header = ("agent", "model", "context", "turns", "idle", "state", "reassess")
    widths = [max(len(row[i]) for row in [header, *rows]) for i in range(len(header) - 1)]
    out = [f"session {session_dir.name}: {len(transcripts)} sub-agents, {len(rows)} shown, {flagged} to reassess"]
    if rows:
        for row in [header, *rows]:
            out.append("  ".join([*(cell.ljust(width) for cell, width in zip(row, widths, strict=False)), row[-1]]))
    return out


def minutes(text: str) -> int:
    value = int(text)
    if value < 0:
        raise argparse.ArgumentTypeError("minutes cannot be negative")
    return value


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="agents-to-reassess.py", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("--session", metavar="ID", help="a session id or its unambiguous start; default: the newest")
    p.add_argument("--all", action="store_true", help="every sub-agent of the session, finished ones included")
    p.add_argument("--quiet", action="store_true", help="only the agents with a reassess flag or a note")
    p.add_argument(
        "--recent",
        type=minutes,
        default=RECENT_MINUTES,
        metavar="MINUTES",
        help=f"a finished agent written within this many minutes still counts as running (default {RECENT_MINUTES})",
    )
    p.add_argument(
        "--project-dir",
        type=Path,
        metavar="DIR",
        help="the folder holding the sessions; default: Claude Code's folder for the main checkout",
    )
    return p


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        limits = read_limits()
        session_dir = find_session(args.project_dir or default_project_dir(), args.session)
        lines = report(session_dir, limits, show_all=args.all, only_flagged=args.quiet, recent=args.recent)
    except ReassessError as e:
        print(f"agents-to-reassess.py: {e}", file=sys.stderr)
        return 2
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
