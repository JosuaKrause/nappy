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
import math
import os
import struct
import subprocess
import sys
import tempfile
import unittest
import wave
from pathlib import Path
from typing import Any

TOOLS = Path(__file__).resolve().parent
PROJECT_ROOT = TOOLS.parent

# Every tools/*.py a person or a script runs directly. Not the test_*.py files themselves --
# unittest.main() already gives every one of them -h and rejects an unknown flag, which is the
# standard library's job rather than this repository's.
ENTRY_POINTS = (
    "agent-identity.py",
    "clip.py",
    "reference.py",
    "remove-checkerboard.py",
    "codex-hooks.py",
    "goatcounter.py",
    "synthesize-sfx.py",
    "split-scenes.py",
    "migrate-queue.py",
    "convert-queue-edits.py",
    "release-notes.py",
)

SOUND_FILES = (
    "footsteps-pass-3-grounded.wav",
    "footsteps-subtle-grounded.wav",
    "stroller-wheels-pass-3-grounded.wav",
    "stroller-wheels-quieter-grounded.wav",
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

    def test_agent_identity_help_and_unknown_flag_do_no_work(self) -> None:
        # run's own "role -- command" without the "--" is rejected the same way as an unknown
        # flag: usage on stderr, before config_root() or the origin remote is ever touched.
        with tempfile.TemporaryDirectory() as temporary:
            agents_dir = Path(temporary) / "nappy-agents"
            env = {**os.environ, "NAPPY_AGENTS_DIR": str(agents_dir)}
            cases: tuple[tuple[bool, tuple[str, ...]], ...] = (
                (True, ("--help",)),
                (True, ("-h",)),
                (False, ("--this-flag-does-not-exist",)),
                (True, ("run", "--help")),
                (False, ("run", "claude-coder")),
            )
            for expect_zero, args in cases:
                with self.subTest(args=args):
                    result = subprocess.run(
                        [sys.executable, str(TOOLS / "agent-identity.py"), *args],
                        stdin=subprocess.DEVNULL,
                        capture_output=True,
                        text=True,
                        timeout=15,
                        env=env,
                    )
                    self.assertEqual(result.returncode == 0, expect_zero, args)
                    self.assertFalse(agents_dir.exists(), f"{args} touched the agent config directory")

    def test_split_scenes_help_and_unknown_flag_do_not_launch_godot(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            marker = root / "godot-was-launched"
            fake_godot = root / "fake-godot"
            fake_godot.write_text(f"#!/bin/sh\ntouch '{marker}'\nexit 91\n")
            fake_godot.chmod(0o755)
            for flag in ("--help", "-h", "--this-flag-does-not-exist"):
                with self.subTest(flag=flag):
                    result = self.run_tool("split-scenes.py", "--godot", str(fake_godot), flag, cwd=root)
                    self.assertEqual(result.returncode == 0, flag in ("--help", "-h"), result.stderr)
                    self.assertFalse(marker.exists(), f"split-scenes.py {flag} launched Godot")

    def test_split_scenes_crop_helper_help_and_unknown_flag_do_no_work(self) -> None:
        godot = Path(os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot"))
        if not godot.is_file():
            self.skipTest("Godot is unavailable for the direct helper CLI boundary")
        helper = TOOLS / "split-scenes-crop.gd"
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for flag in ("--help", "-h", "--this-flag-does-not-exist"):
                with self.subTest(flag=flag):
                    result = subprocess.run(
                        [str(godot), "--headless", "--script", str(helper), "--", flag],
                        stdin=subprocess.DEVNULL,
                        capture_output=True,
                        text=True,
                        timeout=15,
                        cwd=root,
                    )
                    self.assertEqual(result.returncode == 0, flag in ("--help", "-h"), result.stderr)
                    self.assertIn("usage", (result.stdout + result.stderr).lower())
                    self.assertEqual(list(root.iterdir()), [], f"crop helper {flag} wrote output")

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
            # Both builds run the one tracked generator (no frozen per-pass copy is written any
            # more): this checks the generator's own determinism and portability, not a copy's.
            result = self.run_tool("synthesize-sfx.py", "--output", str(first), "--seed", "260926", cwd=root)
            self.assertEqual(result.returncode, 0, result.stderr)
            result = self.run_tool("synthesize-sfx.py", "--output", str(second), "--seed", "260926", cwd=root)
            self.assertEqual(result.returncode, 0, result.stderr)

            first_files = {
                path.relative_to(first).as_posix(): path.read_bytes() for path in first.rglob("*") if path.is_file()
            }
            second_files = {
                path.relative_to(second).as_posix(): path.read_bytes() for path in second.rglob("*") if path.is_file()
            }
            self.assertEqual(first_files, second_files, "same seed produced different output bytes")
            self.assertNotIn(
                "recipe/synthesize-sfx.py", first_files, "the generator no longer writes a frozen copy of itself"
            )

            manifest: dict[str, Any] = json.loads(first_files["manifest.json"])
            self.assertEqual(set(manifest["files"]), set(SOUND_FILES))
            self.assertEqual(manifest["selection"], "subtle-revision")
            self.assertEqual(manifest["generator"], "tools/synthesize-sfx.py")
            self.assertEqual(
                manifest["generator_sha256"], hashlib.sha256((TOOLS / "synthesize-sfx.py").read_bytes()).hexdigest()
            )
            audition_rms_db: dict[str, float] = {}
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
                    rms = math.sqrt(sum(value * value for value in samples) / len(samples))
                    self.assertGreater(peak, 2_000, "audio is effectively silent")
                    self.assertLess(peak, 0.75 * 32_767, "audio lacks the documented headroom")
                    self.assertEqual(samples[0], 0)
                    self.assertEqual(samples[-1], 0)
                    self.assertLess(max(abs(value) for value in samples[:16]), 700)
                    self.assertLess(max(abs(value) for value in samples[-16:]), 700)
                    if filename != "comparison.wav":
                        audition_rms_db[filename] = 20.0 * math.log10(rms / 32_767)
                    self.assertEqual(
                        manifest["files"][filename]["sha256"], hashlib.sha256(path.read_bytes()).hexdigest()
                    )
            self.assertLess(
                audition_rms_db["footsteps-subtle-grounded.wav"],
                audition_rms_db["footsteps-pass-3-grounded.wav"] - 6.0,
                "new footsteps are not substantially quieter than pass 3",
            )
            self.assertLess(
                audition_rms_db["stroller-wheels-quieter-grounded.wav"],
                audition_rms_db["footsteps-subtle-grounded.wav"] - 4.0,
                "new wheels do not sit clearly below the new footsteps",
            )

            page = first_files["index.html"].decode()
            readme = first_files["README.md"].decode()
            for filename in SOUND_FILES:
                self.assertIn(filename, page if filename == "comparison.wav" else page + readme)
            self.assertNotIn(".zip", page, "the listening page no longer offers a zip to download")
            self.assertFalse(list(first.glob("*.zip")), "the generator no longer writes a zip alongside the WAVs")
            self.assertIn("other.pause()", page)
            self.assertIn("other.currentTime = 0", page)

    def test_sound_lab_no_serve_matches_recipe_hashes(self) -> None:
        """The generator's own reproducibility is `test_synth_output_is_valid_deterministic_and_portable`
        above; this is tools/sound-lab.sh's own contract -- that its --no-serve build of the one
        current pass tools/sound-lab/passes.json records (built from the tracked
        tools/synthesize-sfx.py directly, with no pinned commit) matches every hash the recipe
        records for it. No archived evidence is read here: the recipe carries its own expected
        hashes, which is the point of replacing a committed listening kit with a reproducible
        command.

        Builds into a scratch SOUND_LAB_BUILD_ROOT rather than the real build/sound-lab/: the real
        one may be what a running `tools/sound-lab.sh` is serving to a listener, and this test's
        own `rm -rf` (inside the script) must not delete it out from under them."""
        recipe = json.loads((TOOLS / "sound-lab" / "passes.json").read_text())
        pass_name = recipe["pass"]
        recorded_hashes: dict[str, str] = recipe["hashes"]

        with tempfile.TemporaryDirectory() as temporary:
            build_root = Path(temporary) / "sound-lab"
            result = subprocess.run(
                [str(TOOLS / "sound-lab.sh"), "--no-serve"],
                stdin=subprocess.DEVNULL,
                capture_output=True,
                text=True,
                timeout=60,
                cwd=PROJECT_ROOT,
                env={**os.environ, "SOUND_LAB_BUILD_ROOT": str(build_root)},
            )
            self.assertEqual(result.returncode, 0, result.stderr)

            output_dir = build_root / pass_name
            for filename, expected_sha256 in recorded_hashes.items():
                with self.subTest(wav=filename):
                    actual_sha256 = hashlib.sha256((output_dir / filename).read_bytes()).hexdigest()
                    self.assertEqual(actual_sha256, expected_sha256, f"{filename} did not rebuild byte-for-byte")

    def test_sound_lab_rejects_an_unsafe_pass_name_before_deleting_anything(self) -> None:
        """tools/sound-lab.sh derives the directory it `rm -rf`s from passes.json's `pass` field,
        which is committed and hand-edited -- the skill tells whoever freezes a new pass to
        overwrite it. A value that is not a plain name (empty, a dot-led name, or one carrying a
        path separator) must be rejected by the schema check before that `rm -rf` ever runs.
        SOUND_LAB_RECIPE_FILE and SOUND_LAB_BUILD_ROOT point the script at scratch copies, and a
        sentinel directory next to (not inside) the scratch build root stands in for whatever a
        path-traversing pass name would actually delete; it must survive every case."""
        unsafe_names = ("", ".", "..", ".hidden", "../sentinel", "a/b", "/tmp/whatever")
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            recipe_file = root / "passes.json"
            build_root = root / "build" / "sound-lab"
            build_root.mkdir(parents=True)
            sentinel = root / "sentinel"
            sentinel.mkdir()
            (sentinel / "marker").write_text("do not delete")

            for unsafe_name in unsafe_names:
                with self.subTest(pass_name=unsafe_name):
                    recipe_file.write_text(
                        json.dumps(
                            {
                                "pass": unsafe_name,
                                "label": "unsafe name probe",
                                "seed": 1,
                                "args": [],
                                "hashes": {"comparison.wav": "0" * 64},
                            }
                        )
                    )
                    result = subprocess.run(
                        [str(TOOLS / "sound-lab.sh"), "--no-serve"],
                        stdin=subprocess.DEVNULL,
                        capture_output=True,
                        text=True,
                        timeout=30,
                        cwd=PROJECT_ROOT,
                        env={
                            **os.environ,
                            "SOUND_LAB_RECIPE_FILE": str(recipe_file),
                            "SOUND_LAB_BUILD_ROOT": str(build_root),
                        },
                    )
                    self.assertNotEqual(result.returncode, 0, f"pass={unsafe_name!r} was accepted: {result.stdout}")
                    self.assertTrue(
                        sentinel.is_dir() and (sentinel / "marker").is_file(),
                        f"pass={unsafe_name!r} deleted something outside the scratch build root",
                    )

    def test_sound_lab_rejects_a_wav_the_recipe_does_not_record(self) -> None:
        """The hash loop only checks the files passes.json names; a WAV the generator writes
        without a matching entry (for example a new clip added to a recipe set without updating
        the recipe) must still fail the build rather than being served unverified. Points the
        script at a scratch recipe missing one of the real generator's five subtle-revision WAVs
        from its `hashes`, so that WAV is on disk but unrecorded."""
        real_recipe = json.loads((TOOLS / "sound-lab" / "passes.json").read_text())
        incomplete_hashes = dict(real_recipe["hashes"])
        del incomplete_hashes["comparison.wav"]
        self.assertTrue(incomplete_hashes, "the real recipe must still have other hashes to check")

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            recipe_file = root / "passes.json"
            recipe_file.write_text(
                json.dumps(
                    {
                        "pass": real_recipe["pass"],
                        "label": real_recipe["label"],
                        "seed": real_recipe["seed"],
                        "args": real_recipe["args"],
                        "hashes": incomplete_hashes,
                    }
                )
            )
            build_root = root / "build"
            result = subprocess.run(
                [str(TOOLS / "sound-lab.sh"), "--no-serve"],
                stdin=subprocess.DEVNULL,
                capture_output=True,
                text=True,
                timeout=60,
                cwd=PROJECT_ROOT,
                env={
                    **os.environ,
                    "SOUND_LAB_RECIPE_FILE": str(recipe_file),
                    "SOUND_LAB_BUILD_ROOT": str(build_root),
                },
            )
            self.assertNotEqual(result.returncode, 0, "an unrecorded comparison.wav was accepted")
            self.assertIn("comparison.wav", result.stderr)


if __name__ == "__main__":
    unittest.main()
