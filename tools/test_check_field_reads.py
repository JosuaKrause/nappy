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

THING = "class_name Thing\nextends RefCounted\nvar count := 0\nvar _hidden := 1\nvar other: Thing\nvar size := 0\n"
THING += "signal woke\n"
THING += "const LIMIT := 3\nenum Mode { A }\nfunc go() -> void:\n\tpass\nfunc make() -> Thing:\n\treturn Thing.new()\n"
SUB = "class_name SubThing\nextends Thing\nvar extra := 0\n"
LINE = '@warning_ignore_start("untyped_declaration", "unsafe_method_access")\n'


def found(src: dict[str, str], autoloads: dict[str, str] | None = None) -> set[tuple[str, str, str]]:
    tree = reads.Tree(src, autoloads or {})
    return {(r.klass, r.reader, r.name) for r in reads.reads_of(tree).reads}


def reader(body: str, head: str = "class_name Reader\nextends Node\n") -> dict[str, str]:
    return {"src/thing.gd": THING, "src/sub.gd": SUB, "src/reader.gd": head + body}


def unknown(src: dict[str, str]) -> list[tuple[int, str]]:
    return [(u.line, u.expression) for u in reads.reads_of(reads.Tree(src, {})).unknown]


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

    def test_an_untyped_receiver_is_skipped_in_a_file_with_the_line_and_unknown_without_it(self) -> None:
        body = (
            "func a(x, items: Array) -> int:\n\tvar y = items[0]\n\tfor z in items:\n\t\tprint(z.count)\n"
            "\treturn x.count + y.count\n"
        )
        opted = reader(body, LINE + "class_name Reader\nextends Node\n")
        self.assertEqual(found(opted), set())
        got = reads.reads_of(reads.Tree(opted, {}))
        self.assertEqual((got.skipped, got.unknown), (3, []))
        self.assertEqual(found(reader(body)), set())
        self.assertEqual(unknown(reader(body)), [(6, "z.count"), (7, "x.count"), (7, "y.count")])

    def test_what_the_engine_cannot_type_is_unknown_in_a_converted_file(self) -> None:
        body = (
            "func a(items: Array, d: Dictionary, v: Variant) -> void:\n\tprint(items[0].count)\n"
            "\tprint(items.back().count)\n\tprint(d.get(1).count)\n\tprint(v.count)\n\tprint(d.key.count)\n"
        )
        self.assertEqual(
            unknown(reader(body)),
            [
                (4, "items[0].count"),
                (5, "items.back().count"),
                (6, "d.get(1).count"),
                (7, "v.count"),
                (8, "d.key.count"),
            ],
        )

    def test_a_receiver_that_is_not_a_class_under_src_is_told_and_no_read(self) -> None:
        body = (
            "var cam: Camera2D\nfunc a(r: Rect2, n: Array[Node2D]) -> void:\n\tprint(r.size, cam.size, $Cam.size)\n"
            "\tprint(Vector2(1, 2).size, r.get_center().size, n[0].size, (r.size - r.size).size)\n"
            "\tvar w := Rect2(Vector2.ZERO,\n\t\t\tVector2.ONE)\n\tvar d := r.size * 2.0\n\tprint(w.size, d.size)\n"
            '\tvar s := "text"\n\tprint(s.size, get_parent().size, Engine.size)\n'
        )
        self.assertEqual((found(reader(body)), unknown(reader(body))), (set(), []))

    def test_a_typed_array_or_dictionary_gives_its_element(self) -> None:
        body = (
            "var all: Array[Thing] = []\nvar by: Dictionary[Thing, SubThing] = {}\nfunc a() -> int:\n"
            "\tfor t in all:\n\t\tprint(t.count)\n\tfor k in by:\n\t\tprint(k._hidden, by[k].extra)\n"
            "\tvar first := all[0]\n\treturn first.size + all.back().other.count + by.values()[0].extra\n"
        )
        self.assertEqual(
            found(reader(body)),
            {
                ("Thing", "src/reader.gd", "count"),
                ("Thing", "src/reader.gd", "_hidden"),
                ("Thing", "src/reader.gd", "size"),
                ("Thing", "src/reader.gd", "other"),
                ("SubThing", "src/reader.gd", "extra"),
            },
        )
        self.assertEqual(unknown(reader(body)), [])

    def test_a_name_declared_two_ways_in_one_function_takes_the_declaration_in_scope(self) -> None:
        body = (
            "func a(items: Array[Thing], subs: Array[Node2D]) -> void:\n\tfor x in items:\n\t\tprint(x.count)\n"
            "\tfor x in subs:\n\t\tprint(x.size)\n\tif true:\n\t\tvar y := Thing.new()\n\t\tprint(y._hidden)\n"
            "\telse:\n\t\tvar y := Vector2()\n\t\tprint(y.size)\n"
        )
        self.assertEqual(
            found(reader(body)), {("Thing", "src/reader.gd", "count"), ("Thing", "src/reader.gd", "_hidden")}
        )
        self.assertEqual(unknown(reader(body)), [])

    def test_a_chain_through_an_inner_class_and_an_inner_class_named_from_outside(self) -> None:
        holder = "class_name Holder\nextends RefCounted\nclass Box extends RefCounted:\n\tvar thing: Thing\n"
        holder += "\tfunc make() -> Thing:\n\t\treturn thing\n"
        body = (
            "class Mine:\n\tvar thing: Thing\nvar mine: Mine\nfunc a(box: Holder.Box) -> int:\n"
            "\treturn mine.thing.count + box.thing._hidden + box.make().size\n"
        )
        src = reader(body) | {"src/holder.gd": holder}
        self.assertEqual(
            found(src),
            {
                ("Thing", "src/reader.gd", "count"),
                ("Thing", "src/reader.gd", "_hidden"),
                ("Thing", "src/reader.gd", "size"),
            },
        )
        self.assertEqual(unknown(src), [])

    def test_a_ternary_of_a_class_and_its_subclass_is_the_base(self) -> None:
        body = "func a(c: bool) -> int:\n\tvar t := SubThing.new() if c else Thing.new()\n\treturn t.count\n"
        self.assertEqual(found(reader(body)), {("Thing", "src/reader.gd", "count")})

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

    def test_an_inner_class_built_by_its_bare_name_is_that_class(self) -> None:
        body = "class In:\n\tvar o: Thing\nfunc f() -> int:\n\tvar i := In.new()\n\treturn i.o.count\n"
        self.assertEqual(found(reader(body)), {("Thing", "src/reader.gd", "count")})
        body = "class In:\n\tvar o: Thing\nvar i := In.new()\nfunc f() -> int:\n\treturn i.o.count\n"
        self.assertEqual(found(reader(body)), {("Thing", "src/reader.gd", "count")})

    def test_a_local_shadowing_a_member_is_the_member_where_no_declaration_reaches(self) -> None:
        after_loop = (
            "var item: Thing\nfunc f(pts: Array[Vector2]) -> int:\n\tfor item: Vector2 in pts:\n\t\tpass\n"
            "\treturn item.count\n"
        )
        self.assertEqual(found(reader(after_loop)), {("Thing", "src/reader.gd", "count")})
        before_var = "var item: Thing\nfunc g() -> int:\n\tvar n := item.count\n\tvar item: Vector2\n\treturn n\n"
        self.assertEqual(found(reader(before_var)), {("Thing", "src/reader.gd", "count")})
        inside = (
            "var item: Thing\nfunc h(pts: Array[Vector2]) -> void:\n\tfor item: Vector2 in pts:\n\t\tprint(item.x)\n"
        )
        self.assertEqual((found(reader(inside)), unknown(reader(inside))), (set(), []))

    def test_the_array_constructor_gives_an_untyped_array(self) -> None:
        body = "func a(items: Array[Thing]) -> int:\n\treturn Array(items)[0].count\n"
        self.assertEqual(unknown(reader(body)), [(4, "Array(items)[0].count")])

    def test_a_static_var_read_through_the_class_name(self) -> None:
        src = {
            "src/c.gd": "class_name Cache\nstatic var shared := 1\n",
            "src/r.gd": "extends Node\nfunc f() -> int:\n\treturn Cache.shared\n",
        }
        self.assertEqual(found(src), {("Cache", "src/r.gd", "shared")})


