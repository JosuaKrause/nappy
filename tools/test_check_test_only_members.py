#!/usr/bin/env python3
"""Unit tests for `tools/check_test_only_members.py`, against small trees written here and a throwaway repository.

CI's own step (`uv run python tools/check_test_only_members.py`) holds the real tree to the real list; every
case here brings a list of its own, so a change to the game's code never turns these red.
"""

from __future__ import annotations

import io
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from typing import ClassVar

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_layers
import check_test_only_members as members

THING = "src/sim/thing.gd"


def files(src: dict[str, str], tests: dict[str, str]) -> members.Files:
    return members.Files(src=src, tests=tests)


def only(src: dict[str, str], tests: dict[str, str]) -> set[tuple[str, str]]:
    found, _ = members.test_only(files(src, tests))
    return {member.key for member in found}


class DefinitionTests(unittest.TestCase):
    def test_every_public_top_level_kind_is_found_and_private_and_local_ones_are_not(self) -> None:
        text = (
            "class_name Thing\nsignal woke\nconst LIMIT := 3\nvar count := 0\nstatic var shared := 1\n"
            "@export var size := 2\n@onready var node := $Child\nfunc go() -> void:\n\tvar local := 1\n"
            "static func make() -> void:\n\tpass\nfunc _hidden() -> void:\n\tpass\nvar _private := 1\n"
        )
        found = members.members_of(THING, text)
        self.assertEqual(
            [(m.kind, m.name) for m in found],
            [
                ("signal", "woke"),
                ("const", "LIMIT"),
                ("var", "count"),
                ("var", "shared"),
                ("var", "size"),
                ("var", "node"),
                ("func", "go"),
                ("func", "make"),
            ],
        )

    def test_a_definition_in_a_comment_or_a_string_is_not_one(self) -> None:
        text = '# func gone()\nvar text := "func nope()"\n'
        self.assertEqual([m.name for m in members.members_of(THING, text)], ["text"])


class TestOnlyTests(unittest.TestCase):
    def test_a_member_only_a_test_reads_is_test_only(self) -> None:
        src = {THING: "class_name Thing\nvar count := 0\nfunc bump() -> void:\n\tcount += 1\n"}
        self.assertEqual(only(src, {"tests/test_thing.gd": "func f(t):\n\tt.bump()\n"}), {(THING, "bump")})

    def test_a_game_reader_anywhere_under_src_clears_it(self) -> None:
        src = {THING: "class_name Thing\nfunc bump() -> void:\n\tpass\n", "src/ui/hud.gd": "func f(t):\n\tt.bump()\n"}
        self.assertEqual(only(src, {"tests/test_thing.gd": "func f(t):\n\tt.bump()\n"}), set())

    def test_a_caller_in_dev_counts_and_one_in_its_own_file_does_not(self) -> None:
        own = {THING: "class_name Thing\nfunc bump() -> void:\n\tpass\nfunc run() -> void:\n\tbump()\n"}
        dev = {THING: "class_name Thing\nfunc bump() -> void:\n\tpass\n", "src/dev/rig.gd": "func f(t):\n\tt.bump()\n"}
        reads = {"tests/test_thing.gd": "func f(t):\n\tt.bump()\n"}
        self.assertEqual(only(own, reads), {(THING, "bump")})
        self.assertEqual(only(dev, reads), set())

    def test_a_reader_in_a_comment_or_a_string_does_not_count(self) -> None:
        src = {THING: 'class_name Thing\nfunc bump() -> void:\n\tpass\n# bump here\nvar s := "bump"\n'}
        self.assertEqual(only(src, {"tests/test_thing.gd": "func f(t):\n\tt.bump()\n"}), {(THING, "bump")})

    def test_a_member_no_test_reads_is_not_test_only(self) -> None:
        src = {THING: "class_name Thing\nfunc bump() -> void:\n\tpass\n"}
        self.assertEqual(only(src, {"tests/test_thing.gd": "func f(t):\n\t# t.bump()\n\tpass\n"}), set())

    def test_a_namesake_in_another_class_hides_it_and_a_shared_name_nobody_reads_flags_both(self) -> None:
        both = {
            THING: "class_name A\nfunc bump() -> void:\n\tpass\n",
            "src/sim/b.gd": "class_name B\nfunc bump():\n\tpass\n",
        }
        reads = {"tests/test_thing.gd": "func f(t):\n\tt.bump()\n"}
        self.assertEqual(only(both, reads), {(THING, "bump"), ("src/sim/b.gd", "bump")})
        both["src/ui/hud.gd"] = "func f(b):\n\tb.bump()\n"
        self.assertEqual(only(both, reads), set())

    def test_the_reflecting_suites_are_skipped(self) -> None:
        src = {THING: "class_name Thing\nfunc bump() -> void:\n\tpass\n"}
        self.assertEqual(only(src, {"tests/shared_state.gd": "func f(t):\n\tt.bump()\n"}), set())


