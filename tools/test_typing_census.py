#!/usr/bin/env python3
"""Unit tests for `tools/typing_census.py`: what can be tested without the engine (the parsing of the debugger's
lines, the telling of a message to its warning, the rewriting of an opt-out line, the settings text)."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

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

    def test_without_line_strips_only_an_opt_out_line(self) -> None:
        self.assertEqual(census.without_line(SOME + BODY), BODY)
        self.assertEqual(census.without_line(BODY), BODY)


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

    def test_an_unknown_flag_is_refused(self) -> None:
        with self.assertRaises(SystemExit):
            census.parse(["--bogus"])

    def test_the_folder_a_path_is_counted_under(self) -> None:
        self.assertEqual(census.folder_of("src/a.gd"), "src")
        self.assertEqual(census.folder_of("tests/probes/a.gd"), "tests/probes")
        self.assertEqual(census.folder_of("tests/a.gd"), "tests")


if __name__ == "__main__":
    unittest.main()
