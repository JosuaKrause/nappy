#!/usr/bin/env python3
"""Unit tests for CI's pull request checks, `tools/ci_*.py`, and what they share in `tools/lib_ci.py`.

Each check is a pure function from the pull request's changed files, its description and whatever
else it reads to a list of failures, so almost every case here is a fixture and a call. The one
place the shape of real input matters -- `git diff --raw -z` -- is exercised against a throwaway
repository, since a parser tested only against strings written by the same hand proves nothing
about git.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import ci_classify
import ci_telemetry_kinds
import lib_ci
from lib_ci import Change

ZERO = "0" * 40


def added(path: str, blob: str = "a" * 40) -> Change:
    return Change(status="A", path=path, old_blob=ZERO, new_blob=blob)


def modified(path: str) -> Change:
    return Change(status="M", path=path, old_blob="b" * 40, new_blob="c" * 40)


def deleted(path: str, blob: str = "d" * 40) -> Change:
    return Change(status="D", path=path, old_blob=blob, new_blob=ZERO)


def git(repo: Path, *args: str) -> str:
    return subprocess.run(
        ["git", "-c", "user.name=t", "-c", "user.email=t@example.com", *args],
        cwd=repo,
        capture_output=True,
        text=True,
        check=True,
    ).stdout


class ChangedFilesTests(unittest.TestCase):
    def test_a_real_diff_splits_a_rename_and_runs_from_where_the_branch_started(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)
            git(repo, "init", "-q", "-b", "main")
            (repo / "keep.md").write_text("keep\n")
            (repo / "old name.md").write_text("moved\n")
            (repo / "gone.md").write_text("gone\n")
            git(repo, "add", ".")
            git(repo, "commit", "-q", "-m", "base")
            git(repo, "checkout", "-q", "-b", "work")
            git(repo, "mv", "old name.md", "new name.md")
            (repo / "gone.md").unlink()
            (repo / "keep.md").write_text("kept, changed\n")
            git(repo, "add", "-A")
            git(repo, "commit", "-q", "-m", "work")
            # main moves on after the branch left it; three dots keep that out of the branch's diff.
            git(repo, "checkout", "-q", "main")
            (repo / "later.md").write_text("on main only\n")
            git(repo, "add", ".")
            git(repo, "commit", "-q", "-m", "later")

            changes = lib_ci.changed_files("main", "work", cwd=repo)
            by_path = {change.path: change for change in changes}
            self.assertEqual(sorted(by_path), ["gone.md", "keep.md", "new name.md", "old name.md"])
            self.assertEqual(by_path["new name.md"].status, "A")
            self.assertEqual(by_path["old name.md"].status, "D")
            self.assertEqual(by_path["keep.md"].status, "M")
            # The blob ids are full and say the moved file is the same content on both sides.
            self.assertEqual(by_path["new name.md"].new_blob, by_path["old name.md"].old_blob)
            self.assertEqual(len(by_path["gone.md"].old_blob), 40)

    def test_an_unexpected_record_is_an_error_rather_than_a_guess(self) -> None:
        with self.assertRaises(lib_ci.CiError):
            lib_ci.parse_raw_diff("not a raw record\0path\0")


class NormalizeTests(unittest.TestCase):
    def test_wrapping_and_quote_markers_are_forgiven(self) -> None:
        note = "currently shadows are oval below objects.\r\nfor most objects the oval spans"
        playtest = '> "currently shadows are oval\n> below objects. for most objects\n>   the oval spans"'
        self.assertIn(lib_ci.normalize(note), lib_ci.normalize(playtest))

    def test_a_changed_word_case_or_mark_is_not(self) -> None:
        note = lib_ci.normalize("the car's roof")
        for playtest in ("the cars roof", "The car's roof", "the car\u2019s roof", "the car's  hood"):
            with self.subTest(playtest=playtest):
                self.assertNotIn(note, lib_ci.normalize(playtest))

    def test_a_nested_quote_in_the_note_matches_the_same_quote_nested_once_more(self) -> None:
        self.assertIn(lib_ci.normalize("> quoted\nmine"), lib_ci.normalize("> > quoted\n> mine"))


class ClassifyTests(unittest.TestCase):
    def flags(self, *paths: str) -> tuple[bool, bool, bool]:
        flags = ci_classify.classify(list(paths))
        return (flags.queue_only, flags.docs_only, flags.touches_code)

    def test_the_queue_folders_alone_are_queue_only_and_docs_only(self) -> None:
        self.assertEqual(
            self.flags("docs/todo/2026-01-01-a-b/x.md", "docs/review/r.md", "docs/playtests/p.md"),
            (True, True, False),
        )

    def test_any_markdown_or_anything_under_docs_is_docs_only(self) -> None:
        self.assertEqual(
            self.flags("CLAUDE.md", ".claude/skills/verify/SKILL.md", "docs/evidence/x/shot.png", "docs/CITY.md"),
            (False, True, False),
        )

    def test_the_three_docs_the_game_reads_run_everything(self) -> None:
        for path in ci_classify.GAME_READS:
            with self.subTest(path=path):
                self.assertEqual(self.flags("docs/CITY.md", path), (False, False, False))

    def test_code_is_never_docs_only_even_as_markdown(self) -> None:
        self.assertEqual(self.flags("docs/CITY.md", "src/notes.md"), (False, False, True))
        self.assertEqual(self.flags("tests/test_x.gd"), (False, False, True))

    def test_anything_else_runs_everything(self) -> None:
        for path in (".github/workflows/ci.yml", "tools/lint.sh", "art/x.svg", "project.godot"):
            with self.subTest(path=path):
                self.assertEqual(self.flags("docs/CITY.md", path), (False, False, False))

    def test_an_empty_diff_runs_everything(self) -> None:
        self.assertEqual(self.flags(), (False, False, False))

    def test_a_folder_named_like_a_prefix_is_not_inside_it(self) -> None:
        self.assertEqual(self.flags("docs/todo-notes/x.txt"), (False, True, False))
        self.assertEqual(self.flags("srcs/x.gd"), (False, False, False))


TABLE = "\n".join(
    ["| Kind | Written by | Answers |", "| --- | --- | --- |"]
    + [f"| `k{i}` | `x.gd` | a `prose_word` that is not a kind |" for i in "abcdefghijkl"]
)


def written(*extra: str) -> dict[str, str]:
    calls = "\n".join(f'\tTelemetry.note("k{i}", "text")' for i in "abcdefghijkl")
    return {"src/a.gd": calls + "\n" + "\n".join(extra)}


class TelemetryKindsTests(unittest.TestCase):
    def test_equal_sets_pass(self) -> None:
        self.assertEqual(ci_telemetry_kinds.check(written(), TABLE), [])

    def test_a_kind_written_and_undocumented_fails(self) -> None:
        failures = ci_telemetry_kinds.check(written('Telemetry.note("chat", "x")'), TABLE)
        self.assertEqual(len(failures), 1)
        self.assertIn("`chat`", failures[0])

    def test_a_row_nothing_writes_fails(self) -> None:
        failures = ci_telemetry_kinds.check(written(), TABLE + "\n| `stale` | nobody | nothing |")
        self.assertEqual(len(failures), 1)
        self.assertIn("`stale`", failures[0])

    def test_the_shapes_a_call_takes(self) -> None:
        sources = {
            "src/b.gd": "\n".join(
                [
                    'Telemetry.note("calm" if calm else "left", text)',
                    'note("bare", text)',
                    "func note(kind: String, text: String) -> void:",
                    '# Telemetry.note("commented", x)',
                    '_log.note(kind, "not_a_kind")',
                    "Telemetry.note(kind_variable,",
                ]
            )
        }
        self.assertEqual(ci_telemetry_kinds.kinds_written(sources), {"calm", "left", "bare"})

    def test_a_scan_that_finds_nothing_is_a_failure(self) -> None:
        failures = ci_telemetry_kinds.check({}, "")
        self.assertEqual(len(failures), 2)


if __name__ == "__main__":
    unittest.main()
