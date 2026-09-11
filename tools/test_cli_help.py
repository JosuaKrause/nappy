#!/usr/bin/env python3
"""The two-path test the cli-tools skill asks for, for every tools/*.py entry point.

--help must print usage and exit 0 without doing any work; an unknown flag must be rejected --
usage-shaped output, a non-zero exit -- before any work happens either. Exercised through the
real subprocess, which is the boundary a caller actually sees, and it is also what lets this
cover `reference.py` and `remove-checkerboard.py`, whose real work needs positional arguments
neither of these two invocations ever supplies.

`clip.py` and `codex-hooks.py` are exercised the same way for the same reason, even though they
already have their own focused suites (`test_clip.py`, `test_codex_hooks.py`): this file is the
one place the cli-tools contract itself is checked, so a future entry point is added to
`ENTRY_POINTS` once rather than given a bespoke pair of cases wherever it happens to live.
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent

# Every tools/*.py a person or a script runs directly. Not the test_*.py files themselves --
# unittest.main() already gives every one of them -h and rejects an unknown flag, which is the
# standard library's job rather than this repository's.
ENTRY_POINTS = ("clip.py", "reference.py", "remove-checkerboard.py", "codex-hooks.py")


class CliHelpTests(unittest.TestCase):
    def run_tool(self, name: str, *args: str) -> subprocess.CompletedProcess[str]:
        # codex-hooks.py is the one entry point Codex runs with the bare host python3 rather than
        # through uv (see the python-tooling skill); sys.executable is close enough for this
        # check, which is about argv handling rather than about the interpreter version. stdin is
        # closed rather than left attached to the test runner's own, so a bug that reintroduces a
        # blocking stdin read on the --help/bad-flag path fails fast instead of hanging the suite.
        return subprocess.run(
            [sys.executable, str(TOOLS / name), *args],
            stdin=subprocess.DEVNULL,
            capture_output=True,
            text=True,
            timeout=15,
        )

    def test_help_exits_zero_and_prints_usage(self) -> None:
        for name in ENTRY_POINTS:
            with self.subTest(tool=name):
                for flag in ("--help", "-h"):
                    result = self.run_tool(name, flag)
                    self.assertEqual(result.returncode, 0, f"{name} {flag}: {result.stderr}")
                    self.assertIn("usage", (result.stdout + result.stderr).lower(), f"{name} {flag}")

    def test_unknown_flag_is_rejected(self) -> None:
        for name in ENTRY_POINTS:
            with self.subTest(tool=name):
                result = self.run_tool(name, "--this-flag-does-not-exist")
                self.assertNotEqual(result.returncode, 0, f"{name} accepted an unknown flag")


if __name__ == "__main__":
    unittest.main()
