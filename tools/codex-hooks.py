#!/usr/bin/env python3
"""Adapt Codex lifecycle/tool payloads to the shared Claude hooks."""

import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Optional

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / ".claude/skills"


def main() -> None:
    # Codex's own hooks.json invokes this with no arguments, piping one hook-event JSON payload
    # to stdin (see .codex/hooks.json). Checked before touching stdin at all: reading it first and
    # only then discovering an unknown flag would print an error after hanging on a payload nobody
    # sent -- the exact "help doesn't work, it just starts something that becomes unresponsive"
    # failure the cli-tools skill exists to rule out, one file over.
    if len(sys.argv) > 1:
        if sys.argv[1] in ("--help", "-h"):
            print("usage: codex-hooks.py")
            print()
            print(__doc__)
            print()
            print("Reads one Codex hook-event JSON payload from stdin and translates it to the")
            print("shared Claude hooks under .claude/hooks/, printing any additionalContext JSON")
            print("Codex should inject. Takes no arguments; .codex/hooks.json invokes it with none.")
            return
        print(
            f"usage: codex-hooks.py -- takes no arguments, got: {' '.join(sys.argv[1:])}",
            file=sys.stderr,
        )
        raise SystemExit(2)
    event: dict[str, Any] = json.load(sys.stdin)
    kind = event["hook_event_name"]
    # Separate agents, repositories/worktrees and Claude's markers. Never use raw
    # session input as a filesystem path.
    identity = json.dumps([str(ROOT), event.get("session_id"), event.get("transcript_path"), event.get("agent_id")])
    session = "codex-" + hashlib.sha256(identity.encode()).hexdigest()
    state = Path(os.environ.get("TMPDIR") or "/tmp") / "claude-nappy-rules" / session
    state.mkdir(parents=True, exist_ok=True)
    context: list[str] = []

    def run_hook(name: str, tool: str = "", path: Optional[Path] = None) -> None:
        payload = dict(event, session_id=session, tool_name=tool, tool_input={"file_path": str(path)} if path else {})
        result = subprocess.run(
            ["bash", str(ROOT / ".claude/hooks" / name)],
            input=json.dumps(payload),
            text=True,
            capture_output=True,
            check=True,
        )
        if result.stdout.strip():
            output = json.loads(result.stdout)
            text = output.get("hookSpecificOutput", {}).get("additionalContext")
            if text:
                context.append(text)

    if kind in ("SessionStart", "SubagentStart"):
        # Resumed/compacted contexts must receive the rules again, even if the
        # session id is unchanged. SubagentStart supplies its own agent_id.
        for skill in SKILLS.glob("*/SKILL.md"):
            (state / skill.parent.name).unlink(missing_ok=True)
        (state / "shell-reminder").unlink(missing_ok=True)
        run_hook("session-rules.sh")
    else:
        tool = event.get("tool_name", "")
        args = event.get("tool_input") or {}
        if not isinstance(args, dict):
            args = {"command": args}
        if kind == "PreToolUse" and tool in ("spawn_agent", "Agent", "Task"):
            run_hook("project-rules.sh", "Agent")
        elif tool in ("Bash", "exec_command", "shell", "shell_command"):
            if kind == "PreToolUse":
                # Arbitrary scripts can compute their paths. Preserve selective
                # loading instead of dumping all skills on a read-only command.
                marker = state / "shell-reminder"
                if not marker.exists():
                    context.append(
                        "Use apply_patch for ordinary edits so path rules load automatically. "
                        "Before a structural shell/script edit, read every applicable skill "
                        "from CLAUDE.md's path table. Before git mutations, load committing. "
                        "Shell command text cannot reliably identify the files it will change."
                    )
                    marker.touch()
        else:
            paths = []
            if tool == "apply_patch":
                patch = args.get("command", args.get("input", ""))
                paths = re.findall(r"^\*\*\* (?:Add File|Update File|Delete File|Move to): (.+)$", patch, re.MULTILINE)
            elif args.get("file_path"):
                paths = [args["file_path"]]
            cwd = Path(event.get("cwd") or ROOT)
            for name in dict.fromkeys(paths):
                path = (cwd / name).resolve()
                if not path.is_relative_to(ROOT):
                    continue
                if kind == "PreToolUse":
                    run_hook("project-rules.sh", "Edit", path)
                elif kind == "PostToolUse" and path.is_file():
                    run_hook("lint-docs.sh", "Edit", path)

    if context:
        # Codex accepts additionalContext, but rejects Claude's suppressOutput.
        print(json.dumps({"hookSpecificOutput": {"hookEventName": kind, "additionalContext": "\n\n".join(context)}}))


if __name__ == "__main__":
    main()
