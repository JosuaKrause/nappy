#!/usr/bin/env python3
"""PreToolUse hook on SendMessage: refuses, once, the resume of a sub-agent that has outgrown the limit.

A sub-agent re-reads its whole context on every turn, so one kept on through SendMessage for task
after task costs more with every step, and the choice to resume it is made one message at a time,
where reusing a warm agent always looks cheaper than briefing a fresh one. This fires on the
message itself. It spends no model tokens and looks at nothing while an agent runs.

It reads the hook payload on stdin and resolves the message's `to` to a sub-agent transcript of
this session, <session transcript without .jsonl>/subagents/agent-<id>.jsonl: by id, or by the
`name` a .meta.json beside a transcript carries. Where several carry the name, it is the agent
that started last, by the timestamp of its transcript's first entry: the harness sends a name to
the newest agent that took it, and an older one may well have written to its transcript since.
A target that resolves to none (a teammate, another session, a broadcast), a message whose `type`
is not "message" (a shutdown or another protocol message), and any other tool pass silently.

The message is refused when the target's transcript holds
  - a compaction the harness started itself (a `compact_boundary` whose compactMetadata.trigger is
    "auto"; one the player asked for is "manual" and does not count),
  - more assistant turns than the limit, counted as distinct message ids, since one turn is
    written as several lines, or
  - a latest turn whose context (input, cache-read and cache-creation tokens of the last
    assistant usage that reports any) is past the limit.

The limit has one owner, and it is not this file: the two numbers are read from the line of
.claude/skills/orchestrating/references/writing-a-brief.md ("Sizing the task") that LIMIT_LINE
matches, so the sentence the orchestrator sizes a task by is the one enforced.
tools/test_resume_guard.py fails when that line no longer parses; in a session, a line that
cannot be read, and a transcript that cannot be measured, pass the message with a note beside it
saying the resume went unchecked.

The refusal is a prompt to decide and not a ban: the same message to the same agent sent again
passes. That is how a message that only stops a runaway agent ("push what you have and report")
still gets through, and how an orchestrator who has judged the agent fine to go a bit over the
limit keeps it. The marker for a refused message is a file under $TMPDIR/claude-nappy-resume-guard/<session>/
(<session>-<agent id> when a sub-agent sends), named by a hash of the target and the text; it is
kept the way project-rules.sh keeps its own, and like that hook this one refuses only where the
marker could be written, since a refusal that cannot be remembered would refuse for good.

The hook never breaks a session: any error passes the message, goes to errors.log beside the
agent counter's data (~/.claude/nappy-agent-stats/), and the exit status is 0. A transcript can
be tens of megabytes, so it is read once, line by line, and only the lines that can matter are
parsed.

Codex support is frozen (inbox #901 in freckled-moose) and the adapter, tools/codex-hooks.py, does not carry this hook.
"""

import hashlib
import json
import os
import re
import sys
import time
from pathlib import Path

HOOKS = Path(__file__).resolve().parent
REFERENCE = HOOKS.parent / "skills" / "orchestrating" / "references" / "writing-a-brief.md"
LIMIT_LINE = re.compile(r"about ([\d,]+) turns or ([\d,]+)k tokens of context")
ERRORS = Path.home() / ".claude" / "nappy-agent-stats" / "errors.log"
CONTEXT_KEYS = ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")
SAFE_ID = re.compile(r"[A-Za-z0-9_-]+")


class LimitUnreadable(Exception):
    pass


