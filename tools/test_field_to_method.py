#!/usr/bin/env python3
"""Tests for tools/field_to_method.py: the rewrite's pure parts, and whole runs against a replayed engine.

The engine is replaced by a script that prints, for each load of every script, the output a real Godot 4.7.2 gave
for the same fixture project in the same tool run (`tools/field_to_method_recordings/`, one file per load, read
with `ok-0.txt` the load before the rename, `ok-1.txt` the first after it, and so on). They were captured by
running the tool with a wrapper around the engine that kept each load's output, over a project whose
`project.godot` makes the three typing warnings errors as the game's does; the fixture below is that project. A
change to the tool's loop that asks the engine something else fails the replay's count rather than passing on
invented output.
"""

from __future__ import annotations

import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("field_to_method", TOOLS / "field_to_method.py")
assert spec is not None and spec.loader is not None
ftm = importlib.util.module_from_spec(spec)
sys.modules["field_to_method"] = ftm
spec.loader.exec_module(ftm)

BOX = """class_name Box
extends Node

var size: int = 3
var label := "x"

func double() -> int:
	return size * 2 + self.size


func name_of(size_of: int) -> int:
	return size_of
"""

READER = """extends Node

func run(box: Box) -> int:
	var other := box.size + box.size
	# box.size in a comment is not placed by the engine
	return other + box.size()
"""

REPLAY_ENGINE = """#!{python}
import pathlib, sys
if "--import" in sys.argv:
    sys.exit(0)
replay = pathlib.Path("{replay}")
counter = replay / "count"
n = int(counter.read_text()) if counter.exists() else 0
source = replay / ("{kind}-%d.txt" % n)
if not source.exists():
    print("replay has no load number %d" % n, file=sys.stderr)
    sys.exit(3)
counter.write_text(str(n + 1))
sys.stdout.write(source.read_text())
"""

PROJECT = """config_version=5

[application]
config/name="fixture"

[debug]
gdscript/warnings/untyped_declaration=2
gdscript/warnings/unsafe_property_access=2
gdscript/warnings/unsafe_method_access=2
"""
BOX_GD = """class_name Box
extends Node

var size: int = 3


func double() -> int:
	return size * 2
"""
SUB_BOX_GD = """class_name SubBox
extends Box
"""
BAD_BOX_GD = """class_name BadBox
extends Box


func twice() -> int:
	return size * 2
"""
READER_GD = """extends Node


func run(box: Box, sub: SubBox) -> int:
	var both := box.size + box.size
	var chained := (
		box
		.size
	)
	return both + chained + sub.size
"""
RECORDINGS = TOOLS / "field_to_method_recordings"


