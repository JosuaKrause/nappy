#!/usr/bin/env python3
"""Unit tests for `tools/field_answers.py`, against small trees written here: no case reads the game's code, so a
change to it never turns these red."""

from __future__ import annotations

import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import field_answers as answers

HUNT = "class_name Hunt\nextends RefCounted\nvar lets_out := 0\n"
TAIL = 'class_name Tail\nextends RefCounted\nvar on_finish := ""\n'
ROW = """class_name Row
extends RefCounted
var id := ""
var loud := 0.0
var hunts: Hunt
var hunting: Hunt
var tail: Tail
var label := ""
func heard() -> float:
	return loud
func is_quiet() -> bool:
	return loud <= 0.0
func twice_as_loud() -> float:
	return loud * 2.0
func lets_out() -> int:
	return hunting.lets_out if hunting else 0
func leaves() -> String:
	return tail.on_finish
func tail_or_none() -> Tail:
	if tail == null:
		return null
	return tail
func named() -> String:
	var text := label
	return text
"""
PLANNER = """class_name Planner
extends RefCounted
class Plan:
	var def: Row
	var spot := Vector2.ZERO
	var live: Node = null
	var role := 0
	var marks: Array[int] = []
	func row() -> Row:
		return def
	func row_id() -> String:
		return def.id
	func placed_at() -> Vector2:
		return spot
	func is_in_the_world() -> bool:
		return live != null
	func give_role(given: int) -> void:
		role = given
	func mark(at: int, value: int) -> void:
		if at >= 0: marks[at] = value
	func _hidden_role() -> int:
		return role
var plans: Array[Plan] = []
func first() -> Plan:
	return plans[0]
func first_row() -> Row:
	return first().row()
"""
LIVE = """class_name Live
extends Node
enum Phase { ON, DONE }
var phase := Phase.ON
var def: Row
var is_finished: bool:
	get:
		return phase == Phase.DONE
var word: bool:
	get:
		return name == "done"
func is_gone() -> bool:
	return phase == Phase.DONE
func is_called_done() -> bool:
	return name == "over"
func heard() -> float:
	return def.heard()
"""
SCENE = """class_name Scene
extends Node
var map: Ground
func start() -> Vector2:
	return map.start()
func tile(at: Vector2) -> int:
	return map.tile(at)
func shifted(at: Vector2) -> int:
	return map.tile(at + Vector2.ONE)
"""
GROUND = """class_name Ground
extends RefCounted
var cells := {}
func start() -> Vector2:
	return Vector2(cells.size(), 0)
func tile(at: Vector2) -> int:
	return int(at.x)
func other() -> int:
	return 1
"""
PART = "class_name Part\nextends RefCounted\nvar count := 0\nfunc reset() -> void:\n\tcount = 0\n"
PART += "func tally() -> int:\n\treturn count\n"
SUB_PART = "class_name SubPart\nextends Part\nvar extra := 0\nfunc reset() -> void:\n\textra = 0\n"
SUB_PART += "func counted() -> int:\n\treturn count\n"
USER = """class_name User
extends Node
var plan: Planner.Plan
var parts: Array[Part] = []
func a(loose) -> void:
	plan.row()
	plan.row()
	loose.row()
	for part in parts:
		part.reset()
"""
SRC = {
    "src/hunt.gd": HUNT,
    "src/tail.gd": TAIL,
    "src/row.gd": ROW,
    "src/planner.gd": PLANNER,
    "src/live.gd": LIVE,
    "src/scene.gd": SCENE,
    "src/ground.gd": GROUND,
    "src/part.gd": PART,
    "src/sub_part.gd": SUB_PART,
    "src/user.gd": USER,
}
SUITE = "tests/test_it.gd"
HEAD = "extends RefCounted\n"


def report(body: str, more: dict[str, str] | None = None, head: str = HEAD) -> answers.Report:
    """What a suite with `body` reads, in the small tree and any `more` files."""
    tree = answers.Scripts({**SRC, **(more or {}), SUITE: head + body}, {})
    return answers.report_of(tree, [SUITE])


