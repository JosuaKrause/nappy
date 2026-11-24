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


def candidates(files: dict[str, str], section: str) -> list[dead_code.Candidate]:
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        write(root, files)
        return dead_code.FINDERS[section](root)


class BranchTests(unittest.TestCase):
    def test_an_enum_value_only_a_table_key_or_a_membership_or_equality_test_names_is_listed(self) -> None:
        kinds = "enum Kind { MADE, KEYED, ASKED, COMPARED }\n"
        body = (
            "const FLAGS := {\n\tKind.KEYED: true,\n}\n"
            "func ask(kind: Kind) -> bool:\n\tif kind in [Kind.ASKED, Kind.MADE]:\n\t\treturn kind == Kind.COMPARED\n"
            "\treturn false\n\nfunc make() -> Kind:\n\treturn Kind.MADE\n"
        )
        found = candidates({"src/kind.gd": "class_name KindHolder\n" + kinds + body}, "enums")
        self.assertEqual({c.name for c in found}, {"Kind.KEYED", "Kind.ASKED", "Kind.COMPARED"})

    def test_a_file_named_through_its_folder_by_a_test_is_named(self) -> None:
        files = {
            "tools/test_thing.py": 'RECORDINGS = TOOLS / "thing_recordings"\n',
            "tools/thing_recordings/ok-0.txt": "x\n",
            "tools/lonely_recordings/ok-0.txt": "x\n",
        }
        names = {c.path for c in candidates(files, "files")}
        self.assertIn("tools/lonely_recordings/ok-0.txt", names)
        self.assertNotIn("tools/thing_recordings/ok-0.txt", names)

    def test_a_tool_definition_only_a_test_uses_is_listed_with_its_test_uses(self) -> None:
        files = {
            "tools/helper.py": "def only_tested() -> None:\n    pass\n",
            "tools/test_helper.py": "import helper\nhelper.only_tested()\n",
        }
        found = candidates(files, "tools")
        self.assertEqual([(c.name, c.note) for c in found], [("only_tested", "used only by tests (1 words)")])

    def test_a_signal_emitted_only_outside_src_is_listed(self) -> None:
        files = {
            "src/thing.gd": "class_name Thing\nextends Node\nsignal woke\n",
            "tests/test_thing.gd": "extends Node\nfunc run(thing: Thing) -> void:\n\tthing.woke.emit()\n",
        }
        found = candidates(files, "signals")
        self.assertIn(("woke", "emitted only outside src/"), {(c.name, c.note) for c in found})

    def test_a_member_read_only_through_an_untyped_receiver_is_unsure(self) -> None:
        files = {
            "src/thing.gd": "class_name Thing\nextends Node\nfunc shy() -> void:\n\tpass\n",
            "src/user.gd": "class_name User\nextends Node\nfunc go(thing) -> void:\n\tthing.shy()\n",
        }
        notes = {c.name: c.note for c in candidates(files, "members")}
        self.assertTrue(notes["shy"].startswith("UNSURE-ONLY"), notes)

    def test_a_private_member_unused_in_each_of_two_files_is_listed_for_each_with_the_other_file_words(self) -> None:
        body = "extends Node\nfunc _helper() -> void:\n\tpass\n"
        files = {"src/a.gd": "class_name A\n" + body, "src/b.gd": "class_name B\n" + body}
        found = [c for c in candidates(files, "members") if c.name == "_helper"]
        self.assertEqual({c.path for c in found}, {"src/a.gd", "src/b.gd"})
        self.assertTrue(all("1 words of other files" in c.note for c in found), found)

    def test_a_root_with_no_src_is_refused_with_2(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            self.assertEqual(dead_code.main(["--root", temporary]), 2)

    def test_an_abbreviated_flag_is_refused(self) -> None:
        with self.assertRaises(SystemExit) as raised:
            dead_code.parse(["--sec", "enums"])
        self.assertEqual(raised.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
