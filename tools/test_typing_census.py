#!/usr/bin/env python3
"""Unit tests for `tools/typing_census.py`: what can be tested without the engine (the parsing of the debugger's
lines, the telling of a message to its warning, the rewriting of an opt-out line, the settings text, what `--check`
finds, whether a run finished, which failed files stop `--write`, the restore of the tree on a temporary one, and
real SIGINTs sent at random moments of taking the lines out and of the restore, in a child process).
Each case names the change to `tools/typing_census.py` it would fail."""

from __future__ import annotations

import json
import os
import random
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from collections.abc import Sequence
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
from pathlib import Path
from typing import ClassVar
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

import typing_census as census

FULL = '@warning_ignore_start("untyped_declaration", "unsafe_property_access", "unsafe_method_access")\n'
SOME = '@warning_ignore_start("untyped_declaration", "unsafe_method_access")\n'
BODY = "extends Node\nvar x = 1\n"

OUTPUT = """Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: The variable "x" has no static type.
     at: GDScript::reload (res://src/a.gd:3)
     GDScript backtrace (most recent call first):
         [0] _ready (res://tools/typing_census.gd:26)
WARNING: The variable "x" has no static type.
     at: GDScript::reload (res://src/a.gd:3)
WARNING: The property "count" is not present on the inferred type "Node" (but may be present on a subtype).
     at: GDScript::reload (res://tests/b.gd:9)
debug> SCRIPT ERROR: Parse Error: broken
          at: GDScript::reload (res://tests/c.gd:1)
CENSUS_FAILED res://tests/c.gd
CENSUS_LOADED res://src/a.gd
"""


class OptOutLine(unittest.TestCase):
    def test_names_are_read_in_order(self) -> None:
        # Fails if opt_out_names sorts, dedupes or drops the names it reads from the line.
        self.assertEqual(census.opt_out_names(SOME), ["untyped_declaration", "unsafe_method_access"])

    def test_another_first_line_is_not_one(self) -> None:
        # Fails if opt_out_names accepts any first line, or any ignore line that names none of the three warnings.
        self.assertIsNone(census.opt_out_names("extends Node\n"))
        self.assertIsNone(census.opt_out_names('@warning_ignore_start("unused_variable")\n'))
        self.assertIsNone(census.opt_out_names("@tool\n"))

    def test_the_one_form(self) -> None:
        # Fails if opt_out_line does not write the names in the order of TYPING, comma-space separated.
        self.assertEqual(census.opt_out_line({"unsafe_method_access", "untyped_declaration"}), SOME)
        self.assertEqual(census.opt_out_line(set(census.TYPING)), FULL)


class Rewriting(unittest.TestCase):
    def test_a_line_is_rewritten_to_what_the_file_trips(self) -> None:
        # Fails if with_line keeps the line's old names or writes only the tripped ones it lacked.
        self.assertEqual(
            census.with_line(FULL + BODY, {"untyped_declaration"}),
            '@warning_ignore_start("untyped_declaration")\n' + BODY,
        )
        self.assertEqual(census.with_line(SOME + BODY, set(census.TYPING)), FULL + BODY)

    def test_a_correct_line_is_left_as_it_is(self) -> None:
        # Fails if with_line rewrites a line that is already right (a spurious diff on every --write).
        text = SOME + BODY
        self.assertEqual(census.with_line(text, {"untyped_declaration", "unsafe_method_access"}), text)

    def test_the_line_of_a_file_that_trips_none_is_deleted(self) -> None:
        # Fails if with_line leaves an empty or old line on a file that trips nothing.
        self.assertEqual(census.with_line(FULL + BODY, set()), BODY)

    def test_a_file_without_a_line_gains_none(self) -> None:
        # Fails if with_line adds an opt-out line to a file that has none.
        self.assertEqual(census.with_line(BODY, set(census.TYPING)), BODY)

    def test_a_crooked_line_is_made_the_one_form(self) -> None:
        # Fails if with_line copies the old line's spacing instead of writing the one form.
        crooked = '@warning_ignore_start("unsafe_method_access",  "untyped_declaration")\n'
        self.assertEqual(census.with_line(crooked + BODY, set(census.TYPING[:1] + census.TYPING[2:])), SOME + BODY)

    def test_without_line_empties_only_an_opt_out_line(self) -> None:
        # Fails if the line is dropped instead of emptied: every line number the engine prints moves up by one.
        self.assertEqual(census.without_line(SOME + BODY), "\n" + BODY)
        self.assertEqual(census.without_line(BODY), BODY)

    def test_a_crlf_line_is_rewritten_with_crlf(self) -> None:
        # Fails if with_line writes the new line with a bare LF into a CRLF file.
        crlf = SOME.replace("\n", "\r\n") + "extends Node\r\n"
        self.assertEqual(
            census.with_line(crlf, {"untyped_declaration"}),
            '@warning_ignore_start("untyped_declaration")\r\nextends Node\r\n',
        )


