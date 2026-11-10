"""tools/usage-report.py on synthetic transcripts in a temp dir, never the real ones."""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from datetime import UTC, datetime
from pathlib import Path
from types import ModuleType
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / "tools" / "usage-report.py"


def load() -> ModuleType:
    spec = importlib.util.spec_from_file_location("usage_report", TOOL)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules["usage_report"] = module
    spec.loader.exec_module(module)
    return module


ur: Any = load()

FABLE = "claude-fable-5-2"
OPUS = "claude-opus-5-5"


def line(
    mid: str, ts: str, model: str = OPUS, inp: int = 0, w1: int = 0, w5: int = 0, rd: int = 0, out: int = 0
) -> str:
    usage = {
        "input_tokens": inp,
        "cache_read_input_tokens": rd,
        "cache_creation_input_tokens": w1 + w5,
        "cache_creation": {"ephemeral_1h_input_tokens": w1, "ephemeral_5m_input_tokens": w5},
        "output_tokens": out,
    }
    return json.dumps({"type": "assistant", "timestamp": ts, "message": {"id": mid, "model": model, "usage": usage}})


def compact(ts: str, pre: int, trigger: str = "auto") -> str:
    return json.dumps(
        {
            "type": "system",
            "subtype": "compact_boundary",
            "timestamp": ts,
            "compactMetadata": {"trigger": trigger, "preTokens": pre},
        }
    )


