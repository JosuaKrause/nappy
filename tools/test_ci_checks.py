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
import ci_no_handoff
import ci_queue_update
import ci_telemetry_kinds
import ci_transcription
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


class NoHandoffTests(unittest.TestCase):
    def test_an_added_handoff_file_fails_in_any_case_and_any_folder(self) -> None:
        for path in ("HANDOFF.md", "docs/agent-handoff-notes.txt", "notes/Handoffs/today.md"):
            with self.subTest(path=path):
                failures = ci_no_handoff.check([added(path)])
                self.assertEqual(len(failures), 1)
                self.assertTrue(failures[0].startswith(path))

    def test_a_rename_to_a_handoff_name_is_an_addition(self) -> None:
        self.assertEqual(len(ci_no_handoff.check([deleted("notes.md"), added("handoff.md")])), 1)

    def test_one_already_on_the_base_is_not_the_pull_requests(self) -> None:
        changes = [modified("docs/decisions/2026-09-09-handoff-rule.md"), deleted("handoff.md")]
        self.assertEqual(ci_no_handoff.check(changes), [])

    def test_other_additions_pass(self) -> None:
        self.assertEqual(ci_no_handoff.check([added("docs/playtests/x.md"), added("hand-off.md")]), [])


ENTRY = "2026-09-27-leafy-finch"
ITEM = f"docs/todo/{ENTRY}/capture.md"
PLAYTESTS = {
    "docs/playtests/2026-09-27-bouncy-heron.md": '> "let\'s drop the capture\n> script, it is not needed"\n',
    "docs/playtests/2026-09-28-snowy-moose.md": "Answering [the review item](../decisions/2026-09-26-M215.md).\n",
}


class QueueUpdateTests(unittest.TestCase):
    def check(self, changes: list[Change], description: str = "", records: tuple[str, ...] = ()) -> list[str]:
        return ci_queue_update.check(changes, set(records), PLAYTESTS, description)

    def test_adding_a_playtest_and_filing_an_entry_passes(self) -> None:
        changes = [added("docs/playtests/2026-09-29-new.md"), added(ITEM), modified(f"docs/todo/{ENTRY}/README.md")]
        self.assertEqual(self.check(changes), [])

    def test_an_existing_playtest_changed_or_deleted_fails(self) -> None:
        for change in (modified("docs/playtests/2026-09-27-bouncy-heron.md"), deleted("docs/playtests/old.md")):
            with self.subTest(status=change.status):
                failures = self.check([change])
                self.assertEqual(len(failures), 1)
                self.assertTrue(failures[0].startswith(change.path))

    def test_a_deleted_item_with_its_entrys_record_on_the_base_passes(self) -> None:
        self.assertEqual(self.check([deleted(ITEM)], records=(f"{ENTRY}.md",)), [])
        self.assertEqual(self.check([deleted(ITEM)], records=(f"{ENTRY}-2.md",)), [])

    def test_a_record_of_another_entry_does_not_count(self) -> None:
        self.assertEqual(len(self.check([deleted(ITEM)], records=(f"{ENTRY}-lemur.md", "other.md"))), 1)

    def test_a_deleted_item_with_nothing_to_account_for_it_fails_naming_it(self) -> None:
        failures = self.check([deleted(ITEM)])
        self.assertEqual(len(failures), 1)
        self.assertTrue(failures[0].startswith(ITEM))
        self.assertIn("Dropped:", failures[0])

    def test_a_drop_quoting_the_player_passes_for_the_file_or_its_folder(self) -> None:
        readme = f"docs/todo/{ENTRY}/README.md"
        for named in (ITEM, f"docs/todo/{ENTRY}/", f"`docs/todo/{ENTRY}`"):
            with self.subTest(named=named):
                description = f'Filing.\n\n- Dropped: {named} — "let\'s drop the capture script, it is not needed"\n'
                changes = [deleted(ITEM)] + ([deleted(readme)] if named != ITEM else [])
                self.assertEqual(self.check(changes, description), [])

    def test_a_drop_whose_words_are_not_in_a_playtest_fails(self) -> None:
        description = f'Dropped: {ITEM} -- "drop the capture tool"'
        failures = self.check([deleted(ITEM)], description)
        self.assertEqual(len(failures), 1)
        self.assertIn("appear in no file", failures[0])

    def test_a_drop_naming_nothing_deleted_or_not_in_the_form_fails(self) -> None:
        self.assertEqual(len(self.check([], f'Dropped: {ITEM} — "it is not needed"')), 1)
        failures = self.check([deleted(ITEM)], f"Dropped: {ITEM} because it is not needed")
        self.assertEqual(len(failures), 2)
        self.assertIn("does not have the form", failures[0])

    def test_an_item_moved_to_another_entry_unchanged_is_not_a_disappearance(self) -> None:
        changes = [deleted(ITEM, blob="e" * 40), added("docs/todo/2026-09-30-other/capture.md", blob="e" * 40)]
        self.assertEqual(self.check(changes), [])

    def test_a_deleted_review_item_needs_a_playtest_naming_it(self) -> None:
        self.assertEqual(self.check([deleted("docs/review/2026-09-26-M215.md")]), [])
        failures = self.check([deleted("docs/review/2026-09-27-leafy-lemur.md")])
        self.assertEqual(len(failures), 1)
        self.assertIn("2026-09-27-leafy-lemur", failures[0])

    def test_the_summary_prints_the_queue_line_of_each_entry_touched(self) -> None:
        changes = [added(ITEM), deleted("docs/todo/2026-09-01-gone/x.md")]
        entries = ci_queue_update.touched_entries(changes)
        self.assertEqual(entries, ["2026-09-01-gone", ENTRY])
        summary = ci_queue_update.queue_summary(entries, [f"now     {ENTRY}  leafy-finch — Issues as the inbox"])
        self.assertIn(f"now     {ENTRY}  leafy-finch", summary)
        self.assertIn("2026-09-01-gone: no longer in the queue", summary)