class MethodReferenceTests(unittest.TestCase):
    def kinds(self, src: dict[str, str]) -> list[tuple[int, str, str]]:
        return [(u.line, u.expression, u.kind) for u in reads.reads_of(reads.Tree(src, {})).unknown]

    def test_a_method_of_an_unknown_receiver_read_without_parentheses_fails_in_a_converted_file(self) -> None:
        body = "func a(items: Array) -> bool:\n\treturn items[0].make\n"
        self.assertEqual(self.kinds(reader(body)), [(4, "items[0].make", reads.UNKNOWN_METHOD)])
        self.assertEqual(self.kinds(reader(body, LINE + "class_name Reader\nextends Node\n")), [])
        failure = reads.failures_of(reads.reads_of(reads.Tree(reader(body), {})), [])[0]
        self.assertIn("a reference to the function, always true", failure)

    def test_a_known_receivers_method_without_parentheses_fails_where_no_callable_is_handed_on(self) -> None:
        body = (
            "var t: Thing\nfunc f() -> Callable:\n\tif t.make:\n\t\tpass\n\tvar ok := not t.make\n"
            "\tvar cb := t.make\n\tg(t.make, 1)\n\tvar bound := t.make.bind(1)\n\tvar xs := [t.make]\n"
            "\treturn t.make if t else Callable()\nfunc g(c: Callable, n: int) -> void:\n\tpass\n"
        )
        self.assertEqual(
            self.kinds(reader(body)),
            [(5, "t.make", reads.REFERENCE), (7, "t.make", reads.REFERENCE)],
        )
        self.assertEqual(self.kinds(reader(body, LINE + "class_name Reader\nextends Node\n")), [])

    def test_a_name_that_is_also_a_var_a_signal_a_constant_or_an_engine_property_is_not_taken_for_a_method(
        self,
    ) -> None:
        other = (
            "class_name Other\nextends RefCounted\nvar make := 0\nsignal go\nconst LIMIT := 1\nfunc woke() -> void:"
            "\n\tpass\nfunc scale() -> float:\n\treturn 1.0\n"
        )
        body = "func a(items: Array) -> void:\n\tprint(items[0].scale)\n\titems[0].woke.connect(a)\n"
        src = reader(body) | {"src/other.gd": other}
        self.assertEqual(self.kinds(src), [])
        body = "func a(items: Array) -> void:\n\tprint(items[0].go)\n"
        self.assertEqual(self.kinds(reader(body) | {"src/other.gd": other}), [])