class UsageReportTests(unittest.TestCase):
    def setUp(self) -> None:
        scratch = tempfile.TemporaryDirectory(prefix="usage-report-test-")
        self.addCleanup(scratch.cleanup)
        self.home = Path(scratch.name).resolve()
        self.repo = Path("/fake/repo")
        self.projects = self.home / "projects"
        self.project: Path = self.projects / ur.project_dir_name(self.repo)
        self.project.mkdir(parents=True)

    def main_session(self, name: str, lines: list[str]) -> Path:
        path = self.project / f"{name}.jsonl"
        path.write_text("\n".join(lines) + "\n")
        return path

    def sub_session(self, session: str, agent: str, description: str, lines: list[str]) -> Path:
        folder = self.project / session / "subagents"
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / f"agent-{agent}.jsonl"
        path.write_text("\n".join(lines) + "\n")
        path.with_suffix(".meta.json").write_text(json.dumps({"description": description, "model": OPUS}))
        return path

    def sessions(self) -> list[Any]:
        found: list[Any] = ur.read_sessions(self.projects, self.repo)
        return found

    def test_dedup_by_message_id_keeps_the_last_usage_at_the_first_time(self) -> None:
        self.main_session(
            "s1",
            [
                line("m1", "2026-11-01T10:00:00Z", inp=10, out=5),
                line("m1", "2026-11-01T10:00:01Z", inp=10, out=40),
                line("m1", "2026-11-01T10:00:02Z", inp=10, out=99),
                'not json {"usage"',
                line("m2", "2026-11-01T10:01:00Z", inp=1),
            ],
        )
        (session,) = self.sessions()
        self.assertEqual([t.inp for t in session.turns], [10, 1])
        self.assertEqual(session.turns[0].out, 99)
        self.assertEqual(session.turns[0].t, ur.parse_time("2026-11-01T10:00:00Z"))

    def test_a_message_in_two_files_is_counted_once_in_the_sub_agents(self) -> None:
        self.main_session(
            "s1", [line("shared", "2026-11-01T10:00:00Z", inp=7), line("own", "2026-11-01T10:01:00Z", inp=1)]
        )
        self.sub_session("s1", "a", "Build x", [line("shared", "2026-11-01T10:00:00Z", inp=7)])
        sessions = self.sessions()
        self.assertEqual(sum(len(s.turns) for s in sessions), 2)
        sub = next(s for s in sessions if s.is_sub)
        self.assertEqual(len(sub.turns), 1)

    def test_a_session_that_switches_model_books_each_family_under_its_own_row(self) -> None:
        self.main_session(
            "s1",
            [
                line("a", "2026-11-01T10:00:00Z", model=FABLE, inp=1_000_000),
                line("b", "2026-11-01T10:01:00Z", model=OPUS, inp=1_000_000),
                line("c", "2026-11-01T10:02:00Z", model=FABLE, inp=1_000_000),
            ],
        )
        rows = ur.build_rows(self.sessions(), [ur.Window(None, None)])
        by_family = {r.family: r for r in rows}
        self.assertEqual({f: len(r.turns) for f, r in by_family.items()}, {"fable": 2, "opus": 1})
        self.assertAlmostEqual(by_family["fable"].dollars, 16.0)
        self.assertAlmostEqual(by_family["opus"].dollars, 4.0)
        self.assertIn(" main 1 sessions", self.render(rows))

    def render(self, rows: list[Any]) -> str:
        text: str = ur.report(
            [ur.Window(None, None)], rows, self.sessions(), "opus", 8, ["n/a"], datetime(2026, 11, 2, tzinfo=UTC)
        )
        return text

    def test_sub_agent_that_switches_model_is_one_sub_agent_in_the_counts(self) -> None:
        self.sub_session(
            "s1",
            "a",
            "Build x",
            [
                line("a", "2026-11-01T10:00:00Z", model=FABLE, inp=1),
                line("b", "2026-11-01T10:01:00Z", model=OPUS, inp=1),
            ],
        )
        rows = ur.build_rows(self.sessions(), [ur.Window(None, None)])
        self.assertEqual(len(rows), 2)
        self.assertIn("sub-agents 1 ", self.render(rows))

    def test_the_pause_before_a_rewrite_is_measured_from_the_previous_turn_of_any_model(self) -> None:
        self.main_session(
            "s1",
            [
                line("a", "2026-11-01T10:00:00Z", model=FABLE, rd=30_000),
                line("b", "2026-11-01T10:29:00Z", model=OPUS, rd=30_000),
                line("c", "2026-11-01T10:30:00Z", model=FABLE, w1=40_000),
            ],
        )
        rows = ur.build_rows(self.sessions(), [ur.Window(None, None)])
        self.assertEqual({r.family: r.rewrites for r in rows}, {"fable": [], "opus": []})

    def test_older_model_ids_are_priced_and_the_headline_says_n_a_when_most_turns_are_not(self) -> None:
        self.main_session(
            "s1",
            [
                line("a", "2026-11-01T10:00:00Z", model="claude-opus-5", inp=1_000_000, out=1_000_000),
                line("b", "2026-11-01T10:01:00Z", model="claude-fable-5-1", inp=1_000_000),
                line("c", "2026-11-01T10:02:00Z", model="claude-sonnet-5", inp=1_000_000),
                line("d", "2026-11-01T10:03:00Z", model="claude-haiku-4-5-20251001", inp=1_000_000),
            ],
        )
        by_family = {r.family: r for r in ur.build_rows(self.sessions(), [ur.Window(None, None)])}
        self.assertEqual({f: r.unpriced_turns for f, r in by_family.items()}, dict.fromkeys(by_family, 0))
        self.assertAlmostEqual(by_family["opus"].dollars, 30.0)
        self.assertAlmostEqual(by_family["fable"].dollars, 10.0)
        self.assertAlmostEqual(by_family["sonnet"].dollars, 2.0)
        self.assertAlmostEqual(by_family["haiku"].dollars, 1.0)

        self.main_session("s2", [line("u", "2026-11-02T10:00:00Z", model="claude-mystery-9", inp=5)])
        window = ur.Window(ur.parse_time("2026-11-02"), None)
        sessions = self.sessions()
        text = ur.report(
            [window], ur.build_rows(sessions, [window]), sessions, "opus", 8, ["n/a"], datetime(2026, 11, 3, tzinfo=UTC)
        )
        self.assertIn("n/a at API prices (1 of 1 turns have no price)", text)
        self.assertIn("main 1 sessions 100% of tokens, n/a;", text)
        self.assertNotIn("$0.00 at API prices", text)

    def test_haiku_above_100k_of_prompt_is_priced_at_the_upper_tier(self) -> None:
        haiku = "claude-haiku-5-5"
        self.main_session(
            "s1",
            [
                line("a", "2026-11-01T10:00:00Z", model=haiku, inp=100_000),
                line("b", "2026-11-01T10:01:00Z", model=haiku, inp=100_001),
            ],
        )
        (row,) = ur.build_rows(self.sessions(), [ur.Window(None, None)])
        self.assertAlmostEqual(row.dollars, 100_000 * 0.10 / 1e6 + 100_001 * 0.50 / 1e6)

    def test_a_reversed_or_empty_window_is_refused(self) -> None:
        for text in ("2026-11-05..2026-11-01", "2026-11-01..2026-11-01"):
            with self.assertRaises(ur.UsageError):
                ur.parse_window(text)
        ur.parse_window("2026-11-01..")
        ur.parse_window("..2026-11-01")

    def test_save_names_files_by_time_and_never_overwrites(self) -> None:
        self.main_session("s1", [line("a", "2026-11-01T10:00:00Z", inp=100)])
        base = ["--projects-dir", str(self.projects), "--repo", str(self.repo), "--no-prs", "--save"]
        old_home = os.environ.get("HOME")
        os.environ["HOME"] = str(self.home)

        def restore() -> None:
            if old_home is None:
                del os.environ["HOME"]
            else:
                os.environ["HOME"] = old_home

        self.addCleanup(restore)
        folder = self.home / ".claude" / "nappy-agent-stats" / "usage" / "2026-11-02"
        folder.mkdir(parents=True)
        (folder / "report.txt").write_text("the hand-made reference")
        first = datetime(2026, 11, 2, 12, 0, 0).astimezone()
        later = datetime(2026, 11, 2, 12, 0, 5).astimezone()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(ur.run(base, first), 0)
            self.assertEqual(ur.run(base, later), 0)
            self.assertEqual(ur.run(base, first), 1, "the same second again is refused")
        self.assertEqual((folder / "report.txt").read_text(), "the hand-made reference")
        self.assertEqual(
            sorted(p.name for p in folder.iterdir() if p.name != "report.txt"),
            [
                f"{first:%H-%M-%S}-report.txt",
                f"{first:%H-%M-%S}-rows.json",
                f"{later:%H-%M-%S}-report.txt",
                f"{later:%H-%M-%S}-rows.json",
            ],
        )

    def test_other_projects_are_not_read(self) -> None:
        other = self.projects / "-some-other-repo"
        other.mkdir()
        (other / "x.jsonl").write_text(line("m1", "2026-11-01T10:00:00Z", inp=1) + "\n")
        self.main_session("s1", [line("m1", "2026-11-01T10:00:00Z", inp=1)])
        self.assertEqual(len(self.sessions()), 1)

    def test_worktree_sessions_share_the_prefix(self) -> None:
        worktree = self.projects / (ur.project_dir_name(self.repo) + "--claude-worktrees-x")
        worktree.mkdir()
        (worktree / "w.jsonl").write_text(line("m2", "2026-11-01T10:00:00Z", inp=1) + "\n")
        self.main_session("s1", [line("m1", "2026-11-01T10:00:00Z", inp=1)])
        self.assertEqual(len(self.sessions()), 2)

    def test_a_long_session_is_split_across_windows(self) -> None:
        self.main_session(
            "s1",
            [
                line("a", "2026-11-01T23:59:00Z", inp=1),
                line("b", "2026-11-02T00:00:00Z", inp=2),
                line("c", "2026-11-02T00:01:00Z", inp=4),
            ],
        )
        windows = [ur.parse_window("2026-11-01T00:00Z..2026-11-02T00:00Z"), ur.parse_window("2026-11-02T00:00Z..")]
        rows = ur.build_rows(self.sessions(), windows)
        self.assertEqual([(r.window, [t.inp for t in r.turns]) for r in rows], [(0, [1]), (1, [2, 4])])

    def test_one_hour_vs_five_minute_writes_and_unaccounted_creation(self) -> None:
        self.main_session("s1", [line("a", "2026-11-01T10:00:00Z", w1=100, w5=50)])
        extra = {
            "type": "assistant",
            "timestamp": "2026-11-01T10:01:00Z",
            "message": {
                "id": "b",
                "model": OPUS,
                "usage": {"cache_creation_input_tokens": 70, "cache_creation": {"ephemeral_1h_input_tokens": 20}},
            },
        }
        with (self.project / "s1.jsonl").open("a") as f:
            f.write(json.dumps(extra) + "\n")
        (session,) = self.sessions()
        a, b = session.turns
        self.assertEqual((a.w1, a.w5), (100, 50))
        self.assertEqual((b.w1, b.w5), (20, 50), "creation tokens the split does not account for count as 5-minute")
        self.assertAlmostEqual(a.weighted(), 2.0 * 100 + 1.25 * 50)

    def test_pricing_and_unpriced_model(self) -> None:
        self.main_session(
            "s1",
            [
                line(
                    "a", "2026-11-01T10:00:00Z", inp=1_000_000, w1=1_000_000, w5=1_000_000, rd=1_000_000, out=1_000_000
                ),
                line("b", "2026-11-01T10:01:00Z", model="claude-mystery-9", inp=5),
            ],
        )
        rows = {r.family: r for r in ur.build_rows(self.sessions(), [ur.Window(None, None)])}
        row = rows["opus"]
        # opus: 4 input + 20 output + 0.2 read + writes 1.25x4 and 2x4
        self.assertAlmostEqual(row.dollars, 4 + 20 + 0.2 + 5 + 8)
        self.assertEqual(rows["claude-mystery-9"].unpriced_turns, 1)
        text = ur.report(
            [ur.Window(None, None)],
            list(rows.values()),
            self.sessions(),
            "opus",
            8,
            ["n/a"],
            datetime(2026, 11, 2, tzinfo=UTC),
        )
        self.assertIn("unpriced models", text)
        self.assertIn("claude-mystery-9", text)
        self.assertNotIn("estimated", text)

    def test_rewrite_rule(self) -> None:
        self.main_session(
            "s1",
            [
                line("a", "2026-11-01T10:00:00Z", w1=30_000),
                line("b", "2026-11-01T10:04:00Z", rd=30_000, inp=10),  # a short pause: no rewrite
                line("c", "2026-11-01T10:30:00Z", w1=40_000, rd=5_000),  # after a pause, mostly written
                line("d", "2026-11-01T10:40:00Z", w1=1_000, rd=60_000),  # after a pause, mostly read
            ],
        )
        (row,) = ur.build_rows(self.sessions(), [ur.Window(None, None)])
        self.assertEqual(row.rewrites, [26 * 60.0])
        self.assertAlmostEqual(row.rewrite_weighted, 80_000)
        self.assertAlmostEqual(row.rewrite_dollars, 4 * 2 * 40_000 / 1e6)

    def test_kinds_by_description(self) -> None:
        self.sub_session("s1", "a", "Build the thing", [line("a", "2026-11-01T10:00:00Z", inp=1)])
        self.sub_session("s1", "b", "Re-review PR 12", [line("b", "2026-11-01T10:00:00Z", inp=1)])
        self.sub_session("s1", "c", "Delta check", [line("c", "2026-11-01T10:00:00Z", inp=1)])
        self.main_session("s1", [line("m", "2026-11-01T10:00:00Z", inp=1)])
        kinds = sorted((s.description, s.kind) for s in self.sessions())
        self.assertEqual(
            kinds,
            [("", "main"), ("Build the thing", "build"), ("Delta check", "review"), ("Re-review PR 12", "review")],
        )

    def test_comparison_column_prices_the_same_tokens_at_the_other_family(self) -> None:
        self.main_session("s1", [line("a", "2026-11-01T10:00:00Z", model=FABLE, inp=1_000_000, out=1_000_000)])
        rows = ur.build_rows(self.sessions(), [ur.Window(None, None)])
        text = ur.report(
            [ur.Window(None, None)], rows, self.sessions(), "opus", 8, ["n/a"], datetime(2026, 11, 2, tzinfo=UTC)
        )
        fable_line = next(ln for ln in text.splitlines() if ln.startswith("  fable"))
        self.assertIn("$48.00", fable_line)  # 8 + 40
        self.assertIn("$24.00", fable_line)  # 4 + 20 at opus prices
        self.assertIn("2.00x", fable_line)
        self.assertIn("For information only", text)
        self.assertIn("at claude-opus-5-5 prices", text)
        self.assertIn("same tokens is an assumption", text)
        self.assertIn("fewer turns and tokens than Opus", text)
        self.assertIn("does work Opus cannot", text)
        self.assertIn("never chosen on this column alone", text)
        sonnet = ur.report(
            [ur.Window(None, None)], rows, self.sessions(), "sonnet", 8, ["n/a"], datetime(2026, 11, 2, tzinfo=UTC)
        )
        self.assertIn("at sonnet", sonnet)

    def test_compactions_are_listed_with_main_or_sub_agent(self) -> None:
        self.main_session(
            "s1", [line("m", "2026-11-01T10:00:00Z", inp=1), compact("2026-11-01T11:00:00Z", 900_000, "manual")]
        )
        self.sub_session(
            "s1", "a", "Build x", [line("a", "2026-11-01T10:00:00Z", inp=1), compact("2026-11-01T12:00:00Z", 950_000)]
        )
        sessions = self.sessions()
        rows = ur.build_rows(sessions, [ur.Window(None, None)])
        text = ur.report([ur.Window(None, None)], rows, sessions, "opus", 8, ["n/a"], datetime(2026, 11, 2, tzinfo=UTC))
        self.assertIn("compactions: 2 (1 main, 1 sub-agent)", text)
        self.assertIn("900k main", text)
        self.assertIn("950k sub-agent", text)

    def test_pr_lookup_failures_are_none(self) -> None:
        window = ur.Window(None, None)

        def missing(*_: Any, **__: Any) -> Any:
            raise FileNotFoundError("gh")

        def failing(*_: Any, **__: Any) -> Any:
            return subprocess.CompletedProcess([], 1, "", "boom")

        def counting(cmd: list[str], **_: Any) -> Any:
            self.assertIn("merged:*..*", cmd)
            return subprocess.CompletedProcess(cmd, 0, json.dumps([{"number": 1}, {"number": 2}]), "")

        self.assertIsNone(ur.count_merged_prs(window, self.home, missing))
        self.assertIsNone(ur.count_merged_prs(window, self.home, failing))
        self.assertEqual(ur.count_merged_prs(window, self.home, counting), 2)

    def run_cli(self, *args: str, home: Path | None = None) -> subprocess.CompletedProcess[str]:
        env = dict(os.environ, HOME=str(home or self.home), PATH="/nonexistent")
        return subprocess.run([sys.executable, str(TOOL), *args], capture_output=True, text=True, env=env, check=False)

    def test_cli_end_to_end_with_a_missing_gh_save_and_json(self) -> None:
        self.main_session("s1", [line("a", "2026-11-01T10:00:00Z", inp=100, out=10)])
        base = ("--projects-dir", str(self.projects), "--repo", str(self.repo), "--window", "2026-11-01..2026-11-03")
        done = self.run_cli(*base, "--save")
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertIn("merged PRs n/a", done.stdout)
        saved = list((self.home / ".claude" / "nappy-agent-stats" / "usage").glob("*/*-report.txt"))
        self.assertEqual(len(saved), 1)
        self.assertTrue(saved[0].with_name(saved[0].name.replace("report.txt", "rows.json")).exists())
        as_json = self.run_cli(*base, "--json")
        self.assertEqual(json.loads(as_json.stdout)[0]["turns"], 1)
        skipped = self.run_cli(*base, "--no-prs")
        self.assertIn("n/a (skipped)", skipped.stdout)

    def test_help_and_unknown_arguments(self) -> None:
        for flag in ("--help", "-h"):
            done = self.run_cli(flag)
            self.assertEqual(done.returncode, 0)
            self.assertIn("usage: tools/usage-report.py", done.stdout)
        for bad in (
            ["--nope"],
            ["stray"],
            ["--window"],
            ["--window", "x"],
            ["--window", "2026-11-05..2026-11-01"],
            ["--compare-to", "gpt"],
            ["--top", "0"],
        ):
            done = self.run_cli(*bad)
            self.assertEqual(done.returncode, 2, bad)
            self.assertIn("usage:", done.stderr)
            self.assertEqual(done.stdout, "")
        self.assertFalse((self.home / ".claude").exists(), "a rejected run writes nothing")


if __name__ == "__main__":
    unittest.main()
