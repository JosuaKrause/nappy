#!/usr/bin/env python3
"""Unit tests for `tools/check_overrides.py`, each against a small tree of `.gd` files in a temp folder."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_overrides

BASE = "class_name Base\nextends RefCounted\n\nfunc f() -> int:\n\treturn 1\n"


def hits(**files: str) -> list[str]:
    """The check's findings on a tree of `<folder>__<name>` files, written to a temp folder and read back."""
    with tempfile.TemporaryDirectory() as raw:
        root = Path(raw)
        for key, text in files.items():
            folder, name = key.split("__")
            (root / folder).mkdir(exist_ok=True)
            (root / folder / f"{name}.gd").write_text(text, encoding="utf-8")
        for folder in check_overrides.FOLDERS:
            (root / folder).mkdir(exist_ok=True)
        return check_overrides.check(check_overrides.read_checkout(root))


class CheckOverridesTests(unittest.TestCase):
    def test_an_override_with_its_line_passes(self) -> None:
        child = "class_name Child\nextends Base\n\n## Overrides Base.f.\nfunc f() -> int:\n\treturn 2\n"
        self.assertEqual(hits(src__base=BASE, src__child=child), [])

    def test_an_override_without_its_line_fails(self) -> None:
        child = "class_name Child\nextends Base\n\nfunc f() -> int:\n\treturn 2\n"
        found = hits(src__base=BASE, src__child=child)
        self.assertEqual(len(found), 1)
        self.assertIn("src/child.gd:4:", found[0])
        self.assertIn("Overrides Base.f.", found[0])

    def test_a_line_among_other_doc_lines_and_an_annotation_passes(self) -> None:
        child = (
            "class_name Child\nextends Base\n\n## Says what it is.\n##\n## Overrides Base.f.\n"
            '@warning_ignore("x")\nfunc f() -> int:\n\treturn 2\n'
        )
        self.assertEqual(hits(src__base=BASE, src__child=child), [])

    def test_a_line_on_a_method_that_overrides_nothing_fails(self) -> None:
        child = "class_name Child\nextends Base\n\n## Overrides Base.g.\nfunc g() -> int:\n\treturn 2\n"
        found = hits(src__base=BASE, src__child=child)
        self.assertEqual(len(found), 1)
        self.assertIn("overrides nothing", found[0])

    def test_a_misspelled_override_with_a_line_fails(self) -> None:
        child = "class_name Child\nextends Base\n\n## Overrides Base.f.\nfunc ff() -> int:\n\treturn 2\n"
        found = hits(src__base=BASE, src__child=child)
        self.assertEqual(len(found), 1)
        self.assertIn("ff overrides nothing", found[0])

    def test_a_line_naming_the_wrong_ancestor_fails(self) -> None:
        middle = "class_name Middle\nextends Base\n\n## Overrides Base.f.\nfunc f() -> int:\n\treturn 2\n"
        child = "class_name Child\nextends Middle\n\n## Overrides Base.f.\nfunc f() -> int:\n\treturn 3\n"
        found = hits(src__base=BASE, src__middle=middle, src__child=child)
        self.assertEqual(len(found), 1)
        self.assertIn("src/child.gd:5:", found[0])
        self.assertIn("nearest ancestor declaring it is Middle.f", found[0])

    def test_an_engine_virtual_needs_no_line_and_a_line_on_it_fails(self) -> None:
        plain = "class_name Plain\nextends Node\n\nfunc _ready() -> void:\n\tpass\n\nfunc _init() -> void:\n\tpass\n"
        self.assertEqual(hits(src__plain=plain), [])
        child = "class_name Child\nextends Base\n\nfunc _ready() -> void:\n\tpass\n"
        self.assertEqual(hits(src__base=BASE, src__child=child), [])
        marked = "class_name Child\nextends Node\n\n## Overrides Node._ready.\nfunc _ready() -> void:\n\tpass\n"
        self.assertEqual(len(hits(src__child=marked)), 1)

    def test_a_constructor_is_not_an_override(self) -> None:
        base = "class_name Base\nextends RefCounted\n\nfunc _init(a: int) -> void:\n\tpass\n"
        child = "class_name Child\nextends Base\n\nfunc _init() -> void:\n\tsuper(1)\n"
        self.assertEqual(hits(src__base=base, src__child=child), [])

    def test_a_project_virtual_redeclared_down_the_chain_needs_its_line(self) -> None:
        base = "class_name Base\nextends Node\n\nfunc _ready() -> void:\n\tpass\n"
        child = "class_name Child\nextends Base\n\nfunc _ready() -> void:\n\tsuper()\n"
        found = hits(src__base=base, src__child=child)
        self.assertEqual(len(found), 1)
        self.assertIn("Overrides Base._ready.", found[0])

    def test_a_two_level_chain_names_the_nearest_declaring_ancestor(self) -> None:
        middle = "class_name Middle\nextends Base\n\n## Overrides Base.f.\nfunc f() -> int:\n\treturn 2\n"
        passes = "class_name Child\nextends Middle\n\n## Overrides Middle.f.\nfunc f() -> int:\n\treturn 3\n"
        self.assertEqual(hits(src__base=BASE, src__middle=middle, src__child=passes), [])
        # A method only the grandparent declares is named after the grandparent, through the middle class.
        skipping = "class_name Middle\nextends Base\n"
        child = "class_name Child\nextends Middle\n\n## Overrides Base.f.\nfunc f() -> int:\n\treturn 3\n"
        self.assertEqual(hits(src__base=BASE, src__middle=skipping, src__child=child), [])

    def test_an_inner_class_is_named_outer_dot_inner(self) -> None:
        outer = (
            "class_name Outer\nextends RefCounted\n\n"
            "class Step extends RefCounted:\n\tfunc run() -> int:\n\t\treturn 1\n\n"
            "class Fast extends Step:\n\t## Overrides Outer.Step.run.\n\tfunc run() -> int:\n\t\treturn 2\n"
        )
        self.assertEqual(hits(src__outer=outer), [])
        unmarked = outer.replace("\t## Overrides Outer.Step.run.\n", "")
        found = hits(src__outer=unmarked)
        self.assertEqual(len(found), 1)
        self.assertIn("Outer.Step.run", found[0])

    def test_an_inner_class_extending_a_project_class_is_checked(self) -> None:
        fake = "extends RefCounted\n\nclass Fake extends Base:\n\tfunc f() -> int:\n\t\treturn 9\n"
        found = hits(src__base=BASE, tests__test_fake=fake)
        self.assertEqual(len(found), 1)
        self.assertIn("tests/test_fake.gd:4:", found[0])
        self.assertIn("Overrides Base.f.", found[0])

    def test_a_class_extended_by_path_is_named_by_its_file_stem(self) -> None:
        rig = "extends RefCounted\n\nfunc build() -> int:\n\treturn 1\n"
        child = 'extends "res://tests/rig.gd"\n\n## Overrides rig.build.\nfunc build() -> int:\n\treturn 2\n'
        self.assertEqual(hits(tests__rig=rig, tests__child=child), [])
        self.assertEqual(len(hits(tests__rig=rig, tests__child=child.replace("## Overrides rig.build.\n", ""))), 1)

    def test_an_abstract_base_method_is_declared_for_its_overrides(self) -> None:
        base = "@abstract\nclass_name Base\nextends RefCounted\n\n@abstract func f() -> int\n"
        child = "class_name Child\nextends Base\n\n## Overrides Base.f.\nfunc f() -> int:\n\treturn 1\n"
        self.assertEqual(hits(src__base=base, src__child=child), [])
        found = hits(src__base=base, src__child=child.replace("## Overrides Base.f.\n", ""))
        self.assertEqual(len(found), 1)
        self.assertIn("Overrides Base.f.", found[0])

    def test_a_func_in_a_string_is_not_a_method(self) -> None:
        child = 'class_name Child\nextends Base\n\nvar text := """\nfunc f() -> int:\n"""\n'
        self.assertEqual(hits(src__base=BASE, src__child=child), [])

    def test_a_comment_at_column_zero_does_not_end_an_inner_class(self) -> None:
        child = (
            "class_name C\nextends RefCounted\nclass I extends Base:\n#"
            " a note at column 0\n\tfunc f() -> int:\n\t\treturn 2\n"
        )
        found = hits(src__base=BASE, src__child=child)
        self.assertEqual(len(found), 1)
        self.assertIn("src/child.gd:5:", found[0])

    def test_a_triple_quote_in_a_comment_or_a_string_opens_nothing(self) -> None:
        for opener in ('# write """ for long text', 'var q := \'"""\'', 'var r := "a" # """'):
            child = f"class_name C\nextends Base\n{opener}\nfunc f() -> int:\n\treturn 2\n"
            found = hits(src__base=BASE, src__child=child)
            self.assertEqual(len(found), 1, opener)
            self.assertIn("src/child.gd:4:", found[0])

    def test_a_malformed_line_is_a_hit_of_its_own(self) -> None:
        for bad in (
            "## Overrides Base.f().",
            "## Overrides Base.f",
            "## overrides Base.f.",
            "## Overrides: Base.f.",
            "## Overrides `Base.f`.",
        ):
            for method in ("f", "ff"):
                child = f"class_name Child\nextends Base\n\n{bad}\nfunc {method}() -> int:\n\treturn 2\n"
                found = hits(src__base=BASE, src__child=child)
                self.assertEqual(len(found), 1, (bad, method))
                self.assertIn("is not the form", found[0])

    def test_two_lines_on_one_method_are_both_checked(self) -> None:
        child = (
            "class_name Child\nextends Base\n\n## Overrides Nope.f.\n"
            "## Overrides Base.f.\nfunc f() -> int:\n\treturn 2\n"
        )
        found = hits(src__base=BASE, src__child=child)
        self.assertEqual(len(found), 1)
        self.assertIn("Overrides Nope.f.", found[0])

    def test_an_inner_class_inherited_from_a_base_is_resolved(self) -> None:
        outer = "class_name B\nextends RefCounted\n\nclass Step extends Base:\n\tpass\n"
        child = "class_name C\nextends B\n\nclass Fast extends Step:\n\tfunc f() -> int:\n\t\treturn 2\n"
        found = hits(src__base=BASE, src__outer=outer, src__child=child)
        self.assertEqual(len(found), 1)
        self.assertIn("src/child.gd:5:", found[0])
        self.assertIn("Overrides Base.f.", found[0])

    def test_a_preload_alias_is_resolved(self) -> None:
        child = (
            'extends RefCounted\n\nconst B := preload("res://src/base.gd")\n'
            "\nclass I extends B:\n\tfunc f() -> int:\n\t\treturn 2\n"
        )
        found = hits(src__base=BASE, src__child=child)
        self.assertEqual(len(found), 1)
        self.assertIn("src/child.gd:6:", found[0])

    def test_a_relative_path_is_resolved(self) -> None:
        child = 'extends "base.gd"\n\nfunc f() -> int:\n\treturn 2\n'
        found = hits(src__base=BASE, src__child=child)
        self.assertEqual(len(found), 1)
        self.assertIn("Overrides Base.f.", found[0])

    def test_an_extends_that_cannot_be_resolved_is_a_hit(self) -> None:
        for extends, why in (('"uid://abc123"', "uid://"), ('"nowhere.gd"', "names no file")):
            found = hits(src__base=BASE, src__child=f"extends {extends}\n\nfunc f() -> int:\n\treturn 2\n")
            self.assertEqual(len(found), 1, extends)
            self.assertIn(why, found[0])
        alias = 'extends RefCounted\n\nconst B := preload("res://src/gone.gd")\n\nclass I extends B:\n\tpass\n'
        found = hits(src__child=alias)
        self.assertEqual(len(found), 1)
        self.assertIn("names no file", found[0])

    def test_the_command_line_reports_and_rejects(self) -> None:
        tool = str(Path(__file__).resolve().parent / "check_overrides.py")
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            (root / "src").mkdir()
            (root / "src" / "base.gd").write_text(BASE, encoding="utf-8")
            (root / "src" / "child.gd").write_text(
                "class_name Child\nextends Base\n\nfunc f() -> int:\n\treturn 2\n", encoding="utf-8"
            )
            failed = subprocess.run([sys.executable, tool, "--root", raw], capture_output=True, text=True)
            self.assertEqual(failed.returncode, 1)
            self.assertIn("src/child.gd:4:", failed.stdout)
            wrong = subprocess.run([sys.executable, tool, "--nope"], capture_output=True, text=True)
            self.assertEqual(wrong.returncode, 2)


if __name__ == "__main__":
    unittest.main()
