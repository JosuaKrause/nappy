#!/usr/bin/env python3
"""Offline tests for the GoatCounter readback tool: no test here may reach the network or need a
key, per M209's brief. Grouping and formatting are exercised as pure functions over a fixture
shaped like the real API response; pagination is exercised against a fake fetcher; the missing-key
refusal is exercised through main() with a mocked fetcher that would fail the test if it were ever
called.
"""

from __future__ import annotations

import importlib.util
import io
import tempfile
import unittest
import urllib.error
import urllib.parse
from collections.abc import Callable
from contextlib import redirect_stderr, redirect_stdout
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, ClassVar
from unittest import mock

SPEC = importlib.util.spec_from_file_location("goatcounter", Path(__file__).with_name("goatcounter.py"))
assert SPEC and SPEC.loader
goatcounter = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(goatcounter)


def hit(path: str, count: int, path_id: int, *, event: bool = True) -> dict[str, Any]:
    return {"path": path, "path_id": path_id, "count": count, "event": event, "stats": []}


def line_with(lines: list[str], needle: str) -> str:
    return next(line for line in lines if needle in line)


class TimeTests(unittest.TestCase):
    def test_round_to_hour_floors_and_assumes_utc(self) -> None:
        moment = datetime(2026, 9, 26, 14, 37, 52, 123)
        rounded = goatcounter.round_to_hour(moment)
        self.assertEqual(rounded, datetime(2026, 9, 26, 14, 0, 0, tzinfo=UTC))

    def test_rfc3339_formats_as_z(self) -> None:
        moment = datetime(2026, 9, 26, 14, 0, tzinfo=UTC)
        self.assertEqual(goatcounter.rfc3339(moment), "2026-09-26T14:00:00Z")

    def test_parse_moment_accepts_bare_date_and_rfc3339(self) -> None:
        self.assertEqual(
            goatcounter.parse_moment("2026-09-01"),
            datetime(2026, 9, 1, tzinfo=UTC),
        )
        self.assertEqual(
            goatcounter.parse_moment("2026-09-01T05:00:00Z"),
            datetime(2026, 9, 1, 5, 0, tzinfo=UTC),
        )

    def test_parse_moment_rejects_garbage(self) -> None:
        with self.assertRaises(goatcounter.GoatCounterError):
            goatcounter.parse_moment("not a date")


