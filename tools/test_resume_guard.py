""".claude/hooks/resume-guard.py against synthetic transcripts, under a scratch HOME and TMPDIR.

The hook runs as the harness runs it: a process fed the hook payload on stdin, its answer read from
stdout. The limit is never written here: `LIMITS` is what the hook itself reads out of
.claude/skills/orchestrating/references/writing-a-brief.md, so the first test fails when that
sentence stops parsing, and every other case is built at the limit and one past it.
"""

import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
HOOK = ROOT / ".claude/hooks/resume-guard.py"
SKILL = ".claude/skills/orchestrating/SKILL.md"
REFERENCE = ".claude/skills/orchestrating/references/writing-a-brief.md"
AGENT = "a0123456789abcdef"
OTHER = "b0123456789abcdef"


def read_limits() -> tuple[int, int]:
    spec = importlib.util.spec_from_file_location("resume_guard", HOOK)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    turn_limit, context_limit = module.read_limits()
    return int(turn_limit), int(context_limit)


LIMITS = read_limits()


def turn(message_id: str, context: int) -> str:
    """One line of an assistant turn whose context is `context` tokens, split over the three keys."""
    usage = {
        "input_tokens": 2,
        "cache_creation_input_tokens": 100,
        "cache_read_input_tokens": context - 102,
        "output_tokens": 999_999,
    }
    return json.dumps({"type": "assistant", "message": {"id": message_id, "usage": usage, "content": []}})


def turns(count: int, context: int = 1000) -> list[str]:
    return [turn(f"msg_{i}", context) for i in range(count)]


def compaction(trigger: str) -> str:
    return json.dumps({"type": "system", "subtype": "compact_boundary", "compactMetadata": {"trigger": trigger}})


