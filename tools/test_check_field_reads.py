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
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_field_reads as reads

THING = "class_name Thing\nextends RefCounted\nvar count := 0\nvar _hidden := 1\nvar other: Thing\nvar size := 0\n"
THING += "signal woke\n"
THING += "const LIMIT := 3\nenum Mode { A }\nfunc go() -> void:\n\tpass\nfunc make() -> Thing:\n\treturn Thing.new()\n"
SUB = "class_name SubThing\nextends Thing\nvar extra := 0\n"
LINE = '@warning_ignore_start("untyped_declaration", "unsafe_method_access")\n'


def rd(name: str, uses: int = 1, member: str = "count", kind: str = "Thing") -> str:
    """A file `name` whose `uses` functions each read `member` of a typed `kind`."""
    body = f"class_name {name}\nextends Node\nvar t: {kind}\n"
    return body + "".join(f"func f{n}() -> int:\n\treturn t.{member}\n" for n in range(uses))


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

    def test_self_inside_an_inner_class_is_an_engine_value_and_nothing_behind_it_is_seen(self) -> None:
        # The docstring's blind spot: `self` heads a chain as the inner class's own member names do not.
        body = (
            "class In:\n\tvar t: Thing\n\tfunc f() -> int:\n\t\treturn self.t.count\n"
            "\tfunc g() -> void:\n\t\tself.t.go\n"
        )
        self.assertEqual((found(reader(body)), unknown(reader(body))), (set(), []))
        bare = body.replace("self.t.", "t.")
        self.assertEqual(found(reader(bare)), {("Thing", "src/reader.gd", "count")})

    def test_a_chain_through_an_engine_property_typed_variant_is_not_seen(self) -> None:
        # The docstring's blind spot: `JSON.data` is typed Variant, and the chain is told as an engine value.
        body = "func f() -> int:\n\tvar j := JSON.new()\n\treturn j.data.count\n"
        self.assertEqual((found(reader(body)), unknown(reader(body))), (set(), []))

    def test_a_parameter_list_closing_at_the_margin_hides_its_parameters(self) -> None:
        # The docstring's blind spot: a `)` at the margin opens a new block, which declares no parameter.
        tail = "\treturn a.count + b.size\n"
        seen = (
            "func f(a: Thing,\n\t\tb: Thing) -> int:\n" + tail,
            "func f(\n\t\ta: Thing,\n\t\tb: Thing) -> int:\n" + tail,
            "func f(\n\ta: Thing,\n\tb: Thing,\n\t) -> int:\n" + tail,
        )
        for body in seen:
            self.assertEqual(
                found(reader(body)), {("Thing", "src/reader.gd", "count"), ("Thing", "src/reader.gd", "size")}, body
            )
        margin = "func f(\n\t\ta: Thing,\n\t\tb: Thing,\n) -> int:\n" + tail
        self.assertEqual(found(reader(margin)), set())
        hidden = "func f(\n\t\txs: Array,\n) -> int:\n\treturn xs[0].count\n"
        self.assertEqual(unknown(reader(hidden)), [])
        self.assertEqual(unknown(reader(hidden.replace("\n) -> int", ") -> int"))), [(5, "xs[0].count")])

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
        self.assertIn("where the name is a dictionary's key, subscript it", failure)

    def test_a_builtin_types_member_is_not_taken_for_a_method(self) -> None:
        other = "class_name Other\nextends RefCounted\nfunc end() -> int:\n\treturn 0\n"
        body = "func a(rects: Array) -> void:\n\tprint(rects[0].end)\n"
        self.assertEqual(self.kinds(reader(body) | {"src/other.gd": other}), [])

    def test_what_counts_as_a_var_a_class_declares(self) -> None:
        # A var of a class a receiver can name (a class_name or an autoload) counts; one only an inner class or a
        # file with no class_name declares does not, and a use of it through an unknown receiver is not seen.
        inner = "class_name Holder\nextends RefCounted\nclass Box:\n\tvar boxed := 0\n"
        nameless = "extends Node\nvar loose := 0\n"
        src = reader("func a(items: Array) -> void:\n\tprint(items[0].boxed, items[0].loose)\n") | {
            "src/holder.gd": inner,
            "src/nameless.gd": nameless,
        }
        self.assertEqual(self.kinds(src), [])
        names = sorted(reads.var_names_of(reads.Tree(src, {})))
        self.assertEqual(names, ["_hidden", "count", "extra", "other", "size"])
        auto = reader("func a(items: Array) -> void:\n\tprint(items[0].loose)\n") | {"src/nameless.gd": nameless}
        tree = reads.Tree(auto, {"Loose": "src/nameless.gd"})
        self.assertEqual([(u.expression, u.kind) for u in reads.reads_of(tree).unknown], [("items[0].loose", "var")])

    def test_what_excuses_a_methods_name_on_an_unknown_receiver(self) -> None:
        # A var of a named class: the use fails as the var's. A constant or an enum: excused. A var only an inner
        # class or a file with no class_name declares, or a signal: not excused, the use fails as the method's.
        other = (
            "class_name Other\nextends RefCounted\nvar make := 0\nconst LIMIT := 1\nenum Mode { A }\nsignal woke\n"
            "class Box:\n\tvar boxed := 0\nfunc LIMIT() -> void:\n\tpass\nfunc Mode() -> void:\n\tpass\n"
            "func woke() -> void:\n\tpass\nfunc boxed() -> void:\n\tpass\nfunc loose() -> void:\n\tpass\n"
        )
        nameless = "extends Node\nvar loose := 0\n"
        body = (
            "func a(items: Array) -> void:\n\tprint(items[0].make)\n\tprint(items[0].LIMIT, items[0].Mode)\n"
            "\titems[0].woke.connect(a)\n\tprint(items[0].boxed)\n\tprint(items[0].loose)\n"
        )
        src = reader(body) | {"src/other.gd": other, "src/nameless.gd": nameless}
        self.assertEqual(
            self.kinds(src),
            [
                (4, "items[0].make", reads.UNKNOWN_VAR),
                (6, "items[0].woke", reads.UNKNOWN_METHOD),
                (7, "items[0].boxed", reads.UNKNOWN_METHOD),
                (8, "items[0].loose", reads.UNKNOWN_METHOD),
            ],
        )

    def test_the_engine_names_are_a_fixed_list(self) -> None:
        # `scale` is in ENGINE_PROPERTIES and excused; `visible`, an engine property the list does not hold, is
        # taken for the project's method until the list gains it.
        self.assertIn("scale", reads.ENGINE_PROPERTIES)
        self.assertNotIn("visible", reads.ENGINE_PROPERTIES)
        self.assertIn("rect", reads.ENGINE_PROPERTIES)
        # `rect` is also an inner class's var here, which no longer excuses a method's name: the list does.
        other = (
            "class_name Other\nextends RefCounted\nclass Box:\n\tvar rect := Rect2()\nfunc scale() -> float:"
            "\n\treturn 1.0\nfunc visible() -> bool:\n\treturn true\nfunc rect() -> Rect2:\n\treturn Rect2()\n"
        )
        body = "func a(items: Array) -> void:\n\tprint(items[0].scale, items[0].visible, items[0].rect)\n"
        self.assertEqual(
            self.kinds(reader(body) | {"src/other.gd": other}), [(4, "items[0].visible", reads.UNKNOWN_METHOD)]
        )

    def test_an_inner_classs_and_a_nameless_files_members_count_like_a_classs(self) -> None:
        # A method an inner class or a file with no class_name declares is a method; a constant or an enum an inner
        # class declares excuses a method's name; a signal an inner class declares does not.
        other = (
            "class_name Other\nextends RefCounted\nclass Box:\n\tconst cap := 1\n\tenum Kind { A }\n\tsignal rang\n"
            "\tfunc poke() -> void:\n\t\tpass\n\tstatic func forge() -> void:\n\t\tpass\n"
            "func cap() -> void:\n\tpass\nfunc Kind() -> void:\n\tpass\nfunc rang() -> void:\n\tpass\n"
        )
        nameless = "extends Node\nfunc prod() -> void:\n\tpass\n"
        body = (
            "func a(items: Array) -> void:\n\tprint(items[0].poke, items[0].forge, items[0].prod)\n"
            "\tprint(items[0].cap, items[0].Kind)\n\tprint(items[0].rang)\n"
        )
        self.assertEqual(
            self.kinds(reader(body) | {"src/other.gd": other, "src/nameless.gd": nameless}),
            [
                (4, "items[0].poke", reads.UNKNOWN_METHOD),
                (4, "items[0].forge", reads.UNKNOWN_METHOD),
                (4, "items[0].prod", reads.UNKNOWN_METHOD),
                (6, "items[0].rang", reads.UNKNOWN_METHOD),
            ],
        )


