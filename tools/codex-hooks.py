#!/usr/bin/env python3
"""Adapt Codex lifecycle/tool payloads to the shared Claude hooks."""

import contextlib
import hashlib
import json
import os
import re
import signal
import subprocess
import sys
import time
from pathlib import Path
from typing import Any, Optional

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / ".claude/skills"

# Codex gives this hook 10 seconds (.codex/hooks.json) and lets the call through when it runs out,
# so the two guards a shell command goes through share a budget that ends short of that, leaving
# the rest for the interpreter's own start and the reply. A guard still running when it ends is
# killed, and the command is denied: a command the guards could not read in time is exactly the
# one a timed-out hook would let through unread. Any other way a guard can fail -- a non-zero
# exit, a reply that is not JSON, an error starting or killing it -- denies the same way, since an
# adapter that crashes exits non-zero and Codex lets that call through too.
GUARD_BUDGET_SECONDS = 8.0


def guard_deny(reason: str) -> dict[str, Any]:
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def run_guard(script: Path, payload: str, deadline: float) -> Optional[dict[str, Any]]:
    """Run one guard hook; its parsed reply, None for an allow, or a deny when it cannot answer.

    The guard runs in a session of its own so that a timeout kills its jq too: jq holds the
    guard's stdout open, so killing bash alone would leave the read waiting for jq to finish.
    """
    try:
        remaining = deadline - time.monotonic()
        if remaining > 0:
            proc = subprocess.Popen(
                ["bash", str(script)],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                start_new_session=True,
            )
            try:
                stdout, stderr = proc.communicate(payload, timeout=remaining)
            except subprocess.TimeoutExpired:
                # The group may already be gone, or hold only an unreaped zombie, which macOS
                # answers with EPERM rather than ESRCH; the deny below stands either way.
                with contextlib.suppress(OSError):
                    os.killpg(proc.pid, signal.SIGKILL)
                proc.communicate()
            else:
                if proc.returncode != 0:
                    raise subprocess.CalledProcessError(proc.returncode, proc.args, stdout, stderr)
                if not stdout.strip():
                    return None
                output: dict[str, Any] = json.loads(stdout)
                return output
    except Exception as error:
        return guard_deny(
            f"{script.name} failed ({type(error).__name__}: {error}), so this command is denied unread "
            "rather than let through."
        )
    return guard_deny(
        f"{script.name} did not finish inside the shell guards' {GUARD_BUDGET_SECONDS:.0f}-second share "
        "of Codex's 10-second hook timeout, so this command is denied unread rather than let through. "
        "Write any long text to a file first and pass the file, then run a short command."
    )


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
    started = time.monotonic()
    event: dict[str, Any] = json.load(sys.stdin)
    kind = event["hook_event_name"]
    # Separate agents, repositories/worktrees and Claude's markers. Never use raw
    # session input as a filesystem path.
    identity = json.dumps([str(ROOT), event.get("session_id"), event.get("transcript_path"), event.get("agent_id")])
    session = "codex-" + hashlib.sha256(identity.encode()).hexdigest()
    state = Path(os.environ.get("TMPDIR") or "/tmp") / "claude-nappy-rules" / session
    state.mkdir(parents=True, exist_ok=True)
    context: list[str] = []

    def run_hook(
        name: str, tool: str = "", path: Optional[Path] = None, extra_input: Optional[dict[str, Any]] = None
    ) -> Optional[dict[str, Any]]:
        if extra_input is not None:
            tool_input = extra_input
        elif path:
            tool_input = {"file_path": str(path)}
        else:
            tool_input = {}
        payload = dict(event, session_id=session, tool_name=tool, tool_input=tool_input)
        result = subprocess.run(
            ["bash", str(ROOT / ".claude/hooks" / name)],
            input=json.dumps(payload),
            text=True,
            capture_output=True,
            check=True,
        )
        if not result.stdout.strip():
            return None
        output: dict[str, Any] = json.loads(result.stdout)
        text = output.get("hookSpecificOutput", {}).get("additionalContext")
        if text:
            context.append(text)
        return output

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
                # The same two guards Claude Code runs on every Bash call: a git grep with
                # neither -I nor a text-only pathspec can grow without bound (see
                # .claude/hooks/git-grep-guard.sh's own header), and a git push/commit, a
                # GitHub-writing gh call, or a tools/ script that pushes or posts, run outside
                # tools/agent-identity.py run <role> -- ... (see .claude/hooks/github-write-guard.sh's
                # own header) -- Codex's coding and review agents are bound by the same
                # committing/pr-review mandate as Claude Code's. Checked before the
                # shell-reminder below, and on a deny nothing else about this call is
                # printed -- Codex accepts the same permissionDecision JSON Claude Code does.
                # Both guards share GUARD_BUDGET_SECONDS, counted from this call's start; the
                # one running when it ends is killed and the command denied (see run_guard).
                # Codex reports every shell call as `Bash` with `tool_input.command`, a string
                # (measured with Codex CLI 0.157.1). An argument list (["bash", "-lc", "..."])
                # is passed on too, and each guard joins it with spaces, so an unexpected shape
                # is checked rather than skipped. `cmd` is read when `command` is absent only as
                # a fail-safe: it is the argument name of the tool the model calls, and no
                # Codex hook payload has been seen to carry it.
                command = args.get("command") or args.get("cmd")
                if isinstance(command, (str, list)) and command:
                    payload = json.dumps(
                        dict(event, session_id=session, tool_name="Bash", tool_input={"command": command})
                    )
                    deadline = started + GUARD_BUDGET_SECONDS
                    for guard_script in ("git-grep-guard.sh", "github-write-guard.sh"):
                        guard = run_guard(ROOT / ".claude/hooks" / guard_script, payload, deadline)
                        if guard and guard.get("hookSpecificOutput", {}).get("permissionDecision") == "deny":
                            print(json.dumps(guard))
                            return
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