class RunTests(unittest.TestCase):
    def fixture(self, tmp: str, kind: str) -> tuple[Path, Path]:
        """The recorded project (with a script that fails after the rename when kind is "bad") and its engine."""
        root = Path(tmp) / "checkout"
        for sub in ("src", "tests", "tools"):
            (root / sub).mkdir(parents=True)
        (root / "project.godot").write_text(PROJECT)
        (root / "src" / "box.gd").write_text(BOX_GD)
        (root / "src" / "sub_box.gd").write_text(SUB_BOX_GD)
        (root / "tests" / "reader.gd").write_text(READER_GD)
        if kind == "bad":
            (root / "src" / "bad_box.gd").write_text(BAD_BOX_GD)
        replay = Path(tmp) / "replay"
        replay.mkdir()
        for recording in RECORDINGS.glob(kind + "-*.txt"):
            (replay / recording.name).write_text(recording.read_text())
        engine = Path(tmp) / "engine"
        engine.write_text(REPLAY_ENGINE.format(python=sys.executable, replay=replay, kind=kind))
        engine.chmod(0o755)
        return root, engine

    def run_tool(self, root: Path, engine: Path, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(TOOLS / "field_to_method.py"), "--root", str(root), "--godot", str(engine), *args],
            capture_output=True,
            text=True,
            timeout=60,
            env={**os.environ},
        )

    def test_dry_run_lists_every_use_and_writes_nothing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root, engine = self.fixture(tmp, "ok")
            result = self.run_tool(root, engine, "--dry-run", "src/box.gd", "size")
            self.assertEqual(result.returncode, 0, result.stderr)
            # three loads after the rename: the engine refused 4 uses, then the 1 a second use on a line left, then none
            self.assertIn("round 3: the engine refused 0 uses", result.stderr)
            self.assertIn("4 uses on 3 lines in 1 files", result.stdout)
            for use in ("tests/reader.gd:5:0 Box.size", "tests/reader.gd:5:1 Box.size", "tests/reader.gd:8:0 Box.size"):
                self.assertIn(use, result.stdout)
            # the subclass's use is a use of the class's field
            self.assertIn("tests/reader.gd:10:0 SubBox.size", result.stdout)
            self.assertIn("func size() -> int:", result.stdout)
            self.assertEqual((root / "tests" / "reader.gd").read_text(), READER_GD)
            self.assertEqual((root / "src" / "box.gd").read_text(), BOX_GD)

    def test_run_rewrites_both_uses_of_a_line_a_broken_chain_and_a_subclass_use(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root, engine = self.fixture(tmp, "ok")
            result = self.run_tool(root, engine, "src/box.gd", "size")
            self.assertEqual(result.returncode, 0, result.stderr)
            reader = (root / "tests" / "reader.gd").read_text()
            self.assertIn("var both := box.size() + box.size()", reader)
            self.assertIn("\t\t.size()\n", reader)
            self.assertIn("return both + chained + sub.size()", reader)
            box = (root / "src" / "box.gd").read_text()
            self.assertIn("var _size: int = 3", box)
            self.assertIn("return _size * 2", box)
            # the stub is read from the class's text before the rename, so it names the declaration's type
            self.assertIn("func size() -> int:\n\treturn _size", result.stdout)
            self.assertNotIn("Variant", result.stdout)

    def test_a_script_that_loaded_before_and_fails_after_is_refused_with_nothing_written(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root, engine = self.fixture(tmp, "bad")
            result = self.run_tool(root, engine, "src/box.gd", "size")
            self.assertEqual(result.returncode, 1)
            self.assertIn("refused, nothing written", result.stderr)
            self.assertIn("src/bad_box.gd", result.stderr)
            self.assertNotIn("tests/reader.gd\n", result.stderr.split("no use it could place:")[1])
            self.assertEqual((root / "src" / "box.gd").read_text(), BOX_GD)
            self.assertEqual((root / "tests" / "reader.gd").read_text(), READER_GD)

    def test_a_field_not_declared_is_refused_before_the_engine_runs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root, engine = self.fixture(tmp, "ok")
            result = self.run_tool(root, engine, "--dry-run", "src/box.gd", "weight")
            self.assertEqual(result.returncode, 1)
            self.assertIn("declares no public var weight", result.stderr)
            self.assertNotIn("copying", result.stderr)

    def test_a_local_named_like_the_field_is_refused_before_the_engine_runs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root, engine = self.fixture(tmp, "ok")
            (root / "src" / "box.gd").write_text(BOX_GD + "\n\nfunc grow(size: int) -> void:\n\tpass\n")
            result = self.run_tool(root, engine, "--dry-run", "src/box.gd", "size")
            self.assertEqual(result.returncode, 1)
            self.assertIn("names a local or a parameter size too", result.stderr)
            self.assertIn("func grow(size: int)", result.stderr)
            self.assertNotIn("copying", result.stderr)

    def test_a_stray_word_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root, engine = self.fixture(tmp, "ok")
            result = self.run_tool(root, engine, "src/box.gd", "Size!")
            self.assertEqual(result.returncode, 1)
            self.assertIn("not FIELD or FIELD=METHOD", result.stderr)


class PureTests(unittest.TestCase):
    def test_rename_leaves_calls_comments_and_longer_names(self) -> None:
        out = ftm.rename_fields(BOX, ["size"])
        self.assertIn("var _size: int = 3", out)
        self.assertIn("return _size * 2 + self._size", out)
        self.assertIn("func name_of(size_of: int)", out)
        self.assertIn("return size_of", out)

    def test_rewrite_turns_the_listed_use_into_a_call(self) -> None:
        uses = [ftm.Reader("a.gd", 4, 1, "Box", "size"), ftm.Reader("a.gd", 4, 0, "Box", "size")]
        out, done = ftm.rewrite_text("a.gd", READER, uses, {"size": "length"})
        self.assertEqual(done, 2)
        self.assertIn("var other := box.length() + box.length()", out)
        self.assertIn("return other + box.size()", out)

    def test_rewrite_is_idempotent_on_a_rewritten_line(self) -> None:
        once, _ = ftm.rewrite_text("a.gd", READER, [ftm.Reader("a.gd", 4, 0, "Box", "size")], {"size": "size"})
        self.assertIn("box.size() + box.size", once)
        with self.assertRaises(ftm.Refusal):
            ftm.rewrite_text("a.gd", once, [ftm.Reader("a.gd", 4, 1, "Box", "size")], {"size": "size"})

    def test_rewrite_refuses_a_use_it_cannot_place(self) -> None:
        with self.assertRaises(ftm.Refusal):
            ftm.rewrite_text("a.gd", READER, [ftm.Reader("a.gd", 4, 5, "Box", "size")], {"size": "size"})
        with self.assertRaises(ftm.Refusal):
            ftm.rewrite_text("a.gd", READER, [ftm.Reader("a.gd", 99, 0, "Box", "size")], {"size": "size"})

    def test_rewrite_refuses_a_name_already_private(self) -> None:
        text = "extends Node\nfunc f(b: Box) -> int:\n\treturn b._size\n"
        with self.assertRaises(ftm.Refusal):
            ftm.rewrite_text("a.gd", text, [ftm.Reader("a.gd", 3, 0, "Box", "size")], {"size": "size"})

    def test_check_specs_refuses(self) -> None:
        with self.assertRaises(ftm.Refusal):
            ftm.check_specs("b.gd", BOX, [ftm.Spec("_size", "size")])
        with self.assertRaises(ftm.Refusal):
            ftm.check_specs("b.gd", BOX, [ftm.Spec("nothing", "nothing")])
        with self.assertRaises(ftm.Refusal):
            ftm.check_specs("b.gd", BOX + "var _size := 1\n", [ftm.Spec("size", "size")])
        with self.assertRaises(ftm.Refusal):
            ftm.check_specs("b.gd", BOX, [ftm.Spec("size", "double")])
        with self.assertRaises(ftm.Refusal):
            ftm.check_specs("b.gd", "extends Node\nvar size := 1\n", [ftm.Spec("size", "size")])
        ftm.check_specs("b.gd", BOX, [ftm.Spec("size", "size")])

    def test_stub_names_the_declared_type(self) -> None:
        stubs = ftm.stubs(BOX, [ftm.Spec("size", "size"), ftm.Spec("label", "label_text")])
        self.assertEqual(stubs[0], "func size() -> int:\n\treturn _size")
        self.assertEqual(stubs[1], "func label_text() -> Variant:\n\treturn _label")


if __name__ == "__main__":
    unittest.main()
