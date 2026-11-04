#!/usr/bin/env python3
"""SubagentStop hook: append one line per finished sub-agent to ~/.claude/nappy-agent-stats/runs.jsonl.

Reads the hook payload on stdin, finds the agent's transcript (the payload's agent_transcript_path;
failing that <session transcript without .jsonl>/subagents/agent-<id>.jsonl) and its .meta.json, and
records the time, agent id, description, model alias and id, agent type, effort, the largest
context of any turn (tokens) and the tool-call count, plus the payload's own keys. The payload
carries agent_id, agent_transcript_path, agent_type, background_tasks, cwd, effort, hook_event_name,
permission_mode, prompt_id, session_crons, session_id, stop_hook_active and transcript_path. Tokens
are the largest per-turn context, which can differ slightly from the harness's own count. tools/agent-stats.py joins these
lines by agent id when the orchestrator grades the agent.

The data stays outside the repository. The hook never fails or slows a session: any error goes to
errors.log beside the data and the exit status is 0 (the timeout is in .claude/settings.json).

Codex support is frozen (inbox #901 in freckled-moose) and the adapter, tools/codex-hooks.py, does not carry this hook.
"""

import json
import sys
import time
from pathlib import Path

DATA = Path.home() / ".claude" / "nappy-agent-stats"
USAGE_KEYS = ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens", "output_tokens")


def find_transcript(payload):
    for key in ("agent_transcript_path", "agentTranscriptPath"):
        if payload.get(key):
            return Path(payload[key]).expanduser()
    agent = payload.get("agent_id") or payload.get("agentId")
    session = payload.get("transcript_path")
    if agent and session:
        return Path(session).expanduser().with_suffix("") / "subagents" / f"agent-{agent}.jsonl"
    return None


def record(payload):
    row = {"ts": time.strftime("%Y-%m-%dT%H:%M:%S"), "payload_keys": sorted(payload)}
    for key in ("agent_id", "agentId", "agent_type", "effort", "session_id", "cwd"):
        if key in payload:
            row[key] = payload[key]
    path = find_transcript(payload)
    if path and path.exists():
        row["agent"] = path.stem.removeprefix("agent-")
        meta = path.with_suffix(".meta.json")
        if meta.exists():
            try:
                m = json.loads(meta.read_text())
                row.update({k: m.get(k) for k in ("description", "model", "agentType")})
            except (OSError, ValueError, AttributeError):
                row["meta_error"] = True
        tokens, tools, model_id = 0, 0, None
        for line in path.read_text().splitlines():
            try:
                d = json.loads(line)
            except ValueError:
                continue
            if d.get("type") != "assistant":
                continue
            msg = d.get("message") or {}
            usage = msg.get("usage") or {}
            tokens = max(tokens, sum(usage.get(k, 0) or 0 for k in USAGE_KEYS))
            model_id = msg.get("model") or model_id
            tools += sum(1 for c in msg.get("content") or [] if isinstance(c, dict) and c.get("type") == "tool_use")
        row.update({"tokens": tokens, "tools": tools, "model_id": model_id})
    else:
        row["transcript"] = str(path) if path else None
    DATA.mkdir(parents=True, exist_ok=True)
    with (DATA / "runs.jsonl").open("a") as f:
        f.write(json.dumps(row) + "\n")


def main():
    try:
        record(json.loads(sys.stdin.read() or "{}"))
    except Exception as e:  # never break the session
        try:
            DATA.mkdir(parents=True, exist_ok=True)
            with (DATA / "errors.log").open("a") as f:
                f.write(f"{time.ctime()} {e!r}\n")
        except Exception:
            pass
    sys.exit(0)


if __name__ == "__main__":
    main()