class TypedMethodReferenceTests(unittest.TestCase):
    """A typed receiver's own method named without its parentheses fails unless the reference hands the Callable on,
    in one of the forms the checker's docstring numbers; each form has its case below."""

    def refs(self, src: dict[str, str], autoloads: dict[str, str] | None = None) -> list[tuple[int, str]]:
        tree = reads.Tree(src, autoloads or {})
        return [(u.line, u.expression) for u in reads.reads_of(tree).unknown if u.kind == reads.REFERENCE]

    def handed(self, body: str, references: int) -> None:
        """`body`, functions of Reader holding `t: Thing`, makes `references` references to Thing's methods, and each
        hands the Callable on: nothing fails, and every one fails where nothing counts as handing it on."""
        src = reader("var t: Thing\n" + body + "func g(a: Variant, b: Variant = null) -> void:\n\tpass\n")
        self.assertEqual(self.refs(src), [])
        with mock.patch.object(reads, "hands_on", return_value=False):
            self.assertEqual(len(self.refs(src)), references)

    def test_a_reference_that_hands_nothing_on_fails_with_the_line_or_without(self) -> None:
        body = (
            "var t: Thing\nvar d := {}\nfunc f() -> void:\n\tt.go\n\tif t.make:\n\t\tpass\n\telif t.make:\n"
            "\t\tpass\n\twhile t.make:\n\t\tbreak\n\tassert(t.make)\n\tassert(t.make, 'message')\n"
            "\tvar a := not t.make\n\tvar b := d[t.make]\n\tvar c := {1: t.make}\n\tif (t.make):\n\t\tpass\n"
            "\tvar e := t.make == null\n"
        )
        lines = [6, 7, 9, 11, 13, 14, 15, 16, 17, 18, 20]
        self.assertEqual(self.refs(reader(body)), [(n, "t.go" if n == 6 else "t.make") for n in lines])
        with_line = reader(body, LINE + "class_name Reader\nextends Node\n")
        self.assertEqual(self.refs(with_line), [(n + 1, "t.go" if n == 6 else "t.make") for n in lines])
        failure = reads.failures_of(reads.reads_of(reads.Tree(reader(body), {})), [])[0]
        self.assertIn("src/reader.gd:6: `t.go` names a method of the receiver's class without its parentheses", failure)
        self.assertIn("always true in a condition", failure)
        self.assertIn("tools/check_field_reads.py --help", failure)

    def test_it_reaches_a_name_the_unknown_receiver_rule_excuses(self) -> None:
        # `clear` is an inner class's var elsewhere, `scale` an engine property name and another file's constant,
        # `count` another class's var: none of that excuses the receiver's own method.
        crowd = (
            "class_name Crowd\nextends Node\nfunc clear() -> void:\n\tpass\nfunc scale() -> float:\n\treturn 1.0\n"
            "func count() -> int:\n\treturn 0\n"
        )
        other = "class_name Other\nextends RefCounted\nconst scale := 1\nclass Start:\n\tvar clear := true\n"
        body = "var crowd: Crowd\nfunc f() -> void:\n\tcrowd.clear\n\tif crowd.scale:\n\t\tpass\n\tprint(crowd.count)\n"
        src = reader(body) | {"src/crowd.gd": crowd, "src/other.gd": other}
        self.assertIn("scale", reads.ENGINE_PROPERTIES)
        self.assertEqual(self.refs(src), [(5, "crowd.clear"), (6, "crowd.scale")])

    def test_an_inherited_method_an_inner_classs_an_autoloads_its_own_through_self_and_a_static_one(self) -> None:
        body = (
            "var sub: SubThing\nclass Box:\n\tfunc poke() -> void:\n\t\tpass\nfunc own() -> void:\n\tpass\n"
            "func f() -> void:\n\tsub.go\n\tvar box := Box.new()\n\tbox.poke\n\tself.own\n\tLoose.prod\n\tThing.go\n"
        )
        nameless = "extends Node\nfunc prod() -> void:\n\tpass\n"
        src = reader(body) | {"src/nameless.gd": nameless}
        self.assertEqual(
            self.refs(src, {"Loose": "src/nameless.gd"}),
            [(10, "sub.go"), (12, "box.poke"), (13, "self.own"), (14, "Loose.prod"), (15, "Thing.go")],
        )

    def test_an_engine_value_a_field_and_an_unknown_receiver_are_not_this_rule(self) -> None:
        # An engine value's methods are the docstring's blind spot; a field is a read; an unknown receiver is the
        # other rule's.
        body = "var t: Thing\nfunc f(n: Node, items: Array) -> void:\n\tif n.is_inside_tree or t.count:\n\t\tpass\n"
        body += "\tif items[0].make:\n\t\tpass\n"
        src = reader(body)
        self.assertEqual(self.refs(src), [])
        self.assertEqual(unknown(src), [(7, "items[0].make")])

    def test_form_1_a_step_follows_it(self) -> None:
        self.handed("func f() -> void:\n\tt.go.call()\n\tvar cb := t.go.bind(1)\n\tif t.go.is_valid():\n\t\tpass\n", 3)

    def test_form_2_an_argument_of_a_call(self) -> None:
        self.handed(
            "signal done\nfunc f() -> void:\n\tg(t.go)\n\tg(1, t.make)\n\tdone.connect(t.go)\n"
            "\tg(\n\t\t1,\n\t\tt.go,\n\t)\n\tg(\n\t\tt.make\n\t)\n",
            5,
        )

    def test_form_3_an_element_of_an_array_literal(self) -> None:
        self.handed(
            "func f() -> Array:\n\tvar xs := [t.go, t.make]\n\tvar ys := [\n\t\tt.go,\n\t]\n\treturn [t.go]\n", 4
        )

    def test_form_4_the_right_side_of_an_assignment(self) -> None:
        self.handed(
            "var held: Callable\nfunc f(c: Callable = t.go) -> void:\n\tvar a := t.go\n\tvar b: Callable = t.make\n"
            "\theld = t.go\n",
            4,
        )

    def test_form_5_a_returned_value(self) -> None:
        self.handed("func f() -> Callable:\n\tg(func() -> Callable: return t.make)\n\treturn t.go\n", 2)

    def test_form_6_a_branch_of_a_ternary(self) -> None:
        self.handed(
            "func f() -> Callable:\n\tg(t.go if t else Callable())\n\tvar a := Callable() if t else t.make\n"
            "\treturn t.go if t else Callable()\n",
            3,
        )

    def test_a_parenthesised_expression_is_what_its_parentheses_are(self) -> None:
        self.handed("func f() -> Callable:\n\tvar a := (t.go)\n\tg((t.make))\n\treturn (\n\t\tt.go\n\t)\n", 3)
        src = reader("var t: Thing\nfunc f() -> void:\n\tif (t.make):\n\t\tpass\n\tassert((t.go))\n")
        self.assertEqual(self.refs(src), [(5, "t.make"), (7, "t.go")])


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
            "src/i.gd": '@warning_ignore_start \\\n("untyped_declaration")\nextends RefCounted\nvar x = 3\n',
            "src/j.gd": (
                'extends Node\nfunc f() -> void:\n\t@warning_ignore_start \\\n\t("untyped_declaration")\n\tvar x = 3\n'
            ),
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
                "src/i.gd:1",
                "src/j.gd:3",
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

    def trees(self, before: dict[str, str], head: dict[str, str]) -> tuple[reads.Tree, reads.Tree]:
        return reads.Tree(head, {}), reads.Tree(before, {})

    def failing(
        self,
        base_list: str,
        now_list: str,
        before: dict[str, str],
        head: dict[str, str],
        renames: dict[str, str] | None = None,
        changed: bool = False,
    ) -> list[str]:
        head_tree, before_tree = self.trees(before, head)
        return reads.base_failures(
            reads.entries_of(now_list),
            reads.entries_of(base_list),
            renames or {},
            changed,
            head_tree,
            lambda: before_tree,
        )

    def test_against_the_base_an_added_line_fails_unless_it_moves_or_the_checker_changed(self) -> None:
        before = {"src/thing.gd": THING, "src/old.gd": rd("ROLD"), "src/keep.gd": rd("RKEEP")}
        head = {
            "src/thing.gd": THING,
            "src/keep.gd": rd("RKEEP"),
            "src/new.gd": rd("RNEW"),
            "src/other.gd": rd("ROTHER", member="size"),
        }
        base_list = "# [Thing] x\nsrc/old.gd count\nsrc/keep.gd count\n"
        now_list = "# [Thing] x\nsrc/keep.gd count\nsrc/new.gd count\nsrc/other.gd size\n"
        failing = self.failing(base_list, now_list, before, head, {"src/old.gd": "src/new.gd"})
        self.assertEqual(len(failing), 1)
        self.assertIn("src/other.gd size", failing[0])
        self.assertEqual(self.failing(base_list, now_list, before, head, changed=True), [])
        head_tree, before_tree = self.trees(before, head)
        self.assertEqual(
            reads.base_failures(reads.entries_of(now_list), None, {}, False, head_tree, lambda: before_tree),
            [],
        )

    def test_a_rename_pairs_each_removed_line_with_one_added_line(self) -> None:
        before = {"src/thing.gd": THING, "src/old.gd": rd("ROLD")}
        head = {"src/thing.gd": THING, "src/a.gd": rd("RA"), "src/b.gd": rd("RB")}
        got = self.failing(
            "# [Thing] x\nsrc/old.gd count\n",
            "# [Thing] x\nsrc/a.gd count\nsrc/b.gd count\n",
            before,
            head,
            {"src/old.gd": "src/a.gd"},
        )
        self.assertEqual(len(got), 1)
        self.assertIn("src/b.gd count", got[0])

    # Rule 2 of the docstring, the new reader file. Mutations the cases below fail: not_grown always true (a grown
    # move and a new reader pass), always false (the moved function fails), `<=` made `<` (the move fails), the head
    # counted over every file but the base over the differing ones (the unchanged reader in the first case), the
    # count keyed by the class alone or by the field's name alone (the two cases of the class-and-field test), the
    # count per file (the split), the new-file condition dropped (the file that exists at the base).
    def test_code_moved_into_a_new_file_passes_when_the_uses_did_not_grow(self) -> None:
        before = {"src/thing.gd": THING, "src/a.gd": rd("RA"), "src/keep.gd": rd("RK")}
        head = {
            "src/thing.gd": THING,
            "src/a.gd": "class_name RA\nextends Node\n",
            "src/b.gd": rd("RB"),
            "src/keep.gd": rd("RK"),
        }
        base_list = "# [Thing] x\nsrc/a.gd count\nsrc/keep.gd count\n"
        self.assertEqual(self.failing(base_list, "# [Thing] x\nsrc/b.gd count\nsrc/keep.gd count\n", before, head), [])

    def test_a_file_split_into_several_passes_as_one_count_per_class_and_field(self) -> None:
        before = {"src/thing.gd": THING, "src/a.gd": rd("RA", 2)}
        head = {
            "src/thing.gd": THING,
            "src/a.gd": "class_name RA\nextends Node\n",
            "src/b.gd": rd("RB"),
            "src/c.gd": rd("RC"),
        }
        now = "# [Thing] x\nsrc/b.gd count\nsrc/c.gd count\n"
        self.assertEqual(self.failing("# [Thing] x\nsrc/a.gd count\n", now, before, head), [])

    def test_the_same_move_with_one_more_use_fails(self) -> None:
        before = {"src/thing.gd": THING, "src/a.gd": rd("RA")}
        head = {"src/thing.gd": THING, "src/a.gd": "class_name RA\nextends Node\n", "src/b.gd": rd("RB", 2)}
        got = self.failing("# [Thing] x\nsrc/a.gd count\n", "# [Thing] x\nsrc/b.gd count\n", before, head)
        self.assertEqual(len(got), 1)
        self.assertIn("src/b.gd count is added under [Thing]", got[0])

    def test_a_new_file_reading_a_field_no_changed_file_read_fails(self) -> None:
        before = {"src/thing.gd": THING, "src/a.gd": rd("RA")}
        # a field of the same class that nobody read
        head = {"src/thing.gd": THING, "src/a.gd": rd("RA"), "src/b.gd": rd("RB", member="size")}
        self.assertEqual(
            len(
                self.failing(
                    "# [Thing] x\nsrc/a.gd count\n", "# [Thing] x\nsrc/a.gd count\nsrc/b.gd size\n", before, head
                )
            ),
            1,
        )
        # the field an unchanged file reads: the unchanged file is not among those that differ
        head = {"src/thing.gd": THING, "src/a.gd": rd("RA"), "src/b.gd": rd("RB")}
        now = "# [Thing] x\nsrc/a.gd count\nsrc/b.gd count\n"
        self.assertEqual(len(self.failing("# [Thing] x\nsrc/a.gd count\n", now, before, head)), 1)

    def test_the_count_is_keyed_by_class_and_field(self) -> None:
        other = "class_name Other\nextends RefCounted\nvar count := 0\n"
        # a changed file drops its read of Thing.count while a new file reads Thing.size
        before = {"src/thing.gd": THING, "src/a.gd": rd("RA")}
        head = {"src/thing.gd": THING, "src/a.gd": "class_name RA\nextends Node\n", "src/b.gd": rd("RB", member="size")}
        self.assertEqual(
            len(self.failing("# [Thing] x\nsrc/a.gd count\n", "# [Thing] x\nsrc/b.gd size\n", before, head)), 1
        )
        # two classes declare `count`: one loses a reader, the other gains one
        before = {"src/thing.gd": THING, "src/other.gd": other, "src/a.gd": rd("RA", kind="Other")}
        head = {
            "src/thing.gd": THING,
            "src/other.gd": other,
            "src/a.gd": "class_name RA\nextends Node\n",
            "src/b.gd": rd("RB"),
        }
        self.assertEqual(
            len(self.failing("# [Other] x\nsrc/a.gd count\n", "# [Thing] x\nsrc/b.gd count\n", before, head)), 1
        )

    def test_an_added_line_for_a_file_the_base_had_never_passes_by_count(self) -> None:
        # a reader file that exists at the base is not the new-file case, whatever the counts
        before = {"src/thing.gd": THING, "src/a.gd": rd("RA"), "src/b.gd": "class_name RB\nextends Node\n"}
        head = {"src/thing.gd": THING, "src/a.gd": "class_name RA\nextends Node\n", "src/b.gd": rd("RB")}
        now = "# [Thing] x\nsrc/b.gd count\n"
        self.assertEqual(len(self.failing("# [Thing] x\nsrc/a.gd count\n", now, before, head)), 1)

    # Rule 3 of the docstring, the lifted inner class. Mutations the cases below fail: always true (a new class beside
    # a deleted or renamed inner class passes), always false (the lift fails), the inner class's absence from the head
    # ignored (the second new class of the true lift), the field's name ignored (the field the inner class did not
    # declare), "declares every var" dropped (the namesake and the lift that drops a var), the new-file condition
    # dropped (the existing class), the renamed class file not excluded (the renamed class), the inner class's file
    # rename ignored (the renamed file holding the inner class).
    def test_an_inner_class_lifted_into_a_file_of_its_own_passes(self) -> None:
        before = {
            "src/sched.gd": "class_name Sched\nextends Node\nclass Planned:\n\tvar mobile := false\n",
            "src/user.gd": "class_name User\nextends Node\nvar p: Sched.Planned\nfunc f() -> bool:\n\treturn p.mobile\n"
            "",
        }
        head = {
            "src/sched.gd": "class_name Sched\nextends Node\n",
            "src/plan.gd": "class_name Plan\nextends RefCounted\nvar mobile := false\n",
            "src/user.gd": "class_name User\nextends Node\nvar p: Plan\nfunc f() -> bool:\n\treturn p.mobile\n",
            "src/other.gd": "class_name Other\nextends Node\nvar p: Plan\nfunc f() -> bool:\n\treturn p.mobile\n",
        }
        now = "# [Plan] x\nsrc/other.gd mobile\nsrc/user.gd mobile\n"
        self.assertEqual(self.failing("# [Sched] x\n", now, before, head), [])

    def test_a_new_class_with_a_public_var_read_from_outside_fails(self) -> None:
        before = {"src/sched.gd": "class_name Sched\nextends Node\nclass Planned:\n\tvar mobile := false\n"}
        head = {
            "src/sched.gd": "class_name Sched\nextends Node\nclass Planned:\n\tvar mobile := false\n",
            "src/plan.gd": "class_name Plan\nextends RefCounted\nvar mobile := false\n",
            "src/user.gd": "class_name User\nextends Node\nvar p: Plan\nfunc f() -> bool:\n\treturn p.mobile\n",
        }
        self.assertEqual(len(self.failing("# [Sched] x\n", "# [Plan] x\nsrc/user.gd mobile\n", before, head)), 1)

    def test_a_lifted_class_gaining_a_field_the_inner_class_did_not_declare_fails(self) -> None:
        before = {"src/sched.gd": "class_name Sched\nextends Node\nclass Planned:\n\tvar mobile := false\n"}
        head = {
            "src/sched.gd": "class_name Sched\nextends Node\n",
            "src/plan.gd": "class_name Plan\nextends RefCounted\nvar mobile := false\nvar fresh := 0\n",
            "src/user.gd": "class_name User\nextends Node\nvar p: Plan\nfunc f() -> int:\n\treturn p.fresh\n",
        }
        self.assertEqual(len(self.failing("# [Sched] x\n", "# [Plan] x\nsrc/user.gd fresh\n", before, head)), 1)

    def lifted(self, planned: str, plan: str, extra: dict[str, str] | None = None) -> dict[str, str]:
        """The head of a lift: `Sched` without its inner class, `Plan` with `plan`, a reader, and `extra`."""
        user = "class_name User\nextends Node\nvar p: Plan\nfunc f() -> bool:\n\treturn p.mobile\n"
        return {
            "src/sched.gd": "class_name Sched\nextends Node\n",
            "src/plan.gd": f"class_name Plan\nextends RefCounted\n{plan}",
            "src/user.gd": user,
            **(extra or {}),
        }

    def test_a_new_class_beside_a_deleted_or_renamed_inner_class_with_a_namesake_var_fails(self) -> None:
        row = "class_name Sched\nextends Node\nclass Row:\n\tvar pos := 0\n\tvar kind := 0\n"
        user = "class_name User\nextends Node\nvar m: Marker\nfunc f() -> int:\n\treturn m.pos\n"
        marker = "class_name Marker\nextends RefCounted\nvar pos := 0\n"
        before = {"src/sched.gd": row, "src/user.gd": "class_name User\nextends Node\n"}
        now = "# [Marker] x\nsrc/user.gd pos\n"
        deleted = {"src/sched.gd": "class_name Sched\nextends Node\n", "src/marker.gd": marker, "src/user.gd": user}
        self.assertEqual(len(self.failing("# [Sched] x\n", now, before, deleted)), 1)
        renamed = {"src/sched.gd": row.replace("Row", "Entry"), "src/marker.gd": marker, "src/user.gd": user}
        self.assertEqual(len(self.failing("# [Sched] x\n", now, before, renamed)), 1)

    def test_a_true_lift_beside_a_second_new_class_passes_only_the_lifted_one(self) -> None:
        planned = "class_name Sched\nextends Node\nclass Planned:\n\tvar mobile := false\n\tvar pos := 0\n"
        user = "class_name User\nextends Node\nvar p: Plan\nfunc f() -> bool:\n\treturn p.mobile\n"
        build = "class_name Builder\nextends RefCounted\nvar pos := 0\n"
        reader = "class_name Peek\nextends Node\nvar b: Builder\nfunc f() -> int:\n\treturn b.pos\n"
        before = {"src/sched.gd": planned, "src/user.gd": "class_name User\nextends Node\n"}
        head = self.lifted(
            planned, "var mobile := false\nvar pos := 0\n", {"src/builder.gd": build, "src/peek.gd": reader}
        )
        head["src/user.gd"] = user
        now = "# [Builder] x\nsrc/peek.gd pos\n# [Plan] x\nsrc/user.gd mobile\n"
        got = self.failing("# [Sched] x\n", now, before, head)
        self.assertEqual(len(got), 1)
        self.assertIn("[Builder]", got[0])

    def test_a_lift_that_drops_a_var_of_the_inner_class_fails(self) -> None:
        planned = "class_name Sched\nextends Node\nclass Planned:\n\tvar mobile := false\n\tvar pos := 0\n"
        before = {"src/sched.gd": planned}
        head = self.lifted(planned, "var mobile := false\n")
        self.assertEqual(len(self.failing("# [Sched] x\n", "# [Plan] x\nsrc/user.gd mobile\n", before, head)), 1)

    def test_an_existing_class_gaining_the_var_of_a_deleted_inner_class_fails(self) -> None:
        row = "class_name Sched\nextends Node\nclass Row:\n\tvar pos := 0\n"
        thing = THING
        user = "class_name User\nextends Node\nvar t: Thing\nfunc f() -> int:\n\treturn t.pos\n"
        before = {"src/sched.gd": row, "src/thing.gd": thing, "src/user.gd": "class_name User\nextends Node\n"}
        head = {
            "src/sched.gd": "class_name Sched\nextends Node\n",
            "src/thing.gd": thing + "var pos := 0\n",
            "src/user.gd": user,
        }
        self.assertEqual(len(self.failing("# [Sched] x\n", "# [Thing] x\nsrc/user.gd pos\n", before, head)), 1)

    def test_a_class_file_git_renames_is_not_new(self) -> None:
        row = "class_name Sched\nextends Node\nclass Row:\n\tvar pos := 0\n"
        user = "class_name User\nextends Node\nvar t: Thing\nfunc f() -> int:\n\treturn t.pos\n"
        before = {"src/sched.gd": row, "src/thing.gd": THING, "src/user.gd": "class_name User\nextends Node\n"}
        head = {
            "src/sched.gd": "class_name Sched\nextends Node\n",
            "src/thing2.gd": THING + "var pos := 0\n",
            "src/user.gd": user,
        }
        got = self.failing(
            "# [Sched] x\n", "# [Thing] x\nsrc/user.gd pos\n", before, head, {"src/thing.gd": "src/thing2.gd"}
        )
        self.assertEqual(len(got), 1)

    def test_an_inner_class_kept_in_a_renamed_file_is_not_a_lift(self) -> None:
        planned = "class_name Sched\nextends Node\nclass Planned:\n\tvar mobile := false\n"
        user = "class_name User\nextends Node\nvar p: Plan\nfunc f() -> bool:\n\treturn p.mobile\n"
        before = {"src/sched.gd": planned, "src/user.gd": "class_name User\nextends Node\n"}
        head = {
            "src/sched2.gd": planned,
            "src/plan.gd": "class_name Plan\nextends RefCounted\nvar mobile := false\n",
            "src/user.gd": user,
        }
        got = self.failing(
            "# [Sched] x\n", "# [Plan] x\nsrc/user.gd mobile\n", before, head, {"src/sched.gd": "src/sched2.gd"}
        )
        self.assertEqual(len(got), 1)

    def test_the_base_tree_is_not_read_when_no_added_line_needs_it(self) -> None:
        def boom() -> reads.Tree:
            raise AssertionError("the base's tree was read")

        src = {"src/thing.gd": THING, "src/a.gd": rd("RA")}
        head = reads.Tree(src, {})
        listed = reads.entries_of("# [Thing] x\nsrc/a.gd count\n")
        # no added line
        self.assertEqual(reads.base_failures(listed, listed, {}, False, head, boom), [])
        # an added line paired by a rename
        moved = reads.entries_of("# [Thing] x\nsrc/b.gd count\n")
        self.assertEqual(reads.base_failures(moved, listed, {"src/a.gd": "src/b.gd"}, False, head, boom), [])


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

    def test_base_passes_code_moved_into_a_new_file_and_fails_the_same_move_with_one_more_use(self) -> None:
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "t@example.com")
        self.git("config", "user.name", "t")
        self.git("config", "commit.gpgsign", "false")
        self.run_main("--write")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "base")
        # the read leaves reader.gd for a new file: no file is renamed, and the uses did not grow
        (self.root / "src/reader.gd").write_text("class_name Reader\nextends Node\n")
        (self.root / "src/moved.gd").write_text(rd("Moved"))
        self.run_main("--write")
        self.git("add", "-A")
        code, out = self.run_main("--base", "HEAD")
        self.assertEqual(code, 0, out)
        # one more use in the new file fails
        (self.root / "src/moved.gd").write_text(rd("Moved", 2))
        self.run_main("--write")
        self.git("add", "-A")
        code, out = self.run_main("--base", "HEAD")
        self.assertEqual(code, 1)
        self.assertIn("src/moved.gd count is added under [Thing]", out)

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

    def test_help_prints_the_docstring_the_one_text_of_what_the_check_sees(self) -> None:
        out = io.StringIO()
        with redirect_stdout(out), self.assertRaises(SystemExit) as caught:
            reads.parse(["--help"])
        self.assertEqual(caught.exception.code, 0)
        text = " ".join(out.getvalue().split())
        self.assertIn(" ".join((reads.__doc__ or "").split()[:12]), text)
        self.assertIn("a constant or an enum any file or inner class declares", text)
        self.assertIn("**Blind spots, stated.**", text)


if __name__ == "__main__":
    unittest.main()
