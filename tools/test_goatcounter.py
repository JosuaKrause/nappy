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
from collections.abc import Callable
from contextlib import redirect_stderr, redirect_stdout
from datetime import UTC, datetime
from pathlib import Path
from typing import Any
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
        self.assertEqual(
            goatcounter.classify("day-14-instant-charging-dog"),
            goatcounter.Classified("day", "day-14-instant-charging-dog", 14, "instant-charging-dog"),
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

    def test_a_note_says_counts_are_visitors_not_attempts(self) -> None:
        # A day's outcomes can outnumber its began: one visitor can lose, retry with a nerve, and
        # win the same day, and GoatCounter counts each event by visitor, not by attempt.
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
        self.assertIn("visitors, not attempts", text)
        self.assertLess(text.index("visitors, not attempts"), text.index("Day 6:"))

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
        self.assertEqual(calls[1]["exclude_paths"], ["1", "2"])

    def test_stops_rather_than_looping_forever_if_more_is_true_with_nothing_new(self) -> None:
        def fetch(_params: dict[str, Any]) -> dict[str, Any]:
            return {"hits": [], "more": True, "total": 0}

        start = datetime(2026, 9, 1, tzinfo=UTC)
        end = datetime(2026, 9, 2, tzinfo=UTC)
        self.assertEqual(goatcounter.fetch_hits(fetch, start, end), [])

    def test_a_malformed_response_is_an_actionable_error(self) -> None:
        def fetch(_params: dict[str, Any]) -> dict[str, Any]:
            return {"total": 0}

        start = datetime(2026, 9, 1, tzinfo=UTC)
        end = datetime(2026, 9, 2, tzinfo=UTC)
        with self.assertRaises(goatcounter.GoatCounterError):
            goatcounter.fetch_hits(fetch, start, end)


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
        self.assertIn("statistics-only key", result["note"])

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
                "note": "permission list is not available to a statistics-only key, which is the recommended kind",
            },
            site="s",
        )
        self.assertIn("statistics-only key", unavailable)
        self.assertNotIn("secret", unavailable)


class MainTests(unittest.TestCase):
    def test_missing_token_refuses_before_any_network_call(self) -> None:
        def never(_site: str, _token: str) -> None:
            raise AssertionError("make_fetcher must not be called when the key is missing")

        stdout, stderr = io.StringIO(), io.StringIO()
        with (
            mock.patch.dict("os.environ", {}, clear=True),
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
        self.assertIn("statistics-only key", stdout.getvalue())
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
