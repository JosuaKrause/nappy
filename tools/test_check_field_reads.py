#!/usr/bin/env python3
"""Unit tests for `tools/check_field_reads.py`, against small trees written here and a throwaway repository.

CI's own step (`uv run python tools/check_field_reads.py`) holds the real tree to the real list; every case here
brings a list of its own, so a change to the game's code never turns these red.
"""

from __future__ import annotations

import io
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_field_reads as reads

THING = "class_name Thing\nextends RefCounted\nvar count := 0\nvar _hidden := 1\nvar other: Thing\nsignal woke\n"
THING += "const LIMIT := 3\nenum Mode { A }\nfunc go() -> void:\n\tpass\nfunc make() -> Thing:\n\treturn Thing.new()\n"
SUB = "class_name SubThing\nextends Thing\nvar extra := 0\n"


def found(src: dict[str, str], autoloads: dict[str, str] | None = None) -> set[tuple[str, str, str]]:
    tree = reads.Tree(src, autoloads or {})
    return {(r.klass, r.reader, r.name) for r in reads.reads_of(tree).reads}


def reader(body: str, head: str = "class_name Reader\nextends Node\n") -> dict[str, str]:
    return {"src/thing.gd": THING, "src/sub.gd": SUB, "src/reader.gd": head + body}


class ReadTests(unittest.TestCase):
    def test_a_typed_member_var_read_is_found_and_a_write_too(self) -> None:
        body = "var t: Thing\nfunc f() -> void:\n\tprint(t.count)\n\tt.count = 2\n\tt.count += 1\n"
        self.assertEqual(found(reader(body)), {("Thing", "src/reader.gd", "count")})

    def test_an_underscore_var_is_a_field_too(self) -> None:
        self.assertEqual(
            found(reader("var t: Thing\nfunc f() -> int:\n\treturn t._hidden\n")),
            {("Thing", "src/reader.gd", "_hidden")},
        )

    def test_methods_signals_constants_and_enums_are_no_breach(self) -> None:
        body = "var t: Thing\nfunc f() -> void:\n\tt.go()\n\tt.woke.connect(f)\n\tprint(Thing.LIMIT, Thing.Mode.A)\n"
        self.assertEqual(found(reader(body)), set())

    def test_an_engine_property_is_no_breach(self) -> None:
        self.assertEqual(found(reader("var n: Node2D\nfunc f() -> void:\n\tn.position.x = 1.0\n")), set())

    def test_a_var_holding_a_callable_that_is_called_is_a_call(self) -> None:
        self.assertEqual(found(reader("var t: Thing\nfunc f() -> void:\n\tt.count()\n")), set())

    def test_a_parameter_a_built_name_and_a_for_variable_type_the_receiver(self) -> None:
        body = (
            "func a(t: Thing) -> int:\n\treturn t.count\n"
            "func b() -> int:\n\tvar t := Thing.new()\n\treturn t.count\n"
            "func c(items: Array) -> int:\n\tfor t: Thing in items:\n\t\treturn t.count\n\treturn 0\n"
        )
        self.assertEqual(found(reader(body)), {("Thing", "src/reader.gd", "count")})

    def test_a_chain_through_a_typed_field_and_a_return_type(self) -> None:
        body = "var t: Thing\nfunc a() -> int:\n\treturn t.other.count\nfunc b() -> int:\n\treturn t.make().count\n"
        self.assertEqual(
            found(reader(body)), {("Thing", "src/reader.gd", "count"), ("Thing", "src/reader.gd", "other")}
        )

    def test_a_type_inferred_from_a_call_and_a_cast(self) -> None:
        body = (
            "var t: Thing\nfunc a(x) -> int:\n\tvar m := t.make()\n\tvar c := x as Thing\n\treturn m.count + c.count\n"
        )
        self.assertEqual(found(reader(body)), {("Thing", "src/reader.gd", "count")})
        self.assertEqual(
            found(reader("func a(x) -> int:\n\treturn (x as Thing).count\n")), {("Thing", "src/reader.gd", "count")}
        )

    def test_an_inherited_var_is_the_base_classes_field(self) -> None:
        body = "func a(s: SubThing) -> int:\n\treturn s.count + s.extra\n"
        self.assertEqual(
            found(reader(body)), {("Thing", "src/reader.gd", "count"), ("SubThing", "src/reader.gd", "extra")}
        )

    def test_an_untyped_receiver_is_skipped_never_failed(self) -> None:
        body = (
            "func a(x, items: Array) -> int:\n\tvar y = items[0]\n\tfor z in items:\n\t\tprint(z.count)\n"
            "\treturn x.count + y.count\n"
        )
        self.assertEqual(found(reader(body)), set())

    def test_a_name_typed_two_ways_in_one_function_is_unknown_but_not_across_functions(self) -> None:
        body = "func a(t: Thing) -> int:\n\treturn t.count\nfunc b(t: Reader) -> void:\n\tprint(t)\n"
        self.assertEqual(found(reader(body)), {("Thing", "src/reader.gd", "count")})
        body = "func a(t: Thing) -> int:\n\tvar u := 1\n\tvar t: Reader\n\treturn t.count + u\n"
        self.assertEqual(found(reader(body)), set())

    def test_its_own_fields_are_no_breach_nor_self_nor_its_related_classes(self) -> None:
        own = "class_name Thing\nvar count := 0\nvar other: Thing\nfunc f(t: Thing, s: SubThing) -> int:\n"
        own += "\treturn count + self.count + other.count + t.count + s.extra + s.count\n"
        self.assertEqual(found({"src/thing.gd": own, "src/sub.gd": SUB}), set())

    def test_an_inner_class_reading_its_outer_class_is_no_breach(self) -> None:
        body = (
            "var count := 0\nclass Helper:\n\tvar outer: Reader\n\tfunc f() -> int:\n"
            "\t\treturn outer.count + self.count\n"
        )
        self.assertEqual(found(reader(body)), set())

    def test_a_comment_and_a_string_are_not_a_read(self) -> None:
        body = 'var t: Thing\nfunc f() -> String:\n\t# t.count\n\treturn "t.count"\n'
        self.assertEqual(found(reader(body)), set())

    def test_an_autoload_is_a_receiver(self) -> None:
        src = {
            "src/autoload/bus.gd": "extends Node\nvar volume := 1.0\n",
            "src/reader.gd": "extends Node\nfunc f() -> float:\n\treturn Bus.volume\n",
        }
        self.assertEqual(found(src, {"Bus": "src/autoload/bus.gd"}), {("Bus", "src/reader.gd", "volume")})

    def test_a_static_var_read_through_the_class_name(self) -> None:
        src = {
            "src/c.gd": "class_name Cache\nstatic var shared := 1\n",
            "src/r.gd": "extends Node\nfunc f() -> int:\n\treturn Cache.shared\n",
        }
        self.assertEqual(found(src), {("Cache", "src/r.gd", "shared")})