class Output(unittest.TestCase):
    def test_hits_are_deduplicated_with_file_and_line(self) -> None:
        # Fails if the same warning printed twice is counted twice, or the at: line's file or number is misread.
        hits, failed = census.parse_output(OUTPUT)
        self.assertEqual([(h.path, h.line) for h in hits], [("src/a.gd", 3), ("tests/b.gd", 9)])
        self.assertEqual(failed, ["tests/c.gd"])

    def test_a_message_is_told_to_its_warning(self) -> None:
        # Fails if a MESSAGES pattern is swapped or loosened so a message is told to the wrong warning.
        hits, _ = census.parse_output(OUTPUT)
        self.assertEqual([census.classify(h.message) for h in hits], ["untyped_declaration", "unsafe_property_access"])
        self.assertEqual(
            census.classify('The method "go()" is not present on the inferred type "Node".'), "unsafe_method_access"
        )
        self.assertEqual(census.classify('Function "f()" has no static return type.'), "untyped_declaration")

    def test_an_unknown_message_is_told_to_none(self) -> None:
        # Fails if classify answers a warning for a message of none of the three (a miscount instead of an error).
        self.assertIsNone(census.classify("Standalone expression (the line may have no effect)."))


class Checking(unittest.TestCase):
    def test_a_name_the_file_does_not_trip_is_stale(self) -> None:
        # Fails if check_file stops comparing the named warnings with the tripped ones.
        self.assertEqual(
            census.check_file("src/a.gd", FULL, {"untyped_declaration"}),
            [
                "src/a.gd: names unsafe_property_access, which it does not trip",
                "src/a.gd: names unsafe_method_access, which it does not trip",
            ],
        )

    def test_a_tripped_warning_the_line_lacks_is_found(self) -> None:
        # Fails if check_file reads only the names on the line, not what the file trips.
        self.assertEqual(
            census.check_file("src/a.gd", SOME, set(census.TYPING)),
            ["src/a.gd: trips unsafe_property_access, which its line does not name"],
        )

    def test_a_file_with_no_line_that_trips_is_found_and_one_that_does_not_passes(self) -> None:
        # Fails if a file with no line is skipped, or one that trips nothing is reported.
        self.assertEqual(
            census.check_file("src/a.gd", "extends Node\n", {"unsafe_method_access"}),
            ["src/a.gd: trips unsafe_method_access and has no opt-out line"],
        )
        self.assertEqual(census.check_file("src/a.gd", "extends Node\n", set()), [])

    def test_a_line_out_of_form_is_found(self) -> None:
        # Fails if the order of the names is not held (the names compared as a set).
        crooked = '@warning_ignore_start("unsafe_method_access", "untyped_declaration")\n'
        self.assertEqual(
            census.check_file("src/a.gd", crooked, {"untyped_declaration", "unsafe_method_access"}),
            ["src/a.gd: its line is not in the one form"],
        )

    def test_a_name_written_twice_is_out_of_form(self) -> None:
        # Fails if the names are compared as a set, or deduplicated before the comparison: a repeat would pass.
        twice = '@warning_ignore_start("untyped_declaration", "untyped_declaration")\n'
        self.assertEqual(
            census.check_file("src/a.gd", twice, {"untyped_declaration"}),
            ["src/a.gd: its line is not in the one form"],
        )

    def test_a_right_line_passes(self) -> None:
        # Fails if check_file reports a finding for a line that is exactly right.
        self.assertEqual(census.check_file("src/a.gd", FULL, set(census.TYPING)), [])


