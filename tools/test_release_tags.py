#!/usr/bin/env python3
"""Tests for tools/lib_release_tags.py and tools/release-tags.py.

The grammar and the arithmetic are pure functions of a list of tag names, checked on lists; which
candidate a deploy publishes also asks the history whether one tag's commit is an ancestor of
another's, checked with a stand-in answer and then once on a throwaway git repository in $TMPDIR,
through the command line `tools/release.sh` and `.github/workflows/deploy.yml` read.
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib_release_tags as tags

TOOLS = Path(__file__).resolve().parent

DATE = "2026-01-01T12:00:00+0000"


def never_an_ancestor(first: str, second: str) -> bool:
    return False


class GrammarTests(unittest.TestCase):
    def test_a_release_is_three_numbers_and_nothing_else(self) -> None:
        self.assertEqual(tags.parse_release("v0.29.3"), (0, 29, 3))
        self.assertEqual(tags.parse_release("v10.0.12"), (10, 0, 12))
        for name in ("v0.29.3-rc.1", "v1", "v1.2", "0.29.3", "v0.29.3-dirty", "trailer-2026-10-18"):
            self.assertIsNone(tags.parse_release(name), name)

    def test_a_candidate_is_a_release_number_with_a_counter(self) -> None:
        self.assertEqual(tags.parse_candidate("v0.30.0-rc.1"), ((0, 30, 0), 1))
        self.assertEqual(tags.parse_candidate("v0.30.0-rc.12"), ((0, 30, 0), 12))
        for name in ("v0.30.0", "v0.30.0-rc", "v0.30.0-rc.1-3-gabc1234", "v0.30.0-rc.1-dirty", "v0.30-rc.1"):
            self.assertIsNone(tags.parse_candidate(name), name)

    def test_kind_names_each_and_refuses_the_rest(self) -> None:
        self.assertEqual(tags.kind("v0.30.0"), "release")
        self.assertEqual(tags.kind("v0.30.0-rc.2"), "candidate")
        self.assertIsNone(tags.kind("ci-abc"))

    def test_names_round_trip(self) -> None:
        self.assertEqual(tags.release_name((0, 30, 1)), "v0.30.1")
        self.assertEqual(tags.candidate_name(((0, 31, 0), 3)), "v0.31.0-rc.3")


class ArithmeticTests(unittest.TestCase):
    NAMES = ("v0.9.0", "v0.10.0", "v0.10.1", "v0.11.0-rc.1", "v0.11.0-rc.2", "v0.10.2-rc.1")

    def test_the_latest_release_ignores_candidates_and_sorts_numerically(self) -> None:
        self.assertEqual(tags.latest_release(self.NAMES), (0, 10, 1))
        self.assertIsNone(tags.latest_release(["v0.11.0-rc.1"]))

    def test_the_next_release_bumps_the_latest_release_never_a_candidate(self) -> None:
        self.assertEqual(tags.next_release(self.NAMES, "patch"), (0, 10, 2))
        self.assertEqual(tags.next_release(self.NAMES, "minor"), (0, 11, 0))
        self.assertEqual(tags.next_release(self.NAMES, "major"), (1, 0, 0))
        self.assertEqual(tags.next_release([], "minor"), (0, 1, 0))

    def test_the_next_candidate_counts_on_from_the_last_one_for_its_target(self) -> None:
        self.assertEqual(tags.next_candidate(self.NAMES, "minor"), ((0, 11, 0), 3))
        self.assertEqual(tags.next_candidate(self.NAMES, "patch"), ((0, 10, 2), 2))
        self.assertEqual(tags.next_candidate(self.NAMES, "major"), ((1, 0, 0), 1))

    def test_a_part_that_is_not_one_refuses(self) -> None:
        with self.assertRaises(tags.TagError):
            tags.bump((0, 1, 0), "micro")


class PublishedCandidateTests(unittest.TestCase):
    def test_the_newest_candidate_above_the_release_is_published(self) -> None:
        names = ["v0.10.0", "v0.11.0-rc.1", "v0.11.0-rc.2"]
        self.assertEqual(tags.published_candidate(names, never_an_ancestor), "v0.11.0-rc.2")

    def test_a_patch_release_below_the_target_leaves_the_candidate(self) -> None:
        names = ["v0.10.0", "v0.11.0-rc.1", "v0.10.1"]
        self.assertEqual(tags.published_candidate(names, never_an_ancestor), "v0.11.0-rc.1")

    def test_a_patch_release_that_reaches_the_target_removes_the_candidate(self) -> None:
        names = ["v0.10.0", "v0.10.1-rc.1", "v0.10.1"]
        self.assertIsNone(tags.published_candidate(names, never_an_ancestor))

    def test_a_minor_release_removes_a_candidate_cut_before_it_whatever_its_target(self) -> None:
        names = ["v0.10.0", "v1.0.0-rc.1", "v0.11.0"]

        def cut_before(first: str, second: str) -> bool:
            return (first, second) == ("v1.0.0-rc.1", "v0.11.0")

        self.assertIsNone(tags.published_candidate(names, cut_before))

    def test_a_candidate_cut_after_the_minor_release_is_published(self) -> None:
        names = ["v0.10.0", "v0.11.0", "v0.12.0-rc.1"]
        self.assertEqual(tags.published_candidate(names, never_an_ancestor), "v0.12.0-rc.1")

    def test_a_newer_candidate_still_published_wins_over_one_the_minor_release_removed(self) -> None:
        names = ["v0.10.0", "v1.0.0-rc.1", "v0.11.0", "v0.12.0-rc.1"]

        def cut_before(first: str, second: str) -> bool:
            return first == "v1.0.0-rc.1"

        self.assertEqual(tags.published_candidate(names, cut_before), "v0.12.0-rc.1")

    def test_no_candidate_at_all_publishes_none(self) -> None:
        self.assertIsNone(tags.published_candidate(["v0.10.0", "v0.10.1"], never_an_ancestor))


class CommandLineTests(unittest.TestCase):
    """The command line on a real history, where the ancestor question is git's."""

    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.env = dict(
            os.environ,
            GIT_AUTHOR_DATE=DATE,
            GIT_COMMITTER_DATE=DATE,
            GIT_AUTHOR_NAME="t",
            GIT_AUTHOR_EMAIL="t@example.com",
            GIT_COMMITTER_NAME="t",
            GIT_COMMITTER_EMAIL="t@example.com",
        )
        self.git("init", "-q", "-b", "main")

    def git(self, *args: str) -> str:
        result = subprocess.run(["git", *args], cwd=self.repo, env=self.env, capture_output=True, text=True)
        if result.returncode != 0:
            raise AssertionError(f"git {' '.join(args)}: {result.stderr}")
        return result.stdout

    def commit_and_tag(self, name: str) -> None:
        (self.repo / "f.txt").write_text(f"{name}\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", name)
        self.git("tag", "-a", name, "-m", name)

    def cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(TOOLS / "release-tags.py"), "-C", str(self.repo), *args],
            capture_output=True,
            text=True,
        )

    def test_latest_and_next_read_release_tags_only(self) -> None:
        for name in ("v0.29.3", "v0.30.0-rc.1"):
            self.commit_and_tag(name)
        self.assertEqual(self.cli("latest").stdout, "v0.29.3\n")
        self.assertEqual(self.cli("next", "patch").stdout, "v0.29.4\n")
        self.assertEqual(self.cli("next", "minor", "--rc").stdout, "v0.30.0-rc.2\n")

    def test_kind_refuses_a_name_that_is_neither(self) -> None:
        self.assertEqual(self.cli("kind", "v0.30.0-rc.1").stdout, "candidate\n")
        refused = self.cli("kind", "ci-abc")
        self.assertEqual(refused.returncode, 1)
        self.assertIn("refusing", refused.stderr)

    def test_site_asks_the_history_whether_a_minor_release_came_after_the_candidate(self) -> None:
        for name in ("v0.10.0", "v1.0.0-rc.1", "v0.11.0"):
            self.commit_and_tag(name)
        self.assertEqual(self.cli("site").stdout, "release=v0.11.0\ncandidate=\n")
        self.commit_and_tag("v0.12.0-rc.1")
        self.assertEqual(self.cli("site").stdout, "release=v0.11.0\ncandidate=v0.12.0-rc.1\n")
        self.commit_and_tag("v0.11.1")
        self.assertEqual(self.cli("site").stdout, "release=v0.11.1\ncandidate=v0.12.0-rc.1\n")

    def test_site_refuses_a_history_with_no_release(self) -> None:
        self.commit_and_tag("v0.1.0-rc.1")
        self.assertEqual(self.cli("site").returncode, 1)


if __name__ == "__main__":
    unittest.main()