def read_limits():
    """The limit as (assistant turns, context tokens), from the reference's own sentence."""
    try:
        found = LIMIT_LINE.search(REFERENCE.read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:  # a decode error is a ValueError
        raise LimitUnreadable(repr(e)) from e
    if not found:
        raise LimitUnreadable(f"no line of {REFERENCE} matches {LIMIT_LINE.pattern!r}")
    turns, thousands = (int(group.replace(",", "")) for group in found.groups())
    return turns, thousands * 1000


def started(transcript):
    """When the agent started: the timestamp of its transcript's first entry, "" where it has none.

    The harness writes every timestamp in one UTC form, so the strings order as the times do.
    """
    try:
        with transcript.open(encoding="utf-8", errors="replace") as lines:
            stamp = json.loads(lines.readline()).get("timestamp")
    except (OSError, ValueError, AttributeError):
        return ""
    return stamp if isinstance(stamp, str) else ""


def resolve(payload):
    """The sub-agent transcript the message goes to, or None."""
    tool_input = payload.get("tool_input")
    session = payload.get("transcript_path")
    if not isinstance(tool_input, dict) or not isinstance(session, str) or not session:
        return None
    if tool_input.get("type") not in (None, "message"):
        return None
    to = tool_input.get("to") or tool_input.get("recipient")
    if not isinstance(to, str) or not to:
        return None
    agents = Path(session).expanduser().with_suffix("") / "subagents"
    if not agents.is_dir():
        return None
    if SAFE_ID.fullmatch(to):
        by_id = agents / f"agent-{to}.jsonl"
        if by_id.is_file():
            return by_id
    named = []
    for meta in agents.glob("agent-*.meta.json"):
        try:
            data = json.loads(meta.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            continue
        transcript = meta.with_name(meta.name[: -len(".meta.json")] + ".jsonl")
        if isinstance(data, dict) and data.get("name") == to and transcript.is_file():
            named.append((started(transcript), transcript))
    return max(named)[1] if named else None


def measure(transcript):
    """(assistant turns, the latest turn's context in tokens, automatic compactions)."""
    turns, unnamed, context, compactions = set(), 0, 0, 0
    with transcript.open(encoding="utf-8", errors="replace") as lines:
        for line in lines:
            if '"assistant"' not in line and "compact_boundary" not in line:
                continue
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if not isinstance(entry, dict):
                continue
            if entry.get("subtype") == "compact_boundary":
                if (entry.get("compactMetadata") or {}).get("trigger") == "auto":
                    compactions += 1
                continue
            if entry.get("type") != "assistant":
                continue
            message = entry.get("message") or {}
            if message.get("id"):
                turns.add(message["id"])
            else:
                unnamed += 1
            usage = message.get("usage") or {}
            used = sum(usage.get(key) or 0 for key in CONTEXT_KEYS)
            if used:
                context = used
    return len(turns) + unnamed, context, compactions


def description(transcript):
    try:
        meta = json.loads(transcript.with_suffix(".meta.json").read_text(encoding="utf-8"))
        return str(meta.get("description") or "")
    except (OSError, ValueError, AttributeError):
        return ""


def marker(payload, agent, text):
    """Where the refusal of this text to this agent, by this sender, is remembered."""
    sender = str(payload.get("session_id") or "nosession")
    if payload.get("agent_id"):
        sender += f"-{payload['agent_id']}"
    sender = re.sub(r"[^A-Za-z0-9_-]", "_", sender)  # no dot: a session id of ".." names no parent folder
    name = hashlib.sha256(f"{agent}\0{text}".encode()).hexdigest()
    return Path(os.environ.get("TMPDIR") or "/tmp") / "claude-nappy-resume-guard" / sender / name


def answer(**fields):
    fields["hookEventName"] = "PreToolUse"
    print(json.dumps({"hookSpecificOutput": fields, "suppressOutput": True}))


def unchecked(why):
    answer(additionalContext=f"resume-guard.py {why}, so this resume went unchecked.")


def guard(payload):
    if not isinstance(payload, dict) or payload.get("tool_name") not in (None, "SendMessage"):
        return
    transcript = resolve(payload)
    if transcript is None:
        return
    agent = transcript.stem[len("agent-") :]
    try:
        turn_limit, context_limit = read_limits()
    except LimitUnreadable as e:
        log(e)
        unchecked(
            f"could not read the limit an agent may grow to ({e}; restore the sentence it reads, in"
            ' .claude/skills/orchestrating/references/writing-a-brief.md, "Sizing the task")'
        )
        return
    try:
        turns, context, compactions = measure(transcript)
    except Exception as e:  # an entry of a shape measure() does not expect
        log(e)
        unchecked(f"could not measure sub-agent {agent} from its transcript ({e!r})")
        return
    past = []
    if turns > turn_limit:
        past.append(f"{turns:,} turns (the limit is {turn_limit:,})")
    if context > context_limit:
        past.append(
            f"{round(context / 1000):,}k tokens of context in its latest turn (the limit is {context_limit // 1000:,}k)"
        )
    if compactions:
        past.append(f"{compactions} automatic compaction{'s' if compactions > 1 else ''} of its context")
    if not past:
        return
    tool_input = payload["tool_input"]
    text = tool_input.get("message")
    if text is None:
        text = tool_input.get("content")
    if not isinstance(text, str):
        text = json.dumps(text, sort_keys=True)
    seen = marker(payload, agent, text)
    if seen.exists():
        return
    about = description(transcript)
    who = f"sub-agent {agent}" + (f' ("{about}")' if about else "")
    reason = (
        f"{who} has outgrown the limit for a resume: {'; '.join(past)}.\n"
        "The rule is orchestrating's, that an agent stays on one task and no agent grows huge"
        ' (.claude/skills/orchestrating/SKILL.md, "What the orchestrator keeps"); where the limit falls is in'
        ' .claude/skills/orchestrating/references/writing-a-brief.md, "Sizing the task".\n'
        "Follow-up work goes to a fresh agent, briefed from the brief file under .claude/briefs/ and what this"
        " agent left: its branch, its pull request and its last report.\n"
    )
    # Only a refusal asks for the message again: on the path below it has already gone through.
    resend = (
        "This is a prompt to decide, not a ban. Send this same message again, and the resend passes, when it"
        " only stops or wraps the agent up, or when you judge the agent fine to go a bit over; an agent grown"
        " far past that is reassessed first, as the rule says (its model, stuck, looping), and work never moves"
        " to another model by a resume, only by a new brief."
    )
    try:
        seen.parent.mkdir(parents=True, exist_ok=True)
        seen.write_text(time.strftime("%Y-%m-%dT%H:%M:%S\n"))
    except OSError:
        answer(
            additionalContext=f"Not refused, since the refusal could not be remembered: {reason}"
            "The message has gone through: do not send it again."
        )
        return
    answer(permissionDecision="deny", permissionDecisionReason=f"Refused once: {reason}{resend}")


def log(error):
    try:
        ERRORS.parent.mkdir(parents=True, exist_ok=True)
        with ERRORS.open("a") as f:
            f.write(f"{time.ctime()} resume-guard: {error!r}\n")
    except Exception:  # the log is never worth a session either
        pass


def main():
    try:
        guard(json.loads(sys.stdin.read() or "{}"))
    except Exception as e:  # never break the session
        log(e)
    sys.exit(0)


if __name__ == "__main__":
    main()
