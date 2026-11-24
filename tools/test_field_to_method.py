#!/usr/bin/env python3
"""Tests for tools/field_to_method.py: the rewrite's pure parts, and the whole run against a stand-in engine.

The stand-in engine is a script that answers the way the parser does for a tiny fixture class: it reports
"The property X is not present on the inferred type T" for each `.X` use of a renamed field that is not yet
renamed, which is what the fix loop reads. No real engine is started.
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

STUB_ENGINE = """#!{python}
import re, sys
args = sys.argv[1:]
if "--import" in args:
    sys.exit(0)
root = args[args.index("--path") + 1]
import pathlib
failed = 0
for path in sorted(pathlib.Path(root).rglob("*.gd")):
    rel = path.relative_to(root).as_posix()
    if not rel.startswith(("src/", "tests/")):
        continue
    for n, line in enumerate(path.read_text().split("\\n"), start=1):
        if line.lstrip().startswith("#"):
            continue
        if re.search(r"\\.size(?![A-Za-z0-9_(])", line):
            print('SCRIPT ERROR: Parse Error: The property "size" is not present on the inferred type "Box"')
            print("          at: GDScript::reload (res://%s:%d)" % (rel, n))
print("PROBE_DONE 3 0")
"""


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


class RunTests(unittest.TestCase):
    def fixture(self, root: Path) -> Path:
        (root / "src").mkdir()
        (root / "tests").mkdir()
        (root / "tools").mkdir()
        (root / "src" / "box.gd").write_text(BOX)
        (root / "tests" / "reader.gd").write_text(READER)
        (root / "project.godot").write_text("")
        engine = root.parent / (root.name + "-engine")
        engine.write_text(STUB_ENGINE.format(python=sys.executable))
        engine.chmod(0o755)
        return engine

    def run_tool(self, root: Path, engine: Path, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(TOOLS / "field_to_method.py"), "--root", str(root), "--godot", str(engine), *args],
            capture_output=True,
            text=True,
            timeout=60,
            env={**os.environ},
        )

    def test_dry_run_lists_and_writes_nothing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "checkout"
            root.mkdir()
            engine = self.fixture(root)
            result = self.run_tool(root, engine, "--dry-run", "src/box.gd", "size")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("2 uses on 1 lines in 1 files", result.stdout)
            self.assertIn("tests/reader.gd:4:0 Box.size", result.stdout)
            self.assertIn("func size() -> int:", result.stdout)
            self.assertEqual((root / "tests" / "reader.gd").read_text(), READER)
            self.assertEqual((root / "src" / "box.gd").read_text(), BOX)

    def test_run_rewrites_the_readers_and_renames_the_field(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "checkout"
            root.mkdir()
            engine = self.fixture(root)
            result = self.run_tool(root, engine, "src/box.gd", "size")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("var other := box.size() + box.size()", (root / "tests" / "reader.gd").read_text())
            self.assertIn("var _size: int = 3", (root / "src" / "box.gd").read_text())
            # a second run finds the field no longer public and refuses with nothing written
            again = self.run_tool(root, engine, "src/box.gd", "size")
            self.assertEqual(again.returncode, 1)
            self.assertIn("refused, nothing written", again.stderr)

    def test_a_field_not_declared_is_refused_before_the_engine_runs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "checkout"
            root.mkdir()
            engine = self.fixture(root)
            result = self.run_tool(root, engine, "--dry-run", "src/box.gd", "weight")
            self.assertEqual(result.returncode, 1)
            self.assertIn("declares no public var weight", result.stderr)
            self.assertNotIn("copying", result.stderr)

    def test_a_stray_word_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "checkout"
            root.mkdir()
            engine = self.fixture(root)
            result = self.run_tool(root, engine, "src/box.gd", "Size!")
            self.assertEqual(result.returncode, 1)
            self.assertIn("not FIELD or FIELD=METHOD", result.stderr)


if __name__ == "__main__":
    unittest.main()