class Finished(unittest.TestCase):
    PATHS: ClassVar[list[str]] = ["src/a.gd", "tests/b.gd"]
    GOOD = "CENSUS_LOADED res://src/a.gd\nCENSUS_FAILED res://tests/b.gd\nCENSUS_DONE 2\n"

    def test_a_run_that_answered_every_path_is_a_census(self) -> None:
        # Fails if finished refuses a run that answered every path, so no census could ever be taken.
        self.assertIsNone(census.finished(0, self.GOOD, self.PATHS))

    def test_an_engine_that_exited_badly_is_not(self) -> None:
        # Fails if the exit code is not read: a killed engine's partial output would count.
        self.assertIsNotNone(census.finished(1, self.GOOD, self.PATHS))

    def test_a_run_without_its_done_line_is_not(self) -> None:
        # Fails if CENSUS_DONE is not required, or its count is not held to the paths handed.
        self.assertIsNotNone(census.finished(0, self.GOOD.replace("CENSUS_DONE 2\n", ""), self.PATHS))
        self.assertIsNotNone(census.finished(0, self.GOOD.replace("DONE 2", "DONE 1"), self.PATHS))

    def test_a_path_answered_twice_is_not(self) -> None:
        # Fails if finished asks only that each path is answered at least once: a path printed both loaded and
        # failed (a scene that loaded it twice) would count.
        twice = self.GOOD + "CENSUS_FAILED res://src/a.gd\n"
        self.assertIsNotNone(census.finished(0, twice, self.PATHS))

    def test_a_run_that_skipped_a_path_is_not(self) -> None:
        # Fails if a path with no CENSUS_LOADED or CENSUS_FAILED line is taken as loaded with no warnings.
        self.assertIsNotNone(census.finished(0, "CENSUS_LOADED res://src/a.gd\nCENSUS_DONE 2\n", self.PATHS))


class Failures(unittest.TestCase):
    TEXTS: ClassVar[dict[str, str]] = {
        "src/dep.gd": "class_name Dep\n",
        "tests/probe.gd": "extends Node\n",
        "tests/user.gd": "var d = Dep.new()\n",
        "tests/preloader.gd": 'const P := preload("res://tests/other_probe.gd")\n',
        "tests/other_probe.gd": "extends Node\n",
    }

    def test_a_failed_file_under_src_stops_a_write(self) -> None:
        # Fails if only failures others name are counted: a failed src file changes what its dependents trip.
        self.assertEqual(
            census.untrusted_failures(["src/dep.gd"], {"src/dep.gd": "extends Node\n"}, ""), ["src/dep.gd"]
        )

    def test_a_failed_file_named_by_class_or_path_stops_a_write(self) -> None:
        # Fails if neither a class_name nor a res:// path counts as naming.
        texts = dict(self.TEXTS) | {"tests/dep2.gd": "class_name Dep2\n", "tests/u2.gd": "Dep2.new()\n"}
        self.assertEqual(census.untrusted_failures(["tests/dep2.gd"], texts, ""), ["tests/dep2.gd"])
        self.assertEqual(census.untrusted_failures(["tests/other_probe.gd"], texts, ""), ["tests/other_probe.gd"])

    def test_an_autoload_stops_a_write(self) -> None:
        # Fails if project.godot's autoload paths are not read.
        out = census.untrusted_failures(["tests/probe.gd"], self.TEXTS, 'X="*res://tests/probe.gd"\n')
        self.assertEqual(out, ["tests/probe.gd"])

    def test_a_failed_file_nothing_names_does_not(self) -> None:
        # Fails if every failure stops a write (the tool could not run on a tree with a probe that does not parse).
        self.assertEqual(census.untrusted_failures(["tests/probe.gd"], self.TEXTS, ""), [])


