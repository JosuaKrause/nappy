#!/usr/bin/env python3
"""Unit tests for `tools/typing_census.py`: what can be tested without the engine (the parsing of the debugger's
lines, the telling of a message to its warning, the rewriting of an opt-out line, the settings text, what `--check`
finds, whether a run finished, which failed files stop `--write`, and the restore of the tree on a temporary one).
Each case names the change to `tools/typing_census.py` it would fail."""

from __future__ import annotations

import sys
import tempfile
import unittest
from contextlib import redirect_stderr
from io import StringIO
from pathlib import Path
from typing import ClassVar

sys.path.insert(0, str(Path(__file__).resolve().parent))

import typing_census as census

FULL = '@warning_ignore_start("untyped_declaration", "unsafe_property_access", "unsafe_method_access")\n'
SOME = '@warning_ignore_start("untyped_declaration", "unsafe_method_access")\n'
BODY = "extends Node\nvar x = 1\n"

OUTPUT = """Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: The variable "x" has no static type.
     at: GDScript::reload (res://src/a.gd:3)
     GDScript backtrace (most recent call first):
         [0] _ready (res://tools/typing_census.gd:26)
WARNING: The variable "x" has no static type.
     at: GDScript::reload (res://src/a.gd:3)
WARNING: The property "count" is not present on the inferred type "Node" (but may be present on a subtype).
     at: GDScript::reload (res://tests/b.gd:9)
debug> SCRIPT ERROR: Parse Error: broken
          at: GDScript::reload (res://tests/c.gd:1)
CENSUS_FAILED res://tests/c.gd
CENSUS_LOADED res://src/a.gd
"""


class OptOutLine(unittest.TestCase):
    def test_names_are_read_in_order(self) -> None:
        self.assertEqual(census.opt_out_names(SOME), ["untyped_declaration", "unsafe_method_access"])

    def test_another_first_line_is_not_one(self) -> None:
        self.assertIsNone(census.opt_out_names("extends Node\n"))
        self.assertIsNone(census.opt_out_names('@warning_ignore_start("unused_variable")\n'))
        self.assertIsNone(census.opt_out_names("@tool\n"))

    def test_the_one_form(self) -> None:
        self.assertEqual(census.opt_out_line({"unsafe_method_access", "untyped_declaration"}), SOME)
        self.assertEqual(census.opt_out_line(set(census.TYPING)), FULL)


class Rewriting(unittest.TestCase):
    def test_a_line_is_rewritten_to_what_the_file_trips(self) -> None:
        self.assertEqual(
            census.with_line(FULL + BODY, {"untyped_declaration"}),
            '@warning_ignore_start("untyped_declaration")\n' + BODY,
        )
        self.assertEqual(census.with_line(SOME + BODY, set(census.TYPING)), FULL + BODY)

    def test_a_correct_line_is_left_as_it_is(self) -> None:
        text = SOME + BODY
        self.assertEqual(census.with_line(text, {"untyped_declaration", "unsafe_method_access"}), text)

    def test_the_line_of_a_file_that_trips_none_is_deleted(self) -> None:
        self.assertEqual(census.with_line(FULL + BODY, set()), BODY)

    def test_a_file_without_a_line_gains_none(self) -> None:
        self.assertEqual(census.with_line(BODY, set(census.TYPING)), BODY)

    def test_a_crooked_line_is_made_the_one_form(self) -> None:
        crooked = '@warning_ignore_start("unsafe_method_access",  "untyped_declaration")\n'
        self.assertEqual(census.with_line(crooked + BODY, set(census.TYPING[:1] + census.TYPING[2:])), SOME + BODY)

    def test_without_line_empties_only_an_opt_out_line(self) -> None:
        # Fails if the line is dropped instead of emptied: every line number the engine prints moves up by one.
        self.assertEqual(census.without_line(SOME + BODY), "\n" + BODY)
        self.assertEqual(census.without_line(BODY), BODY)

    def test_a_crlf_line_is_rewritten_with_crlf(self) -> None:
        # Fails if with_line writes the new line with a bare LF into a CRLF file.
        crlf = SOME.replace("\n", "\r\n") + "extends Node\r\n"
        self.assertEqual(
            census.with_line(crlf, {"untyped_declaration"}),
            '@warning_ignore_start("untyped_declaration")\r\nextends Node\r\n',
        )


class Output(unittest.TestCase):
    def test_hits_are_deduplicated_with_file_and_line(self) -> None:
        hits, failed = census.parse_output(OUTPUT)
        self.assertEqual([(h.path, h.line) for h in hits], [("src/a.gd", 3), ("tests/b.gd", 9)])
        self.assertEqual(failed, ["tests/c.gd"])

    def test_a_message_is_told_to_its_warning(self) -> None:
        hits, _ = census.parse_output(OUTPUT)
        self.assertEqual([census.classify(h.message) for h in hits], ["untyped_declaration", "unsafe_property_access"])
        self.assertEqual(
            census.classify('The method "go()" is not present on the inferred type "Node".'), "unsafe_method_access"
        )
        self.assertEqual(census.classify('Function "f()" has no static return type.'), "untyped_declaration")

    def test_an_unknown_message_is_told_to_none(self) -> None:
        self.assertIsNone(census.classify("Standalone expression (the line may have no effect)."))


