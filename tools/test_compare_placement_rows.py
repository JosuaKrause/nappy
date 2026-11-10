#!/usr/bin/env python3
"""Tests for compare-placement-rows.py on two small logs."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("compare_placement_rows", TOOLS / "compare-placement-rows.py")
assert SPEC is not None and SPEC.loader is not None
tool = importlib.util.module_from_spec(SPEC)
sys.modules["compare_placement_rows"] = tool
SPEC.loader.exec_module(tool)

ROLES = "ROLE 1 crate 1\nROLE 1 bench 2\nROLE 2 crate 1\n"
MAIN = "RD 1 2 100 4\nRV 1 crate 0 100\nRV 1 bench 1 100\nRK 1 crate sidewalk 100\nRV 2 crate 2 50\n"
HEAD = "RD 1 2 40 4\nRV 1 crate 0 40\nRV 1 bench 1 100\nRK 1 crate sidewalk 40\nRV 2 crate 2 50\n"


class CompareTest(unittest.TestCase):
    def setUp(self) -> None:
        self.dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.dir.cleanup)
        root = Path(self.dir.name)
        self.roles = root / "roles.log"
        self.main = root / "main.log"
        self.head = root / "head.log"
        self.roles.write_text(ROLES)
        self.main.write_text(MAIN)
        self.head.write_text(HEAD)

    def run_tool(self, *extra: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(TOOLS / "compare-placement-rows.py"), "--roles", str(self.roles), *extra],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_lists_the_cells_that_moved(self) -> None:
        r = self.run_tool("--sample", "small", "2", str(self.main), str(self.head))
        self.assertEqual(r.returncode, 0, r.stderr)
        out = r.stdout
        self.assertIn(
            "(b) Outside 2\u03c3 pooled over all 2 cities (small (2)), events per city per day, main \u2192 head:", out
        )
        # 100 -> 40: z = -60 / sqrt(140) = -5.1; 50.00 -> 20.00 per city over one day
        self.assertIn("- row by day: crate day 1, 50.00 \u2192 20.00 (-60%, z -5.1); z per sample -5.1", out)
        self.assertIn("- walls by view and day: on her route day 1, 50.00 \u2192 20.00 (-60%, z -5.1)", out)
        self.assertNotIn("bench day 1", out.split("(c)")[0])
        self.assertIn("- walls by view, on her route: ", out)
        self.assertIn("Outside on two samples or more, same sign: 0.", out)

    def test_two_samples_repeat_a_cell_with_the_same_sign(self) -> None:
        r = self.run_tool(
            "--sample", "a", "1", str(self.main), str(self.head), "--sample", "b", "1", str(self.main), str(self.head)
        )
        self.assertEqual(r.returncode, 0, r.stderr)
        repeated = r.stdout.split("(c)")[1].split("Summary")[0]
        self.assertIn("row by day: crate day 1", repeated)
        self.assertNotIn("bench", repeated)

    def test_missing_log_is_an_error_not_a_trace(self) -> None:
        r = self.run_tool("--sample", "small", "2", str(self.main), str(self.main) + ".none")
        self.assertEqual(r.returncode, 2)
        self.assertIn("cannot read", r.stderr)
        self.assertNotIn("Traceback", r.stderr)

    def test_bad_arguments_are_refused_before_any_work(self) -> None:
        self.assertNotEqual(self.run_tool().returncode, 0)
        self.assertNotEqual(self.run_tool("--bogus").returncode, 0)
        r = self.run_tool("--sample", "small", "zero", str(self.main), str(self.head))
        self.assertEqual(r.returncode, 2)


if __name__ == "__main__":
    unittest.main()
