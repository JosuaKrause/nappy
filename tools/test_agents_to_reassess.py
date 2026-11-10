"""tools/agents-to-reassess.py against scratch transcripts in a scratch project folder, never real ones."""

import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / "tools/agents-to-reassess.py"

spec = importlib.util.spec_from_file_location("agents_to_reassess", TOOL)
assert spec is not None and spec.loader is not None
tool = importlib.util.module_from_spec(spec)
sys.modules["agents_to_reassess"] = tool
spec.loader.exec_module(tool)

Entry = dict[str, Any]


def call(name: str, command: str, call_id: str) -> Entry:
    return {"type": "tool_use", "id": call_id, "name": name, "input": {"command": command}}


def turn(number: int, context: int, *blocks: Entry, stop: str = "tool_use", model: str = "model-a") -> Entry:
    usage = {"input_tokens": 10, "cache_read_input_tokens": context - 15, "cache_creation_input_tokens": 5}
    message = {"id": f"msg-{number}", "model": model, "usage": usage, "stop_reason": stop, "content": list(blocks)}
    return {"type": "assistant", "message": message}


def result(call_id: str) -> Entry:
    content = [{"type": "tool_result", "tool_use_id": call_id, "content": "SECRET-RESULT"}]
    return {"type": "user", "message": {"content": content}}


def prompt() -> Entry:
    return {"type": "user", "message": {"content": "SECRET-PROMPT"}}


def working(turns: int, context: int = 50_000, command: str = "step {}") -> list[Entry]:
    """An agent mid-task: a prompt, then turns of one distinct tool call each, the last unanswered."""
    entries = [prompt()]
    for number in range(turns):
        entries += [turn(number, context, call("Bash", command.format(number), f"c{number}")), result(f"c{number}")]
    return entries[:-1]


def done(context: int = 50_000) -> list[Entry]:
    final = {"type": "text", "text": "SECRET-REPORT"}
    return [*working(2, context), result("c1"), turn(9, context, final, stop="end_turn")]