class Restoring(unittest.TestCase):
    def tree(self, files: dict[str, bytes]) -> tuple[census.Tree, Path]:
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        tmp = Path(scratch.name)
        for name, data in files.items():
            (tmp / name).write_bytes(data)
        return census.Tree(tmp), tmp

    def test_a_crlf_file_comes_back_byte_for_byte(self) -> None:
        # Fails if the files are read or written as text: the line endings would change.
        crlf = SOME.replace("\n", "\r\n").encode() + b"extends Node\r\nvar x = 1\r\n"
        tree, tmp = self.tree({"a.gd": crlf, "project.godot": b"[debug]\r\n"})
        tree.original_project = (tmp / "project.godot").read_bytes()
        tree.take_lines_out([tmp / "a.gd"])
        self.assertTrue((tmp / "a.gd").read_bytes().startswith(b"\nextends Node"))
        (tmp / "project.godot").write_bytes(b"changed")
        tree.restore()
        self.assertEqual((tmp / "a.gd").read_bytes(), crlf)
        self.assertEqual((tmp / "project.godot").read_bytes(), b"[debug]\r\n")

    def test_a_file_without_a_line_is_not_touched(self) -> None:
        # Fails if take_lines_out records or rewrites a file with no opt-out line (the `continue` deleted): a save
        # made to it during the run would be lost, and it is read straight after, before anything else can mend it.
        tree, tmp = self.tree({"a.gd": SOME.encode() + b"x\n", "b.gd": b"extends Node\n"})
        tree.take_lines_out([tmp / "a.gd", tmp / "b.gd"])
        self.assertEqual((tmp / "b.gd").read_bytes(), b"extends Node\n")
        self.assertEqual(list(tree.first_lines), [tmp / "a.gd"])
        tree.restore()
        self.assertEqual((tmp / "b.gd").read_bytes(), b"extends Node\n")

    def test_an_edit_below_the_line_survives_the_restore(self) -> None:
        # Fails if the restore writes the saved whole file back instead of the first line.
        tree, tmp = self.tree({"a.gd": SOME.encode() + b"x\n"})
        tree.take_lines_out([tmp / "a.gd"])
        (tmp / "a.gd").write_bytes(b"\nx\nvar edited = 1\n")
        tree.restore()
        self.assertEqual((tmp / "a.gd").read_bytes(), SOME.encode() + b"x\nvar edited = 1\n")

    def test_a_file_whose_first_line_was_changed_is_left_as_found(self) -> None:
        # Fails if the restore overwrites a first line somebody else wrote.
        tree, tmp = self.tree({"a.gd": SOME.encode() + b"x\n"})
        tree.take_lines_out([tmp / "a.gd"])
        (tmp / "a.gd").write_bytes(b"extends Node\nx\n")
        with redirect_stderr(StringIO()) as err:
            tree.restore()
        self.assertIn("left as it is", err.getvalue())
        self.assertEqual((tmp / "a.gd").read_bytes(), b"extends Node\nx\n")

    def test_the_notice_names_the_path_relative_and_the_line_not_put_back(self) -> None:
        # Fails if the notice prints the absolute path or leaves out the first line, which is then only in git.
        tree, tmp = self.tree({"a.gd": SOME.encode() + b"x\n"})
        tree.take_lines_out([tmp / "a.gd"])
        (tmp / "a.gd").write_bytes(b"# mine\nx\n")
        with redirect_stderr(StringIO()) as err:
            tree.restore()
        self.assertIn(
            f"typing_census.py: a.gd was changed during the run; left as it is (its first line was {SOME.strip()})",
            err.getvalue(),
        )

    def test_an_interrupt_inside_a_write_leaves_the_file_whole(self) -> None:
        # Fails if a write truncates the target before its new bytes are down (Path.write_bytes in place of
        # atomic_write): an interrupt between the two leaves the file empty and nothing in memory to put back.
        text = SOME.encode() + b"extends Node\nvar x = 1\n"
        tree, tmp = self.tree({"a.gd": text})
        with (
            mock.patch("os.replace", side_effect=KeyboardInterrupt) as replace,
            self.assertRaises(KeyboardInterrupt),
        ):
            tree.take_lines_out([tmp / "a.gd"])
        replace.assert_called_once()
        self.assertEqual((tmp / "a.gd").read_bytes(), text)
        self.assertEqual(sorted(p.name for p in tmp.iterdir()), ["a.gd"])
        tree.restore()
        self.assertEqual((tmp / "a.gd").read_bytes(), text)

    def test_an_interrupt_inside_the_restore_leaves_every_file_whole(self) -> None:
        # Fails if either of the restore's two writes is made in place (`write_bytes` on project.godot or on the
        # file): each write must reach `os.replace`, so the patch lets project.godot's through and interrupts the
        # file's after its temporary file is written and before it is moved over, and an in-place write of either
        # leaves the interrupt unraised. A truncating in-place write left a file empty on a real interrupt.
        text = SOME.encode() + b"x\n"
        tree, tmp = self.tree({"a.gd": text, "project.godot": b"[debug]\n"})
        tree.original_project = b"[debug]\n"
        tree.take_lines_out([tmp / "a.gd"])
        (tmp / "project.godot").write_bytes(b"changed")
        real_replace = os.replace
        targets: list[str] = []

        def replace_once_then_interrupt(src: Path, dst: Path) -> None:
            targets.append(Path(dst).name)
            if len(targets) > 1:
                raise KeyboardInterrupt
            real_replace(src, dst)

        with (
            mock.patch("os.replace", side_effect=replace_once_then_interrupt),
            self.assertRaises(KeyboardInterrupt),
        ):
            tree.restore()
        self.assertEqual(targets, ["project.godot", "a.gd"])
        self.assertEqual((tmp / "project.godot").read_bytes(), b"[debug]\n")
        self.assertEqual((tmp / "a.gd").read_bytes(), b"\nx\n")
        self.assertEqual(sorted(p.name for p in tmp.iterdir()), ["a.gd", "project.godot"])
        tree.restore()
        self.assertEqual((tmp / "a.gd").read_bytes(), text)
        self.assertEqual((tmp / "project.godot").read_bytes(), b"[debug]\n")

    def test_a_restore_entered_twice_puts_back_once_and_names_nothing(self) -> None:
        # Fails if restore leaves first_lines as it was or reads a restored file as changed by somebody else: a
        # signal during a restore starts a second one, which would name every file the first had put back.
        files = {f"{n}.gd": SOME.encode() + b"x\n" for n in "abc"}
        tree, tmp = self.tree(files)
        tree.take_lines_out([tmp / n for n in files])
        inner = census.atomic_write
        entered: list[bool] = []

        def write_then_enter_again(path: Path, data: bytes) -> None:
            inner(path, data)
            if not entered:
                entered.append(True)
                tree.restore()

        with redirect_stderr(StringIO()) as err, mock.patch.object(census, "atomic_write", write_then_enter_again):
            tree.restore()
        self.assertEqual(err.getvalue(), "")
        for name, data in files.items():
            self.assertEqual((tmp / name).read_bytes(), data)
        self.assertEqual(tree.first_lines, {})


