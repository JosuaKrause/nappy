"""tools/agent-stats.py and .claude/hooks/agent-stats.py against a scratch HOME, never the real data."""

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / "tools/agent-stats.py"
HOOK = ROOT / ".claude/hooks/agent-stats.py"


def turn(tokens: int, tool_uses: int) -> str:
    content = [{"type": "tool_use", "id": str(i)} for i in range(tool_uses)]
    usage = {"input_tokens": tokens - 10, "cache_read_input_tokens": 5, "output_tokens": 5}
    return json.dumps({"type": "assistant", "message": {"model": "m-1", "usage": usage, "content": content}})


class AgentStatsTests(unittest.TestCase):
    def setUp(self) -> None:
        scratch = tempfile.TemporaryDirectory(prefix="agent-stats-test-")
        self.addCleanup(scratch.cleanup)
        self.home = Path(scratch.name).resolve()
        self.data = self.home / ".claude" / "nappy-agent-stats"

    def run_script(self, script: Path, *args: str, stdin: str = "") -> subprocess.CompletedProcess[str]:
        env = dict(os.environ, HOME=str(self.home))
        return subprocess.run(
            [sys.executable, str(script), *args], input=stdin, text=True, capture_output=True, env=env, check=False
        )

    def make_transcript(self) -> Path:
        session = self.home / "proj" / "sess.jsonl"
        agents = session.with_suffix("") / "subagents"
        agents.mkdir(parents=True)
        (agents / "agent-abc123def.jsonl").write_text(
            "\n".join([turn(1000, 2), "not json", turn(5000, 1), turn(3000, 0)]) + "\n"
        )
        (agents / "agent-abc123def.meta.json").write_text(
            json.dumps({"description": "Do a thing", "model": "sonnet", "agentType": "general-purpose"})
        )
        return session

    def test_hook_records_the_largest_turn_and_the_tool_calls(self) -> None:
        session = self.make_transcript()
        payload = json.dumps({"agent_id": "abc123def", "transcript_path": str(session), "extra": 1})
        result = self.run_script(HOOK, stdin=payload)
        self.assertEqual(result.returncode, 0)
        row = json.loads((self.data / "runs.jsonl").read_text())
        self.assertEqual((row["tokens"], row["tools"]), (5000, 3))
        self.assertEqual(row["description"], "Do a thing")
        self.assertEqual(row["model_id"], "m-1")
        self.assertEqual(row["payload_keys"], ["agent_id", "extra", "transcript_path"])

    def test_hook_exits_zero_and_logs_an_error_on_garbage(self) -> None:
        result = self.run_script(HOOK, stdin="{not json")
        self.assertEqual(result.returncode, 0)
        self.assertIn("JSONDecodeError", (self.data / "errors.log").read_text())

    def test_add_takes_tokens_and_tools_from_the_hook_by_shortened_id(self) -> None:
        payload = json.dumps({"agent_id": "abc123def", "transcript_path": str(self.make_transcript())})
        self.run_script(HOOK, stdin=payload)
        added = self.run_script(
            TOOL, "add", "--kind", "review", "--model", "sonnet", "--rounds", "0", "--grade", "good", "--agent", "abc123"
        )
        self.assertEqual(added.returncode, 0, added.stderr)
        row = json.loads((self.data / "log.jsonl").read_text())
        self.assertEqual((row["tokens"], row["tools"]), (5000, 3))

    def test_add_refuses_a_prefix_two_runs_share_and_a_short_one(self) -> None:
        self.data.mkdir(parents=True)
        runs = [{"agent": "abcdef111", "tokens": 1, "tools": 1}, {"agent": "abcdef222", "tokens": 2, "tools": 2}]
        (self.data / "runs.jsonl").write_text("".join(json.dumps(r) + "\n" for r in runs))
        base = ("add", "--kind", "review", "--model", "sonnet", "--rounds", "0", "--grade", "ok")
        shared = self.run_script(TOOL, *base, "--agent", "abcdef")
        self.assertEqual(shared.returncode, 2)
        self.assertIn("abcdef111", shared.stderr)
        short = self.run_script(TOOL, *base, "--agent", "abc")
        self.assertEqual(short.returncode, 2)
        self.assertFalse((self.data / "log.jsonl").exists())
        self.assertEqual(self.run_script(TOOL, *base, "--agent", "abcdef2").returncode, 0)
        self.assertEqual(json.loads((self.data / "log.jsonl").read_text())["tokens"], 2)

    def test_hook_keeps_the_row_when_meta_is_unreadable(self) -> None:
        session = self.make_transcript()
        (session.with_suffix("") / "subagents" / "agent-abc123def.meta.json").write_text("{broken")
        payload = json.dumps({"agent_id": "abc123def", "transcript_path": str(session)})
        self.run_script(HOOK, stdin=payload)
        row = json.loads((self.data / "runs.jsonl").read_text())
        self.assertEqual((row["tokens"], row["tools"]), (5000, 3))

    def test_add_without_tokens_or_a_run_is_refused(self) -> None:
        result = self.run_script(TOOL, "add", "--kind", "review", "--model", "sonnet", "--rounds", "0", "--grade", "ok")
        self.assertEqual(result.returncode, 2)
        self.assertFalse((self.data / "log.jsonl").exists())

    def test_summary_reads_the_old_format_and_groups(self) -> None:
        self.data.mkdir(parents=True)
        old = {"kind": "review", "model": "sonnet", "pr": 1, "tokens": 100, "tools": None, "rounds": 0, "grade": "good"}
        new = dict(old, tokens=300, rounds=2, grade="bad", redone=True)
        (self.data / "log.jsonl").write_text(json.dumps(old) + "\n" + json.dumps(new) + "\n")
        result = self.run_script(TOOL, "summary")
        self.assertEqual(result.returncode, 0, result.stderr)
        line = next(x for x in result.stdout.splitlines() if x.startswith("review"))
        self.assertEqual(line.split(), ["review", "sonnet", "2", "200", "1.0", "1", "1/0/1"])
        self.assertEqual(len(self.run_script(TOOL, "list", "--last", "1").stdout.splitlines()), 1)

    def test_unknown_argument_is_rejected(self) -> None:
        self.assertEqual(self.run_script(TOOL, "summary", "--bogus").returncode, 2)
        self.assertEqual(self.run_script(TOOL, "--help").returncode, 0)


if __name__ == "__main__":
    unittest.main()
