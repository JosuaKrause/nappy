#!/usr/bin/env python3
"""Unit tests for `tools/check_test_only_members.py`, against small trees written here and a throwaway repository.

CI's own step (`uv run python tools/check_test_only_members.py`) holds the real tree to the real list; every
case here brings a list of its own, so a change to the game's code never turns these red.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import ClassVar

sys.path.insert(0, str(Path(__file__).resolve().parent))

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
            (root / "tools" / "test_only_members.txt").write_text("src/thing.gd bump  # kept\n")
            self.assertEqual(
                members.check(members.read_checkout(root), members.listed(members.read_checkout(root).allowlist))[0], []
            )

    def test_the_list_file_is_read_with_comments_and_rejects_a_bad_line(self) -> None:
        self.assertEqual(members.listed("# why\n\nsrc/a.gd go  # tail\n"), {("src/a.gd", "go")})
        with self.assertRaises(members.MembersError):
            members.listed("src/a.gd\n")
        with self.assertRaises(members.MembersError):
            members.listed("src/a.gd go\nsrc/a.gd go\n")


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


if __name__ == "__main__":
    unittest.main()
