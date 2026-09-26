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

import hashlib
import json
import struct
import subprocess
import sys
import tempfile
import unittest
import wave
import zipfile
from pathlib import Path
from typing import Any

TOOLS = Path(__file__).resolve().parent

# Every tools/*.py a person or a script runs directly. Not the test_*.py files themselves --
# unittest.main() already gives every one of them -h and rejects an unknown flag, which is the
# standard library's job rather than this repository's.
ENTRY_POINTS = ("clip.py", "reference.py", "remove-checkerboard.py", "codex-hooks.py", "synthesize-sfx.py")

SOUND_FILES = (
    "footsteps-grounded.wav",
    "footsteps-stylized.wav",
    "stroller-wheels-grounded.wav",
    "stroller-wheels-stylized.wav",
    "car-horn-grounded.wav",
    "car-horn-stylized.wav",
    "loudspeaker-crackle-grounded.wav",
    "loudspeaker-crackle-stylized.wav",
    "comparison.wav",
)


class CliHelpTests(unittest.TestCase):
    def run_tool(self, name: str, *args: str, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
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
            cwd=cwd,
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

    def test_synth_help_and_unknown_flag_do_no_work(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for flag in ("--help", "--this-flag-does-not-exist"):
                with self.subTest(flag=flag):
                    output = root / flag.removeprefix("--")
                    result = self.run_tool("synthesize-sfx.py", "--output", str(output), flag, cwd=root)
                    self.assertEqual(result.returncode == 0, flag == "--help", result.stderr)
                    self.assertFalse(output.exists(), f"synthesize-sfx.py {flag} created output")

    def test_synth_output_is_valid_deterministic_and_portable(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            first = root / "first"
            second = root / "second"
            for output in (first, second):
                result = self.run_tool(
                    "synthesize-sfx.py", "--output", str(output), "--seed", "4173", cwd=root
                )
                self.assertEqual(result.returncode, 0, result.stderr)

            first_files = {path.name: path.read_bytes() for path in first.iterdir()}
            second_files = {path.name: path.read_bytes() for path in second.iterdir()}
            self.assertEqual(first_files, second_files, "same seed produced different output bytes")

            manifest: dict[str, Any] = json.loads(first_files["manifest.json"])
            self.assertEqual(set(manifest["files"]), set(SOUND_FILES))
            for filename in SOUND_FILES:
                with self.subTest(wav=filename):
                    path = first / filename
                    with wave.open(str(path), "rb") as wav_file:
                        self.assertEqual(wav_file.getnchannels(), 1)
                        self.assertEqual(wav_file.getsampwidth(), 2)
                        self.assertEqual(wav_file.getframerate(), 48_000)
                        self.assertGreater(wav_file.getnframes(), 1_000)
                        raw = wav_file.readframes(wav_file.getnframes())
                    samples = [value[0] for value in struct.iter_unpack("<h", raw)]
                    peak = max(abs(value) for value in samples)
                    self.assertGreater(peak, 2_000, "audio is effectively silent")
                    self.assertLess(peak, 0.75 * 32_767, "audio lacks the documented headroom")
                    self.assertEqual(samples[0], 0)
                    self.assertEqual(samples[-1], 0)
                    self.assertLess(max(abs(value) for value in samples[:16]), 700)
                    self.assertLess(max(abs(value) for value in samples[-16:]), 700)
                    self.assertEqual(manifest["files"][filename]["sha256"], hashlib.sha256(path.read_bytes()).hexdigest())

            page = first_files["index.html"].decode()
            readme = first_files["README.md"].decode()
            for filename in SOUND_FILES:
                self.assertIn(filename, page if filename == "comparison.wav" else page + readme)
            self.assertIn("copper-lark-sound-lab.zip", page)

            with zipfile.ZipFile(first / "copper-lark-sound-lab.zip") as archive:
                names = set(archive.namelist())
                self.assertEqual(names, set(manifest["archive_contents"]))
                for name in names - {"recipe/synthesize-sfx.py"}:
                    self.assertEqual(archive.read(name), first_files[name], f"archive copy differs: {name}")
                self.assertEqual(archive.read("recipe/synthesize-sfx.py"), (TOOLS / "synthesize-sfx.py").read_bytes())


if __name__ == "__main__":
    unittest.main()
