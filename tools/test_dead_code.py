#!/usr/bin/env python3
"""Unit tests for `tools/dead_code.py`, against a small checkout written here."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import dead_code

THING = """class_name Thing
extends Node

enum Kind { USED, NEVER }

signal woke
signal quiet

func start() -> void:
	woke.emit()
	print(Kind.USED)

func live() -> void:
	pass

func lonely() -> void:
	pass

func _hidden() -> void:
	pass

func _ready() -> void:
	pass
"""
USER = """class_name User
extends Node

func go(thing: Thing) -> void:
	thing.start()
	thing.call("live")
	thing.woke.connect(go)
"""
TOOL = """def used() -> None:
    pass


def lonely_tool() -> None:
    pass


used()
"""


def write(root: Path, files: dict[str, str]) -> None:
    for name, text in files.items():
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")


class DeadCodeTests(unittest.TestCase):
    def survey(self, section: str) -> set[tuple[str, str]]:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root,
                {
                    "src/thing.gd": THING,
                    "src/user.gd": USER,
                    "tests/test_thing.gd": "extends Node\nfunc run() -> void:\n\tpass\n",
                    "tools/helper.py": TOOL,
                    "scenes/orphan.tscn": "[gd_scene]\n",
                    "scenes/used.tscn": "[gd_scene]\n",
                    "project.godot": 'run/main_scene="res://scenes/used.tscn"\n',
                },
            )
            found = dead_code.FINDERS[section](root)
        return {(c.kind, c.name) for c in found}

    def test_a_definition_nothing_names_is_listed_and_one_reached_by_a_call_string_is_not(self) -> None:
        found = self.survey("definitions")
        self.assertIn(("func", "lonely"), found)
        self.assertNotIn(("func", "live"), found)
        self.assertNotIn(("func", "start"), found)
        self.assertNotIn(("func", "_ready"), found)

    def test_a_member_no_receiver_reaches_is_dead_and_a_called_one_is_not(self) -> None:
        names = {name for _, name in self.survey("members")}
        self.assertIn("lonely", names)
        self.assertIn("_hidden", names)
        self.assertNotIn("start", names)
        # A call("live") is a string, which the typing does not read: the definitions section clears it.
        self.assertIn("live", names)

    def test_an_enum_value_named_once_is_listed(self) -> None:
        names = {name for _, name in self.survey("enums")}
        self.assertEqual(names, {"Kind.NEVER"})

    def test_a_signal_never_emitted_and_never_connected_is_listed_twice(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(root, {"src/thing.gd": THING, "src/user.gd": USER})
            notes = {(c.name, c.note) for c in dead_code.signal_candidates(root)}
        self.assertEqual(notes, {("quiet", "never emitted"), ("quiet", "never connected or referred to")})

    def test_a_file_no_other_file_names_is_listed(self) -> None:
        found = {name for _, name in self.survey("files")}
        self.assertIn("orphan.tscn", found)
        self.assertNotIn("used.tscn", found)

    def test_a_tool_definition_used_nowhere_is_listed(self) -> None:
        found = self.survey("tools")
        self.assertIn(("def", "lonely_tool"), found)
        self.assertNotIn(("def", "used"), found)

    def test_a_comment_is_not_a_use(self) -> None:
        self.assertEqual(dead_code.blank_comments('x = "# kept"  # gone'), 'x = "# kept"  ')


if __name__ == "__main__":
    unittest.main()