def found(body: str, more: dict[str, str] | None = None, head: str = HEAD) -> dict[tuple[str, str, str], list[str]]:
    """Each entry of a suite's report as (class, label, access), with the methods that answer it."""
    made = report(body, more, head)
    return {
        (e.klass.replace("src/", "").replace(".gd", ""), e.label, e.access): [a.method for a in e.answers]
        for e in made.entries
    }


def unknown(body: str, more: dict[str, str] | None = None) -> list[tuple[int, str]]:
    return [(u.line, u.expression) for u in report(body, more).unknown]


class AnswerTests(unittest.TestCase):
    def test_a_method_that_returns_the_field_answers_a_read_of_it(self) -> None:
        got = found("func f(row: Row) -> void:\n\tprint(row.loud, row.id)\n")
        self.assertEqual(got, {("row", "loud", "read"): ["heard"], ("row", "id", "read"): []})

    def test_a_field_of_an_inner_class_is_listed_under_outer_dot_inner(self) -> None:
        made = report("func f() -> void:\n\tvar plan := Planner.Plan.new()\n\tprint(plan.spot)\n")
        self.assertEqual([(e.klass, e.label) for e in made.entries], [("src/planner.gd::Plan", "spot")])
        self.assertEqual([a.method for a in made.entries[0].answers], ["placed_at"])
        tree = answers.Scripts({**SRC, SUITE: HEAD}, {})
        self.assertEqual(tree.display("src/planner.gd::Plan"), "Planner.Plan")

    def test_a_chain_names_the_method_of_the_class_it_starts_at(self) -> None:
        got = found("func f(plan: Planner.Plan) -> void:\n\tprint(plan.def.id)\n")
        self.assertEqual(
            got, {("planner::Plan", "def", "read"): ["row"], ("planner::Plan", "def.id", "read"): ["row_id"]}
        )

    def test_a_chain_no_method_returns_is_the_last_field_alone(self) -> None:
        got = found("func f(plan: Planner.Plan) -> void:\n\tprint(plan.def.label)\n")
        self.assertEqual(got, {("planner::Plan", "def", "read"): ["row"], ("row", "label", "read"): []})

    def test_a_chain_through_a_method_that_returns_a_field_is_the_same_chain(self) -> None:
        got = found("func f(plan: Planner.Plan) -> void:\n\tprint(plan.row().id)\n")
        self.assertEqual(got, {("planner::Plan", "row().id", "read"): ["row_id"]})

    def test_a_return_behind_a_null_guard_is_an_answer(self) -> None:
        got = found("func f(row: Row) -> void:\n\tprint(row.hunting.lets_out, row.tail)\n")
        self.assertEqual(got[("row", "hunting.lets_out", "read")], ["lets_out"])
        self.assertEqual(got[("row", "tail", "read")], ["tail_or_none"])

    def test_a_guard_on_another_member_or_a_fallback_to_one_is_no_answer(self) -> None:
        row = ROW + "var ready := false\nfunc a() -> Tail:\n\treturn tail if ready else null\n"
        row += "func b() -> Tail:\n\treturn tail if tail else hunts\n"
        got = found("func f(row: Row) -> void:\n\tprint(row.tail)\n", {"src/row.gd": row})
        self.assertEqual(got, {("row", "tail", "read"): ["tail_or_none"]})

    def test_a_method_that_returns_a_value_derived_from_another_field_is_refused(self) -> None:
        got = found("func f(row: Row) -> void:\n\tprint(row.hunts.lets_out)\n")
        self.assertEqual(got, {("row", "hunts", "read"): [], ("hunt", "lets_out", "read"): []})

    def test_a_method_that_returns_the_field_worked_on_or_through_a_local_is_refused(self) -> None:
        made = report("func f(row: Row) -> void:\n\tprint(row.loud, row.label)\n")
        by_label = {e.label: e for e in made.entries}
        self.assertEqual([a.method for a in by_label["loud"].answers], ["heard"])
        self.assertEqual([(a.method, a.does) for a in by_label["loud"].asking], [("is_quiet", "loud <= 0.0")])
        self.assertEqual((by_label["label"].answers, by_label["label"].asking), ([], []))

    def test_a_yes_or_no_method_on_the_field_alone_is_printed_as_asking_not_as_an_answer(self) -> None:
        made = report("func f(plan: Planner.Plan) -> void:\n\tprint(plan.live != null)\n")
        self.assertEqual(made.entries[0].answers, [])
        self.assertEqual([(a.method, a.does) for a in made.entries[0].asking], [("is_in_the_world", "live != null")])

    def test_a_property_is_answered_by_the_method_that_returns_what_its_getter_returns(self) -> None:
        got = found("func f(live: Live) -> void:\n\tprint(live.is_finished)\n")
        self.assertEqual(got, {("live", "is_finished", "read"): ["is_gone"]})

    def test_a_getter_with_a_string_is_matched_to_no_method(self) -> None:
        got = found("func f(live: Live) -> void:\n\tprint(live.word)\n")
        self.assertEqual(got, {("live", "word", "read"): []})

    def test_a_method_that_returns_another_methods_answer_is_read_through(self) -> None:
        got = found("func f(live: Live) -> void:\n\tprint(live.def.loud)\n")
        self.assertEqual(got, {("live", "def", "read"): [], ("live", "def.loud", "read"): ["heard"]})
        got = found("func f(live: Live) -> void:\n\tprint(live.def.heard())\n")
        self.assertEqual(got, {("live", "def.heard()", "read"): ["heard"]})

    def test_a_call_the_class_hands_on_with_its_parameters_is_the_chain(self) -> None:
        body = "func f(scene: Scene, at: Vector2) -> void:\n\tprint(scene.map.start(), scene.map.tile(at))\n"
        got = found(body)
        self.assertEqual(got, {("scene", "map.start()", "read"): ["start"], ("scene", "map.tile()", "read"): ["tile"]})

    def test_a_call_nothing_hands_on_leaves_the_field_read(self) -> None:
        got = found("func f(scene: Scene) -> void:\n\tprint(scene.map.other(), scene.map.tile())\n")
        self.assertEqual(got, {("scene", "map", "read"): []})

    def test_a_write_names_the_methods_that_assign_the_field(self) -> None:
        body = "func f(plan: Planner.Plan) -> void:\n\tplan.role = 2\n\tplan.role += 1\n\tplan.marks[0] = 4\n"
        made = report(body)
        by_label = {e.label: e for e in made.entries}
        self.assertEqual({e.access for e in made.entries}, {"written"})
        self.assertEqual([(a.method, a.does) for a in by_label["role"].answers], [("give_role", "role = given")])
        self.assertEqual([(a.method, a.does) for a in by_label["marks"].answers], [("mark", "marks[at] = value")])
        self.assertEqual(by_label["role"].sites, [(SUITE, 3), (SUITE, 4)])

    def test_a_comparison_is_a_read_and_a_read_and_a_write_are_two_entries(self) -> None:
        got = found("func f(plan: Planner.Plan) -> void:\n\tif plan.role == 2 or plan.role >= 3:\n\t\tplan.role = 1\n")
        self.assertEqual(
            got, {("planner::Plan", "role", "read"): [], ("planner::Plan", "role", "written"): ["give_role"]}
        )

    def test_a_private_method_is_no_answer(self) -> None:
        self.assertEqual(
            found("func f(p: Planner.Plan) -> void:\n\tprint(p.role)\n"), {("planner::Plan", "role", "read"): []}
        )

    def test_a_method_call_and_an_engine_property_are_not_listed(self) -> None:
        self.assertEqual(found("func f(live: Live) -> void:\n\tprint(live.is_gone(), live.position, live.name)\n"), {})

    def test_an_inherited_field_is_listed_under_the_class_that_declares_it(self) -> None:
        got = found("func f(part: SubPart) -> void:\n\tprint(part.count, part.extra)\n")
        self.assertEqual(got, {("part", "count", "read"): ["counted", "tally"], ("sub_part", "extra", "read"): []})

    def test_a_getter_a_base_class_declares_answers_a_read_through_a_subclass_receiver(self) -> None:
        body = "func f(part: SubPart) -> void:\n\tprint(part.count)\n"
        tree = answers.Scripts({**SRC, SUITE: HEAD + body}, {})
        made = answers.report_of(tree, [SUITE])
        (entry,) = made.entries
        self.assertEqual(
            (entry.klass, entry.receivers, entry.through()), ("src/part.gd", ["src/sub_part.gd"], ["src/sub_part.gd"])
        )
        self.assertEqual(
            [(a.klass, a.method) for a in entry.answers], [("src/sub_part.gd", "counted"), ("src/part.gd", "tally")]
        )
        line = answers.markdown(tree, made).splitlines()[2]
        self.assertEqual(
            line,
            f"- `Part`: `count` read through `SubPart` (`{SUITE}`:3):"
            " `SubPart.counted()` (0 calls), `tally()` (0 calls)",
        )

    def test_a_read_through_the_declaring_class_names_no_other_and_not_the_subclasss_getter(self) -> None:
        body = "func f(part: Part, sub: SubPart) -> void:\n\tprint(part.count)\n"
        tree = answers.Scripts({**SRC, SUITE: HEAD + body}, {})
        made = answers.report_of(tree, [SUITE])
        self.assertEqual(made.entries[0].through(), [])
        self.assertEqual([a.method for a in made.entries[0].answers], ["tally"])
        self.assertIn(f"`count` read (`{SUITE}`:3): `tally()`", answers.markdown(tree, made))


