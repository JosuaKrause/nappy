#!/usr/bin/env python3
"""The disk-space preflight, against a stub `df`: no test fills, or needs, a real drive.

`tools/lib_disk_headroom.sh` is exercised directly through `bash -c` in its three bands (refuse
below the estimate, warn and run below estimate plus reserve, silent above). Then every tool that
sources it is run with a stub `df` reporting less than its estimate and a stub Godot, and must
refuse before it launches anything or writes its output; one tool is run in the warning band and
must warn and carry on.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

import test_cli_help

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "tools/lib_disk_headroom.sh"


class HeadroomFixture(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="headroom-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.df_args = self.root / "df-args"
        self.launches = self.root / "launches"
        self.write_executable(
            "df",
            '#!/bin/sh\nprintf "%s\\n" "$@" > "$DF_ARGS"\n'
            '[ "$DF_FAIL" = 1 ] && exit 1\n'
            'echo "Filesystem 1024-blocks Used Available Capacity Mounted on"\n'
            'echo "/dev/fixture 100000000 1 $DF_AVAILABLE_KIB 1% /"\n',
        )
        self.godot = self.write_executable("godot", '#!/bin/sh\necho "godot $*" >> "$LAUNCHES"\nexit 0\n')
        self.write_executable("ffmpeg", '#!/bin/sh\necho "ffmpeg $*" >> "$LAUNCHES"\nexit 0\n')
        self.env = {key: value for key, value in os.environ.items() if not key.startswith("NAPPY_HEADROOM_")}
        self.env.update(
            PATH=f"{self.bin}:{self.env['PATH']}",
            DF_ARGS=str(self.df_args),
            LAUNCHES=str(self.launches),
            GODOT=str(self.godot),
            DF_AVAILABLE_KIB=str(1024 * 1024 * 1024),
        )

    def write_executable(self, name: str, content: str) -> Path:
        path = self.bin / name
        path.write_text(content)
        path.chmod(0o755)
        return path

    def available_mib(self, mib: int) -> None:
        self.env["DF_AVAILABLE_KIB"] = str(mib * 1024)

    def preflight(self, *args: str, **env: str) -> subprocess.CompletedProcess[str]:
        script = f'source "{LIB}"; headroom_preflight "$@"'
        return subprocess.run(
            ["bash", "-c", script, "preflight", *args],
            env={**self.env, **env},
            capture_output=True,
            text=True,
            check=False,
        )


class PreflightTests(HeadroomFixture):
    def test_enough_space_passes_silently(self) -> None:
        self.available_mib(3072 + 4)
        result = self.preflight("tool", str(self.root), "", "shot")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")

    def test_below_the_estimate_refuses_naming_the_numbers_the_hint_and_the_cleanup(self) -> None:
        self.available_mib(3)
        result = self.preflight("tool", str(self.root), "photograph fewer", "shot")
        self.assertEqual(result.returncode, 1)
        for expected in (
            "tool: refusing to start",
            "3 MiB available",
            "needed: estimated peak 4 MiB (shot 4 MiB)",
            "short by: 1 MiB",
            "smaller batch: photograph fewer",
            "tools/prune-merged.sh --all",
        ):
            self.assertIn(expected, result.stderr)

    def test_inside_the_reserve_warns_and_runs(self) -> None:
        for available in (4, 3072 + 3):
            with self.subTest(available=available):
                self.available_mib(available)
                result = self.preflight("tool", str(self.root), "photograph fewer", "shot")
                self.assertEqual(result.returncode, 0, result.stderr)
                for expected in (
                    "tool: WARNING: low disk space",
                    f"{available} MiB available",
                    "estimated peak 4 MiB (shot 4 MiB); with the reserve 3076 MiB",
                    f"below the reserve by: {3076 - available} MiB",
                    "start no new task or agent",
                    "tools/prune-merged.sh --all",
                ):
                    self.assertIn(expected, result.stderr)
                self.assertNotIn("refusing", result.stderr)

    def test_counts_multiply_and_jobs_add(self) -> None:
        self.available_mib(0)
        result = self.preflight("tool", str(self.root), "", "scene-capture:10", "import")
        self.assertIn("estimated peak 36 MiB (scene-capture 2 MiB x 10 + import 16 MiB)", result.stderr)

    def test_an_unmeasured_job_is_refused_rather_than_guessed(self) -> None:
        result = self.preflight("tool", str(self.root), "", "never-measured")
        self.assertEqual(result.returncode, 1)
        self.assertIn("no measured peak for 'never-measured'", result.stderr)
        self.assertIn("NAPPY_HEADROOM_PEAK_MIB_NEVER_MEASURED", result.stderr)
        self.assertFalse(self.df_args.exists(), "an unknown estimate must refuse before asking df")

    def test_an_override_supplies_or_replaces_an_estimate(self) -> None:
        self.available_mib(3072 + 10)
        result = self.preflight(
            "tool", str(self.root), "", "never-measured", NAPPY_HEADROOM_PEAK_MIB_NEVER_MEASURED="10"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.preflight("tool", str(self.root), "", "shot", NAPPY_HEADROOM_PEAK_MIB_SHOT="11")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("WARNING", result.stderr)
        self.assertIn("shot 11 MiB", result.stderr)

    def test_a_malformed_value_is_refused_never_read_as_zero(self) -> None:
        for variable in ("NAPPY_HEADROOM_PEAK_MIB_SHOT", "NAPPY_HEADROOM_RESERVE_MIB"):
            for value in ("-1", "1.5", "lots"):
                result = self.preflight("tool", str(self.root), "", "shot", **{variable: value})
                self.assertEqual(result.returncode, 1, f"{variable}={value}")
                self.assertIn(variable, result.stderr)

    def test_the_reserve_is_configurable(self) -> None:
        self.available_mib(5)
        result = self.preflight("tool", str(self.root), "", "shot", NAPPY_HEADROOM_RESERVE_MIB="1")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_the_check_can_be_switched_off_but_not_misspelt(self) -> None:
        self.available_mib(0)
        result = self.preflight("tool", str(self.root), "", "shot", NAPPY_HEADROOM_CHECK="off")
        self.assertEqual(result.returncode, 0)
        self.assertIn("skipped", result.stderr)
        result = self.preflight("tool", str(self.root), "", "shot", NAPPY_HEADROOM_CHECK="of")
        self.assertEqual(result.returncode, 1)

    def test_unreadable_free_space_is_refused(self) -> None:
        result = self.preflight("tool", str(self.root), "", "shot", DF_FAIL="1")
        self.assertEqual(result.returncode, 1)
        self.assertIn("could not read the free space", result.stderr)
        self.env["DF_AVAILABLE_KIB"] = "unknown"
        result = self.preflight("tool", str(self.root), "", "shot")
        self.assertEqual(result.returncode, 1)
        self.assertIn("could not read the free space", result.stderr)

    def test_a_destination_not_created_yet_is_measured_on_its_nearest_ancestor(self) -> None:
        destination = self.root / "not" / "yet" / "made"
        result = self.preflight("tool", str(destination), "", "shot")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.df_args.read_text().split(), ["-Pk", str(self.root)])
        self.assertFalse((self.root / "not").exists())

    def test_every_measured_job_has_a_whole_number_estimate(self) -> None:
        jobs = [
            "worktree-full",
            "worktree-sparse",
            "import",
            "atlas-bake",
            "web-export",
            "web-template-build",
            "scene-recipe",
            "scene-capture",
            "shot",
            "record-second",
        ]
        for job in jobs:
            result = subprocess.run(
                ["bash", "-c", f'source "{LIB}"; headroom_measured_peak_mib "$1"', "peak", job],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, job)
            self.assertRegex(result.stdout.strip(), r"^[1-9][0-9]*$", job)


class ToolRefusalTests(HeadroomFixture):
    """Each wired tool refuses on a full volume before it launches or writes anything."""

    def setUp(self) -> None:
        super().setUp()
        self.available_mib(1)

    def run_tool(self, *command: str, cwd: Path = ROOT) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            list(command), cwd=cwd, env=self.env, capture_output=True, text=True, check=False, timeout=120
        )

    def assert_refused(self, result: subprocess.CompletedProcess[str], tool: str) -> None:
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(f"{tool}: refusing to start", result.stderr)
        if self.launches.exists():
            self.fail(f"{tool} launched {self.launches.read_text()!r}")

    def test_a_tool_in_the_warning_band_warns_and_carries_on(self) -> None:
        self.available_mib(10)
        result = self.run_tool("tools/bake-atlases.sh", "--force")
        self.assertIn("tools/bake-atlases.sh: WARNING: low disk space", result.stderr)
        self.assertNotIn("refusing", result.stderr)
        self.assertTrue(self.launches.exists(), "the bake should have started after the warning")

    def test_bake_atlases(self) -> None:
        self.assert_refused(self.run_tool("tools/bake-atlases.sh", "--force"), "tools/bake-atlases.sh")

    def test_scene_recipes_names_the_smaller_batch(self) -> None:
        output = self.root / "recipes"
        result = self.run_tool("tools/scene-recipes.sh", "--screenshots", "--output", str(output))
        self.assert_refused(result, "tools/scene-recipes.sh")
        self.assertIn("run fewer recipes", result.stderr)
        self.assertFalse(output.exists())

    def test_shot(self) -> None:
        still = self.root / "still.png"
        self.assert_refused(self.run_tool("tools/shot.sh", str(still), "1"), "tools/shot.sh")
        self.assertFalse(still.exists())

    def test_record_counts_every_second_the_rig_may_run(self) -> None:
        if shutil.which("jq") is None:
            self.skipTest("record.sh needs jq on PATH before its preflight")
        tmp = self.root / "record-tmp"
        tmp.mkdir()
        self.env["TMPDIR"] = str(tmp)
        atlases_current = self.run_tool("tools/bake-atlases.sh", "--check").returncode == 0
        result = self.run_tool("tools/record.sh", "--after", "2", "--seed", "1")
        self.assert_refused(result, "tools/record.sh")
        if atlases_current:
            # --after 2 records at most 2 game seconds plus the rig's 15-second margin; the outside
            # kill's grace is wall time after the game has quit, and is not charged.
            self.assertIn("record-second 31 MiB x 17", result.stderr)
            self.assertIn("record a shorter run", result.stderr)
        else:
            # Stale pages mean an import repair first, which is refused before check.sh runs.
            self.assertIn("import 16 MiB", result.stderr)
        self.assertEqual(list(tmp.iterdir()), [])

    def trailer_fixture(self) -> tuple[Path, Path, dict[str, str]]:
        """The trailer copied into a scratch repository with a stub engine, as test_cli_help does."""
        repo = Path(tempfile.mkdtemp(prefix="trailer-repo-", dir=self.root))
        script, fixture_env = test_cli_help.CliHelpTests.recipe_trailer_fixture(self, repo)  # type: ignore[arg-type]
        tmp = Path(tempfile.mkdtemp(prefix="trailer-tmp-", dir=self.root))
        stub = {key: fixture_env[key] for key in ("GODOT", "RECIPE_CALLS", "RECIPE_RESULT")}
        env = {**self.env, **stub, "TMPDIR": str(tmp)}
        return script, tmp, env

    def run_trailer(self, script: Path, env: dict[str, str], *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(script), *arguments],
            cwd=script.parent.parent,
            env=env,
            capture_output=True,
            text=True,
            check=False,
            timeout=120,
        )

    def test_trailer_counts_the_summed_render_seconds_of_the_shots_asked_for(self) -> None:
        if shutil.which("jq") is None:
            self.skipTest("trailer.sh needs jq on PATH before its preflight")
        # Seven gameplay recipes each run 10 seconds; editorial cards need no engine frames.
        for arguments, seconds in ((("--shot", "choice"), 10), ((), 70)):
            with self.subTest(arguments=arguments):
                script, tmp, env = self.trailer_fixture()
                result = self.run_trailer(script, env, *arguments)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("tools/trailer.sh: refusing to start", result.stderr)
                self.assertIn(f"record-second 31 MiB x {seconds}", result.stderr)
                self.assertIn("render fewer shots", result.stderr)
                self.assertNotIn("--write-movie", (script.parent.parent / "calls").read_text())
                self.assertEqual(list(tmp.iterdir()), [])

    def test_trailer_in_the_warning_band_warns_and_renders(self) -> None:
        if shutil.which("jq") is None:
            self.skipTest("trailer.sh needs jq on PATH before its preflight")
        script, _, env = self.trailer_fixture()
        env["DF_AVAILABLE_KIB"] = str((31 * 10 + 10) * 1024)
        result = self.run_trailer(script, env, "--shot", "choice")
        # The stub engine cannot finish a render, so only the warning and the launch matter here.
        self.assertIn("tools/trailer.sh: WARNING: low disk space", result.stderr)
        self.assertNotIn("refusing", result.stderr)
        self.assertIn("--write-movie", (script.parent.parent / "calls").read_text())

    def test_trailer_validation_and_listing_ask_for_no_space(self) -> None:
        if shutil.which("jq") is None:
            self.skipTest("trailer.sh needs jq on PATH before its preflight")
        script, _, env = self.trailer_fixture()
        env["DF_AVAILABLE_KIB"] = "1024"
        for flag in ("--list", "--validate"):
            with self.subTest(flag=flag):
                self.df_args.unlink(missing_ok=True)
                result = self.run_trailer(script, env, flag)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertFalse(self.df_args.exists())

    def test_run_refuses_its_import_repair(self) -> None:
        if (ROOT / ".godot/global_script_class_cache.cfg").exists():
            self.skipTest("this checkout's class cache is built, so run.sh has no repair to refuse")
        self.assert_refused(self.run_tool("tools/run.sh", "--no-save"), "tools/run.sh")

    def test_export_web(self) -> None:
        before = (ROOT / "project.godot").read_text()
        result = self.run_tool("tools/export-web.sh", "debug")
        self.assert_refused(result, "tools/export-web.sh")
        self.assertEqual((ROOT / "project.godot").read_text(), before)

    def test_build_web_template_on_a_cache_miss(self) -> None:
        repo = self.root / "template-repo"
        (repo / "tools/web-template").mkdir(parents=True)
        for relative in (
            "tools/build-web-template.sh",
            "tools/lib_disk_headroom.sh",
            "tools/web-template/pins.env",
            "tools/web-template/profile.args",
        ):
            shutil.copy2(ROOT / relative, repo / relative)
        result = self.run_tool("tools/build-web-template.sh", cwd=repo)
        self.assert_refused(result, "tools/build-web-template.sh")
        self.assertFalse((repo / "build").exists())

    def test_help_and_rejection_never_ask_for_space(self) -> None:
        tools = (
            "tools/bake-atlases.sh",
            "tools/scene-recipes.sh",
            "tools/shot.sh",
            "tools/record.sh",
            "tools/trailer.sh",
            "tools/run.sh",
            "tools/export-web.sh",
            "tools/build-web-template.sh",
        )
        for tool in tools:
            for flag, expect_zero in (("--help", True), ("-h", True), ("--bogus", False)):
                with self.subTest(tool=tool, flag=flag):
                    self.df_args.unlink(missing_ok=True)
                    self.launches.unlink(missing_ok=True)
                    result = self.run_tool(tool, flag)
                    self.assertEqual(result.returncode == 0, expect_zero, result.stdout + result.stderr)
                    self.assertFalse(self.df_args.exists())
                    self.assertFalse(self.launches.exists())


if __name__ == "__main__":
    unittest.main()
