#!/usr/bin/env python3
"""Tests for `tools/merge-test-only-members.py`, against a throwaway repository with a conflicting list."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOL = Path(__file__).resolve().parent / "merge-test-only-members.py"
LIST = "tools/test_only_members.txt"
BASE = "# [no reader]\na.gd one\na.gd two\na.gd three\n\n# [kept]\nb.gd keep # why\n"


class MergeTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.repo = Path(self._tmp.name)
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "t@example.com")
        self.git("config", "user.name", "t")
        self.git("config", "commit.gpgsign", "false")
        (self.repo / "tools").mkdir()

    def git(self, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
        return subprocess.run(["git", *args], cwd=self.repo, capture_output=True, text=True, check=check)

    def commit(self, text: str) -> None:
        (self.repo / LIST).write_text(text)
        self.git("add", LIST)
        self.git("commit", "-q", "-m", "x")

    def conflict(self, branch: str, main: str) -> None:
        self.commit(BASE)
        self.git("checkout", "-q", "-b", "feature")
        self.commit(branch)
        self.git("checkout", "-q", "main")
        self.commit(main)
        self.git("checkout", "-q", "feature")
        self.git("merge", "main", check=False)

    def tool(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(TOOL), *args], cwd=self.repo, capture_output=True, text=True, check=False
        )

    def test_replays_the_branch_edits_on_mains_file(self) -> None:
        branch = BASE.replace("a.gd two\n", "").replace("a.gd three\n", "a.gd three\na.gd new\n")
        main = BASE.replace("a.gd one\n", "a.gd one\na.gd mainnew\n").replace(
            "b.gd keep # why\n", "b.gd keep # why\nb.gd more # y\n"
        )
        self.conflict(branch, main)
        done = self.tool()
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertIn("1 added, 1 removed", done.stdout)
        want = (
            "# [no reader]\na.gd one\na.gd mainnew\na.gd three\na.gd new\n\n# [kept]\nb.gd keep # why\nb.gd more # y\n"
        )
        self.assertEqual((self.repo / LIST).read_text(), want)
        self.assertEqual(self.git("ls-files", "-u").stdout, "")

    def test_dry_run_changes_nothing(self) -> None:
        self.conflict(BASE.replace("a.gd two\n", ""), BASE.replace("a.gd one\n", "a.gd one\na.gd mainnew\n"))
        before = (self.repo / LIST).read_text()
        done = self.tool("--dry-run")
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertIn("dry run", done.stdout)
        self.assertEqual((self.repo / LIST).read_text(), before)
        self.assertNotEqual(self.git("ls-files", "-u").stdout, "")

    def test_refuses_a_removed_line_main_already_dropped(self) -> None:
        self.conflict(BASE.replace("a.gd two\n", ""), BASE.replace("a.gd two\n", "a.gd other\n"))
        done = self.tool()
        self.assertEqual(done.returncode, 1)
        self.assertIn("a.gd two", done.stderr)
        self.assertNotEqual(self.git("ls-files", "-u").stdout, "")

    def test_refuses_an_added_line_whose_predecessor_main_dropped(self) -> None:
        self.conflict(BASE.replace("a.gd two\n", "a.gd two\na.gd new\n"), BASE.replace("a.gd two\n", "a.gd other\n"))
        done = self.tool()
        self.assertEqual(done.returncode, 1)
        self.assertIn("a.gd two", done.stderr)

    def test_refuses_a_path_that_is_not_unmerged(self) -> None:
        self.commit(BASE)
        done = self.tool()
        self.assertEqual(done.returncode, 1)
        self.assertIn("not unmerged", done.stderr)

    def test_refuses_any_other_path(self) -> None:
        done = self.tool("tools/other.txt")
        self.assertEqual(done.returncode, 1)
        self.assertIn("only", done.stderr)


if __name__ == "__main__":
    unittest.main()