class ReceiverTests(unittest.TestCase):
    def test_an_unknown_receiver_is_on_a_line_of_its_own_and_in_no_entry(self) -> None:
        body = "func f(x, items: Array) -> void:\n\tvar y = items[0]\n\tprint(x.id, y.loud)\n\tprint(x.nothing)\n"
        made = report(body)
        self.assertEqual(made.entries, [])
        self.assertEqual([(u.line, u.expression) for u in made.unknown], [(4, "x.id"), (4, "y.loud")])
        tree = answers.Scripts({**SRC, SUITE: HEAD + body}, {})
        text = answers.markdown(tree, made)
        self.assertIn(f"- Receiver's class not told: `{SUITE}:4` `x.id`\n", text)

    def test_a_bare_name_nothing_declares_is_unknown_not_an_engine_value(self) -> None:
        self.assertEqual(unknown("func f() -> void:\n\tprint(stray.id)\n"), [(3, "stray.id")])

    def test_a_script_with_no_class_name_is_told_through_its_preload(self) -> None:
        rig = "extends RefCounted\nstatic func plan() -> Planner.Plan:\n\treturn Planner.Plan.new()\n"
        rig += "class Stage:\n\tvar row: Row\n"
        body = 'const Rig := preload("res://tests/rig.gd")\nfunc f() -> void:\n\tprint(Rig.plan().spot)\n'
        body += "\tvar stage := Rig.Stage.new()\n\tprint(stage.row.loud)\n"
        got = found(body, {"tests/rig.gd": rig})
        self.assertEqual(got, {("planner::Plan", "spot", "read"): ["placed_at"], ("row", "loud", "read"): ["heard"]})

    def test_a_script_extended_by_its_path_hands_down_its_members(self) -> None:
        base = "extends RefCounted\nvar row: Row\nfunc plan() -> Planner.Plan:\n\treturn null\n"
        body = "func f() -> void:\n\tprint(row.loud, plan().spot, self.row.id)\n"
        got = found(body, {"tests/base_rig.gd": base}, 'extends "res://tests/base_rig.gd"\n')
        self.assertEqual(sorted(label for _, label, _ in got), ["id", "loud", "spot"])

    def test_an_awaited_call_and_a_for_whose_head_spans_lines_type_their_names(self) -> None:
        rig = "extends RefCounted\nstatic func later() -> Planner.Plan:\n\treturn null\n"
        rig += "static func some(n: int, m: int) -> Array[Planner.Plan]:\n\treturn []\n"
        body = 'const Rig := preload("res://tests/rig.gd")\nfunc f() -> void:\n\tvar plan := await Rig.later()\n'
        body += "\tprint(plan.spot)\n\tfor each in Rig.some(1,\n\t\t\t2):\n\t\tprint(each.role)\n"
        body += "\tvar word = await Rig.done\n\tprint(word.spot)\n"
        made = report(body, {"tests/rig.gd": rig})
        self.assertEqual([e.label for e in made.entries], ["role", "spot"])
        self.assertEqual([(u.line, u.expression) for u in made.unknown], [(10, "word.spot")])

    def test_a_dot_that_opens_a_continuation_line_reads_its_receiver_from_the_lines_before(self) -> None:
        body = "func f(plans: Array[Planner.Plan]) -> void:\n\tprint(plans[0]\n\t\t\t.spot)\n"
        body += "\tprint(Planner.new().first(\n\t\t\t)\n\t\t\t.role)\n"
        made = report(body)
        self.assertEqual([(e.label, e.sites) for e in made.entries], [("role", [(SUITE, 7)]), ("spot", [(SUITE, 4)])])
        self.assertEqual(made.unknown, [])

    def test_an_inner_class_named_with_an_underscore_is_told(self) -> None:
        body = "class _Fake:\n\tvar row: Row\nfunc f() -> void:\n\tvar fake := _Fake.new()\n\tprint(fake.row.loud)\n"
        self.assertEqual(found(body), {("row", "loud", "read"): ["heard"]})

    def test_a_files_own_fields_and_its_inner_classes_are_not_listed(self) -> None:
        tree = answers.Scripts(SRC, {})
        made = answers.report_of(tree, ["src/planner.gd", "src/live.gd"])
        self.assertEqual([(e.klass, e.label) for e in made.entries], [("src/row.gd", "id")])