class AgentsToReassessTests(unittest.TestCase):
    def setUp(self) -> None:
        scratch = tempfile.TemporaryDirectory(prefix="agents-to-reassess-test-")
        self.addCleanup(scratch.cleanup)
        self.project = Path(scratch.name).resolve() / "project"
        self.project.mkdir()

    def agent(self, name: str, entries: list[Entry], *, idle: int = 0, session: str = "sess-one") -> Path:
        folder = self.project / session / "subagents"
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / f"agent-{name}.jsonl"
        path.write_text("not json\n" + "".join(json.dumps(entry) + "\n" for entry in entries))
        written = time.time() - idle * 60
        os.utime(path, (written, written))
        return path

    def run_tool(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(TOOL), "--project-dir", str(self.project), *args],
            text=True,
            capture_output=True,
            check=False,
        )

    def line(self, output: str, name: str) -> str:
        found = [line for line in output.splitlines() if line.startswith(name + " ")]
        self.assertEqual(len(found), 1, f"{name} in:\n{output}")
        return found[0]

    def test_a_line_holds_the_model_the_last_context_the_turns_and_the_idle_minutes(self) -> None:
        entries = working(3)
        entries[-1]["message"]["usage"]["cache_read_input_tokens"] = 123_985
        # One turn is written as several lines under one message id, and counts once.
        entries.append(turn(2, 124_000, call("Read", "x", "c-extra")))
        self.agent("abc", entries, idle=7)
        out = self.run_tool()
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertEqual(self.line(out.stdout, "abc").split(), ["abc", "model-a", "124k", "3", "7m", "running", "-"])
        self.assertIn("session sess-one: 1 sub-agents, 1 shown, 0 to reassess", out.stdout)

    def test_only_running_agents_are_listed_unless_all(self) -> None:
        self.agent("old-done", done(), idle=30)
        self.agent("fresh-done", done(), idle=2)
        self.agent("working", working(2), idle=20)
        out = self.run_tool().stdout
        self.assertNotIn("old-done", out)
        self.assertIn("finished", self.line(out, "fresh-done"))
        self.assertIn("running", self.line(out, "working"))
        self.assertNotIn("fresh-done", self.run_tool("--recent", "1").stdout)
        self.assertIn("finished", self.line(self.run_tool("--all").stdout, "old-done"))

    def test_a_handback_finishes_an_agent_and_a_new_prompt_starts_it_again(self) -> None:
        handed = [*working(1), result("c0"), turn(5, 50_000, call("SubagentHandback", "report", "h")), result("h")]
        self.agent("handed", handed, idle=90)
        self.agent("resumed", [*handed, prompt()], idle=90)
        out = self.run_tool("--all").stdout
        self.assertEqual(self.line(out, "handed").split()[5:], ["finished", "-"])
        self.assertIn("REASSESS: quiet (90m >= 45m, not finished)", self.line(out, "resumed"))

    def test_a_stopped_agent_is_listed_like_a_finished_one_and_never_quiet(self) -> None:
        for number, marker in enumerate(tool.INTERRUPT_MARKERS):
            stop = {"type": "user", "message": {"content": [{"type": "text", "text": marker}]}}
            self.agent(f"stopped-{number}", [*working(2), stop], idle=90)
            self.agent(f"just-stopped-{number}", [*working(2), stop], idle=2)
            self.agent(f"prompted-{number}", [*working(2), stop, prompt()], idle=90)
            again = turn(50, 50_000, call("Bash", "after", "again"))
            self.agent(f"answered-{number}", [*working(2), stop, again], idle=90)
        self.assertEqual(len(tool.INTERRUPT_MARKERS), 2)
        default = self.run_tool().stdout
        everything = self.run_tool("--all").stdout
        for number in range(2):
            self.assertNotIn(f"\nstopped-{number} ", default)
            self.assertEqual(self.line(default, f"just-stopped-{number}").split()[5:], ["stopped", "-"])
            self.assertEqual(self.line(everything, f"stopped-{number}").split()[5:], ["stopped", "-"])
            for resumed in (f"prompted-{number}", f"answered-{number}"):
                self.assertIn("running", self.line(default, resumed))
                self.assertIn("REASSESS: quiet (90m >= 45m, not finished)", self.line(default, resumed))
        self.assertIn("4 to reassess", everything)

    def test_a_harness_notice_after_the_final_message_leaves_the_agent_finished(self) -> None:
        notice = {"type": "user", "isMeta": True, "message": {"content": "SECRET-NOTICE"}}
        self.agent("noticed", [*done(), notice], idle=90)
        self.assertEqual(self.line(self.run_tool("--all").stdout, "noticed").split()[5:], ["finished", "-"])

    def test_the_context_is_the_last_usage_that_reports_any(self) -> None:
        entries = working(3, 80_000)
        silent = turn(40, 50_000, call("Read", "x", "silent-1"))
        silent["message"]["usage"] = {"input_tokens": 0, "cache_read_input_tokens": 0}
        bare = turn(41, 50_000, call("Read", "y", "silent-2"))
        del bare["message"]["usage"]
        self.agent("abc", [*entries, silent, bare])
        self.assertEqual(self.line(self.run_tool().stdout, "abc").split()[2], "80k")

    def test_size_is_flagged_at_the_players_number_and_not_below_it(self) -> None:
        self.agent("at", working(2, 500_000))
        self.agent("below", working(2, 499_999))
        out = self.run_tool().stdout
        self.assertIn("REASSESS: size (500k >= 500k); note: past-guide (500k > 300k)", self.line(out, "at"))
        self.assertTrue(self.line(out, "below").endswith("note: past-guide (499k > 300k)"))
        self.assertIn("1 to reassess", out)

    def test_past_the_guide_is_a_note_for_turns_or_context(self) -> None:
        limits = tool.read_limits()
        self.agent("turns", working(limits.turns + 1))
        self.agent("at-limit", working(limits.turns, limits.context))
        out = self.run_tool().stdout
        self.assertTrue(
            self.line(out, "turns").endswith(f"note: past-guide ({limits.turns + 1} > {limits.turns} turns)")
        )
        self.assertEqual(self.line(out, "at-limit").split()[5:], ["running", "-"])
        self.assertIn("0 to reassess", out)

    def test_an_automatic_compaction_is_flagged_and_a_manual_one_is_not(self) -> None:
        auto = {"type": "system", "subtype": "compact_boundary", "compactMetadata": {"trigger": "auto"}}
        manual = {"type": "system", "subtype": "compact_boundary", "compactMetadata": {"trigger": "manual"}}
        self.agent("auto", [*working(2), auto])
        self.agent("manual", [*working(2), manual])
        out = self.run_tool().stdout
        self.assertIn("REASSESS: auto-compacted (x1)", self.line(out, "auto"))
        self.assertEqual(self.line(out, "manual").split()[5:], ["running", "-"])

    def test_quiet_needs_an_unfinished_agent_and_the_interval(self) -> None:
        self.agent("stuck", working(2), idle=46)
        self.agent("at", working(2), idle=45)
        self.agent("slow", working(2), idle=44)
        self.agent("done", done(), idle=300)
        out = self.run_tool("--all").stdout
        self.assertIn("REASSESS: quiet (46m >= 45m, not finished)", self.line(out, "stuck"))
        self.assertIn("REASSESS: quiet (45m >= 45m, not finished)", self.line(out, "at"))
        self.assertEqual(self.line(out, "slow").split()[5:], ["running", "-"])
        self.assertEqual(self.line(out, "done").split()[5:], ["finished", "-"])

    def test_looping_is_the_same_call_repeated_inside_the_window(self) -> None:
        count, window = tool.LOOP_COUNT, tool.LOOP_WINDOW
        same = [turn(100 + n, 50_000, call("Bash", "poll", f"p{n}")) for n in range(count)]
        self.agent("loop", [*working(3), *same])
        self.agent("almost", [*working(3), *same[:-1]])
        # The same input to another tool is another call.
        self.agent("two-tools", [*working(3), *same[:-1], turn(200, 50_000, call("Read", "poll", "r"))])
        # Repeats that have left the window no longer count.
        after = [turn(300 + n, 50_000, call("Bash", f"other {n}", f"o{n}")) for n in range(window - count + 1)]
        self.agent("moved-on", [*working(3), *same, *after])
        # One call written on two lines is one call.
        self.agent("rewritten", [*working(3), *same[:-1], same[0]])
        # The same call made several times in parallel in one turn is one call of that turn.
        parallel = turn(400, 50_000, *(call("Bash", "poll", f"par{n}") for n in range(count)))
        self.agent("parallel", [*working(3), parallel])
        out = self.run_tool().stdout
        self.assertIn(f"REASSESS: looping (Bash x{count} in the last {3 + count} calls)", self.line(out, "loop"))
        for name in ("almost", "two-tools", "moved-on", "rewritten", "parallel"):
            self.assertEqual(self.line(out, name).split()[5:], ["running", "-"])

    def test_quiet_flag_keeps_only_flagged_and_noted_agents(self) -> None:
        self.agent("plain", working(2))
        self.agent("big", working(2, 600_000))
        self.agent("noted", working(2, 400_000))
        out = self.run_tool("--quiet").stdout
        self.assertNotIn("plain", out)
        self.line(out, "big")
        self.line(out, "noted")
        self.assertIn("3 sub-agents, 2 shown, 1 to reassess", out)

    def test_the_default_session_is_the_one_written_last_and_session_takes_a_prefix(self) -> None:
        self.agent("older", working(2), idle=50, session="aaa-older")
        self.agent("newer", working(2), idle=5, session="bbb-newer")
        self.assertIn("session bbb-newer:", self.run_tool().stdout)
        self.assertIn("session aaa-older:", self.run_tool("--session", "aaa").stdout)
        missing = self.run_tool("--session", "zzz")
        self.assertEqual(missing.returncode, 2)
        self.assertIn("no session with sub-agents matching --session zzz", missing.stderr)
        self.assertEqual(missing.stdout, "")

    def test_nothing_to_report_exits_zero_and_a_missing_project_folder_exits_two(self) -> None:
        self.agent("done", done(), idle=300)
        out = self.run_tool()
        self.assertEqual(out.returncode, 0)
        self.assertEqual(out.stdout.strip(), "session sess-one: 1 sub-agents, 0 shown, 0 to reassess")
        gone = subprocess.run(
            [sys.executable, str(TOOL), "--project-dir", str(self.project / "nowhere")],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(gone.returncode, 2)

    def test_no_message_content_or_tool_input_or_path_is_printed(self) -> None:
        self.agent("loop", [turn(n, 600_000, call("Bash", "SECRET-INPUT", f"p{n}")) for n in range(9)], idle=99)
        self.agent("done", done())
        out = self.run_tool("--all")
        self.assertNotIn("SECRET", out.stdout + out.stderr)
        self.assertNotIn(str(self.project), out.stdout + out.stderr)

    def test_the_limit_is_read_from_the_brief_guide_and_an_unreadable_sentence_fails(self) -> None:
        limits = tool.read_limits()
        self.assertGreater(limits.turns, 0)
        self.assertGreater(limits.context, 1000)
        reworded = self.project / "writing-a-brief.md"
        reworded.write_text("- The limit is roughly 1,200 turns or 2,500k tokens of context.\n")
        with self.assertRaises(tool.ReassessError):
            tool.read_limits(reworded)
        reworded.write_text("- The limit is about 1,200 turns or 2,500k tokens of context.\n")
        self.assertEqual(tool.read_limits(reworded), tool.Limits(turns=1200, context=2_500_000))
        with self.assertRaises(tool.ReassessError):
            tool.read_limits(self.project / "no-such-file.md")


if __name__ == "__main__":
    unittest.main()