# The child the real-signal cases interrupt: the tool's own handlers (`put_back_on_every_exit`) around the phase
# named, on the scratch tree named. It prints START right before the phase and END with its length after it.
CHILD = """
import sys, time
from pathlib import Path
sys.path.insert(0, sys.argv[1])
import typing_census as census
tree = census.Tree(Path(sys.argv[2]))
phase = sys.argv[3]
files = tree.gd_files()
tree.original_project = tree.project.read_bytes()
with census.put_back_on_every_exit(tree):
    if phase == "restore":
        census.atomic_write(tree.project, b"[debug]\\ngdscript/warnings/untyped_declaration=1\\n")
        tree.take_lines_out(files)
    print("START", flush=True)
    start = time.perf_counter()
    if phase == "take":
        census.atomic_write(tree.project, b"[debug]\\ngdscript/warnings/untyped_declaration=1\\n")
        tree.take_lines_out(files)
    else:
        tree.restore()
    print(f"END {time.perf_counter() - start}", flush=True)
"""


class RealSignals(unittest.TestCase):
    """A real SIGINT at a random moment of taking the lines out, and of the restore, in a child process.

    A case that raises from one patched call holds only that point, while a real signal is handled wherever the
    interpreter next checks for one, inside any call. So these send the signal itself, with `os.kill`, after a
    delay drawn from a seeded generator within the phase's measured length, and after every trial compare the whole
    scratch tree with what it was: every file byte for byte with its mode, and no file added or removed.
    """

    SEED = 1321
    # Per phase. A temporary file made by `tempfile.mkstemp` and left behind by a signal handled inside it was the
    # last hole: about one interrupt in five during either phase found it, so 40 that land miss it about once in
    # 7500 runs.
    TRIALS = 50
    # The trials are drawn until TRIALS // 2 have landed, and at most this many are: how many land depends on how
    # fast the machine ran each trial against the one that measured the phase, so a busy runner needs more draws.
    MAX_TRIALS = 4 * TRIALS
    FILES = 120

    def setUp(self) -> None:
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        self.root = Path(scratch.name) / "project"
        for i in range(self.FILES):
            folder = ("src", "src/city", "tests", "tests/probes", "tools")[i % 5]
            body = f"extends Node\nvar x{i} = {i}\n".encode()
            text = (FULL.encode(), SOME.encode(), b"", FULL.replace("\n", "\r\n").encode())[i % 4] + body
            path = self.root / folder / f"f{i}.gd"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(text)
            path.chmod(0o755 if i % 7 == 0 else 0o644)
        (self.root / "project.godot").write_bytes(b"[debug]\ngdscript/warnings/untyped_declaration=2\n")
        self.original = self.snapshot()

    def snapshot(self) -> dict[str, tuple[bytes, int] | None]:
        return {
            str(p.relative_to(self.root)): (p.read_bytes(), p.stat().st_mode & 0o7777) if p.is_file() else None
            for p in sorted(self.root.rglob("*"))
        }

    def child(self, phase: str, delay: float | None) -> tuple[int, str, str]:
        tools = str(Path(__file__).resolve().parent)
        with subprocess.Popen(
            [sys.executable, "-c", CHILD, tools, str(self.root), phase],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        ) as proc:
            assert proc.stdout is not None
            # Read before anything is asserted: reading the child's stderr waits for it to end.
            first = proc.stdout.readline()
            if first == "START\n" and delay is not None:
                time.sleep(delay)
                os.kill(proc.pid, signal.SIGINT)
            out, err = proc.communicate(timeout=60)
        self.assertEqual(first, "START\n", err)
        return proc.returncode, out, err

    def interrupt(self, phase: str) -> None:
        code, out, _ = self.child(phase, None)
        self.assertEqual(code, 0)
        length = float(out.split()[-1])
        self.assertEqual(self.snapshot(), self.original)
        rng = random.Random(f"{self.SEED}-{phase}")
        landed = 0
        wanted = self.TRIALS // 2
        trial = 0
        while landed < wanted and trial < self.MAX_TRIALS:
            # The phase repeats one write per file, so its first four fifths hold every window and a delay drawn
            # there lands inside it even when a trial runs a little faster than the measuring one.
            delay = rng.uniform(0.0, 0.8 * length)
            code, out, err = self.child(phase, delay)
            landed += code == 128 + signal.SIGINT and "END" not in out
            after = self.snapshot()
            if after != self.original or "left as it is" in err:
                added = sorted(set(after) - set(self.original))
                changed = sorted(p for p in self.original if after.get(p) != self.original[p])
                self.fail(
                    f"{phase}, trial {trial}, SIGINT {delay * 1000:.2f} ms into a {length * 1000:.1f} ms phase: "
                    f"added {added}, changed or removed {changed}; stderr {err!r}"
                )
            trial += 1
        self.assertGreaterEqual(landed, wanted, f"only {landed} signals landed in {trial} trials of the {phase} phase")

    def test_a_signal_while_the_lines_are_taken_out_leaves_the_tree_as_it_was(self) -> None:
        # Fails if a signal handled inside a write can leave the file beside behind (atomic_write naming it through
        # tempfile.mkstemp, about one trial in five), empty a script (a write in place), or leave a line out.
        self.interrupt("take")

    def test_a_signal_during_the_restore_leaves_the_tree_as_it_was(self) -> None:
        # Fails as the case above does, for the restore's writes, and if a handler's restore that runs while the
        # interrupted one is half done names or skips a file.
        self.interrupt("restore")