class ListTests(unittest.TestCase):
    def tree_found(self, body: str) -> reads.Found:
        return reads.reads_of(reads.Tree(reader(body), {}))

    def test_an_unlisted_read_fails_and_a_listed_one_stands(self) -> None:
        got = self.tree_found("var t: Thing\nfunc f() -> int:\n\treturn t.count\n")
        self.assertEqual(len(reads.failures_of(got, [])), 1)
        self.assertIn("src/reader.gd:", reads.failures_of(got, [])[0])
        self.assertEqual(reads.failures_of(got, reads.entries_of("# [Thing] src/thing.gd\nsrc/reader.gd count\n")), [])

    def test_a_listed_line_with_no_read_is_a_remove_line(self) -> None:
        got = self.tree_found("func f() -> void:\n\tpass\n")
        text = "# [Thing] src/thing.gd\nsrc/reader.gd count\n"
        self.assertEqual(
            reads.failures_of(got, reads.entries_of(text)),
            ["REMOVE from tools/field_reads.txt: src/reader.gd count (no longer reads Thing.count)"],
        )

    def test_the_list_renders_sorted_and_parses_back(self) -> None:
        tree = reads.Tree(reader("var t: Thing\nfunc f() -> int:\n\treturn t.count + t._hidden\n"), {})
        got = reads.reads_of(tree)
        text = reads.render(tree, got)
        self.assertIn("# [Thing] src/thing.gd\nsrc/reader.gd _hidden\nsrc/reader.gd count\n", text)
        self.assertEqual(reads.failures_of(got, reads.entries_of(text)), [])
        self.assertEqual(reads.render(tree, got), text)

    def test_a_malformed_list_is_an_error(self) -> None:
        for text in ("src/a.gd count\n", "# [Thing] x\nsrc/a.gd\n", "# [Thing] x\na b\na b\n"):
            with self.assertRaises(reads.FieldReadsError):
                reads.entries_of(text)

    def test_against_the_base_an_added_line_fails_unless_it_moves_or_the_checker_changed(self) -> None:
        base = reads.entries_of("# [Thing] x\nsrc/old.gd count\nsrc/keep.gd count\n")
        now = reads.entries_of("# [Thing] x\nsrc/keep.gd count\nsrc/new.gd count\nsrc/other.gd extra\n")
        failing = reads.base_failures(now, base, {"src/old.gd": "src/new.gd"}, False)
        self.assertEqual(len(failing), 1)
        self.assertIn("src/other.gd extra", failing[0])
        self.assertEqual(len(reads.base_failures(now, base, {}, False)), 2)
        self.assertEqual(reads.base_failures(now, base, {}, True), [])
        self.assertEqual(reads.base_failures(now, None, {}, False), [])

    def test_a_rename_pairs_each_removed_line_with_one_added_line(self) -> None:
        base = reads.entries_of("# [Thing] x\nsrc/old.gd count\n")
        now = reads.entries_of("# [Thing] x\nsrc/a.gd count\nsrc/b.gd count\n")
        self.assertEqual(len(reads.base_failures(now, base, {"src/old.gd": "src/a.gd"}, False)), 1)


class EndToEndTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name)
        (self.root / "src").mkdir()
        (self.root / "tools").mkdir()
        (self.root / "project.godot").write_text("[autoload]\n\n[display]\n")
        for path, text in reader("var t: Thing\nfunc f() -> int:\n\treturn t.count\n").items():
            (self.root / path).write_text(text)

    def run_main(self, *argv: str) -> tuple[int, str]:
        out = io.StringIO()
        with redirect_stdout(out):
            code = reads.main(["--root", str(self.root), *argv])
        return code, out.getvalue()

    def git(self, *args: str) -> None:
        subprocess.run(["git", *args], cwd=self.root, capture_output=True, text=True, check=True)

    def test_write_then_check_passes_and_a_new_read_then_fails(self) -> None:
        self.assertEqual(self.run_main()[0], 1)
        self.assertEqual(self.run_main("--write")[0], 0)
        code, out = self.run_main()
        self.assertEqual(code, 0, out)
        (self.root / "src/reader.gd").write_text(
            (self.root / "src/reader.gd").read_text() + "func g() -> int:\n\treturn t._hidden\n"
        )
        code, out = self.run_main()
        self.assertEqual(code, 1)
        self.assertIn("FAILED: src/reader.gd:", out)

    def test_summary_and_list_print_and_do_not_fail(self) -> None:
        for flag in ("--summary", "--list"):
            code, out = self.run_main(flag)
            self.assertEqual(code, 0, out)
            self.assertIn("Thing", out)

    def test_base_fails_a_line_added_since_the_base_and_passes_a_moved_file(self) -> None:
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "t@example.com")
        self.git("config", "user.name", "t")
        self.git("config", "commit.gpgsign", "false")
        (self.root / "src/second.gd").write_text(
            "class_name Second\nextends Node\nvar t: Thing\nfunc f() -> int:\n\treturn t.count\n"
        )
        self.run_main("--write")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "base")
        self.assertEqual(self.run_main("--base", "HEAD")[0], 0)
        # a new reader, listed by hand: fails against the base
        (self.root / "src/third.gd").write_text(
            "class_name Third\nextends Node\nvar t: Thing\nfunc f() -> int:\n\treturn t.count\n"
        )
        self.run_main("--write")
        code, out = self.run_main("--base", "HEAD")
        self.assertEqual(code, 1)
        self.assertIn("the list only shrinks", out)
        # a moved reader file carries its line
        (self.root / "src/third.gd").unlink()
        self.git("mv", "src/second.gd", "src/moved.gd")
        self.run_main("--write")
        self.git("add", "-A")
        code, out = self.run_main("--base", "HEAD")
        self.assertEqual(code, 0, out)

    def test_unknown_flags_are_rejected(self) -> None:
        with redirect_stderr(io.StringIO()):
            for argv in (["--nonsense"], ["--write", "--base", "HEAD"]):
                with self.assertRaises(SystemExit) as caught:
                    reads.parse(argv)
                self.assertNotEqual(caught.exception.code, 0)


if __name__ == "__main__":
    unittest.main()