class Checking(unittest.TestCase):
    def test_a_name_the_file_does_not_trip_is_stale(self) -> None:
        # Fails if check_file stops comparing the named warnings with the tripped ones.
        self.assertEqual(
            census.check_file("src/a.gd", FULL, {"untyped_declaration"}),
            [
                "src/a.gd: names unsafe_property_access, which it does not trip",
                "src/a.gd: names unsafe_method_access, which it does not trip",
            ],
        )

    def test_a_tripped_warning_the_line_lacks_is_found(self) -> None:
        # Fails if check_file reads only the names on the line, not what the file trips.
        self.assertEqual(
            census.check_file("src/a.gd", SOME, set(census.TYPING)),
            ["src/a.gd: trips unsafe_property_access, which its line does not name"],
        )

    def test_a_file_with_no_line_that_trips_is_found_and_one_that_does_not_passes(self) -> None:
        # Fails if a file with no line is skipped, or one that trips nothing is reported.
        self.assertEqual(
            census.check_file("src/a.gd", "extends Node\n", {"unsafe_method_access"}),
            ["src/a.gd: trips unsafe_method_access and has no opt-out line"],
        )
        self.assertEqual(census.check_file("src/a.gd", "extends Node\n", set()), [])

    def test_a_line_out_of_form_is_found(self) -> None:
        # Fails if the order and the duplicates of the names are not held.
        crooked = '@warning_ignore_start("unsafe_method_access", "untyped_declaration")\n'
        self.assertEqual(
            census.check_file("src/a.gd", crooked, {"untyped_declaration", "unsafe_method_access"}),
            ["src/a.gd: its line is not in the one form"],
        )

    def test_a_right_line_passes(self) -> None:
        self.assertEqual(census.check_file("src/a.gd", FULL, set(census.TYPING)), [])


class Finished(unittest.TestCase):
    PATHS: ClassVar[list[str]] = ["src/a.gd", "tests/b.gd"]
    GOOD = "CENSUS_LOADED res://src/a.gd\nCENSUS_FAILED res://tests/b.gd\nCENSUS_DONE 2\n"

    def test_a_run_that_answered_every_path_is_a_census(self) -> None:
        self.assertIsNone(census.finished(0, self.GOOD, self.PATHS))

    def test_an_engine_that_exited_badly_is_not(self) -> None:
        # Fails if the exit code is not read: a killed engine's partial output would count.
        self.assertIsNotNone(census.finished(1, self.GOOD, self.PATHS))

    def test_a_run_without_its_done_line_is_not(self) -> None:
        # Fails if CENSUS_DONE is not required, or its count is not held to the paths handed.
        self.assertIsNotNone(census.finished(0, self.GOOD.replace("CENSUS_DONE 2\n", ""), self.PATHS))
        self.assertIsNotNone(census.finished(0, self.GOOD.replace("DONE 2", "DONE 1"), self.PATHS))

    def test_a_run_that_skipped_a_path_is_not(self) -> None:
        # Fails if a path with no CENSUS_LOADED or CENSUS_FAILED line is taken as loaded with no warnings.
        self.assertIsNotNone(census.finished(0, "CENSUS_LOADED res://src/a.gd\nCENSUS_DONE 2\n", self.PATHS))


class Failures(unittest.TestCase):
    TEXTS: ClassVar[dict[str, str]] = {
        "src/dep.gd": "class_name Dep\n",
        "tests/probe.gd": "extends Node\n",
        "tests/user.gd": "var d = Dep.new()\n",
        "tests/preloader.gd": 'const P := preload("res://tests/other_probe.gd")\n',
        "tests/other_probe.gd": "extends Node\n",
    }

    def test_a_failed_file_under_src_stops_a_write(self) -> None:
        # Fails if only failures others name are counted: a failed src file changes what its dependents trip.
        self.assertEqual(
            census.untrusted_failures(["src/dep.gd"], {"src/dep.gd": "extends Node\n"}, ""), ["src/dep.gd"]
        )

    def test_a_failed_file_named_by_class_or_path_stops_a_write(self) -> None:
        # Fails if neither a class_name nor a res:// path counts as naming.
        texts = dict(self.TEXTS) | {"tests/dep2.gd": "class_name Dep2\n", "tests/u2.gd": "Dep2.new()\n"}
        self.assertEqual(census.untrusted_failures(["tests/dep2.gd"], texts, ""), ["tests/dep2.gd"])
        self.assertEqual(census.untrusted_failures(["tests/other_probe.gd"], texts, ""), ["tests/other_probe.gd"])

    def test_an_autoload_stops_a_write(self) -> None:
        # Fails if project.godot's autoload paths are not read.
        out = census.untrusted_failures(["tests/probe.gd"], self.TEXTS, 'X="*res://tests/probe.gd"\n')
        self.assertEqual(out, ["tests/probe.gd"])

    def test_a_failed_file_nothing_names_does_not(self) -> None:
        # Fails if every failure stops a write (the tool could not run on a tree with a probe that does not parse).
        self.assertEqual(census.untrusted_failures(["tests/probe.gd"], self.TEXTS, ""), [])


