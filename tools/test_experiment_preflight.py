#!/usr/bin/env python3
"""Regression coverage for measurement and audit preflight boundaries."""

from __future__ import annotations

import hashlib
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PREDICTION_RUNNER = ROOT / "docs/evidence/m159-danger-prediction-reuse-2026-09-29/measure-native.py"
SHAPE_RUNNER = ROOT / "docs/evidence/m159-event-shape-cache-2026-09-29/measure-native.py"
AUDIT = ROOT / "tests/probes/m159_prediction_audit.py"
RUNNERS = (PREDICTION_RUNNER, SHAPE_RUNNER)
COLLECTORS = (
    "entity_frame_profile.gd",
    "entity_frame_profile.tscn",
    "entity_frame_profile_observer.gd",
)
SOURCES = ("src/events/event_instance.gd", "src/crowd/crowd_agent.gd")


class ExperimentPreflightTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.launch_log = self.root / "launches.log"
        self.godot = self.root / "fake-godot"
        self.godot.write_text(
            "#!/bin/sh\n"
            'printf "godot\\n" >> "$LAUNCH_LOG"\n'
            'printf "{}\\n" > "${ENTITY_PROFILE_OUTPUT}-scene.json"\n'
            'printf "{}\\n" > "${ENTITY_PROFILE_OUTPUT}-profiler.json"\n'
        )
        self.godot.chmod(0o755)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _git(self, checkout: Path, *args: str) -> None:
        subprocess.run(["git", *args], cwd=checkout, check=True, capture_output=True, text=True)

    def _checkout(self, name: str, source_suffix: str = "") -> Path:
        checkout = self.root / name
        for relative in (
            "tools/check.sh",
            *(f"tests/probes/{collector}" for collector in COLLECTORS),
            "tests/probes/entity_frame_profile_analyze.py",
            *SOURCES,
        ):
            (checkout / relative).parent.mkdir(parents=True, exist_ok=True)
            (checkout / relative).write_text(relative + "\n")
        (checkout / "tools/check.sh").write_text('#!/bin/sh\nprintf "check\\n" >> "$LAUNCH_LOG"\n')
        (checkout / "tools/check.sh").chmod(0o755)
        (checkout / "tests/probes/entity_frame_profile_analyze.py").write_text(
            "def analyze(prefix, profiler_disabled=False):\n"
            "    return {'accepted': True, 'rejections': [], 'native_ms': None, "
            "'callback_interval_ms': {}}\n"
        )
        for relative in SOURCES:
            (checkout / relative).write_text(relative + source_suffix + "\n")
        self._git(checkout, "init", "-q")
        self._git(checkout, "config", "user.name", "Experiment Test")
        self._git(checkout, "config", "user.email", "experiment@example.invalid")
        self._git(checkout, "add", ".")
        self._git(checkout, "commit", "-qm", "fixture")
        return checkout

    def _run(self, script: Path, *args: str, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(script), *args],
            cwd=cwd or self.root,
            env={**os.environ, "LAUNCH_LOG": str(self.launch_log)},
            capture_output=True,
            text=True,
            timeout=30,
        )

    def _runner_args(self, baseline: Path | str, after: Path | str, output: Path | str) -> tuple[str, ...]:
        return (
            "--baseline",
            str(baseline),
            "--after",
            str(after),
            "--output",
            str(output),
            "--godot",
            str(self.godot),
            "--mode",
            "disabled",
        )

    def assert_nothing_launched(self) -> None:
        self.assertFalse(self.launch_log.exists())

    def test_invalid_checkout_fails_before_output_or_launch_for_both_runners(self) -> None:
        after = self._checkout("after")
        for runner in RUNNERS:
            with self.subTest(runner=runner.name):
                output = self.root / f"{runner.parent.name}-invalid-output"
                result = self._run(runner, *self._runner_args(self.root / "missing", after, output))
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertIn("checkout is not a directory", result.stderr)
                self.assertFalse(output.exists())
                self.assert_nothing_launched()

    def test_existing_output_fails_without_touching_it_or_launching(self) -> None:
        baseline = self._checkout("before")
        after = self._checkout("after")
        for runner in RUNNERS:
            with self.subTest(runner=runner.name):
                output = self.root / f"{runner.parent.name}-existing"
                output.mkdir()
                sentinel = output / "sentinel"
                sentinel.write_text("untouched\n")
                result = self._run(runner, *self._runner_args(baseline, after, output))
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertIn("output path already exists", result.stderr)
                self.assertEqual(sentinel.read_text(), "untouched\n")
                self.assert_nothing_launched()

    def test_prediction_runner_rejects_dirty_tracked_source_before_output(self) -> None:
        baseline = self._checkout("before")
        after = self._checkout("after")
        (baseline / SOURCES[0]).write_text("dirty\n")
        output = self.root / "dirty-output"
        result = self._run(PREDICTION_RUNNER, *self._runner_args(baseline, after, output))
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("dirty tracked files", result.stderr)
        self.assertFalse(output.exists())
        self.assert_nothing_launched()

    def test_audit_refuses_dirty_or_its_own_repository(self) -> None:
        checkout = self._checkout("audit")
        (checkout / SOURCES[0]).write_text("dirty\n")
        dirty = self._run(AUDIT, str(checkout))
        self.assertEqual(dirty.returncode, 2, dirty.stderr)
        self.assertIn("dirty tracked files", dirty.stderr)

        own = self._run(AUDIT, str(ROOT))
        self.assertEqual(own.returncode, 2, own.stderr)
        self.assertIn("repository that contains this audit script", own.stderr)

    def test_clean_source_hashes_reach_provenance_with_relative_paths(self) -> None:
        baseline = self._checkout("before", "-before")
        after = self._checkout("after", "-after")
        result = self._run(
            PREDICTION_RUNNER,
            *self._runner_args("before", "after", "output"),
            cwd=self.root,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        provenance = __import__("json").loads((self.root / "output/provenance.json").read_text())
        for side, checkout in (("before", baseline), ("after", after)):
            for relative in SOURCES:
                expected = hashlib.sha256((checkout / relative).read_bytes()).hexdigest()
                self.assertEqual(provenance["source_sha256"][side][relative], expected)
        self.assertEqual(self.launch_log.read_text().splitlines().count("check"), 2)
        self.assertEqual(self.launch_log.read_text().splitlines().count("godot"), 6)


if __name__ == "__main__":
    unittest.main()