class DotenvTests(unittest.TestCase):
    def test_parses_key_value_pairs_ignoring_blanks_and_comments(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / ".env").write_text(
                "\n".join(
                    [
                        "# a comment",
                        "",
                        "GOATCOUNTER_TOKEN=abc123",
                        "  GOATCOUNTER_SITE = https://example.goatcounter.com/api/v0/  ",
                        "QUOTED='single quoted'",
                        'DQUOTED="double quoted"',
                        "not a valid line",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            values = goatcounter._parse_dotenv(root / ".env")
            self.assertEqual(values["GOATCOUNTER_TOKEN"], "abc123")
            self.assertEqual(values["GOATCOUNTER_SITE"], "https://example.goatcounter.com/api/v0/")
            self.assertEqual(values["QUOTED"], "single quoted")
            self.assertEqual(values["DQUOTED"], "double quoted")
            self.assertNotIn("not a valid line", "".join(values))

    def test_a_missing_dotenv_file_parses_as_empty(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            self.assertEqual(goatcounter._parse_dotenv(Path(temp) / "no-such-file.env"), {})

    def test_env_or_dotenv_reads_the_file_when_the_process_environment_is_unset(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / ".env").write_text("GOATCOUNTER_TOKEN=from-dotenv\n", encoding="utf-8")
            with mock.patch.dict("os.environ", {}, clear=True):
                self.assertEqual(goatcounter.env_or_dotenv("GOATCOUNTER_TOKEN", root=root), "from-dotenv")

    def test_env_or_dotenv_prefers_the_process_environment_over_the_file(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / ".env").write_text("GOATCOUNTER_TOKEN=from-dotenv\n", encoding="utf-8")
            with mock.patch.dict("os.environ", {"GOATCOUNTER_TOKEN": "from-process"}, clear=True):
                self.assertEqual(goatcounter.env_or_dotenv("GOATCOUNTER_TOKEN", root=root), "from-process")

    def test_env_or_dotenv_is_none_when_neither_has_it(self) -> None:
        with tempfile.TemporaryDirectory() as temp, mock.patch.dict("os.environ", {}, clear=True):
            self.assertIsNone(goatcounter.env_or_dotenv("GOATCOUNTER_TOKEN", root=Path(temp)))

    def _worktree_layout(self, temp: str) -> tuple[Path, Path]:
        # The layout `git worktree add` leaves: the main checkout's .git directory holds
        # worktrees/<name>/commondir ("../.."), and the worktree's .git is a file pointing there.
        main = Path(temp) / "main"
        gitdir = main / ".git" / "worktrees" / "wt"
        gitdir.mkdir(parents=True)
        (gitdir / "commondir").write_text("../..\n", encoding="utf-8")
        worktree = main / ".claude" / "worktrees" / "wt"
        worktree.mkdir(parents=True)
        (worktree / ".git").write_text(f"gitdir: {gitdir}\n", encoding="utf-8")
        return main, worktree

    def test_env_or_dotenv_in_a_worktree_falls_back_to_the_main_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as temp, mock.patch.dict("os.environ", {}, clear=True):
            main, worktree = self._worktree_layout(temp)
            (main / ".env").write_text("GOATCOUNTER_TOKEN=from-main\n", encoding="utf-8")
            self.assertEqual(goatcounter.env_or_dotenv("GOATCOUNTER_TOKEN", root=worktree), "from-main")
            (worktree / ".env").write_text("GOATCOUNTER_TOKEN=from-worktree\n", encoding="utf-8")
            self.assertEqual(goatcounter.env_or_dotenv("GOATCOUNTER_TOKEN", root=worktree), "from-worktree")

    def test_main_checkout_is_none_outside_a_worktree(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            main, _worktree = self._worktree_layout(temp)
            self.assertIsNone(goatcounter._main_checkout(main))
            self.assertIsNone(goatcounter._main_checkout(Path(temp)))

    def test_main_checkout_is_none_when_the_shared_directory_is_not_a_dot_git(self) -> None:
        # A worktree of a bare repository (or of one made with --separate-git-dir): commondir
        # names a directory that is not `<checkout>/.git`, so its parent is no checkout, and a
        # `.env` beside it is never read.
        with tempfile.TemporaryDirectory() as temp, mock.patch.dict("os.environ", {}, clear=True):
            bare = Path(temp) / "shared" / "repo.git"
            gitdir = bare / "worktrees" / "wt"
            gitdir.mkdir(parents=True)
            (gitdir / "commondir").write_text("../..\n", encoding="utf-8")
            worktree = Path(temp) / "wt"
            worktree.mkdir()
            (worktree / ".git").write_text(f"gitdir: {gitdir}\n", encoding="utf-8")
            (bare.parent / ".env").write_text("GOATCOUNTER_TOKEN=unrelated\n", encoding="utf-8")
            self.assertIsNone(goatcounter._main_checkout(worktree))
            self.assertIsNone(goatcounter.env_or_dotenv("GOATCOUNTER_TOKEN", root=worktree))


class ClassifyTests(unittest.TestCase):
    def test_run_level_shapes(self) -> None:
        for name in ("run-fresh", "run-resumed-day-3", "ending-good", "escape-out", "controls-tap"):
            with self.subTest(name=name):
                self.assertEqual(goatcounter.classify(name), goatcounter.Classified("run", name))

    def test_day_shape(self) -> None:
        self.assertEqual(
            goatcounter.classify("day-6-lost-crying"),
            goatcounter.Classified("day", "day-6-lost-crying", 6, "lost-crying"),
        )
        # classify() only splits off the day number -- it does not know or care that the rest is
        # a lost-* shape; split_losses() is what reads that further, downstream in format_text.
        self.assertEqual(
            goatcounter.classify("day-14-lost-hard-fail-charging-dog"),
            goatcounter.Classified("day", "day-14-lost-hard-fail-charging-dog", 14, "lost-hard-fail-charging-dog"),
        )

    def test_other_shape(self) -> None:
        self.assertEqual(
            goatcounter.classify("something-else-entirely"),
            goatcounter.Classified("other", "something-else-entirely"),
        )


class GroupHitsTests(unittest.TestCase):
    def test_groups_run_level_day_and_other_and_drops_the_rest(self) -> None:
        hits = [
            hit("nappy-run-fresh", 42, 1),
            hit("nappy-ending-good", 9, 2),
            hit("nappy-day-1-began", 50, 3),
            hit("nappy-day-1-won", 45, 4),
            hit("nappy-day-1-lost-crying", 5, 5),
            hit("nappy-day-6-mark-seen", 12, 6),
            hit("nappy-oddly-shaped-thing", 3, 7),
            # Not the prefix at all -- the game's own page-load path, e.g. -- must be excluded.
            hit("josuakrause.github.io/nappy", 1000, 8, event=False),
        ]
        grouped = goatcounter.group_hits(hits, "nappy-")
        self.assertEqual(grouped["run_level"], {"run-fresh": 42, "ending-good": 9})
        self.assertEqual(
            grouped["days"],
            {1: {"began": 50, "won": 45, "lost-crying": 5}, 6: {"mark-seen": 12}},
        )
        self.assertEqual(grouped["other"], {"oddly-shaped-thing": 3})

    def test_a_custom_prefix_is_honoured(self) -> None:
        hits = [hit("other-run-fresh", 7, 1), hit("nappy-run-fresh", 99, 2)]
        grouped = goatcounter.group_hits(hits, "other-")
        self.assertEqual(grouped["run_level"], {"run-fresh": 7})

    def test_repeated_names_sum_rather_than_overwrite(self) -> None:
        # Two pages should not happen for the same path in practice (exclude_paths prevents it),
        # but grouping itself stays additive rather than assuming it never will.
        hits = [hit("nappy-day-2-began", 10, 1), hit("nappy-day-2-began", 5, 1)]
        grouped = goatcounter.group_hits(hits, "nappy-")
        self.assertEqual(grouped["days"], {2: {"began": 15}})


class SplitLossesTests(unittest.TestCase):
    """`split_losses()` is the pure function `format_text` folds a day's own `lost-*` keys through --
    VisitCounter._loss_event_suffix()'s shape, `lost-crying-<cause>` / `lost-hard-fail-<cause>` /
    `lost-timeout` (never a cause), plus the old two-event shape's bare `lost-crying` /
    `lost-hard-fail` (no cause, one playthrough, from before the fold).
    """

    def test_splits_causes_under_their_own_kind_and_sums_a_subtotal_per_kind(self) -> None:
        bucket = {
            "began": 20,
            "won": 12,
            "lost-crying-traffic": 2,
            "lost-crying-alley-robbery": 2,
            "lost-hard-fail-car": 1,
            "lost-hard-fail-alley-robbery": 3,
            "lost-timeout": 2,
        }
        split = goatcounter.split_losses(bucket)
        self.assertEqual(split.totals, {"crying": 4, "hard-fail": 4, "timeout": 2})
        self.assertEqual(
            split.causes,
            {"crying": {"traffic": 2, "alley-robbery": 2}, "hard-fail": {"car": 1, "alley-robbery": 3}},
        )
        self.assertEqual(
            split.consumed,
            {
                "lost-crying-traffic",
                "lost-crying-alley-robbery",
                "lost-hard-fail-car",
                "lost-hard-fail-alley-robbery",
                "lost-timeout",
            },
        )
        # "began" and "won" are never a loss and are left for the caller's own leftover pass.
        self.assertNotIn("began", split.consumed)
        self.assertNotIn("won", split.consumed)

    def test_the_old_bare_shape_folds_into_its_kind_subtotal_with_no_cause_line_of_its_own(self) -> None:
        # One playthrough's own old two-event shape (per the player: "the old version only affects
        # one playthrough") -- no special handling beyond still being listed, which the subtotal
        # already does.
        split = goatcounter.split_losses({"began": 5, "lost-crying": 3})
        self.assertEqual(split.totals, {"crying": 3})
        self.assertEqual(split.causes, {})
        self.assertIn("lost-crying", split.consumed)

    def test_a_kind_with_no_hits_at_all_is_simply_absent(self) -> None:
        split = goatcounter.split_losses({"began": 5, "won": 5})
        self.assertEqual(split.totals, {})
        self.assertEqual(split.causes, {})
        self.assertEqual(split.consumed, set())


class FormatTextTests(unittest.TestCase):
    def setUp(self) -> None:
        self.start = datetime(2026, 8, 27, tzinfo=UTC)
        self.end = datetime(2026, 9, 26, tzinfo=UTC)

    def test_header_names_site_and_range(self) -> None:
        grouped = goatcounter.group_hits([], "nappy-")
        text = goatcounter.format_text(
            grouped, site="https://example.goatcounter.com/api/v0/", start=self.start, end=self.end, prefix="nappy-"
        )
        self.assertIn("https://example.goatcounter.com/api/v0/", text)
        self.assertIn("2026-08-27T00:00:00Z", text)
        self.assertIn("2026-09-26T00:00:00Z", text)

    def test_a_note_says_counts_are_attempts_not_visitors(self) -> None:
        # Every event opts out of the site's sessions, so one person losing day 6 twice and winning it
        # on the third attempt sends began three times; the header says so before the first day's counts.
        grouped = goatcounter.group_hits(
            [
                hit("nappy-day-6-began", 1, 1),
                hit("nappy-day-6-lost-crying", 1, 2),
                hit("nappy-day-6-lost-hard-fail", 1, 3),
                hit("nappy-day-6-won", 1, 4),
            ],
            "nappy-",
        )
        text = goatcounter.format_text(grouped, site="s", start=self.start, end=self.end, prefix="nappy-")
        self.assertIn("attempts, not visitors", text)
        self.assertLess(text.index("attempts, not visitors"), text.index("Day 6:"))

    def test_began_comes_first_and_rest_sorts_by_count_descending_with_percentage(self) -> None:
        hits = [
            hit("nappy-day-3-began", 100, 1),
            hit("nappy-day-3-lost-crying", 10, 2),
            hit("nappy-day-3-won", 80, 3),
            hit("nappy-day-3-lost-timeout", 5, 4),
        ]
        grouped = goatcounter.group_hits(hits, "nappy-")
        text = goatcounter.format_text(grouped, site="s", start=self.start, end=self.end, prefix="nappy-")
        day_block = text.split("Day 3:")[1].split("\n\n")[0]
        lines = [line for line in day_block.splitlines() if line.strip()]

        self.assertIn("began: 100", lines[0])
        # won (80) outranks lost-crying (10) outranks lost-timeout (5).
        self.assertLess(lines.index(line_with(lines, "won")), lines.index(line_with(lines, "lost-crying")))
        self.assertIn("80.0% of began", line_with(lines, "won"))
        self.assertIn("5.0% of began", line_with(lines, "lost-timeout"))

    def test_days_print_in_numeric_order_not_first_seen_order(self) -> None:
        hits = [hit("nappy-day-10-began", 1, 1), hit("nappy-day-2-began", 1, 2)]
        grouped = goatcounter.group_hits(hits, "nappy-")
        text = goatcounter.format_text(grouped, site="s", start=self.start, end=self.end, prefix="nappy-")
        self.assertLess(text.index("Day 2:"), text.index("Day 10:"))

    def test_a_day_with_no_began_shows_bare_counts(self) -> None:
        hits = [hit("nappy-day-6-mark-seen", 4, 1)]
        grouped = goatcounter.group_hits(hits, "nappy-")
        text = goatcounter.format_text(grouped, site="s", start=self.start, end=self.end, prefix="nappy-")
        self.assertIn("nappy-day-6-mark-seen: 4", text)
        self.assertNotIn("% of began", text)

    def test_unmatched_shapes_are_listed_at_the_end_rather_than_dropped(self) -> None:
        hits = [hit("nappy-run-fresh", 1, 1), hit("nappy-strange-one-off", 2, 2)]
        grouped = goatcounter.group_hits(hits, "nappy-")
        text = goatcounter.format_text(grouped, site="s", start=self.start, end=self.end, prefix="nappy-")
        self.assertIn("nappy-strange-one-off: 2", text)
        self.assertGreater(text.index("nappy-strange-one-off"), text.index("Run-level:"))

    def test_to_jsonable_round_trips_through_json(self) -> None:
        import json

        hits = [hit("nappy-day-1-began", 3, 1), hit("nappy-run-fresh", 1, 2)]
        grouped = goatcounter.group_hits(hits, "nappy-")
        payload = json.loads(json.dumps(goatcounter.to_jsonable(grouped)))
        self.assertEqual(payload["days"]["1"]["began"], 3)
        self.assertEqual(payload["run_level"]["run-fresh"], 1)

    def test_losses_group_under_one_lost_heading_with_a_subtotal_per_kind_and_the_causes_under_it(
        self,
    ) -> None:
        hits = [
            hit("nappy-day-7-began", 20, 1),
            hit("nappy-day-7-won", 12, 2),
            hit("nappy-day-7-lost-crying-traffic", 2, 3),
            hit("nappy-day-7-lost-crying-alley-robbery", 2, 4),
            hit("nappy-day-7-lost-hard-fail-car", 1, 5),
            hit("nappy-day-7-lost-hard-fail-alley-robbery", 3, 6),
            hit("nappy-day-7-lost-timeout", 2, 7),
        ]
        grouped = goatcounter.group_hits(hits, "nappy-")
        text = goatcounter.format_text(grouped, site="s", start=self.start, end=self.end, prefix="nappy-")
        day_block = text.split("Day 7:")[1].split("\n\n")[0]
        lines = [line for line in day_block.splitlines() if line.strip()]
        # One "Lost:" heading, not a lost-crying line beside a lost-hard-fail line of its own --
        # the double counting the player asked to see gone.
        self.assertEqual(sum(1 for line in lines if line.strip().startswith("Lost:")), 1)
        self.assertIn("Lost: 10 (50.0% of began)", "\n".join(lines))
        self.assertIn("nappy-day-7-lost-crying: 4 (20.0% of began)", "\n".join(lines))
        self.assertIn("nappy-day-7-lost-hard-fail: 4 (20.0% of began)", "\n".join(lines))
        self.assertIn("nappy-day-7-lost-timeout: 2 (10.0% of began)", "\n".join(lines))
        self.assertIn("nappy-day-7-lost-crying-traffic: 2 (10.0% of began)", "\n".join(lines))
        self.assertIn("nappy-day-7-lost-crying-alley-robbery: 2 (10.0% of began)", "\n".join(lines))
        self.assertIn("nappy-day-7-lost-hard-fail-car: 1 (5.0% of began)", "\n".join(lines))
        self.assertIn("nappy-day-7-lost-hard-fail-alley-robbery: 3 (15.0% of began)", "\n".join(lines))
        # The heading sorts among won and everything else by its own total (10), same as any other
        # entry -- here behind won (12) and ahead of nothing else in this fixture.
        self.assertLess(lines.index(line_with(lines, "won")), lines.index(line_with(lines, "Lost:")))

    def test_the_pelican_events_read_back_under_their_day_and_its_loss_as_a_cause(self) -> None:
        # The pelican's own four events and a day lost to it (inbox #527 in azure-tapir: "it must appear as its own
        # entry"), in VisitCounter's day-numbered shape -- listed under the day they were sent on,
        # never among the names that match none of the known shapes.
        hits = [
            hit("nappy-day-4-began", 10, 1),
            hit("nappy-day-4-pelican-spawned", 2, 2),
            hit("nappy-day-4-pelican-seen", 2, 3),
            hit("nappy-day-4-pelican-excited", 1, 4),
            hit("nappy-day-4-pelican-hit", 1, 5),
            hit("nappy-day-4-lost-hard-fail-pelican", 1, 6),
        ]
        grouped = goatcounter.group_hits(hits, "nappy-")
        self.assertEqual(grouped["other"], {})
        text = goatcounter.format_text(grouped, site="s", start=self.start, end=self.end, prefix="nappy-")
        self.assertNotIn("none of the known shapes", text)
        day_block = text.split("Day 4:")[1].split("\n\n")[0]
        for name, count in (("spawned", 2), ("seen", 2), ("excited", 1), ("hit", 1)):
            self.assertIn(f"nappy-day-4-pelican-{name}: {count}", day_block)
        self.assertIn("nappy-day-4-lost-hard-fail-pelican: 1 (10.0% of began)", day_block)

    def test_the_old_bare_shape_is_still_listed_folded_into_its_kind_subtotal(self) -> None:
        # One playthrough's own old two-event shape (per the player: "the old version only affects
        # one playthrough") -- no cause line of its own, but not dropped either.
        hits = [hit("nappy-day-2-began", 5, 1), hit("nappy-day-2-lost-crying", 3, 2)]
        grouped = goatcounter.group_hits(hits, "nappy-")
        text = goatcounter.format_text(grouped, site="s", start=self.start, end=self.end, prefix="nappy-")
        self.assertIn("Lost: 3 (60.0% of began)", text)
        self.assertIn("nappy-day-2-lost-crying: 3 (60.0% of began)", text)


class EncounterTableTests(unittest.TestCase):
    """`--encounters`: influenced / seen per event type, overall and by day, on canned hits."""

    HITS: ClassVar[list[dict[str, Any]]] = [
        hit("nappy-day-2-seen-homeless-yeller", 4, 1),
        hit("nappy-day-2-influenced-homeless-yeller", 1, 2),
        hit("nappy-day-2-influenced-unseen-homeless-yeller", 2, 3),
        hit("nappy-day-3-seen-homeless-yeller", 6, 4),
        hit("nappy-day-3-influenced-homeless-yeller", 3, 5),
        hit("nappy-day-3-seen-charging-dog", 0, 6),
        hit("nappy-day-3-influenced-unseen-pelican", 1, 7),
        hit("nappy-day-3-seen-fire", 1, 8),
        hit("nappy-day-3-began", 10, 9),
        hit("nappy-day-3-ran", 7, 10),
    ]

    def table(self) -> dict[str, Any]:
        table: dict[str, Any] = goatcounter.encounter_table(goatcounter.group_hits(self.HITS, "nappy-"))
        return table

    def test_overall_sums_the_days_and_divides_influenced_by_seen(self) -> None:
        yeller = self.table()["overall"]["homeless-yeller"]
        self.assertEqual((yeller["seen"], yeller["influenced"], yeller["influenced-unseen"]), (10, 4, 2))
        self.assertAlmostEqual(yeller["ratio"], 0.4)

    def test_each_day_has_its_own_rows(self) -> None:
        days = self.table()["days"]
        self.assertEqual(list(days), [2, 3])
        self.assertAlmostEqual(days[2]["homeless-yeller"]["ratio"], 0.25)
        self.assertAlmostEqual(days[3]["homeless-yeller"]["ratio"], 0.5)

    def test_the_unseen_influences_stay_out_of_the_ratio_and_nothing_seen_leaves_it_blank(self) -> None:
        overall = self.table()["overall"]
        self.assertEqual(overall["pelican"]["influenced-unseen"], 1)
        self.assertEqual(overall["pelican"]["influenced"], 0)
        self.assertIsNone(overall["pelican"]["ratio"])
        self.assertIsNone(overall["charging-dog"]["ratio"])

    def test_the_fires_older_sighting_and_the_rest_of_the_day_are_not_encounters(self) -> None:
        overall = self.table()["overall"]
        self.assertEqual(sorted(overall), ["charging-dog", "homeless-yeller", "pelican"])

    def test_the_printout_has_a_row_per_event_with_its_ratio(self) -> None:
        text = goatcounter.format_encounters(
            self.table(),
            site="s",
            start=datetime(2026, 10, 1, tzinfo=UTC),
            end=datetime(2026, 10, 5, tzinfo=UTC),
            prefix="nappy-",
        )
        lines = text.splitlines()
        overall = lines.index("Overall:")
        day_3 = lines.index("Day 3:")
        self.assertLess(overall, lines.index("Day 2:"))
        yeller_overall = line_with(lines[overall:], "homeless-yeller").split()
        self.assertEqual(yeller_overall, ["homeless-yeller", "10", "4", "0.40", "2"])
        yeller_day_3 = line_with(lines[day_3:], "homeless-yeller").split()
        self.assertEqual(yeller_day_3, ["homeless-yeller", "6", "3", "0.50", "0"])
        self.assertEqual(line_with(lines[overall:], "pelican").split(), ["pelican", "0", "0", "1"])

    def test_main_prints_the_table_for_the_flag_and_json_with_it(self) -> None:
        import json

        for argv in (["--encounters"], ["--encounters", "--json"]):
            stdout, stderr = io.StringIO(), io.StringIO()
            with (
                mock.patch.dict("os.environ", {"GOATCOUNTER_TOKEN": "secret"}, clear=True),
                mock.patch.object(
                    goatcounter, "make_fetcher", return_value=lambda _params: {"hits": self.HITS, "more": False}
                ),
                redirect_stdout(stdout),
                redirect_stderr(stderr),
            ):
                code = goatcounter.main(argv)
            self.assertEqual(code, 0, stderr.getvalue())
            if "--json" in argv:
                payload = json.loads(stdout.getvalue())
                self.assertAlmostEqual(payload["days"]["3"]["homeless-yeller"]["ratio"], 0.5)
            else:
                self.assertIn("Overall:", stdout.getvalue())
                self.assertNotIn("began", stdout.getvalue())


class FetchHitsTests(unittest.TestCase):
    def test_pages_with_exclude_paths_until_more_is_false(self) -> None:
        calls: list[dict[str, Any]] = []

        def fetch(params: dict[str, Any]) -> dict[str, Any]:
            calls.append(dict(params))
            if len(calls) == 1:
                return {"hits": [hit("nappy-a", 1, 1), hit("nappy-b", 2, 2)], "more": True, "total": 3}
            return {"hits": [hit("nappy-c", 3, 3)], "more": False, "total": 3}

        start = datetime(2026, 9, 1, tzinfo=UTC)
        end = datetime(2026, 9, 2, tzinfo=UTC)
        hits = goatcounter.fetch_hits(fetch, start, end)
        self.assertEqual([h["path"] for h in hits], ["nappy-a", "nappy-b", "nappy-c"])
        self.assertEqual(len(calls), 2)
        self.assertNotIn("exclude_paths", calls[0])
        # One comma-separated value: the server honours only the first of a repeated parameter.
        self.assertEqual(calls[1]["exclude_paths"], "1,2")

    def test_a_path_the_server_repeats_is_counted_once(self) -> None:
        pages = iter(
            [
                {"hits": [hit("nappy-a", 1, 1), hit("nappy-b", 2, 2)], "more": True},
                {"hits": [hit("nappy-b", 2, 2), hit("nappy-c", 3, 3)], "more": False},
            ]
        )
        hits = goatcounter.fetch_hits(
            lambda _p: next(pages), datetime(2026, 9, 1, tzinfo=UTC), datetime(2026, 9, 2, tzinfo=UTC)
        )
        self.assertEqual([h["path"] for h in hits], ["nappy-a", "nappy-b", "nappy-c"])

    def test_a_page_of_only_repeats_stops_the_paging(self) -> None:
        calls: list[int] = []

        def fetch(_params: dict[str, Any]) -> dict[str, Any]:
            calls.append(1)
            return {"hits": [hit("nappy-a", 1, 1)], "more": True}

        hits = goatcounter.fetch_hits(fetch, datetime(2026, 9, 1, tzinfo=UTC), datetime(2026, 9, 2, tzinfo=UTC))
        self.assertEqual(len(hits), 1)
        self.assertEqual(len(calls), 2)

    def test_thousands_of_paths_page_to_the_end_with_a_query_the_server_accepts(self) -> None:
        total = 3000
        queries: list[int] = []

        def fetch(params: dict[str, Any]) -> dict[str, Any]:
            excluded = {int(i) for i in str(params.get("exclude_paths", "")).split(",") if i}
            rest = [i for i in range(1, total + 1) if i not in excluded]
            queries.append(len(urllib.parse.urlencode(params, safe=",")))
            page = rest[: params["limit"]]
            return {"hits": [hit(f"nappy-{i}", 1, i) for i in page], "more": len(rest) > len(page)}

        hits = goatcounter.fetch_hits(fetch, datetime(2026, 9, 1, tzinfo=UTC), datetime(2026, 9, 2, tzinfo=UTC))
        self.assertEqual(len(hits), total)
        self.assertLess(max(queries), goatcounter.MAX_QUERY_BYTES)

    def test_a_query_past_the_servers_limit_is_refused_with_the_way_out(self) -> None:
        fetch = goatcounter.make_fetcher("https://example.goatcounter.com/api/v0/", "k")
        with self.assertRaises(goatcounter.GoatCounterError) as ctx:
            fetch({"exclude_paths": ",".join(str(100_000_000 + i) for i in range(4000))})
        self.assertIn("narrow the range", str(ctx.exception))

    def test_stops_rather_than_looping_forever_if_more_is_true_with_nothing_new(self) -> None:
        def fetch(_params: dict[str, Any]) -> dict[str, Any]:
            return {"hits": [], "more": True, "total": 0}

        start = datetime(2026, 9, 1, tzinfo=UTC)
        end = datetime(2026, 9, 2, tzinfo=UTC)
        self.assertEqual(goatcounter.fetch_hits(fetch, start, end), [])

    def test_a_page_with_no_path_id_to_page_past_is_an_error_not_a_short_count(self) -> None:
        def fetch(_params: dict[str, Any]) -> dict[str, Any]:
            return {"hits": [{"path": "nappy-a", "count": 1, "event": True, "stats": []}], "more": True}

        start = datetime(2026, 9, 1, tzinfo=UTC)
        end = datetime(2026, 9, 2, tzinfo=UTC)
        with self.assertRaises(goatcounter.GoatCounterError) as ctx:
            goatcounter.fetch_hits(fetch, start, end)
        self.assertIn("path_id", str(ctx.exception))

    def test_a_malformed_response_is_an_actionable_error(self) -> None:
        def fetch(_params: dict[str, Any]) -> dict[str, Any]:
            return {"total": 0}

        start = datetime(2026, 9, 1, tzinfo=UTC)
        end = datetime(2026, 9, 2, tzinfo=UTC)
        with self.assertRaises(goatcounter.GoatCounterError):
            goatcounter.fetch_hits(fetch, start, end)


class GetRetryTests(unittest.TestCase):
    """_get against an opener that answers from a script, with the sleeping stubbed out."""

    def opener(self, script: list[Any]) -> Any:
        steps = iter(script)

        def open_(_request: Any, timeout: float = 0) -> Any:
            step = next(steps)
            if isinstance(step, BaseException):
                raise step
            response = mock.MagicMock()
            response.__enter__.return_value.read.return_value = step
            return response

        return mock.Mock(open=open_)

    def test_a_dropped_connection_is_retried_and_then_succeeds(self) -> None:
        import http.client

        opener = self.opener([http.client.RemoteDisconnected("closed"), b'{"hits": []}'])
        with mock.patch.object(goatcounter.time, "sleep"):
            self.assertEqual(goatcounter._get(opener, "https://x/y", "k"), {"hits": []})

    def test_a_connection_that_keeps_dropping_fails_after_the_retries(self) -> None:
        import http.client

        opener = self.opener([http.client.RemoteDisconnected("closed")] * (goatcounter.MAX_RETRIES + 1))
        with mock.patch.object(goatcounter.time, "sleep"), self.assertRaises(goatcounter.GoatCounterError):
            goatcounter._get(opener, "https://x/y", "k")

    def test_a_429_is_retried(self) -> None:
        error = urllib.error.HTTPError("https://x/y", 429, "slow down", mock.Mock(), io.BytesIO(b"rate limited"))
        self.addCleanup(error.close)
        opener = self.opener([error, b'{"ok": 1}'])
        with mock.patch.object(goatcounter.time, "sleep"):
            self.assertEqual(goatcounter._get(opener, "https://x/y", "k"), {"ok": 1})

    def test_a_real_error_carries_the_servers_own_answer_and_not_the_query(self) -> None:
        error = urllib.error.HTTPError(
            "https://x/y?secret=1", 400, "Bad Request", mock.Mock(), io.BytesIO(b'{"error": "bad start"}')
        )
        self.addCleanup(error.close)
        with self.assertRaises(goatcounter.GoatCounterHTTPError) as ctx:
            goatcounter._get(self.opener([error]), "https://x/y?secret=1", "k")
        self.assertIn("bad start", str(ctx.exception))
        self.assertEqual(ctx.exception.status, 400)
        self.assertNotIn("secret", str(ctx.exception))


class RawModeTests(unittest.TestCase):
    def test_format_raw_lists_every_path_regardless_of_prefix_sorted_by_count(self) -> None:
        hits = [
            hit("nappy-day-1-began", 5, 1, event=True),
            hit("josuakrause.github.io/nappy", 50, 2, event=False),
            hit("nappy-run-fresh", 20, 3, event=True),
        ]
        start = datetime(2026, 9, 1, tzinfo=UTC)
        end = datetime(2026, 9, 2, tzinfo=UTC)
        text = goatcounter.format_raw(hits, site="s", start=start, end=end)
        # The page load (50) outranks run-fresh (20) outranks began (5) -- --raw does not filter.
        self.assertLess(text.index("josuakrause.github.io/nappy"), text.index("nappy-run-fresh"))
        self.assertLess(text.index("nappy-run-fresh"), text.index("nappy-day-1-began"))
        self.assertIn("[page]", text)
        self.assertIn("[event]", text)

    def test_format_raw_says_so_when_the_range_is_empty(self) -> None:
        start = datetime(2026, 9, 1, tzinfo=UTC)
        end = datetime(2026, 9, 2, tzinfo=UTC)
        self.assertIn("no hits", goatcounter.format_raw([], site="s", start=start, end=end))

    def test_to_raw_jsonable_round_trips(self) -> None:
        import json

        hits = [hit("nappy-run-fresh", 2, 1, event=True), hit("page", 9, 2, event=False)]
        payload = json.loads(json.dumps(goatcounter.to_raw_jsonable(hits)))
        self.assertEqual(
            payload,
            [{"path": "nappy-run-fresh", "count": 2, "event": True}, {"path": "page", "count": 9, "event": False}],
        )


class CheckKeyTests(unittest.TestCase):
    """Offline tests for check_key's three required shapes: stats OK + /me 200, stats OK + /me 404,
    and stats 401 (the real failure) -- plus format_check never printing a key.
    """

    def stats_ok(self, calls: list[tuple[str, str, datetime, datetime]] | None = None) -> Any:
        def stats_fetch(site: str, token: str, start: datetime, end: datetime) -> dict[str, Any]:
            if calls is not None:
                calls.append((site, token, start, end))
            return {"total": 5, "total_events": 5, "total_utc": 5, "stats": []}

        return stats_fetch

    def test_stats_ok_and_me_200_reports_name_permissions_and_sites(self) -> None:
        def me_fetch(_site: str, _token: str) -> dict[str, Any]:
            return {"token": {"name": "read-only", "permissions": 3, "sites": [1]}, "user": {"email": "x@example.com"}}

        result = goatcounter.check_key("s", "secret", stats_fetch=self.stats_ok(), me_fetch=me_fetch)
        self.assertEqual(
            result,
            {
                "ok": True,
                "reads_statistics": True,
                "permissions_available": True,
                "name": "read-only",
                "permissions": 3,
                "sites": [1],
            },
        )
        self.assertNotIn("email", str(result))
        self.assertNotIn("secret", str(result))

    def test_stats_ok_and_me_404_still_succeeds_without_permissions(self) -> None:
        def me_fetch(_site: str, _token: str) -> dict[str, Any]:
            raise goatcounter.GoatCounterHTTPError(404, "GoatCounter returned HTTP 404 for .../me")

        result = goatcounter.check_key("s", "secret", stats_fetch=self.stats_ok(), me_fetch=me_fetch)
        self.assertTrue(result["ok"])
        self.assertTrue(result["reads_statistics"])
        self.assertFalse(result["permissions_available"])
        self.assertIn("HTTP 404", result["note"])
        self.assertIn("the key still reads statistics", result["note"])

    def test_stats_ok_and_me_403_is_the_same_as_404(self) -> None:
        def me_fetch(_site: str, _token: str) -> dict[str, Any]:
            raise goatcounter.GoatCounterHTTPError(403, "GoatCounter returned HTTP 403 for .../me")

        result = goatcounter.check_key("s", "secret", stats_fetch=self.stats_ok(), me_fetch=me_fetch)
        self.assertTrue(result["ok"])
        self.assertFalse(result["permissions_available"])

    def test_stats_401_is_the_real_failure_and_me_is_never_called(self) -> None:
        def stats_fetch(_site: str, _token: str, _start: datetime, _end: datetime) -> dict[str, Any]:
            raise goatcounter.GoatCounterHTTPError(401, "GoatCounter rejected the API key (HTTP 401)")

        def never_me(_site: str, _token: str) -> None:
            raise AssertionError("check_key must not call /me when /stats/total already failed")

        with self.assertRaises(goatcounter.GoatCounterError):
            goatcounter.check_key("s", "secret", stats_fetch=stats_fetch, me_fetch=never_me)

    def test_stats_call_uses_the_last_hour_rounded(self) -> None:
        calls: list[tuple[str, str, datetime, datetime]] = []
        now = datetime(2026, 9, 26, 14, 37, tzinfo=UTC)
        goatcounter.check_key(
            "s", "secret", now=now, stats_fetch=self.stats_ok(calls), me_fetch=lambda _s, _t: {"token": {}}
        )
        self.assertEqual(len(calls), 1)
        _site, _token, start, end = calls[0]
        self.assertEqual(end, datetime(2026, 9, 26, 14, 0, tzinfo=UTC))
        self.assertEqual(start, datetime(2026, 9, 26, 13, 0, tzinfo=UTC))

    def test_format_check_never_prints_a_key_and_names_the_reason_when_unavailable(self) -> None:
        available = goatcounter.format_check(
            {
                "ok": True,
                "reads_statistics": True,
                "permissions_available": True,
                "name": "ro",
                "permissions": 3,
                "sites": [1],
            },
            site="https://example.goatcounter.com/api/v0/",
        )
        self.assertIn("ro", available)
        self.assertIn("reads statistics", available)
        unavailable = goatcounter.format_check(
            {
                "ok": True,
                "reads_statistics": True,
                "permissions_available": False,
                "note": (
                    "permission list could not be read (GET /api/v0/me answered HTTP 404); "
                    "the key still reads statistics"
                ),
            },
            site="s",
        )
        self.assertIn("could not be read", unavailable)
        self.assertNotIn("secret", unavailable)


class KeyStaysOnItsSiteTests(unittest.TestCase):
    def test_require_https_refuses_anything_but_an_https_url_with_a_host(self) -> None:
        goatcounter.require_https("https://nappy.goatcounter.com/api/v0/")
        for site in ("http://nappy.goatcounter.com/api/v0/", "nappy.goatcounter.com/api/v0/", "https://", "ftp://x/"):
            with self.subTest(site=site), self.assertRaises(goatcounter.GoatCounterError):
                goatcounter.require_https(site)

    def _redirect(self, newurl: str) -> Any:
        request = goatcounter.urllib.request.Request(
            "https://nappy.goatcounter.com/api/v0/stats/hits", headers={"Authorization": "Bearer secret"}
        )
        return goatcounter._SameSiteRedirects().redirect_request(request, None, 302, "Found", {}, newurl)

    def test_a_redirect_to_another_host_or_to_http_is_refused_rather_than_sent_the_key(self) -> None:
        for newurl in (
            "https://elsewhere.example/api/v0/stats/hits",
            "http://nappy.goatcounter.com/api/v0/stats/hits",
            "https://nappy.goatcounter.com.elsewhere.example/",
        ):
            with self.subTest(newurl=newurl), self.assertRaises(goatcounter.GoatCounterError) as caught:
                self._redirect(newurl)
            self.assertNotIn("secret", str(caught.exception))

    def test_a_redirect_within_the_same_https_host_is_followed(self) -> None:
        # urllib's own http_error_302 joins a relative Location onto the request's URL before
        # redirect_request sees it, so what arrives here is always absolute.
        followed = self._redirect("https://nappy.goatcounter.com/api/v0/stats/hits?page=2")
        self.assertIsNotNone(followed)
        self.assertEqual(followed.full_url, "https://nappy.goatcounter.com/api/v0/stats/hits?page=2")

    def test_the_opener_uses_the_same_site_redirect_handler(self) -> None:
        opener = goatcounter._build_opener()
        self.assertTrue(any(isinstance(h, goatcounter._SameSiteRedirects) for h in opener.handlers))
        self.assertFalse(
            any(type(h) is goatcounter.urllib.request.HTTPRedirectHandler for h in opener.handlers),
            "urllib's own handler, which carries the key to any host, is replaced rather than kept beside it",
        )

    def test_main_refuses_an_http_site_from_the_flag_or_the_environment_before_any_request(self) -> None:
        def never(_site: str, _token: str) -> None:
            raise AssertionError("make_fetcher must not be called for a site that is not https")

        for argv, env in (
            (["--site", "http://nappy.goatcounter.com/api/v0/"], {"GOATCOUNTER_TOKEN": "secret"}),
            ([], {"GOATCOUNTER_TOKEN": "secret", "GOATCOUNTER_SITE": "http://nappy.goatcounter.com/api/v0/"}),
            (["--check", "--site", "http://nappy.goatcounter.com/api/v0/"], {"GOATCOUNTER_TOKEN": "secret"}),
        ):
            stdout, stderr = io.StringIO(), io.StringIO()
            with (
                self.subTest(argv=argv, env=sorted(env)),
                mock.patch.dict("os.environ", env, clear=True),
                mock.patch.object(goatcounter, "make_fetcher", side_effect=never),
                mock.patch.object(goatcounter, "check_key", side_effect=never),
                redirect_stdout(stdout),
                redirect_stderr(stderr),
            ):
                code = goatcounter.main(argv)
            self.assertEqual(code, 2)
            self.assertIn("https://", stderr.getvalue())
            self.assertNotIn("secret", stderr.getvalue() + stdout.getvalue())


class MainTests(unittest.TestCase):
    def test_missing_token_refuses_before_any_network_call(self) -> None:
        def never(_site: str, _token: str) -> None:
            raise AssertionError("make_fetcher must not be called when the key is missing")

        stdout, stderr = io.StringIO(), io.StringIO()
        # An empty root, so a real .env in this checkout (or in the main checkout, from a worktree)
        # cannot supply the key the test says is missing.
        with (
            tempfile.TemporaryDirectory() as temp,
            mock.patch.dict("os.environ", {}, clear=True),
            mock.patch.object(goatcounter, "_repo_root", return_value=Path(temp)),
            mock.patch.object(goatcounter, "make_fetcher", side_effect=never),
            redirect_stdout(stdout),
            redirect_stderr(stderr),
        ):
            code = goatcounter.main([])
        self.assertNotEqual(code, 0)
        self.assertIn("GOATCOUNTER_TOKEN", stderr.getvalue())
        # Both ways to set it are named -- an export and a .env file at the repo root.
        self.assertIn("export GOATCOUNTER_TOKEN", stderr.getvalue())
        self.assertIn(".env", stderr.getvalue())

    def test_a_token_from_dotenv_reaches_the_fetcher_when_the_environment_has_none(self) -> None:
        hits = [hit("nappy-run-fresh", 1, 1)]
        seen_tokens: list[str] = []

        def fetcher(_site: str, token: str) -> Callable[[dict[str, Any]], dict[str, Any]]:
            seen_tokens.append(token)
            return lambda _params: {"hits": hits, "more": False}

        stdout = io.StringIO()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / ".env").write_text("GOATCOUNTER_TOKEN=from-dotenv\n", encoding="utf-8")
            with (
                mock.patch.dict("os.environ", {}, clear=True),
                mock.patch.object(goatcounter, "_repo_root", return_value=root),
                mock.patch.object(goatcounter, "make_fetcher", side_effect=fetcher),
                redirect_stdout(stdout),
            ):
                code = goatcounter.main([])
        self.assertEqual(code, 0)
        self.assertEqual(seen_tokens, ["from-dotenv"])
        self.assertNotIn("from-dotenv", stdout.getvalue())

    def test_a_present_token_reaches_the_fetcher_and_prints_text(self) -> None:
        hits = [hit("nappy-day-1-began", 5, 1)]
        stdout, stderr = io.StringIO(), io.StringIO()
        with (
            mock.patch.dict("os.environ", {"GOATCOUNTER_TOKEN": "secret"}, clear=True),
            mock.patch.object(goatcounter, "make_fetcher", return_value=lambda _params: {"hits": hits, "more": False}),
            redirect_stdout(stdout),
            redirect_stderr(stderr),
        ):
            code = goatcounter.main(["--days", "5"])
        self.assertEqual(code, 0, stderr.getvalue())
        self.assertIn("nappy-day-1-began: 5", stdout.getvalue())
        self.assertNotIn("secret", stdout.getvalue())

    def test_json_flag_prints_valid_json(self) -> None:
        import json

        hits = [hit("nappy-run-fresh", 2, 1)]
        stdout = io.StringIO()
        with (
            mock.patch.dict("os.environ", {"GOATCOUNTER_TOKEN": "secret"}, clear=True),
            mock.patch.object(goatcounter, "make_fetcher", return_value=lambda _params: {"hits": hits, "more": False}),
            redirect_stdout(stdout),
        ):
            code = goatcounter.main(["--json"])
        self.assertEqual(code, 0)
        payload = json.loads(stdout.getvalue())
        self.assertEqual(payload["run_level"]["run-fresh"], 2)

    def test_a_non_positive_days_is_rejected_before_the_token_check(self) -> None:
        stderr = io.StringIO()
        with mock.patch.dict("os.environ", {}, clear=True), redirect_stderr(stderr):
            code = goatcounter.main(["--days", "0"])
        self.assertNotEqual(code, 0)
        self.assertIn("--days", stderr.getvalue())

    def test_raw_prints_every_path_unfiltered_and_ignores_prefix_filtering(self) -> None:
        hits = [hit("nappy-run-fresh", 2, 1), hit("josuakrause.github.io/nappy", 40, 2, event=False)]
        stdout = io.StringIO()
        with (
            mock.patch.dict("os.environ", {"GOATCOUNTER_TOKEN": "secret"}, clear=True),
            mock.patch.object(goatcounter, "make_fetcher", return_value=lambda _params: {"hits": hits, "more": False}),
            redirect_stdout(stdout),
        ):
            code = goatcounter.main(["--raw"])
        self.assertEqual(code, 0)
        self.assertIn("josuakrause.github.io/nappy: 40", stdout.getvalue())
        self.assertIn("nappy-run-fresh: 2", stdout.getvalue())

    def test_raw_as_json(self) -> None:
        import json

        hits = [hit("nappy-run-fresh", 2, 1)]
        stdout = io.StringIO()
        with (
            mock.patch.dict("os.environ", {"GOATCOUNTER_TOKEN": "secret"}, clear=True),
            mock.patch.object(goatcounter, "make_fetcher", return_value=lambda _params: {"hits": hits, "more": False}),
            redirect_stdout(stdout),
        ):
            code = goatcounter.main(["--raw", "--json"])
        self.assertEqual(code, 0)
        payload = json.loads(stdout.getvalue())
        self.assertEqual(payload, [{"path": "nappy-run-fresh", "count": 2, "event": True}])

    def test_check_calls_me_not_hits_and_never_prints_the_token(self) -> None:
        stdout = io.StringIO()

        def stats_fetch(_site: str, token: str, _start: datetime, _end: datetime) -> dict[str, Any]:
            self.assertEqual(token, "secret")
            return {"total": 1}

        def fetch_me(_site: str, token: str) -> dict[str, Any]:
            self.assertEqual(token, "secret")
            return {"token": {"name": "read-only", "permissions": 3, "sites": [1]}}

        def never_hits(*_args: object, **_kwargs: object) -> None:
            raise AssertionError("--check must not call fetch_hits/make_fetcher")

        with (
            mock.patch.dict("os.environ", {"GOATCOUNTER_TOKEN": "secret"}, clear=True),
            mock.patch.object(goatcounter, "fetch_stats_total", side_effect=stats_fetch),
            mock.patch.object(goatcounter, "fetch_me", side_effect=fetch_me),
            mock.patch.object(goatcounter, "make_fetcher", side_effect=never_hits),
            redirect_stdout(stdout),
        ):
            code = goatcounter.main(["--check"])
        self.assertEqual(code, 0)
        self.assertIn("reads statistics", stdout.getvalue())
        self.assertIn("read-only", stdout.getvalue())
        self.assertNotIn("secret", stdout.getvalue())

    def test_check_reports_a_statistics_only_key_as_working_without_permissions(self) -> None:
        stdout = io.StringIO()

        def stats_fetch(_site: str, _token: str, _start: datetime, _end: datetime) -> dict[str, Any]:
            return {"total": 1}

        def fetch_me(_site: str, _token: str) -> dict[str, Any]:
            raise goatcounter.GoatCounterHTTPError(404, "GoatCounter returned HTTP 404 for .../me")

        with (
            mock.patch.dict("os.environ", {"GOATCOUNTER_TOKEN": "secret"}, clear=True),
            mock.patch.object(goatcounter, "fetch_stats_total", side_effect=stats_fetch),
            mock.patch.object(goatcounter, "fetch_me", side_effect=fetch_me),
            redirect_stdout(stdout),
        ):
            code = goatcounter.main(["--check"])
        self.assertEqual(code, 0)
        self.assertIn("reads statistics", stdout.getvalue())
        self.assertIn("HTTP 404", stdout.getvalue())
        self.assertNotIn("secret", stdout.getvalue())

    def test_check_reports_a_rejected_key_with_a_nonzero_exit_and_never_calls_me(self) -> None:
        def stats_fetch(_site: str, _token: str, _start: datetime, _end: datetime) -> dict[str, Any]:
            raise goatcounter.GoatCounterHTTPError(
                401, "GoatCounter rejected the API key (HTTP 401) -- check GOATCOUNTER_TOKEN"
            )

        def never_me(_site: str, _token: str) -> None:
            raise AssertionError("--check must not call /me when /stats/total already failed")

        stderr = io.StringIO()
        with (
            mock.patch.dict("os.environ", {"GOATCOUNTER_TOKEN": "bad"}, clear=True),
            mock.patch.object(goatcounter, "fetch_stats_total", side_effect=stats_fetch),
            mock.patch.object(goatcounter, "fetch_me", side_effect=never_me),
            redirect_stderr(stderr),
        ):
            code = goatcounter.main(["--check"])
        self.assertNotEqual(code, 0)
        self.assertIn("GOATCOUNTER_TOKEN", stderr.getvalue())
        self.assertNotIn("bad", stderr.getvalue())

    def test_raw_and_check_together_are_rejected_by_argparse(self) -> None:
        stderr = io.StringIO()
        with self.assertRaises(SystemExit) as raised, redirect_stderr(stderr):
            goatcounter.main(["--raw", "--check"])
        self.assertNotEqual(raised.exception.code, 0)
        self.assertIn("usage", stderr.getvalue().lower())


if __name__ == "__main__":
    unittest.main()