ENGINE = """#!{python}
import json
import sys
from pathlib import Path

here = Path(__file__).parent
conf = json.loads((here / "conf.json").read_text())
args = sys.argv[1:]
if any("typing_census_names" in a for a in args):
    print("\\n".join("CENSUS_WARNING " + n for n in conf["names"]))
    sys.exit(0)
root = Path(args[args.index("--path") + 1])
listing = Path(args[-1]).read_text().split()
seen = {{p: (root / p.removeprefix("res://")).read_bytes().split(b"\\n")[0].decode() for p in listing}}
project = (root / "project.godot").read_text()
(here / "seen.json").write_text(json.dumps({{"first_lines": seen, "project": project}}))
out = conf["warnings"]
for p in listing:
    out += ("CENSUS_FAILED " if p in conf["failed"] else "CENSUS_LOADED ") + p + "\\n"
if not conf.get("no_done"):
    out += "CENSUS_DONE " + str(len(listing)) + "\\n"
sys.stdout.write(out)
sys.exit(conf.get("code", 0))
"""
NAMES = [*census.TYPING, "standalone_expression", "unused_variable"]


def warning(kind: str, path: str, line: int) -> str:
    text = {
        "u": 'The variable "x" has no static type.',
        "p": 'The property "a" is not present on the inferred type "Node" (but may be present on a subtype).',
        "m": 'The method "go()" is not present on the inferred type "Node".',
    }[kind]
    return f"WARNING: {text}\n     at: GDScript::reload (res://{path}:{line})\n"


