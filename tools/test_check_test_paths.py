#!/usr/bin/env python3
"""Unit tests for `tools/check_test_paths.py`, each against a small tree of files in a temp folder."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_test_paths

SUITE = "extends RefCounted\n"


def hits(files: dict[str, str]) -> list[str]:
    """The check's findings on a tree of path -> text, written to a temp folder and read back."""
    with tempfile.TemporaryDirectory() as raw:
        root = Path(raw)
        for name, text in files.items():
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
        return check_test_paths.check(root)


class CheckTestPathsTests(unittest.TestCase):
    def test_a_path_that_exists_passes_and_one_that_does_not_fails(self) -> None:
        tree = {"tests/test_blocks.gd": SUITE, "docs/CITY.md": "Intro.\n\nHeld by tests/test_blocks.gd today.\n"}
        self.assertEqual(hits(tree), [])
        tree["docs/CITY.md"] = "Intro.\n\nHeld by tests/test_routes.gd today.\n"
        found = hits(tree)
        self.assertEqual(len(found), 1)
        self.assertTrue(found[0].startswith("docs/CITY.md:3: names tests/test_routes.gd, which does not exist"))
        self.assertIn("name the suite that holds the check, or say that none does", found[0])

    def test_a_bare_suite_name_is_looked_for_at_any_depth(self) -> None:
        tree = {
            "tests/test_blocks.gd": SUITE,
            "tests/probes/test_deep.gd": SUITE,
            "README.md": "See test_blocks.gd and test_deep.gd.\n",
        }
        self.assertEqual(hits(tree), [])
        tree["README.md"] = "See test_crowd.gd.\n"
        found = hits(tree)
        self.assertEqual(len(found), 1)
        self.assertIn("README.md:1: names test_crowd.gd, and no file under tests/ has that name", found[0])

    def test_a_path_is_looked_for_where_it_says_and_not_by_name(self) -> None:
        tree = {"tests/probes/test_deep.gd": SUITE, "README.md": "See tests/test_deep.gd.\n"}
        found = hits(tree)
        self.assertEqual(len(found), 1)
        self.assertIn("names tests/test_deep.gd, which does not exist", found[0])
        tree["README.md"] = "See tests/probes/test_deep.gd.\n"
        self.assertEqual(hits(tree), [])

    def test_a_placeholder_or_a_glob_is_not_a_reference(self) -> None:
        for text in (
            "A throwaway tests/test_zz_*.gd prints numbers.",
            "Every test_*.gd and test_<x>.gd is a suite.",
            "Name it tests/test_<name>.gd or tests/<folder>/x.gd.",
            "The runner prints tests/%s.gd, and test_{a,b}.gd is two.",
            "The folder tests/probes/ and the glob tests/** hold them.",
            "Run test_blocks without its extension.",
        ):
            self.assertEqual(hits({"tests/fake.gd": SUITE, "CLAUDE.md": text + "\n"}), [], text)

    def test_the_punctuation_round_a_name_is_not_part_of_it(self) -> None:
        for text in (
            "It is in tests/test_gone.gd.",
            "It is in **tests/test_gone.gd**, bold.",
            "It is in (`tests/test_gone.gd`): a suite.",
            "A link [the suite](tests/test_gone.gd) to it.",
            "tests/test_gone.gd's own header says so.",
            'load("res://tests/test_gone.gd") reads it; so does ./tests/test_gone.gd.',
        ):
            found = hits({"tests/fake.gd": SUITE, "CLAUDE.md": text + "\n"})
            self.assertTrue(found, text)
            for hit in found:
                self.assertIn("names tests/test_gone.gd, which does not exist", hit, text)
        found = hits({"tests/fake.gd": SUITE, "CLAUDE.md": "In `test_gone.gd`. And *test_gone.gd*, too.\n"})
        self.assertEqual(len(found), 2)
        self.assertIn("names test_gone.gd, and", found[0])

    def test_a_longer_file_name_is_read_whole(self) -> None:
        text = "The fixture tests/runner_fixtures/unparseable_suite.gd.src fails to parse.\n"
        tree = {"tests/runner_fixtures/unparseable_suite.gd.src": "func\n", "README.md": text}
        self.assertEqual(hits(tree), [])
        found = hits({"tests/runner_fixtures/unparseable_suite.gd": SUITE, "README.md": text})
        self.assertEqual(len(found), 1)
        self.assertIn("names tests/runner_fixtures/unparseable_suite.gd.src, which", found[0])

    def test_a_method_named_after_a_file_is_not_part_of_its_name(self) -> None:
        text = "Restored by tests/shared_state.gd.restore() after every suite.\n"
        self.assertEqual(hits({"tests/shared_state.gd": SUITE, "README.md": text}), [])
        found = hits({"tests/fake.gd": SUITE, "README.md": text})
        self.assertEqual(len(found), 1)
        self.assertIn("names tests/shared_state.gd, which does not exist", found[0])

    def test_every_extension_of_a_tests_file_is_a_reference(self) -> None:
        for name in ("tests/tests.tscn", "tests/suite_costs.txt", "tests/fixtures/save.json", "tests/rig.py"):
            found = hits({"tests/fake.gd": SUITE, "README.md": f"Read {name} first.\n"})
            self.assertEqual(len(found), 1, name)
            self.assertIn(f"names {name}, which does not exist", found[0])
            self.assertEqual(hits({name: "x\n", "README.md": f"Read {name} first.\n"}), [], name)

    def test_the_tail_of_a_longer_path_is_not_a_bare_name(self) -> None:
        text = (
            "tools/test_cli_help.sh holds the cases, tools/test_probe.gd is a tool's,\n"
            "src/dev/test_rig.gd is the game's, .claude/worktrees/x/tests/test_gone.gd is another\n"
            "checkout's, and probes/m64_density.gd is given from inside the folder.\n"
        )
        self.assertEqual(hits({"tests/fake.gd": SUITE, "README.md": text}), [])

    def test_a_path_above_the_file_is_read_through(self) -> None:
        tree = {"tests/fake.gd": SUITE, "docs/CITY.md": "See [it](../tests/test_gone.gd) and [it](../tests/fake.gd).\n"}
        found = hits(tree)
        self.assertEqual(len(found), 1)
        self.assertIn("docs/CITY.md:1: names tests/test_gone.gd, which does not exist", found[0])

    def test_the_comments_of_a_gd_file_are_read_in_all_three_folders(self) -> None:
        for folder in ("src", "tests", "tools"):
            code = "extends RefCounted\n## Held by tests/test_gone.gd.\nvar a := 1  # and test_lost.gd\n"
            found = hits({"tests/fake.gd": SUITE, f"{folder}/deep/thing.gd": code})
            self.assertEqual(len(found), 2, folder)
            self.assertIn(f"{folder}/deep/thing.gd:2: names tests/test_gone.gd, which does not exist", found[0])
            self.assertIn(f"{folder}/deep/thing.gd:3: names test_lost.gd, and", found[1])

    def test_the_code_of_a_gd_file_is_not_read(self) -> None:
        code = (
            'const A := preload("res://tests/test_gone.gd")\n'
            'var b := "# not a comment: tests/test_gone.gd"\n'
            "var c := '# nor this: test_gone.gd'\n"
            'var d := "a \\" quote # still inside: test_gone.gd"\n'
        )
        self.assertEqual(hits({"tests/fake.gd": SUITE, "src/thing.gd": code}), [])
        after = 'var b := "a # b"  # but this is one: test_gone.gd\n'
        found = hits({"tests/fake.gd": SUITE, "src/thing.gd": after})
        self.assertEqual(len(found), 1)
        self.assertIn("src/thing.gd:1: names test_gone.gd", found[0])

    def test_a_triple_quoted_string_is_followed_across_its_lines(self) -> None:
        for quote in ('"""', "'''"):
            code = (
                f"var text := {quote}\n# inside the string: tests/test_gone.gd\n"
                f"still inside {quote}  # outside it: test_lost.gd\n# a comment: tests/test_last.gd\n"
            )
            found = hits({"tests/fake.gd": SUITE, "src/thing.gd": code})
            self.assertEqual(len(found), 2, quote)
            self.assertIn("src/thing.gd:3: names test_lost.gd", found[0])
            self.assertIn("src/thing.gd:4: names tests/test_last.gd", found[1])

    def test_the_governed_docs_are_read(self) -> None:
        text = "Held by tests/test_gone.gd.\n"
        for name in (
            "CLAUDE.md",
            "README.md",
            ".claude/skills/city/SKILL.md",
            ".claude/skills/city/references/deep/sweeps.md",
            "docs/CITY.md",
        ):
            found = hits({"tests/fake.gd": SUITE, name: text})
            self.assertEqual(len(found), 1, name)
            self.assertTrue(found[0].startswith(f"{name}:1: "), found[0])

    def test_the_records_the_queue_and_the_scripts_are_not_read(self) -> None:
        text = "Held by tests/test_gone.gd and test_lost.gd.\n"
        unread = (
            "docs/decisions/2026-01-01-amber-ibis.md",
            "docs/playtests/PLAYTEST-1.md",
            "docs/todo/2026-01-01-amber-ibis/README.md",
            "docs/review/2026-01-01-amber-ibis.md",
            "docs/evidence/README.md",
            "tools/test_thing.py",
            "tools/thing.sh",
            "notes/other.md",
        )
        tree = dict.fromkeys(unread, text)
        tree["tests/fake.gd"] = SUITE
        self.assertEqual(hits(tree), [])

    def test_a_tree_with_no_tests_folder_fails_every_name(self) -> None:
        found = hits({"README.md": "See test_blocks.gd and tests/test_blocks.gd.\n"})
        self.assertEqual(len(found), 2)

    def test_the_command_line_reports_and_rejects(self) -> None:
        tool = str(Path(__file__).resolve().parent / "check_test_paths.py")
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            (root / "tests").mkdir()
            (root / "tests" / "test_blocks.gd").write_text(SUITE, encoding="utf-8")
            (root / "README.md").write_text("See tests/test_blocks.gd.\n", encoding="utf-8")
            passed = subprocess.run([sys.executable, tool, "--root", raw], capture_output=True, text=True)
            self.assertEqual(passed.returncode, 0)
            self.assertTrue(passed.stdout.startswith("OK"))
            (root / "README.md").write_text("See tests/test_routes.gd.\n", encoding="utf-8")
            failed = subprocess.run([sys.executable, tool, "--root", raw], capture_output=True, text=True)
            self.assertEqual(failed.returncode, 1)
            lines = failed.stdout.splitlines()
            self.assertTrue(lines[0].startswith("README.md:1: names tests/test_routes.gd"))
            self.assertTrue(lines[-1].startswith("tools/check_test_paths.py: 1 "))
            wrong = subprocess.run([sys.executable, tool, "--nope"], capture_output=True, text=True)
            self.assertEqual(wrong.returncode, 2)
            stray = subprocess.run([sys.executable, tool, "README.md"], capture_output=True, text=True)
            self.assertEqual(stray.returncode, 2)


if __name__ == "__main__":
    unittest.main()