NOTE_BODY = (
    "currently shadows are oval below objects. for most objects the oval spans the entire visual bounding box.\r\n\r\n"
    "this does not read as shadow."
)
FILED_PLAYTEST = {
    "docs/playtests/2026-09-29-new.md": (
        '## Shadows\n\n> "currently shadows are oval below objects. for most objects the oval spans the\n'
        '> entire visual bounding box.\n>\n> this does not read as shadow."\n\n1. **Shadows.** → x.\n'
    )
}


def note(
    number: int = 423, author: str = "JosuaKrause", labels: tuple[str, ...] = ("inbox",), body: str = NOTE_BODY
) -> ci_transcription.Note:
    return ci_transcription.Note(number=number, author=author, labels=labels, body=body, is_pull_request=False)


class TranscriptionTests(unittest.TestCase):
    def test_the_filed_lines_are_read_once_each_in_order(self) -> None:
        description = (
            "Files two notes.\n\n- Filed from #423\nFiled from #7 (shadows)\nnot Filed from #9\nFiled from #423\n"
        )
        self.assertEqual(ci_transcription.filed_numbers(description), [423, 7])

    def test_the_players_note_copied_word_for_word_passes(self) -> None:
        self.assertEqual(ci_transcription.check([note()], FILED_PLAYTEST), [])

    def test_a_note_with_a_word_changed_fails_saying_where(self) -> None:
        playtest = {path: text.replace("visual bounding", "visible bounding") for path, text in FILED_PLAYTEST.items()}
        failures = ci_transcription.check([note()], playtest)
        self.assertEqual(len(failures), 1)
        self.assertIn("first 14 of", failures[0])
        self.assertIn("'visual bounding box.", failures[0])

    def test_a_note_in_no_added_playtest_fails(self) -> None:
        self.assertIn("adds no file", ci_transcription.check([note()], {})[0])

    def test_a_note_anyone_else_opened_fails_whatever_its_labels(self) -> None:
        failures = ci_transcription.check([note(author="someone", labels=("inbox", "captured"))], FILED_PLAYTEST)
        self.assertEqual(len(failures), 1)
        self.assertIn("never filed", failures[0])

    def test_a_captured_note_counts_only_with_the_label(self) -> None:
        for bot in ci_transcription.CAPTURE_BOTS:
            with self.subTest(bot=bot):
                self.assertEqual(
                    ci_transcription.check([note(author=bot, labels=("inbox", "captured"))], FILED_PLAYTEST), []
                )
                failures = ci_transcription.check([note(author=bot)], FILED_PLAYTEST)
                self.assertIn("without the `captured` label", failures[0])

    def test_another_bot_with_the_label_is_not_the_capture_script(self) -> None:
        failures = ci_transcription.check(
            [note(author="nappy-claude-coder[bot]", labels=("captured",))], FILED_PLAYTEST
        )
        self.assertEqual(len(failures), 1)

    def test_a_pull_request_or_an_empty_note_fails(self) -> None:
        pull = ci_transcription.Note(number=5, author="JosuaKrause", labels=(), body="x", is_pull_request=True)
        self.assertIn("a pull request", ci_transcription.check([pull], FILED_PLAYTEST)[0])
        self.assertIn("no body", ci_transcription.check([note(body=" \r\n")], FILED_PLAYTEST)[0])

    def test_the_api_shape_is_read_whatever_the_state(self) -> None:
        data: dict[str, object] = {
            "user": {"login": "JosuaKrause", "type": "User"},
            "labels": [{"name": "inbox"}, {"name": "queue_next"}],
            "body": None,
            "state": "closed",
        }
        read = ci_transcription.note_from_api(423, data)
        self.assertEqual(
            (read.author, read.labels, read.body, read.is_pull_request),
            ("JosuaKrause", ("inbox", "queue_next"), "", False),
        )


if __name__ == "__main__":
    unittest.main()