class ResumeGuardTests(unittest.TestCase):
    def setUp(self) -> None:
        scratch = tempfile.TemporaryDirectory(prefix="resume-guard-test-")
        self.addCleanup(scratch.cleanup)
        self.home = Path(scratch.name).resolve()
        self.state = self.home / "tmp"
        self.state.mkdir()
        self.session = self.home / "proj" / "sess.jsonl"
        self.agents = self.session.with_suffix("") / "subagents"
        self.agents.mkdir(parents=True)
        self.errors = self.home / ".claude" / "nappy-agent-stats" / "errors.log"

    def transcript(self, lines: list[str], agent: str = AGENT, **meta: Any) -> None:
        (self.agents / f"agent-{agent}.jsonl").write_text("\n".join(lines) + "\n")
        meta.setdefault("description", "Build the thing")
        (self.agents / f"agent-{agent}.meta.json").write_text(json.dumps(meta))

    def payload(self, to: str = AGENT, message: str = "One more task for you.", **extra: Any) -> str:
        tool_input = {"to": to, "summary": "s", "message": message, "type": "message", "recipient": to}
        base = {"tool_name": "SendMessage", "session_id": "sess", "transcript_path": str(self.session)}
        return json.dumps({**base, "tool_input": tool_input, **extra})

    def run_hook(self, stdin: str, hook: Path = HOOK) -> dict[str, Any]:
        """The hook's answer, {} for none. It exits 0 and prints no error whatever it was given."""
        env = dict(os.environ, HOME=str(self.home), TMPDIR=str(self.state))
        result = subprocess.run(
            [sys.executable, str(hook)], input=stdin, text=True, capture_output=True, env=env, check=False
        )
        self.assertEqual((result.returncode, result.stderr), (0, ""))
        if not result.stdout.strip():
            return {}
        answer = json.loads(result.stdout)
        self.assertEqual(answer["hookSpecificOutput"]["hookEventName"], "PreToolUse")
        return dict(answer["hookSpecificOutput"])

    def refusal(self, stdin: str, hook: Path = HOOK) -> str:
        answer = self.run_hook(stdin, hook)
        self.assertEqual(answer.get("permissionDecision"), "deny", answer)
        return str(answer["permissionDecisionReason"])

    def assert_passes(self, stdin: str) -> None:
        self.assertEqual(self.run_hook(stdin), {})

    def test_the_settings_run_the_hook_before_every_send_message(self) -> None:
        settings = json.loads((ROOT / ".claude/settings.json").read_text())
        commands = [
            hook["command"]
            for entry in settings["hooks"]["PreToolUse"]
            if entry["matcher"] == "SendMessage"
            for hook in entry["hooks"]
        ]
        self.assertEqual(commands, ['python3 "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/resume-guard.py"'])
        self.assertTrue(os.access(HOOK, os.X_OK))

    def test_the_limit_is_read_from_the_reference(self) -> None:
        turn_limit, context_limit = LIMITS
        self.assertGreater(turn_limit, 0)
        self.assertGreater(context_limit, 1000)

    def test_an_agent_at_the_limit_passes(self) -> None:
        turn_limit, context_limit = LIMITS
        self.transcript([*turns(turn_limit - 1), turn("last", context_limit)])
        self.assert_passes(self.payload())
        self.assertFalse(self.errors.exists())

    def test_an_agent_past_the_turn_limit_is_refused(self) -> None:
        turn_limit, _ = LIMITS
        self.transcript(turns(turn_limit + 1))
        reason = self.refusal(self.payload())
        self.assertIn(f"{turn_limit + 1:,} turns (the limit is {turn_limit:,})", reason)
        self.assertIn(f'sub-agent {AGENT} ("Build the thing")', reason)
        self.assertNotIn("tokens of context", reason)
        self.assertNotIn("compaction", reason)

    def test_a_turn_written_as_several_lines_counts_once(self) -> None:
        turn_limit, _ = LIMITS
        lines = turns(turn_limit)
        self.transcript([*lines, *lines, "not json", json.dumps({"type": "user", "message": {"content": "x"}})])
        self.assert_passes(self.payload())

    def test_an_agent_whose_latest_turn_is_past_the_context_limit_is_refused(self) -> None:
        _, context_limit = LIMITS
        self.transcript([*turns(3), turn("last", context_limit + 1000)])
        reason = self.refusal(self.payload())
        thousands = context_limit // 1000
        self.assertIn(f"{thousands + 1:,}k tokens of context in its latest turn (the limit is {thousands:,}k)", reason)
        self.assertNotIn("turns (the limit", reason)

    def test_the_context_is_the_latest_turns_and_not_the_largest(self) -> None:
        _, context_limit = LIMITS
        no_usage = json.dumps({"type": "assistant", "message": {"id": "error", "usage": {"input_tokens": 0}}})
        self.transcript([turn("big", context_limit * 2), compaction("manual"), turn("small", 5000), no_usage])
        self.assert_passes(self.payload())

    def test_an_automatic_compaction_is_refused(self) -> None:
        self.transcript([*turns(3), compaction("auto"), turn("after", 5000)])
        reason = self.refusal(self.payload())
        self.assertIn("1 automatic compaction of its context", reason)
        self.assertNotIn("the limit is", reason)

    def test_a_manual_compaction_alone_passes(self) -> None:
        self.transcript([*turns(3), compaction("manual"), turn("after", 5000)])
        self.assert_passes(self.payload())

    def test_the_refusal_says_where_the_rule_lives_and_what_to_do(self) -> None:
        self.transcript([compaction("auto")])
        reason = self.refusal(self.payload())
        self.assertTrue(reason.startswith("Refused once"))
        for path, section in ((SKILL, "What the orchestrator keeps"), (REFERENCE, "Sizing the task")):
            self.assertIn(f'{path}, "{section}"', reason)
            self.assertIn(f"\n## {section}\n", (ROOT / path).read_text())
        for words in ("fresh agent", ".claude/briefs/", "stop or wrap-up instruction", "the resend passes"):
            self.assertIn(words, reason)

    def test_the_same_message_sent_again_passes(self) -> None:
        self.transcript([compaction("auto")])
        stop = self.payload(message="Push what you have and report.")
        self.refusal(stop)
        self.assert_passes(stop)
        self.assert_passes(stop)

    def test_another_message_agent_or_sender_is_refused_on_its_own(self) -> None:
        self.transcript([compaction("auto")])
        self.transcript([compaction("auto")], agent=OTHER)
        self.refusal(self.payload(message="first"))
        self.refusal(self.payload(message="second"))
        self.refusal(self.payload(to=OTHER, message="first"))
        self.refusal(self.payload(message="first", agent_id="c0123456789abcdef"))
        self.assert_passes(self.payload(message="first"))

    def test_a_refusal_that_cannot_be_remembered_passes_with_a_note(self) -> None:
        self.transcript([compaction("auto")])
        (self.state / "claude-nappy-resume-guard").write_text("a file where the state directory goes")
        for _ in range(2):
            answer = self.run_hook(self.payload())
            self.assertNotIn("permissionDecision", answer)
            self.assertIn("1 automatic compaction", answer["additionalContext"])

    def test_a_target_named_in_its_meta_file_is_resolved(self) -> None:
        self.transcript(turns(2), agent=OTHER, name="reviewer")
        self.transcript([compaction("auto")], name="builder")
        self.assertIn(f"sub-agent {AGENT}", self.refusal(self.payload(to="builder")))
        self.assert_passes(self.payload(to="reviewer"))

    def test_an_unresolvable_target_passes(self) -> None:
        self.transcript([compaction("auto")], name="builder")
        for to in ("a9999999999999999", "*", "team-lead", "../../sess", ""):
            self.assert_passes(self.payload(to=to))
        other_session = json.loads(self.payload())
        other_session["transcript_path"] = str(self.home / "other" / "sess.jsonl")
        self.assert_passes(json.dumps(other_session))
        self.assertFalse(self.errors.exists())

    def test_a_protocol_message_and_another_tool_pass(self) -> None:
        self.transcript([compaction("auto")])
        shutdown = json.loads(self.payload())
        shutdown["tool_input"]["type"] = "shutdown_request"
        self.assert_passes(json.dumps(shutdown))
        self.assert_passes(self.payload(tool_name="Bash"))

    def test_a_malformed_payload_passes(self) -> None:
        self.transcript([compaction("auto")])
        shapeless = ("", "[]", '"text"', "{}", '{"tool_input": "text"}', '{"tool_input": {"to": 7}}')
        for stdin in (*shapeless, '{"tool_input": {"to": "x"}, "transcript_path": 3}'):
            self.assert_passes(stdin)
        self.assertFalse(self.errors.exists())
        self.assert_passes("{not json")
        self.assertIn("resume-guard", self.errors.read_text())

    def test_an_unreadable_limit_passes_with_a_note(self) -> None:
        # The hook finds the reference from its own place in the tree, so a copy of the hook in a
        # scratch tree reads that tree's reference.
        turn_limit, _ = LIMITS
        self.transcript(turns(turn_limit + 1))
        hooks = self.home / "repo" / ".claude" / "hooks"
        reference = self.home / "repo" / REFERENCE
        hooks.mkdir(parents=True)
        reference.parent.mkdir(parents=True)
        copy = Path(shutil.copy(HOOK, hooks))
        for text in (None, "The limit is generous.\n"):
            if text is not None:
                reference.write_text(text)
            answer = self.run_hook(self.payload(), hook=copy)
            self.assertNotIn("permissionDecision", answer)
            self.assertIn("went unchecked", answer["additionalContext"])
        self.assertEqual(len(self.errors.read_text().splitlines()), 2)
        reference.write_text("- The limit is about 7 turns or 1,200k tokens of context.\n")
        reason = self.refusal(self.payload(), hook=copy)
        self.assertIn("turns (the limit is 7)", reason)
        self.assertNotIn("tokens of context", reason)


if __name__ == "__main__":
    unittest.main()
