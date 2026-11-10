#!/usr/bin/env python3
"""Tests for compare-placement-rows.py on two small logs."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
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
            "--sample", "a", "2", str(self.main), str(self.head), "--sample", "b", "2", str(self.main), str(self.head)
        )
        self.assertEqual(r.returncode, 0, r.stderr)
        repeated = r.stdout.split("(c)")[1].split("Summary")[0]
        self.assertIn("row by day: crate day 1", repeated)
        self.assertNotIn("bench", repeated)

    def test_opposite_signs_are_not_a_repeat(self) -> None:
        r = self.run_tool(
            "--sample", "a", "2", str(self.main), str(self.head), "--sample", "b", "2", str(self.head), str(self.main)
        )
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("Outside on two samples or more, same sign: 0.", r.stdout)
        self.assertIn("(b) Outside", r.stdout)

    def refused(self, *args: str) -> str:
        r = subprocess.run(
            [sys.executable, str(TOOLS / "compare-placement-rows.py"), *args],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(r.returncode, 2, r.stderr)
        self.assertEqual(r.stdout, "")
        self.assertNotIn("Traceback", r.stderr)
        return r.stderr

    def sample(
        self, name: str = "s", cities: str = "2", main: Path | None = None, head: Path | None = None
    ) -> list[str]:
        return ["--sample", name, cities, str(main or self.main), str(head or self.head)]

    def refuse_with(self, roles: Path | None, *rest: str) -> str:
        return self.refused("--roles", str(roles or self.roles), *rest)

    def test_a_missing_or_undecodable_file_is_refused(self) -> None:
        self.assertIn("cannot read", self.refuse_with(None, *self.sample(head=Path(str(self.head) + ".none"))))
        self.assertIn("cannot read", self.refuse_with(Path(str(self.roles) + ".none"), *self.sample()))
        bad = self.roles.parent / "bad.log"
        bad.write_bytes(b"\xff\xfe\x00")
        self.assertIn("UTF-8", self.refuse_with(None, *self.sample(head=bad)))
        self.assertIn("UTF-8", self.refuse_with(bad, *self.sample()))

    def test_a_log_without_rows_is_refused(self) -> None:
        empty = self.roles.parent / "empty.log"
        empty.write_text("LOAD FAIL\n")
        self.assertIn("no RD line", self.refuse_with(None, *self.sample(head=empty)))
        self.assertIn("no RD line", self.refuse_with(None, *self.sample(main=empty)))

    def test_a_role_table_without_roles_or_malformed_is_refused(self) -> None:
        self.assertIn("no ROLE line", self.refuse_with(self.main, *self.sample()))
        for text in ("ROLE 1 crate\n", "ROLE x crate 1\n", "ROLE 1 crate 1 9\n"):
            bad = self.roles.parent / "badroles.log"
            bad.write_text(text)
            self.assertIn("cannot read the line", self.refuse_with(bad, *self.sample()))

    def test_a_city_count_the_logs_do_not_carry_is_refused(self) -> None:
        self.assertIn("counts 2 cities, not 9", self.refuse_with(None, *self.sample(cities="9")))
        other = self.roles.parent / "other.log"
        other.write_text(HEAD.replace("RD 1 2", "RD 1 3"))
        self.assertIn("counts 3 cities, not 2", self.refuse_with(None, *self.sample(head=other)))

    def test_a_malformed_row_is_refused(self) -> None:
        for line in (
            "RV 1 crate -1 10",
            "RV 1 crate 3 10",
            "RV 1 crate 0 ten",
            "RV 1 crate 0",
            "RK 1 crate sidewalk \u00b2",
        ):
            bad = self.roles.parent / "badrows.log"
            bad.write_text(MAIN + line + "\n")
            self.assertIn("cannot read the line", self.refuse_with(None, *self.sample(main=bad)))

    def test_bad_arguments_are_refused_before_any_work(self) -> None:
        self.assertEqual(self.refuse_with(None).count("usage"), 1)
        self.refused("--roles", str(self.roles), "--bogus")
        self.refused("--roles", str(self.roles), "stray", *self.sample())
        for count in ("zero", "0", "-3", "\u00b2"):
            self.assertIn("city count", self.refuse_with(None, *self.sample(cities=count)))


if __name__ == "__main__":
    unittest.main()