class CollisionTests(unittest.TestCase):
    """Two classes with a member of one name: a reader is the member's when its type is that class or not known."""

    CORDON = "src/resistance/cordon.gd"
    CLOSURE = "src/routes/closure.gd"
    HUD = "src/ui/hud.gd"
    SRC: ClassVar[dict[str, str]] = {
        CORDON: "class_name Cordon\nvar gap := 0\n",
        CLOSURE: "class_name Closure\nvar gap := 1\nfunc total() -> int:\n\treturn gap\n",
    }
    TESTS: ClassVar[dict[str, str]] = {"tests/test_cordon.gd": "func f(c: Cordon):\n\tprint(c.gap)\n"}

    def test_the_other_classes_own_use_no_longer_hides_a_member_a_typed_test_reads(self) -> None:
        self.assertEqual(only(self.SRC, self.TESTS), {(self.CORDON, "gap")})

    def test_a_game_reader_typed_as_the_other_class_is_not_a_reader_of_this_one(self) -> None:
        hud = {self.HUD: "func f(k: Closure):\n\tprint(k.gap)\n"}
        self.assertEqual(only(self.SRC | hud, self.TESTS), {(self.CORDON, "gap")})

    def test_a_game_reader_typed_as_this_class_clears_it(self) -> None:
        hud = {self.HUD: "func f():\n\tvar c := Cordon.new()\n\tprint(c.gap)\n"}
        self.assertEqual(only(self.SRC | hud, self.TESTS), set())

    def test_a_static_call_through_the_class_name_is_typed(self) -> None:
        hud = {self.HUD: "func f():\n\tprint(Closure.gap)\n"}
        self.assertEqual(only(self.SRC | hud, self.TESTS), {(self.CORDON, "gap")})

    def test_an_untyped_game_reader_still_counts_as_the_games(self) -> None:
        hud = {self.HUD: "func f(k):\n\tprint(k.gap)\n"}
        self.assertEqual(only(self.SRC | hud, self.TESTS), set())

    def test_a_test_typed_as_the_other_class_does_not_read_this_one(self) -> None:
        tests = {"tests/test_closure.gd": "func f(k: Closure):\n\tprint(k.gap)\n"}
        self.assertEqual(only(self.SRC, tests), {(self.CLOSURE, "gap")})

    def test_an_untyped_test_read_is_a_read_of_each_class_that_has_the_name(self) -> None:
        tests = {"tests/test_any.gd": "func f(x):\n\tprint(x.gap)\n"}
        self.assertEqual(only(self.SRC, tests), {(self.CORDON, "gap"), (self.CLOSURE, "gap")})

    def test_a_kept_line_stands_while_only_untyped_reads_hide_the_member(self) -> None:
        hud = {self.HUD: "func f(k):\n\tprint(k.gap)\n"}
        src = self.SRC | hud
        key = (self.CORDON, "gap")
        self.assertEqual(len(members.check(files(src, self.TESTS), {key})[0]), 1)
        self.assertEqual(members.check(files(src, self.TESTS), {key}, frozenset({key}))[0], [])

    def test_a_kept_line_is_stale_once_a_typed_reader_reads_it(self) -> None:
        hud = {self.HUD: "func f():\n\tvar c := Cordon.new()\n\tprint(c.gap)\n"}
        key = (self.CORDON, "gap")
        failures = members.check(files(self.SRC | hud, self.TESTS), {key}, frozenset({key}))[0]
        self.assertEqual(
            failures,
            [f"REMOVE from tools/test_only_members.txt: {self.CORDON} gap (now read by another file under src/)"],
        )

    def test_a_reader_typed_as_a_subclass_reaches_the_member_its_parent_defines(self) -> None:
        sub = {"src/x/sub.gd": "class_name Sub\nextends Cordon\n"}
        hud = {self.HUD: "func f(s: Sub):\n\tprint(s.gap)\n"}
        self.assertEqual(only(self.SRC | sub | hud, self.TESTS), set())

    BASE = "src/x/strategy.gd"
    CAR = "src/x/car.gd"
    CAR_TEST: ClassVar[dict[str, str]] = {"tests/test_car.gd": "func f(c: Car):\n\tprint(c.speed())\n"}

    def overriding(self, game: dict[str, str]) -> dict[str, str]:
        return {
            self.BASE: "class_name Strategy\nfunc speed() -> float:\n\treturn 1.0\n" + game.get(self.BASE, ""),
            self.CAR: "class_name Car\nextends Strategy\nfunc speed() -> float:\n\treturn 2.0\n",
        } | {path: text for path, text in game.items() if path != self.BASE}

    def test_an_override_the_game_reads_through_its_base_type_is_read(self) -> None:
        game = {self.HUD: "func f(s: Strategy):\n\tprint(s.speed())\n"}
        self.assertEqual(only(self.overriding(game), self.CAR_TEST), set())

    def test_an_override_nothing_reads_but_a_test_is_test_only(self) -> None:
        self.assertEqual(only(self.overriding({}), self.CAR_TEST), {(self.BASE, "speed"), (self.CAR, "speed")})

    def test_a_base_class_calling_the_name_plainly_reads_the_override(self) -> None:
        game = {self.BASE: "func tick() -> void:\n\tspeed()\n"}
        # The base's own call reads the override, not the base's own member (which is its own file's use).
        self.assertEqual(only(self.overriding(game), self.CAR_TEST), {(self.BASE, "speed")})

    def test_a_subclass_calling_the_name_plainly_does_not_read_the_base(self) -> None:
        car = "class_name Car\nextends Strategy\nfunc speed() -> float:\n\treturn 2.0\nfunc go():\n\tspeed()\n"
        tests = {"tests/test_base.gd": "func f(s: Strategy):\n\tprint(s.speed())\n"}
        self.assertIn((self.BASE, "speed"), only(self.overriding({}) | {self.CAR: car}, tests))

    def test_an_inner_class_type_is_not_read_as_its_outer_class(self) -> None:
        # `p: Closure.Piece` is not a `Closure`, so `p.gap` is not typed and counts for every class with the name.
        hud = {self.HUD: "func f(p: Closure.Piece):\n\tprint(p.gap)\n"}
        self.assertEqual(only(self.SRC | hud, self.TESTS), set())

    def test_a_one_line_if_declares_nothing(self) -> None:
        hud = {self.HUD: "func f(c, k):\n\tif c: Closure.reset()\n\tprint(c.gap)\n"}
        self.assertEqual(only(self.SRC | hud, self.TESTS), set())

    def test_self_names_the_files_own_class(self) -> None:
        own = {self.CLOSURE: "class_name Closure\nvar gap := 1\nfunc total() -> int:\n\treturn self.gap\n"}
        self.assertEqual(only(self.SRC | own, self.TESTS), {(self.CORDON, "gap")})

    def test_a_name_defined_once_is_still_judged_by_its_word(self) -> None:
        src = {self.CORDON: "class_name Cordon\nvar gap := 0\n", self.HUD: "func f(k: Other):\n\tprint(k.gap)\n"}
        self.assertEqual(only(src, self.TESTS), set())


