""".claude/hooks/resume-guard.py against synthetic transcripts, under a scratch HOME and TMPDIR.

The hook runs as the harness runs it: a process fed the hook payload on stdin, its answer read from
stdout. The size is never written here: `SIZE` is what the hook itself reads out of
.claude/skills/orchestrating/references/writing-a-brief.md, so this file errors when that
sentence stops parsing, and every other case is built at the size and one past it.
"""

import importlib.util
import json
import os
import re
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


def read_refusal_size() -> int:
    spec = importlib.util.spec_from_file_location("resume_guard", HOOK)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return int(module.read_refusal_size())


SIZE = read_refusal_size()


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


def start(stamp: str) -> str:
    """A transcript's first entry, the agent's prompt, written at `stamp`."""
    return json.dumps({"type": "user", "timestamp": stamp, "message": {"role": "user", "content": "The brief."}})


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

    def test_the_refusal_size_is_read_from_the_reference(self) -> None:
        self.assertGreater(SIZE, 1000)

    def test_an_agent_at_the_size_passes(self) -> None:
        self.transcript([*turns(3), turn("last", SIZE)])
        self.assert_passes(self.payload())
        self.assertFalse(self.errors.exists())

    def test_no_number_of_turns_is_refused(self) -> None:
        self.transcript(turns(2500))
        self.assert_passes(self.payload())

    def test_an_agent_whose_latest_turn_is_past_the_size_is_refused(self) -> None:
        self.transcript([*turns(3), turn("last", SIZE + 1)])
        reason = self.refusal(self.payload())
        self.assertIn(
            f"{SIZE + 1:,} tokens of context in its latest turn (a resume is refused once past {SIZE:,})", reason
        )
        self.assertIn(f'sub-agent {AGENT} ("Build the thing")', reason)
        self.assertIsNone(re.search(r"\bturns\b", reason))
        self.assertNotIn("compaction", reason)

    def test_the_context_is_the_latest_turns_and_not_the_largest(self) -> None:
        no_usage = json.dumps({"type": "assistant", "message": {"id": "error", "usage": {"input_tokens": 0}}})
        self.transcript([turn("big", SIZE * 2), compaction("manual"), turn("small", 5000), no_usage])
        self.assert_passes(self.payload())

    def test_an_automatic_compaction_is_refused(self) -> None:
        self.transcript([*turns(3), compaction("auto"), turn("after", 5000)])
        reason = self.refusal(self.payload())
        self.assertIn("1 automatic compaction of its context", reason)
        self.assertNotIn("tokens of context in its latest turn", reason)
        self.transcript([compaction("auto"), compaction("auto")], agent=OTHER)
        self.assertIn("2 automatic compactions of its context", self.refusal(self.payload(to=OTHER)))

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
        for words in (
            "follow-up on the agent's own pull request, or new work",
            "a delta review, review or CI fixes, a merge of main, a stop or wrap-up",
            "send this same message again, and the resend passes",
            "the next step, the next pull request, another task",
            "do not resend",
            "fresh agent",
            ".claude/briefs/",
            "applies on top",
        ):
            self.assertIn(words, reason)
        self.assertIsNone(re.search(r"\bturns\b", reason))

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
            note = answer["additionalContext"]
            self.assertIn("1 automatic compaction", note)
            self.assertIn("The message has gone through: do not send it again.", note)
            for path, section in ((SKILL, "What the orchestrator keeps"), (REFERENCE, "Sizing the task")):
                self.assertIn(f'{path}, "{section}"', note)
            for words in ("One question decides it", "send this same message again", "the resend passes"):
                self.assertNotIn(words, note)

    def test_a_target_named_in_its_meta_file_is_resolved(self) -> None:
        self.transcript(turns(2), agent=OTHER, name="reviewer")
        self.transcript([compaction("auto")], name="builder")
        self.assertIn(f"sub-agent {AGENT}", self.refusal(self.payload(to="builder")))
        self.assert_passes(self.payload(to="reviewer"))

    def test_a_name_two_agents_took_is_the_one_that_started_last(self) -> None:
        # The older agent is the huge one and the one written last, as when it is still working, or
        # was sent a stop, after its successor went idle; the message goes to the successor.
        new = [start("2026-01-01T10:00:00.000Z"), *turns(1)]
        old = [start("2026-01-01T09:00:00.000Z"), turn("big", SIZE + 1)]
        self.transcript(new, agent=OTHER, name="builder")
        self.transcript(old, name="builder")
        now = (self.agents / f"agent-{AGENT}.jsonl").stat().st_mtime
        os.utime(self.agents / f"agent-{OTHER}.jsonl", (now - 600, now - 600))
        self.assert_passes(self.payload(to="builder"))
        self.assertIn(f"sub-agent {AGENT}", self.refusal(self.payload()))
        # The other way round, the newest is the huge one, however long ago it last wrote.
        self.transcript([start("2026-01-01T11:00:00.000Z"), compaction("auto")], agent=OTHER, name="builder")
        os.utime(self.agents / f"agent-{OTHER}.jsonl", (now - 600, now - 600))
        self.assertIn(f"sub-agent {OTHER}", self.refusal(self.payload(to="builder")))
        # A transcript with no first timestamp is older than one that has it.
        self.transcript([turn("big", SIZE + 1)], name="reviewer")
        self.transcript([start("2026-01-01T08:00:00.000Z"), *turns(1)], agent=OTHER, name="reviewer")
        self.assert_passes(self.payload(to="reviewer"))

    def test_an_assistant_line_with_no_message_id_still_gives_the_context(self) -> None:
        def line(context: int) -> str:
            return json.dumps({"type": "assistant", "message": {"usage": {"input_tokens": context}, "content": []}})

        self.transcript([line(SIZE)])
        self.assert_passes(self.payload())
        self.transcript([line(SIZE + 1)])
        self.assertIn(f"{SIZE + 1:,} tokens", self.refusal(self.payload()))

    def test_a_transcript_that_cannot_be_measured_passes_with_a_note(self) -> None:
        entries = (
            {"type": "assistant", "message": "a string where the message goes"},
            {"type": "assistant", "message": {"id": "m", "usage": {"input_tokens": "many"}}},
            {"type": "assistant", "message": {"id": "m", "usage": "a string where the usage goes"}},
            {"type": "system", "subtype": "compact_boundary", "compactMetadata": "auto"},
        )
        for count, entry in enumerate(entries, start=1):
            self.transcript([turn("big", SIZE + 1), json.dumps(entry)])
            answer = self.run_hook(self.payload())
            self.assertNotIn("permissionDecision", answer)
            self.assertIn(f"could not measure sub-agent {AGENT}", answer["additionalContext"])
            self.assertIn("went unchecked", answer["additionalContext"])
            self.assertEqual(len(self.errors.read_text().splitlines()), count)

    def test_a_sender_shaped_like_a_path_keeps_its_marker_in_the_state_folder(self) -> None:
        self.transcript([compaction("auto")])
        state = self.state / "claude-nappy-resume-guard"
        for sender in ("..", "../..", "a/b", "."):
            stdin = self.payload(session_id=sender)
            self.refusal(stdin)
            self.assert_passes(stdin)
        markers = [path for path in self.state.rglob("*") if path.is_file()]
        self.assertEqual(len(markers), 4)
        for path in markers:
            self.assertEqual(path.parent.parent, state)
            self.assertNotIn(".", path.parent.name)

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

    def test_an_unreadable_size_passes_with_a_note(self) -> None:
        # The hook finds the reference from its own place in the tree, so a copy of the hook in a
        # scratch tree reads that tree's reference.
        self.transcript([turn("big", 1_200_001)])
        hooks = self.home / "repo" / ".claude" / "hooks"
        reference = self.home / "repo" / REFERENCE
        hooks.mkdir(parents=True)
        reference.parent.mkdir(parents=True)
        copy = Path(shutil.copy(HOOK, hooks))
        contents = (
            None,
            b"- The limit is about 300k tokens of context, and no limit counts turns.\n",
            b"- The limit is about 150 turns or 300k tokens of context.\n",
            b"A resume is refused once past 9k tokens of context \xff\xfe\n",
            b"A resume is refused once past 9k tokens of context. A resume is"
            b" refused once past 8k tokens of context.\n",
            b"A resume is refused once past 0k tokens of context.\n",
        )
        for content in contents:
            if content is not None:
                reference.write_bytes(content)
            answer = self.run_hook(self.payload(), hook=copy)
            self.assertNotIn("permissionDecision", answer)
            self.assertIn("could not read the size past which a resume is refused", answer["additionalContext"])
            self.assertIn("went unchecked", answer["additionalContext"])
        self.assertEqual(len(self.errors.read_text().splitlines()), len(contents))
        reference.write_text(
            "- **A resume is refused once past\n  1,200k tokens of context** (inbox #1298 in merry-badger),"
            " the context being the latest turn's.\n"
        )
        reason = self.refusal(self.payload(), hook=copy)
        self.assertIn("a resume is refused once past 1,200,000", reason)
        self.transcript([turn("big", 1_200_000)])
        self.assertEqual(self.run_hook(self.payload(message="again"), hook=copy), {})


if __name__ == "__main__":
    unittest.main()