class Running(unittest.TestCase):
    """`main()` on a scratch project with a stand-in engine that prints a canned census."""

    FILES: ClassVar[dict[str, str]] = {
        "src/a.gd": FULL + BODY,
        "tests/b.gd": FULL + BODY,
        "tests/p.gd": FULL + BODY,
        "project.godot": "[debug]\n\n[display]\nx=1\n",
    }

    def setUp(self) -> None:
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        self.base = Path(scratch.name)
        self.root = self.base / "project"
        self.engine_dir = self.base / "engine"
        self.engine_dir.mkdir()

    def make(self, cache: bool = True) -> dict[str, bytes]:
        for name, text in self.FILES.items():
            (self.root / name).parent.mkdir(parents=True, exist_ok=True)
            (self.root / name).write_bytes(text.encode())
        if cache:
            (self.root / ".godot").mkdir()
            (self.root / ".godot" / "global_script_class_cache.cfg").write_text("")
        git = ["git", "-c", "user.name=t", "-c", "user.email=t@t", "-C", str(self.root)]
        subprocess.run([*git, "init", "-q"], check=True)
        subprocess.run([*git, "add", "project.godot"], check=True)
        subprocess.run([*git, "commit", "-q", "-m", "x"], check=True)
        return self.snapshot()

    def snapshot(self) -> dict[str, bytes]:
        return {
            str(p.relative_to(self.root)): p.read_bytes()
            for p in sorted(self.root.rglob("*.*"))
            if ".git" not in p.parts and ".godot" not in p.parts
        }

    def go(
        self, argv: list[str], warnings: str = "", failed: Sequence[str] = (), **conf: object
    ) -> tuple[int, str, str]:
        engine = self.engine_dir / "godot"
        engine.write_text(ENGINE.format(python=sys.executable))
        engine.chmod(0o755)
        (self.engine_dir / "conf.json").write_text(
            json.dumps({"names": NAMES, "warnings": warnings, "failed": [f"res://{f}" for f in failed], **conf})
        )
        with redirect_stdout(StringIO()) as out, redirect_stderr(StringIO()) as err:
            code = census.main(argv, self.root, str(engine))
        return code, out.getvalue(), err.getvalue()

    def test_the_run_sees_the_lines_out_and_the_warnings_at_warn_and_leaves_the_tree_as_it_was(self) -> None:
        # Fails if take_lines_out or the settings write is skipped (the engine would see the lines and the error
        # level), or if the restore is skipped on the way out (the tree would differ, or git say it is modified).
        before = self.make()
        code, _, _ = self.go(["--check"], warning("u", "src/a.gd", 2))
        seen = json.loads((self.engine_dir / "seen.json").read_text())
        self.assertEqual(set(seen["first_lines"].values()), {""})
        self.assertIn("gdscript/warnings/untyped_declaration=1", seen["project"])
        self.assertIn("gdscript/warnings/unsafe_method_access=1", seen["project"])
        self.assertEqual(self.snapshot(), before)
        status = subprocess.run(
            ["git", "-C", str(self.root), "status", "--porcelain", "project.godot"], capture_output=True, text=True
        )
        self.assertEqual(status.stdout, "")
        self.assertEqual(code, 1)

    def test_a_write_from_a_run_a_src_file_failed_in_is_refused_and_changes_nothing(self) -> None:
        # Fails if the `if untrusted:` refusal never fires: tests/b.gd's stale line would be rewritten from a
        # census a failed autoload skewed, and the exit would be 0.
        before = self.make()
        code, _, err = self.go(["--write"], warning("u", "tests/b.gd", 2), failed=["src/a.gd"])
        self.assertEqual(code, 1)
        self.assertIn("--write refused", err)
        self.assertIn("src/a.gd", err)
        self.assertEqual(self.snapshot(), before)

    def test_a_check_fails_for_a_file_that_failed_to_load(self) -> None:
        # Fails if `--check` returns 0 for a failed file that nothing names (`return 1 if bad else 0`): its line
        # was never compared. Every file that loaded trips exactly what its line names, so the failed file is the
        # only reason the check can fail.
        self.make()
        warns = "".join(warning(k, f, 2) for k in "upm" for f in ("src/a.gd", "tests/b.gd"))
        code, out, _ = self.go(["--check"], warns, failed=["tests/p.gd"])
        self.assertEqual(
            [ln for ln in out.splitlines() if ln.startswith("FAIL")],
            ["FAIL tests/p.gd: failed to load, so its line cannot be checked"],
        )
        self.assertEqual(code, 1)

    def test_the_settings_for_the_run_are_written_beside_and_moved_over(self) -> None:
        # Fails if run_census writes the run's settings into project.godot in place (`write_bytes`) rather than
        # through atomic_write: an interrupt during that write would leave project.godot empty.
        self.make()
        written = self.record_writes()
        self.go(["--check"], warning("u", "src/a.gd", 2))
        settings = [d for p, d in written if p == "project.godot" and b"gdscript/warnings/untyped_declaration=1" in d]
        self.assertEqual(len(settings), 1)

    def test_a_rewritten_line_is_written_beside_and_moved_over(self) -> None:
        # Fails if `--write` rewrites a line in place (`write_bytes`) rather than through atomic_write: an interrupt
        # during the rewrite would leave the script empty.
        self.make()
        written = self.record_writes()
        code, _, _ = self.go(["--write"], warning("u", "tests/b.gd", 2) + warning("u", "src/a.gd", 2))
        self.assertEqual(code, 0)
        new = b'@warning_ignore_start("untyped_declaration")\n' + BODY.encode()
        self.assertIn(("tests/b.gd", new), written)
        self.assertEqual((self.root / "tests/b.gd").read_bytes(), new)

    def record_writes(self) -> list[tuple[str, bytes]]:
        """Every write through atomic_write while the case runs, as (path relative to the project, bytes)."""
        written: list[tuple[str, bytes]] = []
        inner = census.atomic_write

        def recording(path: Path, data: bytes) -> None:
            written.append((str(path.relative_to(self.root)), data))
            inner(path, data)

        patch = mock.patch.object(census, "atomic_write", recording)
        patch.start()
        self.addCleanup(patch.stop)
        return written

    def test_a_failed_file_is_neither_rewritten_nor_compared(self) -> None:
        # Fails if a failed file counts as tripping nothing: `--write` would delete its line, and `--check` would
        # call its names stale (the two mutations are `path in failed` dropped in each place).
        before = self.make()
        warns = warning("u", "tests/b.gd", 2) + warning("u", "src/a.gd", 2)
        code, _, _ = self.go(["--write"], warns, failed=["tests/p.gd"])
        self.assertEqual(code, 0)
        self.assertEqual((self.root / "tests/p.gd").read_bytes(), before["tests/p.gd"])
        self.assertEqual(
            (self.root / "tests/b.gd").read_bytes(), b'@warning_ignore_start("untyped_declaration")\n' + BODY.encode()
        )
        _, out, _ = self.go(["--check"], warns, failed=["tests/p.gd"])
        self.assertNotIn("tests/p.gd: names", out)

    def test_a_check_under_a_failure_that_stops_a_write_prints_no_skewed_lines(self) -> None:
        # Fails if `--check` prints per-file findings from a census a failed src file skewed: it says the refusal.
        self.make()
        code, out, err = self.go(["--check"], warning("u", "tests/b.gd", 2), failed=["src/a.gd"])
        self.assertEqual(code, 1)
        self.assertNotIn("FAIL tests/b.gd", out)
        self.assertIn("src/a.gd", err)

    def test_no_import_cache_refuses_before_the_engine_runs(self) -> None:
        # Fails if the `.godot/` test never fires: the engine would run and most files fail to load.
        before = self.make(cache=False)
        code, _, err = self.go(["--write"])
        self.assertEqual(code, 1)
        self.assertIn("no import cache", err)
        self.assertFalse((self.engine_dir / "seen.json").exists())
        self.assertEqual(self.snapshot(), before)

    def test_a_run_that_did_not_finish_changes_nothing_in_any_mode(self) -> None:
        # Fails if a run without CENSUS_DONE, or an engine that exited badly, is taken as a census.
        before = self.make()
        for mode in ("--write", "--check", "--lines"):
            code, _, err = self.go([mode], warning("u", "tests/b.gd", 2), no_done=True)
            self.assertEqual(code, 1, mode)
            self.assertIn("did not finish", err)
            code, _, err = self.go([mode], warning("u", "tests/b.gd", 2), code=1)
            self.assertEqual(code, 1, mode)
            self.assertEqual(self.snapshot(), before)


