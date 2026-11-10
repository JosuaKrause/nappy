"""tools/agent-stats.py and .claude/hooks/agent-stats.py against a scratch HOME, never the real data."""

import json
import os
import subprocess
import sys
import tempfile
import unittest
from datetime import date
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
            TOOL,
            "add",
            "--kind",
            "review",
            "--model",
            "sonnet",
            "--rounds",
            "0",
            "--grade",
            "good",
            "--agent",
            "abc123",
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

    def write_data(self, runs: list[dict[str, object]], grades: list[dict[str, object]]) -> None:
        self.data.mkdir(parents=True)
        (self.data / "runs.jsonl").write_text("".join(json.dumps(r) + "\n" for r in runs))
        (self.data / "log.jsonl").write_text("".join(json.dumps(g) + "\n" for g in grades))

    def ungraded(self, *args: str) -> list[str]:
        result = self.run_script(TOOL, "ungraded", "--all", *args)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.splitlines()

    @staticmethod
    def stop(agent: str, ts: str, tokens: int = 10, session: str = "s1") -> dict[str, object]:
        return {
            "ts": ts,
            "agent": agent,
            "session_id": session,
            "tokens": tokens,
            "model": "sonnet",
            "description": "d " + agent,
        }

    @staticmethod
    def grade(agent: str, day: str) -> dict[str, object]:
        return {"kind": "fix", "model": "sonnet", "tokens": 1, "rounds": 0, "grade": "ok", "agent": agent, "date": day}

    def test_ungraded_lists_never_graded_and_stops_after_the_last_grade(self) -> None:
        runs = [
            self.stop("aaaaaa111", "2026-11-01T10:00:00", 50),
            self.stop("aaaaaa111", "2026-11-02T10:00:00", 90),
            self.stop("bbbbbb222", "2026-11-01T10:00:00"),
            self.stop("bbbbbb222", "2026-11-03T10:00:00", 70),
            self.stop("bbbbbb222", "2026-11-04T10:00:00", 20),
            self.stop("cccccc333", "2026-11-01T10:00:00"),
        ]
        self.write_data(runs, [self.grade("bbbbbb222", "2026-11-02"), self.grade("cccccc333", "2026-11-01")])
        lines = self.ungraded()
        self.assertEqual(len(lines), 2)
        a = next(x for x in lines if x.startswith("aaaaaa111"))
        self.assertIn("2 stops", a)
        self.assertIn("90 tokens", a)
        self.assertIn("graded never", a)
        self.assertIn("d aaaaaa111", a)
        b = next(x for x in lines if x.startswith("bbbbbb222"))
        self.assertIn("2 stops", b)
        self.assertIn("2026-11-03T10:00:00 .. 2026-11-04T10:00:00", b)
        self.assertIn("graded 2026-11-02", b)

    def test_ungraded_joins_a_short_grade_and_skips_an_ambiguous_one(self) -> None:
        runs = [
            self.stop("abcdef111", "2026-11-01T10:00:00"),
            self.stop("abcxyz111", "2026-11-01T10:00:00"),
            self.stop("abcxyz222", "2026-11-01T10:00:00"),
        ]
        self.write_data(runs, [self.grade("abcdef1", "2026-11-01"), self.grade("abc", "2026-11-01")])
        self.assertEqual({x.split()[0] for x in self.ungraded()}, {"abcxyz111", "abcxyz222"})
        self.data.joinpath("log.jsonl").write_text(json.dumps(self.grade("abcxyz", "2026-11-01")) + "\n")
        result = self.run_script(TOOL, "ungraded", "--all")
        self.assertIn("abcxyz111, abcxyz222", result.stderr)
        self.assertEqual(len(result.stdout.splitlines()), 3)

    def test_ungraded_since_session_and_the_default_window(self) -> None:
        old = self.stop("oldold111", "2020-01-01T10:00:00")
        new = self.stop("newnew111", date.today().isoformat() + "T10:00:00", session="s2")
        self.write_data([old, new], [])
        self.assertEqual(len(self.ungraded()), 2)
        self.assertEqual([x.split()[0] for x in self.ungraded("--session", "s2")], ["newnew111"])
        default = self.run_script(TOOL, "ungraded").stdout.splitlines()
        self.assertEqual([x.split()[0] for x in default], ["newnew111"])
        since = self.run_script(TOOL, "ungraded", "--since", "2019-12-31").stdout.splitlines()
        self.assertEqual(len(since), 2)
        self.assertEqual(self.run_script(TOOL, "ungraded", "--since", "2020-01-02", "--all").returncode, 2)

    def test_ungraded_uses_the_later_of_two_grades_and_counts_the_grade_day_as_graded(self) -> None:
        runs = [
            self.stop("aaaaaa111", "2026-11-02T10:00:00"),
            self.stop("aaaaaa111", "2026-11-04T23:00:00"),
            self.stop("aaaaaa111", "2026-11-05T10:00:00", 30),
            self.stop("bbbbbb222", "2026-11-04T23:00:00"),
        ]
        later_first = [
            self.grade("aaaaaa111", "2026-11-04"),
            self.grade("aaaaaa1", "2026-11-01"),
            self.grade("bbbbbb222", "2026-11-01"),
            self.grade("bbbbbb222", "2026-11-04"),
        ]
        self.write_data(runs, later_first)
        lines = self.ungraded()
        self.assertEqual([x.split()[0] for x in lines], ["aaaaaa111"])
        self.assertIn("  1 stops", lines[0])
        self.assertIn("2026-11-05T10:00:00 .. 2026-11-05T10:00:00", lines[0])
        self.assertIn("graded 2026-11-04", lines[0])

    def test_ungraded_lists_a_run_row_that_carries_only_agent_id(self) -> None:
        self.write_data([{"ts": "2026-11-01T10:00:00", "agent_id": "onlyid111"}], [])
        lines = self.ungraded()
        self.assertEqual(len(lines), 1)
        self.assertEqual(lines[0].split()[:4], ["onlyid111", "-", "1", "stops"])
        self.assertTrue(lines[0].endswith("0 tokens  graded never  -"), lines[0])
        self.data.joinpath("log.jsonl").write_text(json.dumps(self.grade("onlyid", "2026-11-01")) + "\n")
        self.assertEqual(self.ungraded(), [])

    def test_a_malformed_line_is_skipped_with_a_note_on_stderr(self) -> None:
        self.data.mkdir(parents=True)
        good = json.dumps(self.stop("aaaaaa111", "2026-11-01T10:00:00"))
        torn = '{"ts": "2026-11-02T10:00:00", "agent": "bbbb'
        (self.data / "runs.jsonl").write_text("\n".join([good, torn, "[1, 2]", good]) + "\n")
        (self.data / "log.jsonl").write_text(
            '{"kind": "fix", "mod\n' + json.dumps(self.grade("zzzzzz999", "2026-11-01")) + "\n"
        )
        result = self.run_script(TOOL, "ungraded", "--all")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("Traceback", result.stderr)
        self.assertIn("runs.jsonl line 2", result.stderr)
        self.assertIn("runs.jsonl line 3", result.stderr)
        self.assertIn("log.jsonl line 1", result.stderr)
        lines = result.stdout.splitlines()
        self.assertEqual(len(lines), 1)
        self.assertIn("aaaaaa111", lines[0])
        self.assertIn("2 stops", lines[0])
        summary = self.run_script(TOOL, "summary")
        self.assertEqual(summary.returncode, 0, summary.stderr)
        self.assertIn("log.jsonl line 1", summary.stderr)

    def test_unknown_argument_is_rejected(self) -> None:
        self.assertEqual(self.run_script(TOOL, "summary", "--bogus").returncode, 2)
        self.assertEqual(self.run_script(TOOL, "--help").returncode, 0)


if __name__ == "__main__":
    unittest.main()