class CallSiteTests(unittest.TestCase):
    def test_calls_are_counted_by_the_receivers_class_apart_from_its_own_file_and_the_untold(self) -> None:
        made = report("func f(plan: Planner.Plan) -> void:\n\tprint(plan.def)\n")
        self.assertEqual(made.calls[("src/planner.gd::Plan", "row")], answers.Calls(elsewhere=2, own=1, untold=1))

    def test_a_call_through_the_base_class_reaches_the_override(self) -> None:
        made = report("func f(part: SubPart) -> void:\n\tpart.extra = 1\n\tpart.count = 1\n")
        self.assertEqual(made.calls[("src/sub_part.gd", "reset")], answers.Calls(elsewhere=1))
        self.assertEqual(made.calls[("src/part.gd", "reset")], answers.Calls(elsewhere=1))

    def test_a_bare_call_in_the_class_itself_is_its_own_files(self) -> None:
        row = ROW + "func louder() -> float:\n\treturn heard() + 1.0\n"
        made = report("func f(row: Row) -> void:\n\tprint(row.loud)\n", {"src/row.gd": row})
        self.assertEqual(made.calls[("src/row.gd", "heard")], answers.Calls(elsewhere=1, own=1))


class OutputTests(unittest.TestCase):
    BODY = "func f(plan: Planner.Plan, x) -> void:\n\tprint(plan.def.id, plan.live)\n\tplan.role = 1\n\tprint(x.id)\n"

    def setUp(self) -> None:
        self.tree = answers.Scripts({**SRC, SUITE: HEAD + self.BODY}, {})
        self.report = answers.report_of(self.tree, [SUITE])

    def test_markdown_is_one_line_per_class_and_one_per_unknown_receiver(self) -> None:
        lines = answers.markdown(self.tree, self.report).splitlines()
        self.assertTrue(lines[0].startswith(f"Fields of classes under `src/` that `{SUITE}` read or write"))
        self.assertEqual(
            lines[2:],
            [
                f"- `Planner.Plan`: `def` read (`{SUITE}`:3): `row()` (2 calls, +1 own, +1 untold);"
                f" `def.id` read (`{SUITE}`:3): `row_id()` (0 calls);"
                f" `live` read (`{SUITE}`:3): no method; of it alone, `is_in_the_world()` returns `live != null`"
                f" (0 calls); `role` written (`{SUITE}`:4): `give_role()` does `role = given` (0 calls)",
                f"- Receiver's class not told: `{SUITE}:5` `x.id`",
            ],
        )

    def test_counts_prints_how_many_lines_not_which(self) -> None:
        text = answers.markdown(self.tree, self.report, counts=True)
        self.assertIn(f"`def` read (`{SUITE}` on 1 line): `row()`", text)

    def test_nothing_read_says_so(self) -> None:
        tree = answers.Scripts({**SRC, SUITE: HEAD}, {})
        text = answers.markdown(tree, answers.report_of(tree, [SUITE]))
        self.assertEqual(
            text,
            f"No field of a class under `src/` is read or written through a receiver of that class in `{SUITE}`.\n",
        )

    def test_json_carries_every_site_method_and_count(self) -> None:
        data = json.loads(answers.as_json(self.tree, self.report))
        self.assertEqual(data["files"], [SUITE])
        self.assertEqual(data["unknown"], [{"file": SUITE, "line": 5, "expression": "x.id"}])
        (group,) = data["classes"]
        self.assertEqual((group["class"], group["path"]), ("Planner.Plan", "src/planner.gd"))
        chain = next(f for f in group["fields"] if f["field"] == "def.id")
        self.assertEqual((chain["access"], chain["declared"]), ("read", "Row.id"))
        self.assertEqual(chain["receivers"], ["Planner.Plan"])
        self.assertEqual(chain["sites"], [{"file": SUITE, "line": 3}])
        self.assertEqual(
            chain["methods"],
            [
                {
                    "class": "Planner.Plan",
                    "method": "row_id",
                    "does": "",
                    "calls": 0,
                    "own_file_calls": 0,
                    "untold_calls": 0,
                }
            ],
        )
        live = next(f for f in group["fields"] if f["field"] == "live")
        self.assertEqual([m["method"] for m in live["asking_of_it_alone"]], ["is_in_the_world"])


class CommandLineTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name)
        (self.root / "project.godot").write_text("[autoload]\n\n[display]\n")
        body = "func f(row: Row) -> void:\n\tprint(row.loud)\n"
        for path, text in {**SRC, SUITE: HEAD + body, "tests/test_other.gd": HEAD}.items():
            (self.root / path).parent.mkdir(parents=True, exist_ok=True)
            (self.root / path).write_text(text)

    def run_main(self, *argv: str) -> tuple[int, str, str]:
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = answers.main(["--root", str(self.root), *argv])
        return code, out.getvalue(), err.getvalue()

    def test_a_named_file_is_read_from_the_checkout(self) -> None:
        code, out, _ = self.run_main(SUITE)
        self.assertEqual(code, 0)
        self.assertIn(f"- `Row`: `loud` read (`{SUITE}`:3): `heard()` (1 call); of it alone, `is_quiet()`", out)
        code, out, _ = self.run_main("--json", str(self.root / SUITE))
        self.assertEqual((code, json.loads(out)["files"]), (0, [SUITE]))

    def test_a_briefs_files_are_read_by_path_or_by_name(self) -> None:
        brief = self.root / "brief.md"
        brief.write_text(
            "# A pass\n\n**Your files** (under `tests/`): `test_it.gd`,\n`tests/test_other.gd`. Two.\n\nMore `x.gd`.\n"
        )
        code, out, _ = self.run_main("--brief", str(brief))
        self.assertEqual(code, 0)
        self.assertIn(f"that `{SUITE}`, `tests/test_other.gd` read or write", out)

    def test_a_brief_naming_no_file_or_a_file_that_is_not_one_script_fails(self) -> None:
        brief = self.root / "brief.md"
        brief.write_text("No list here.\n")
        self.assertEqual(self.run_main("--brief", str(brief))[0], 1)
        brief.write_text("**Your files**: `test_missing.gd`.\n")
        code, out, err = self.run_main("--brief", str(brief))
        self.assertEqual((code, out), (1, ""))
        self.assertIn("`test_missing.gd`, which is 0 scripts", err)

    def test_a_file_the_tree_does_not_hold_fails_before_anything_is_printed(self) -> None:
        code, out, err = self.run_main("tests/test_absent.gd")
        self.assertEqual((code, out), (1, ""))
        self.assertIn("tests/test_absent.gd", err)

    def test_no_file_a_file_that_is_no_script_and_an_unknown_flag_are_rejected(self) -> None:
        for argv in ([], ["notes.md"], ["--nope", SUITE], ["--json", "--counts", SUITE]):
            with self.subTest(argv=argv), redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as raised:
                answers.main(argv)
            self.assertEqual(raised.exception.code, 2)

    def test_help_prints_the_docstring_and_exits_0(self) -> None:
        out = io.StringIO()
        with redirect_stdout(out), self.assertRaises(SystemExit) as raised:
            answers.main(["--help"])
        self.assertEqual(raised.exception.code, 0)
        self.assertIn("A receiver whose class cannot be told", out.getvalue())


if __name__ == "__main__":
    unittest.main()