class Settings(unittest.TestCase):
    def test_the_warning_settings_are_replaced(self) -> None:
        # Fails if settings_text keeps the old warning lines or puts the new ones outside [debug].
        original = "[debug]\n\n; note\ngdscript/warnings/untyped_declaration=2\n\n[display]\nx=1\n"
        text = census.settings_text(original, {"untyped_declaration": 1, "unused_variable": 0})
        self.assertEqual(
            text,
            "[debug]\ngdscript/warnings/untyped_declaration=1\ngdscript/warnings/unused_variable=0\n"
            "\n; note\n\n[display]\nx=1\n",
        )


class Arguments(unittest.TestCase):
    def test_flags_and_warnings(self) -> None:
        # Fails if parse drops a flag or the warning names given as arguments.
        args = census.parse(["--check", "--lines", "standalone_expression"])
        self.assertTrue(args.check and args.lines)
        self.assertEqual(args.warnings, ["standalone_expression"])

    def test_check_with_write_is_refused(self) -> None:
        # Fails if the exclusive pair is accepted.
        with self.assertRaises(SystemExit), redirect_stderr(StringIO()):
            census.parse(["--check", "--write"])

    def test_the_folder_a_path_is_counted_under(self) -> None:
        # Fails if folder_of counts tests/probes/x.gd under tests, or a src file under anything but src.
        self.assertEqual(census.folder_of("src/a.gd"), "src")
        self.assertEqual(census.folder_of("tests/probes/a.gd"), "tests/probes")
        self.assertEqual(census.folder_of("tests/a.gd"), "tests")


if __name__ == "__main__":
    unittest.main()