class ListTests(unittest.TestCase):
    SRC: ClassVar[dict[str, str]] = {
        THING: "class_name Thing\nfunc bump() -> void:\n\tpass\nfunc used() -> void:\n\tpass\n"
    }
    TESTS: ClassVar[dict[str, str]] = {"tests/test_thing.gd": "func f(t):\n\tt.bump()\n\tt.used()\n"}

    def test_an_unlisted_test_only_member_fails_with_its_line_and_its_reader(self) -> None:
        src = dict(self.SRC, **{"src/ui/hud.gd": "func f(t):\n\tt.used()\n"})
        failures, _ = members.check(files(src, self.TESTS), set())
        self.assertEqual(len(failures), 1)
        self.assertIn(f"{THING}:2: func bump is read by tests (tests/test_thing.gd:2, 1 line(s))", failures[0])

    def test_a_listed_member_passes(self) -> None:
        src = dict(self.SRC, **{"src/ui/hud.gd": "func f(t):\n\tt.used()\n"})
        self.assertEqual(members.check(files(src, self.TESTS), {(THING, "bump")})[0], [])

    def test_a_listed_member_that_gained_a_reader_fails_as_a_line_to_remove(self) -> None:
        src = dict(self.SRC, **{"src/ui/hud.gd": "func f(t):\n\tt.used()\n\tt.bump()\n"})
        failures, _ = members.check(files(src, self.TESTS), {(THING, "bump")})
        gone = f"REMOVE from tools/test_only_members.txt: {THING} bump (now read by another file under src/)"
        self.assertEqual(failures, [gone])

    def test_a_listed_member_that_is_gone_or_unread_fails_as_a_line_to_remove(self) -> None:
        src = {THING: "class_name Thing\nfunc other() -> void:\n\tpass\n"}
        failures, _ = members.check(files(src, {}), {(THING, "bump"), (THING, "other")})
        self.assertEqual(
            failures,
            [
                f"REMOVE from tools/test_only_members.txt: {THING} bump (no longer defined)",
                f"REMOVE from tools/test_only_members.txt: {THING} other (no longer read by a test)",
            ],
        )

    def test_a_namesakes_definition_is_not_a_use_and_its_call_clears_the_member_it_reaches(self) -> None:
        # a.gd's walks() returns b.walks(); a test calls walks(): b's is read by a, a's only by tests.
        src = {
            "src/sim/a.gd": "class_name A\nfunc walks() -> bool:\n\treturn b.walks()\n",
            "src/sim/b.gd": "class_name B\nfunc walks() -> bool:\n\treturn true\n",
        }
        self.assertEqual(only(src, {"tests/test_a.gd": "func f(t):\n\tt.walks()\n"}), {("src/sim/a.gd", "walks")})

    def test_a_call_on_a_namesake_is_not_an_own_use_so_the_member_has_no_reader(self) -> None:
        src = {
            "src/sim/a.gd": "class_name A\nfunc walks() -> bool:\n\treturn b.walks()\n",
            "src/sim/b.gd": "class_name B\nfunc walks() -> bool:\n\treturn true\n",
            THING: "class_name Thing\nfunc bump() -> void:\n\tpass\nfunc run() -> void:\n\tself.bump()\n",
        }
        reads = {"tests/test_a.gd": "func f(t):\n\tt.walks()\n\tt.bump()\n"}
        found, _ = members.test_only(files(src, reads))
        _, stands = members.scan(files(src, reads))
        groups = {m.key: members.group_of(stands[m.key]) for m in found}
        self.assertEqual(groups, {("src/sim/a.gd", "walks"): "no reader", (THING, "bump"): "own file only"})

    def test_a_function_is_read_only_as_a_call_and_an_engine_name_is_never_read(self) -> None:
        src = {THING: "class_name Thing\nfunc enabled() -> bool:\n\treturn true\nfunc bump() -> void:\n\tpass\n"}
        engine = {"tests/test_thing.gd": "func f(c):\n\tc.enabled = false\n\tc.bump\n"}
        self.assertEqual(only(src, engine), set())
        self.assertEqual(only(src, {"tests/test_thing.gd": "func f(c):\n\tc.bump()\n"}), {(THING, "bump")})
        var = {THING: "class_name Thing\nvar size := 3\nfunc f() -> int:\n\treturn size\n"}
        self.assertEqual(only(var, {"tests/test_thing.gd": "func f(c):\n\tc.size.x\n"}), set())

    def test_a_constant_used_in_its_own_file_is_exempt_and_one_used_nowhere_is_not(self) -> None:
        src = {THING: "class_name Thing\nconst USED := 1\nconst UNUSED := 2\nfunc f() -> int:\n\treturn USED\n"}
        reads = {"tests/test_thing.gd": "func f():\n\tassert(Thing.USED < Thing.UNUSED)\n"}
        self.assertEqual(only(src, reads), {(THING, "UNUSED")})

    def test_the_list_is_read_from_the_tree_that_is_checked(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "src").mkdir()
            (root / "tests").mkdir()
            (root / "tools").mkdir()
            (root / "src" / "thing.gd").write_text("func bump() -> void:\n\tpass\n")
            (root / "tests" / "test_thing.gd").write_text("func f(t):\n\tt.bump()\n")
            (root / "tools" / "test_only_members.txt").write_text("# [kept] why\nsrc/thing.gd bump  # kept\n")
            self.assertEqual(
                members.check(members.read_checkout(root), members.listed(members.read_checkout(root).allowlist))[0], []
            )

    def test_the_list_file_is_read_with_comments_and_rejects_a_bad_line(self) -> None:
        self.assertEqual(members.listed("# [no reader] why\n\nsrc/a.gd go  # tail\n"), {("src/a.gd", "go")})
        for bad in (
            "# [kept] k\nsrc/a.gd\n",
            "# [kept] k\nsrc/a.gd go\nsrc/a.gd go\n",
            "src/a.gd go  # r\n",
            "# [nope] k\nsrc/a.gd go\n",
        ):
            with self.assertRaises(members.MembersError, msg=bad):
                members.listed(bad)

    def test_a_line_belongs_to_the_group_above_it_and_keeps_its_reason(self) -> None:
        text = "# [no reader] a\nsrc/a.gd one\n# [own file only] b\nsrc/a.gd two\n# [kept] c\nsrc/a.gd three  # why\n"
        got = [(e.name, e.group, e.reason, e.number) for e in members.entries_of(text)]
        self.assertEqual(
            got, [("one", "no reader", "", 2), ("two", "own file only", "", 4), ("three", "kept", "why", 6)]
        )

    def test_a_kept_line_with_no_reason_fails_in_any_state_of_the_base(self) -> None:
        entries = members.entries_of("# [kept] c\nsrc/a.gd one\nsrc/a.gd two  # why\n")
        failures = members.list_failures(entries, None)
        self.assertEqual(len(failures), 1)
        self.assertIn("test_only_members.txt:2: src/a.gd one is in a kept group with no reason", failures[0])

    def test_a_line_added_to_a_shrinking_group_fails_against_the_base_and_nothing_else_does(self) -> None:
        base = members.entries_of("# [no reader] a\nsrc/a.gd old\n# [own file only] b\nsrc/a.gd own\n")
        now = members.entries_of(
            "# [no reader] a\nsrc/a.gd new\nsrc/a.gd own\n# [own file only] b\nsrc/a.gd old\nsrc/a.gd added\n"
            "# [kept] c\nsrc/a.gd fresh  # why\n"
        )
        failures = members.list_failures(now, base)
        self.assertEqual(len(failures), 2)
        self.assertIn("src/a.gd new is added to the [no reader] group", failures[0])
        self.assertIn("src/a.gd added is added to the [own file only] group", failures[1])
        self.assertEqual(members.list_failures(now, None), [])
        self.assertEqual(members.list_failures(now, base, checker_changed=True), [])

    def test_a_member_moved_to_a_kept_group_is_not_an_addition_to_a_shrinking_one(self) -> None:
        base = members.entries_of("# [no reader] a\nsrc/a.gd old\n")
        now = members.entries_of("# [kept] c\nsrc/a.gd old  # why\n")
        self.assertEqual(members.list_failures(now, base), [])
        back = members.entries_of("# [kept] c\nsrc/a.gd old  # why\n")
        self.assertEqual(
            members.list_failures(members.entries_of("# [own file only] b\nsrc/a.gd old\n"), back),
            [
                "test_only_members.txt:2: src/a.gd old is added to the [own file only] group, which only shrinks; "
                "give the game a reader, or test through what the class does outward, or, where it must stay "
                "public, put the line in a kept group with its reason"
            ],
        )

    def test_a_stale_line_names_its_real_cause(self) -> None:
        src = {
            THING: (
                "class_name Thing\nconst K := 1\nfunc enabled() -> bool:\n\treturn true\n"
                "func run() -> int:\n\treturn K\n"
            )
        }
        reads = {"tests/test_thing.gd": "func f(t):\n\tt.K\n\tt.enabled()\n"}
        failures, _ = members.check(files(src, reads), {(THING, "K"), (THING, "enabled")})
        self.assertEqual(
            failures,
            [
                f"REMOVE from tools/test_only_members.txt: {THING} K (a constant used in its own file is exempt)",
                f"REMOVE from tools/test_only_members.txt: {THING} enabled (enabled is an engine member name in "
                "ENGINE_MEMBERS, never taken as a read)",
            ],
        )

    def test_a_call_on_another_instance_of_the_class_is_no_own_use(self) -> None:
        src = {
            THING: (
                "class_name Thing\nfunc total(other: Thing) -> int:\n\treturn other.inner()\n"
                "func inner() -> int:\n\treturn 1\n"
            )
        }
        found, _ = members.test_only(files(src, {"tests/test_thing.gd": "func f(t):\n\tt.inner()\n"}))
        _, stands = members.scan(files(src, {}))
        self.assertEqual([members.group_of(stands[m.key]) for m in found], ["no reader"])

    def test_a_file_move_carries_its_lines_one_to_one_and_nothing_else_gets_in(self) -> None:
        base = members.entries_of("# [no reader] a\nsrc/a.gd old\nsrc/b.gd keep\n")
        renames = {"src/a.gd": "src/x.gd"}
        moved = members.entries_of("# [no reader] a\nsrc/x.gd old\nsrc/b.gd keep\n")
        self.assertEqual(members.list_failures(moved, base, renames), [])
        self.assertEqual(len(members.list_failures(moved, base, {})), 1)
        self.assertEqual(len(members.list_failures(moved, base, None)), 1)
        # the move carries only the line it moved: a second addition in the new file fails
        extra = members.entries_of("# [no reader] a\nsrc/x.gd old\nsrc/x.gd newer\nsrc/b.gd keep\n")
        failures = members.list_failures(extra, base, renames)
        self.assertEqual(len(failures), 1)
        self.assertIn("src/x.gd newer is added", failures[0])

    def test_a_removal_lets_neither_a_new_member_in_its_file_nor_a_namesake_elsewhere_in(self) -> None:
        base = members.entries_of("# [no reader] a\nsrc/a.gd old\n")
        same_file = members.entries_of("# [no reader] a\nsrc/a.gd newer\nsrc/a.gd newest\n")
        self.assertEqual(len(members.list_failures(same_file, base, {})), 2)
        same_name = members.entries_of("# [no reader] a\nsrc/z.gd old\n")
        self.assertEqual(len(members.list_failures(same_name, base, {})), 1)
        self.assertEqual(len(members.list_failures(same_name, base, {"src/a.gd": "src/y.gd"})), 1)

    def test_a_move_pairs_only_within_a_group(self) -> None:
        base = members.entries_of("# [no reader] a\nsrc/a.gd old\n")
        now = members.entries_of("# [own file only] b\nsrc/x.gd old\n")
        self.assertEqual(len(members.list_failures(now, base, {"src/a.gd": "src/x.gd"})), 1)

    def test_renames_are_read_from_git(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)

            def run(*args: str) -> None:
                command = ["git", "-c", "user.name=t", "-c", "user.email=t@t", *args]
                subprocess.run(command, cwd=root, check=True, capture_output=True)

            run("init", "-q")
            (root / "a.gd").write_text("class_name A\nfunc one() -> int:\n\treturn 1\n")
            (root / "c.gd").write_text("x\n")
            run("add", "-A")
            run("commit", "-q", "-m", "base")
            run("mv", "a.gd", "b.gd")
            (root / "c.gd").write_text("y\n")
            self.assertEqual(members.read_renames("HEAD", root), {"a.gd": "b.gd"})
            run("add", "-A")
            run("commit", "-q", "-m", "move")
            self.assertEqual(members.read_renames("HEAD~1", root, "HEAD"), {"a.gd": "b.gd"})

    def test_a_change_to_the_checker_is_read_from_git(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            checker = root / "tools" / Path(members.__file__).name

            def run(*args: str) -> None:
                command = ["git", "-c", "user.name=t", "-c", "user.email=t@t", *args]
                subprocess.run(command, cwd=root, check=True, capture_output=True)

            run("init", "-q")
            checker.parent.mkdir()
            checker.write_text("one\n")
            run("add", "-A")
            run("commit", "-q", "-m", "base")
            self.assertFalse(members.read_checker_changed("HEAD", root))
            checker.write_text("two\n")
            self.assertTrue(members.read_checker_changed("HEAD", root))

    def test_main_lets_a_group_grow_only_in_a_diff_that_changes_the_checker(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            checker = root / "tools" / Path(members.__file__).name
            listing = root / members.ALLOWLIST

            def run(*args: str) -> None:
                command = ["git", "-c", "user.name=t", "-c", "user.email=t@t", *args]
                subprocess.run(command, cwd=root, check=True, capture_output=True)

            (root / "src").mkdir()
            (root / "tests").mkdir()
            checker.parent.mkdir()
            (root / "src" / "a.gd").write_text("class_name A\nfunc bump() -> void:\n\tpass\n")
            (root / "tests" / "test_a.gd").write_text("func f(a):\n\ta.bump()\n")
            checker.write_text("one\n")
            listing.write_text("# [no reader] group\n")
            run("init", "-q")
            run("add", "-A")
            run("commit", "-q", "-m", "base")
            listing.write_text("# [no reader] group\nsrc/a.gd bump\n")

            def main() -> int:
                with redirect_stdout(io.StringIO()):
                    return members.main(["--root", str(root), "--base", "HEAD"])

            self.assertEqual(main(), 1)
            checker.write_text("two\n")
            self.assertEqual(main(), 0)


class ReadTests(unittest.TestCase):
    def test_a_revision_is_read_from_git_and_a_checkout_from_disk(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)

            def git(*args: str) -> None:
                subprocess.run(
                    ["git", "-c", "user.name=t", "-c", "user.email=t@example.com", *args],
                    cwd=repo,
                    check=True,
                    capture_output=True,
                )

            git("init", "-q", "-b", "main")
            (repo / "src" / "sim").mkdir(parents=True)
            (repo / "tests").mkdir()
            (repo / "src" / "sim" / "thing.gd").write_text("func bump() -> void:\n\tpass\n")
            (repo / "src" / "sim" / "notes.txt").write_text("not code\n")
            (repo / "tests" / "test_thing.gd").write_text("func f(t):\n\tt.bump()\n")
            git("add", ".")
            git("commit", "-q", "-m", "one")
            (repo / "src" / "sim" / "thing.gd").write_text("func other() -> void:\n\tpass\n")
            read = members.read_rev("HEAD", root=repo)
            self.assertEqual(list(read.src), [THING])
            self.assertEqual(list(read.tests), ["tests/test_thing.gd"])
            self.assertIn("bump", read.src[THING])
            self.assertIn("other", members.read_checkout(repo).src[THING])

    def test_the_base_list_is_read_from_a_commit_and_a_base_without_one_compares_nothing(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)

            def run(*args: str) -> None:
                subprocess.run(
                    ["git", "-c", "user.name=t", "-c", "user.email=t@example.com", *args],
                    cwd=repo,
                    check=True,
                    capture_output=True,
                )

            run("init", "-q", "-b", "main")
            (repo / "tools").mkdir()
            (repo / "README").write_text("x\n")
            run("add", ".")
            run("commit", "-q", "-m", "none")
            (repo / "tools" / "test_only_members.txt").write_text("# [no reader] a\nsrc/a.gd go\n")
            run("add", ".")
            run("commit", "-q", "-m", "list")
            self.assertIsNone(members.read_base("HEAD~1", repo))
            base = members.read_base("HEAD", repo)
            assert base is not None
            self.assertEqual([e.key for e in base], [("src/a.gd", "go")])
            with self.assertRaises(check_layers.LayerError):
                members.read_base("no-such-rev", repo)


if __name__ == "__main__":
    unittest.main()
