#!/usr/bin/env python3
"""A dry run of tools/assemble-site.py: the deploy's layout of the Pages site, on stand-in exports.

Each export is a directory shaped as `tools/export-web.sh` leaves `build/web/` (an `index.html`
naming its files under a directory named for its tag), built in $TMPDIR, so the layout, the two
forwarding pages and the refusals are checked without Godot or a deploy.
"""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import ModuleType

TOOLS = Path(__file__).resolve().parent


def load(name: str, file: str) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, TOOLS / file)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


site = load("assemble_site", "assemble-site.py")


class AssembleSiteTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.card = self.root / "social-card.png"
        self.card.write_bytes(b"png")

    def export(self, tag: str) -> Path:
        directory = self.root / tag
        (directory / tag).mkdir(parents=True)
        (directory / tag / "index.pck").write_text(tag)
        (directory / "index.html").write_text(
            f'<!DOCTYPE html><html><head><meta charset="utf-8"></head>'
            f'<body><script src="{tag}/index.js"></script></body></html>'
        )
        return directory

    def run_tool(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run([sys.executable, str(TOOLS / "assemble-site.py"), *args], capture_output=True, text=True)

    def test_the_release_is_at_the_root_and_the_candidate_under_rc(self) -> None:
        out = self.root / "site"
        result = self.run_tool(
            "--release", str(self.export("v0.30.0")),
            "--candidate", str(self.export("v0.31.0-rc.1")),
            "--social-card", str(self.card),
            "--out", str(out),
        )  # fmt: skip
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((out / "v0.30.0" / "index.pck").read_text(), "v0.30.0")
        self.assertEqual((out / "rc" / "v0.31.0-rc.1" / "index.pck").read_text(), "v0.31.0-rc.1")
        self.assertIn('src="v0.31.0-rc.1/index.js"', (out / "rc" / "index.html").read_text())
        self.assertEqual((out / "social-card.png").read_bytes(), b"png")

    def test_the_root_page_forwards_rc_1_before_anything_else_in_its_head(self) -> None:
        out = self.root / "site"
        site.assemble(self.export("v0.30.0"), self.export("v0.31.0-rc.1"), self.card, out)
        root_page = (out / "index.html").read_text()
        self.assertIn("<head><script>if (new URLSearchParams(location.search).get('rc') === '1')", root_page)
        self.assertIn("location.replace('rc/' + location.search + location.hash)", root_page)
        self.assertNotIn("URLSearchParams", (out / "rc" / "index.html").read_text(), "only the root forwards")

    def test_with_no_candidate_rc_forwards_to_the_root_without_the_rc_parameter(self) -> None:
        out = self.root / "site"
        site.assemble(self.export("v0.30.0"), None, self.card, out)
        page = (out / "rc" / "index.html").read_text()
        self.assertIn("query.delete('rc')", page, "keeping rc=1 would send the page straight back here")
        self.assertIn("location.replace('../'", page)
        self.assertIn("get('rc') === '1'", (out / "index.html").read_text(), "the root still forwards")

    def test_refuses_an_export_without_a_page_a_used_out_dir_and_a_missing_card(self) -> None:
        release = self.export("v0.30.0")
        with self.assertRaises(site.AssembleError):
            site.assemble(self.root / "nothing", None, self.card, self.root / "a")
        used = self.root / "used"
        used.mkdir()
        (used / "old.txt").write_text("x")
        with self.assertRaises(site.AssembleError):
            site.assemble(release, None, self.card, used)
        with self.assertRaises(site.AssembleError):
            site.assemble(release, None, self.root / "no-card.png", self.root / "b")

    def test_refuses_a_page_whose_head_cannot_be_found_once(self) -> None:
        release = self.export("v0.30.0")
        (release / "index.html").write_text("<html><body>no head</body></html>")
        with self.assertRaises(site.AssembleError):
            site.assemble(release, None, self.card, self.root / "site")

    def test_a_release_deploy_whose_candidate_failed_publishes_the_release_alone_and_says_so(self) -> None:
        """The deploy hands in the candidate's directory whether or not it built; a failed build has
        none to download, so the release is laid out with rc/ forwarding to the root."""
        out = self.root / "site"
        result = self.run_tool(
            "--release", str(self.export("v0.30.1")),
            "--candidate", str(self.root / "never-downloaded"),
            "--candidate-build", "failure",
            "--pushed", "release",
            "--social-card", str(self.card),
            "--out", str(out),
        )  # fmt: skip
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((out / "v0.30.1" / "index.pck").read_text(), "v0.30.1")
        self.assertIn("query.delete('rc')", (out / "rc" / "index.html").read_text(), "rc/ forwards to the root")
        self.assertIn("with no candidate", result.stdout, "the notice the deploy's summary carries")

    def test_a_candidate_deploy_whose_candidate_failed_publishes_nothing(self) -> None:
        out = self.root / "site"
        for build in ("failure", "cancelled", "skipped"):
            result = self.run_tool(
                "--release", str(self.export(f"v0.30.1-{build}")),
                "--candidate", str(self.root / "never-downloaded"),
                "--candidate-build", build,
                "--pushed", "candidate",
                "--social-card", str(self.card),
                "--out", str(out),
            )  # fmt: skip
            self.assertEqual(result.returncode, 1, build)
            self.assertIn("publishes nothing new", result.stderr, build)
            self.assertFalse(out.exists(), f"{build}: nothing is laid out to upload")

    def test_a_candidate_that_built_is_laid_out_whatever_was_pushed(self) -> None:
        for pushed in ("release", "candidate"):
            candidate = self.root / pushed
            self.assertEqual(site.candidate_to_lay_out(candidate, "success", pushed), (candidate, None))
            self.assertEqual(site.candidate_to_lay_out(None, "skipped", pushed), (None, None), "none was planned")

    def test_a_refusal_exits_non_zero_with_its_reason(self) -> None:
        result = self.run_tool(
            "--release", str(self.root / "nothing"), "--social-card", str(self.card), "--out", str(self.root / "s")
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("refusing: the release export", result.stderr)


if __name__ == "__main__":
    unittest.main()