class Restoring(unittest.TestCase):
    def tree(self, files: dict[str, bytes]) -> tuple[census.Tree, Path]:
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        tmp = Path(scratch.name)
        for name, data in files.items():
            (tmp / name).write_bytes(data)
        return census.Tree(tmp), tmp

    def test_a_crlf_file_comes_back_byte_for_byte(self) -> None:
        # Fails if the files are read or written as text: the line endings would change.
        crlf = SOME.replace("\n", "\r\n").encode() + b"extends Node\r\nvar x = 1\r\n"
        tree, tmp = self.tree({"a.gd": crlf, "project.godot": b"[debug]\r\n"})
        tree.original_project = (tmp / "project.godot").read_bytes()
        tree.take_lines_out([tmp / "a.gd"])
        self.assertTrue((tmp / "a.gd").read_bytes().startswith(b"\nextends Node"))
        (tmp / "project.godot").write_bytes(b"changed")
        tree.restore()
        self.assertEqual((tmp / "a.gd").read_bytes(), crlf)
        self.assertEqual((tmp / "project.godot").read_bytes(), b"[debug]\r\n")

    def test_a_file_without_a_line_is_not_touched(self) -> None:
        # Fails if every file is recorded and rewritten: a save made to it during the run would be lost.
        tree, tmp = self.tree({"a.gd": SOME.encode() + b"x\n", "b.gd": b"extends Node\n"})
        tree.take_lines_out([tmp / "a.gd", tmp / "b.gd"])
        (tmp / "b.gd").write_bytes(b"extends Node\nvar edited = 1\n")
        tree.restore()
        self.assertEqual((tmp / "b.gd").read_bytes(), b"extends Node\nvar edited = 1\n")
        self.assertEqual((tmp / "a.gd").read_bytes(), SOME.encode() + b"x\n")

    def test_an_edit_below_the_line_survives_the_restore(self) -> None:
        # Fails if the restore writes the saved whole file back instead of the first line.
        tree, tmp = self.tree({"a.gd": SOME.encode() + b"x\n"})
        tree.take_lines_out([tmp / "a.gd"])
        (tmp / "a.gd").write_bytes(b"\nx\nvar edited = 1\n")
        tree.restore()
        self.assertEqual((tmp / "a.gd").read_bytes(), SOME.encode() + b"x\nvar edited = 1\n")

    def test_a_file_whose_first_line_was_changed_is_left_as_found(self) -> None:
        # Fails if the restore overwrites a first line somebody else wrote.
        tree, tmp = self.tree({"a.gd": SOME.encode() + b"x\n"})
        tree.take_lines_out([tmp / "a.gd"])
        (tmp / "a.gd").write_bytes(b"extends Node\nx\n")
        with redirect_stderr(StringIO()) as err:
            tree.restore()
        self.assertIn("left as it is", err.getvalue())
        self.assertEqual((tmp / "a.gd").read_bytes(), b"extends Node\nx\n")


class Settings(unittest.TestCase):
    def test_the_warning_settings_are_replaced(self) -> None:
        original = "[debug]\n\n; note\ngdscript/warnings/untyped_declaration=2\n\n[display]\nx=1\n"
        text = census.settings_text(original, {"untyped_declaration": 1, "unused_variable": 0})
        self.assertEqual(
            text,
            "[debug]\ngdscript/warnings/untyped_declaration=1\ngdscript/warnings/unused_variable=0\n"
            "\n; note\n\n[display]\nx=1\n",
        )


class Arguments(unittest.TestCase):
    def test_flags_and_warnings(self) -> None:
        args = census.parse(["--check", "--lines", "standalone_expression"])
        self.assertTrue(args.check and args.lines)
        self.assertEqual(args.warnings, ["standalone_expression"])

    def test_check_with_write_is_refused(self) -> None:
        # Fails if the exclusive pair is accepted.
        with self.assertRaises(SystemExit), redirect_stderr(StringIO()):
            census.parse(["--check", "--write"])

    def test_the_folder_a_path_is_counted_under(self) -> None:
        self.assertEqual(census.folder_of("src/a.gd"), "src")
        self.assertEqual(census.folder_of("tests/probes/a.gd"), "tests/probes")
        self.assertEqual(census.folder_of("tests/a.gd"), "tests")


if __name__ == "__main__":
    unittest.main()