class OptOutTests(unittest.TestCase):
    def test_the_line_is_read_from_the_first_line_only(self) -> None:
        line = reads.opt_out_of(LINE + "extends Node\n")
        self.assertEqual(line, reads.OptOut(("untyped_declaration", "unsafe_method_access")))
        self.assertIsNone(reads.opt_out_of("extends Node\n" + LINE))

    def test_a_malformed_line_fails_and_so_does_an_ignore_below_the_first_line(self) -> None:
        files = {
            "src/a.gd": '@warning_ignore_start("unused_variable")\n',
            "src/b.gd": '@warning_ignore_start("untyped_declaration", "untyped_declaration")\n',
            "src/c.gd": "@warning_ignore_start(NAME)\n",
            "src/d.gd": "@warning_ignore_start()\n",
            "src/e.gd": 'extends Node\nfunc f() -> void:\n\t@warning_ignore("unsafe_method_access")\n\tpass\n',
            "src/f.gd": 'extends Node\n@warning_ignore_start("unsafe_property_access")\n',
            "tests/g.gd": LINE + 'func f() -> void:\n\t@warning_ignore("unused_variable")\n\tpass\n',
        }
        failing = reads.line_failures(files)
        self.assertEqual(
            [f.split(":", 2)[0] + ":" + f.split(":", 2)[1] for f in failing],
            ["src/a.gd:1", "src/b.gd:1", "src/c.gd:1", "src/d.gd:1", "src/e.gd:3", "src/f.gd:2"],
        )

    def test_every_form_of_ignore_the_engine_honours_is_read_and_fails_outside_the_one_form(self) -> None:
        files = {
            "src/a.gd": '@warning_ignore_start("untyped_declaration") # later\nvar t = 3\n',
            "src/b.gd": '@warning_ignore_start ("untyped_declaration")\nvar t = 3\n',
            "src/c.gd": '@warning_ignore_start(\n\t"untyped_declaration")\nvar t = 3\n',
            "src/d.gd": "extends Node\nfunc f() -> void:\n\t@warning_ignore('untyped_declaration')\n\tvar t = 3\n",
            "src/e.gd": (
                'extends Node\nfunc f() -> void:\n\t@warning_ignore(\n\t\t"untyped_declaration")\n\tvar t = 3\n'
            ),
            "src/f.gd": '@warning_ignore_start("unsafe_method_access", "untyped_declaration")\n',
            "src/g.gd": 'extends Node\nconst W := "untyped_declaration"\n@warning_ignore_start(W)\n',
            "src/h.gd": 'extends Node\n@warning_ignore_restore("unsafe_method_access") # a comment\n',
            "src/ok.gd": (
                '# @warning_ignore("untyped_declaration")\nextends Node\n'
                'var s := "@warning_ignore(\\"untyped_declaration\\")"\n@warning_ignore("unused_variable")\n'
            ),
        }
        failing = reads.line_failures(files)
        self.assertEqual(
            [":".join(f.split(":", 2)[:2]) for f in failing],
            [
                "src/a.gd:1",
                "src/b.gd:1",
                "src/c.gd:1",
                "src/d.gd:3",
                "src/e.gd:3",
                "src/f.gd:1",
                "src/g.gd:3",
                "src/h.gd:2",
            ],
        )
        self.assertIn('`@warning_ignore_start("untyped_declaration")`', failing[0])
        self.assertIn("out of the order", failing[5])
        self.assertIn("cannot read", failing[6])
        self.assertIsNone(reads.opt_out_of(files["src/a.gd"]))

    def test_an_opt_out_line_naming_nothing_is_told_to_go(self) -> None:
        self.assertEqual(
            reads.line_failures({"src/d.gd": "@warning_ignore_start()\n"}),
            ["src/d.gd:1: the opt-out line names no warning; delete it"],
        )

    def test_a_file_that_gains_the_line_is_told_what_to_write_instead(self) -> None:
        now: dict[str, tuple[str, ...]] = {
            "tests/test_new.gd": ("untyped_declaration",),
            "src/new.gd": ("untyped_declaration",),
        }
        failing = reads.base_line_failures(now, {}, {}, False)
        self.assertIn("type the declaration, or read the value through a typed name", failing[0])
        self.assertNotIn("TestRunner", failing[0])
        self.assertIn("`func run(t: TestRunner) -> void:`", failing[1])
        self.assertIn('"A suite is typed, and opens with the typed runner header"', failing[1])

    def test_against_the_base_a_file_gaining_the_line_or_a_warning_fails(self) -> None:
        base = {"src/a.gd": ("untyped_declaration",), "src/old.gd": ("untyped_declaration",), "src/gone.gd": ()}
        now = {
            "src/a.gd": ("untyped_declaration", "unsafe_method_access"),
            "src/new.gd": ("untyped_declaration",),
            "tests/fresh.gd": ("untyped_declaration",),
        }
        failing = reads.base_line_failures(now, base, {"src/old.gd": "src/new.gd"}, False)
        self.assertEqual(len(failing), 2)
        self.assertIn("src/a.gd:1: the opt-out line gains unsafe_method_access", failing[0])
        self.assertIn("tests/fresh.gd:1: gains the opt-out line", failing[1])
        self.assertEqual(reads.base_line_failures(now, base, {}, True), [])
        self.assertEqual(reads.base_line_failures({"src/a.gd": ()}, base, {}, False), [])

    def test_summary_counts_the_files_carrying_the_line_and_the_uses_skipped(self) -> None:
        got = reads.reads_of(reads.Tree(reader("func a(x) -> int:\n\treturn x.count\n", LINE + "extends Node\n"), {}))
        text = "\n".join(reads.summary(got, {"src/reader.gd": ("untyped_declaration",), "tests/t.gd": ()}))
        self.assertIn("2 file(s) still carry the opt-out line:\n  src        1\n  tests      1\n", text)
        self.assertIn("1 use(s) skipped", text)


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

    def test_an_unknown_receiver_in_a_converted_file_fails_naming_the_line_and_expression(self) -> None:
        self.run_main("--write")
        (self.root / "src/reader.gd").write_text(
            (self.root / "src/reader.gd").read_text() + "func g(items: Array) -> int:\n\treturn items[0].count\n"
        )
        code, out = self.run_main()
        self.assertEqual(code, 1)
        self.assertIn("FAILED: src/reader.gd:7: cannot tell the class of the receiver in `items[0].count`", out)
        (self.root / "src/reader.gd").write_text(LINE + (self.root / "src/reader.gd").read_text())
        code, out = self.run_main()
        self.assertEqual(code, 0, out)
        self.assertIn("1 file(s) still carry the opt-out line", out)

    def test_base_fails_a_file_that_gains_the_line_and_passes_one_that_drops_it(self) -> None:
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "t@example.com")
        self.git("config", "user.name", "t")
        self.git("config", "commit.gpgsign", "false")
        (self.root / "tests").mkdir()
        (self.root / "tests/test_a.gd").write_text(LINE + "extends Node\n")
        self.run_main("--write")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "base")
        (self.root / "tests/test_a.gd").write_text("extends Node\n")
        self.assertEqual(self.run_main("--base", "HEAD")[0], 0)
        (self.root / "tests/test_b.gd").write_text(LINE + "extends Node\n")
        code, out = self.run_main("--base", "HEAD")
        self.assertEqual(code, 1)
        self.assertIn("FAILED: tests/test_b.gd:1: gains the opt-out line", out)
        (self.root / "docs").mkdir()
        (self.root / "tests/test_b.gd").unlink()
        (self.root / "docs/probe.gd").write_text(LINE + "extends Node\n")
        self.assertEqual(self.run_main("--base", "HEAD")[0], 0)

    def test_unknown_flags_are_rejected(self) -> None:
        with redirect_stderr(io.StringIO()):
            for argv in (["--nonsense"], ["--write", "--base", "HEAD"]):
                with self.assertRaises(SystemExit) as caught:
                    reads.parse(argv)
                self.assertNotEqual(caught.exception.code, 0)


if __name__ == "__main__":
    unittest.main()
