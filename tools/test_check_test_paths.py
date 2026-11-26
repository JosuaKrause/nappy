#!/usr/bin/env python3
"""Unit tests for `tools/check_test_paths.py`, each against a small checkout in a temp folder."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_test_paths


def hits(files: dict[str, str], only: list[str] | None = None) -> list[str]:
    """The check's findings on a checkout holding `files` (path -> text) and `tests/test_real.gd`."""
    with tempfile.TemporaryDirectory() as raw:
        root = Path(raw)
        tree = {"tests/test_real.gd": "extends RefCounted\n", "tests/probes/m1_probe.gd": "extends RefCounted\n"}
        tree.update(files)
        for rel, text in tree.items():
            path = root / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
        return check_test_paths.check(root, only)


class CheckTestPathsTests(unittest.TestCase):
    def test_a_suite_that_exists_passes(self) -> None:
        doc = "`tests/test_real.gd` holds it, and so does `test_real.gd` and `res://tests/probes/m1_probe.gd`.\n"
        self.assertEqual(hits({"docs/EVENTS.md": doc}), [])

    def test_a_path_that_names_no_file_fails(self) -> None:
        found = hits({"docs/EVENTS.md": "first line\n`tests/test_gone.gd` holds it.\n"})
        self.assertEqual(found, ["docs/EVENTS.md:2: tests/test_gone.gd names no file under tests/"])

    def test_a_bare_name_that_names_no_file_fails(self) -> None:
        found = hits({"CLAUDE.md": "See test_gone.gd.\n"})
        self.assertEqual(len(found), 1)
        self.assertIn("test_gone.gd", found[0])

    def test_a_bare_name_is_found_at_any_depth(self) -> None:
        self.assertEqual(hits({"README.md": "`test_deep.gd`\n", "tests/probes/test_deep.gd": ""}), [])

    def test_a_placeholder_or_a_wildcard_is_not_a_name(self) -> None:
        doc = "`test_<x>.gd`, `tests/test_zz_*.gd` and `tests/runner_fixtures/broken.gd.src` name no file.\n"
        self.assertEqual(hits({"docs/MECHANICS.md": doc}), [])

    def test_only_a_gd_files_comments_are_read(self) -> None:
        code = (
            'const P := "res://tests/test_gone.gd"\n'
            "## Held by `tests/test_other_gone.gd`.\n"
            "var x := 1  # test_third_gone.gd\n"
        )
        found = hits({"src/thing.gd": code})
        self.assertEqual(
            found,
            [
                "src/thing.gd:2: tests/test_other_gone.gd names no file under tests/",
                "src/thing.gd:3: test_third_gone.gd names no file under tests/",
            ],
        )

    def test_the_skills_and_the_tools_scripts_are_read(self) -> None:
        found = hits({".claude/skills/x/references/y.md": "`tests/test_gone.gd`\n", "tools/t.gd": "# test_gone.gd\n"})
        self.assertEqual(len(found), 2)

    def test_the_history_and_the_queue_are_not_read(self) -> None:
        files = {
            "docs/DECISIONS.md": "`tests/test_gone.gd`\n",
            "docs/decisions/2026-01-01-a-b.md": "`tests/test_gone.gd`\n",
            "docs/playtests/PLAYTEST-1.md": "`tests/test_gone.gd`\n",
            "docs/todo/2026-01-01-a-b/README.md": "`tests/test_gone.gd`\n",
            "docs/review/2026-01-01-a-b.md": "`tests/test_gone.gd`\n",
        }
        self.assertEqual(hits(files), [])

    def test_a_line_marked_lint_allow_is_not_read(self) -> None:
        self.assertEqual(hits({"docs/CITY.md": "`tests/test_gone.gd` <!-- lint-allow: an example -->\n"}), [])

    def test_named_files_limit_the_scope(self) -> None:
        files = {"docs/CITY.md": "`tests/test_gone.gd`\n", "docs/EVENTS.md": "`tests/test_gone.gd`\n"}
        found = hits(files, ["docs/CITY.md", "docs/todo/x.md"])
        self.assertEqual(found, ["docs/CITY.md:1: tests/test_gone.gd names no file under tests/"])

    def test_the_real_tree_passes(self) -> None:
        self.assertEqual(check_test_paths.check(check_test_paths.ROOT), [])

    def test_a_named_file_that_does_not_exist_is_an_error(self) -> None:
        self.assertEqual(check_test_paths.main(["docs/no-such-file.md"]), 2)


if __name__ == "__main__":
    unittest.main()
