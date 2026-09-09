#!/usr/bin/env python3
"""Focused integration tests for the gameplay burst converter."""

from __future__ import annotations

import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from PIL import Image

SPEC = importlib.util.spec_from_file_location("clip", Path(__file__).with_name("clip.py"))
assert SPEC and SPEC.loader
clip = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(clip)


class ClipTests(unittest.TestCase):
    def burst(self, root: Path, *, status: str = "complete", frames: int = 3) -> Path:
        folder = root / "run with spaces and 'quote'" / "asked" / "burst-special"
        folder.mkdir(parents=True)
        stamps = [0.0, 0.11, 0.31][:frames]
        for index, colour in enumerate(((255, 0, 0), (0, 255, 0), (0, 0, 255))[:frames], 1):
            Image.new("RGB", (17, 11), colour).save(folder / f"frame-{index:04d}.png")
        (folder / "burst.json").write_text(json.dumps({
            "schema_version": 1,
            "frames": [{"file": f"frame-{i:04d}.png", "elapsed_seconds": t}
                       for i, t in enumerate(stamps, 1)],
            "duration_seconds": 0.6,
            "target_fps": 12,
            "status": status,
            "context": "test",
        }), encoding="utf-8")
        return folder

    def test_real_ffmpeg_timing_output_and_source_preservation(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            folder = self.burst(Path(temp))
            source_bytes = {path: path.read_bytes() for path in folder.glob("frame-*.png")}
            metadata_bytes = (folder / "burst.json").read_bytes()
            output = clip.convert(folder)
            self.assertEqual(output, (folder.parent / "burst-special.mp4").resolve())
            self.assertTrue(output.is_file())
            self.assertEqual(metadata_bytes, (folder / "burst.json").read_bytes())
            self.assertEqual(source_bytes, {path: path.read_bytes() for path in folder.glob("frame-*.png")})
            probe = __import__("subprocess").run(
                ["ffprobe", "-v", "error", "-show_entries", "format=duration:stream=pix_fmt,width,height",
                 "-of", "default=noprint_wrappers=1", str(output)],
                check=True, capture_output=True, text=True)
            self.assertIn("pix_fmt=yuv420p", probe.stdout)
            self.assertIn("width=18", probe.stdout)
            self.assertIn("height=12", probe.stdout)
            duration = float(next(line.split("=", 1)[1] for line in probe.stdout.splitlines() if line.startswith("duration=")))
            self.assertGreater(duration, 0.45)
            self.assertLess(duration, 0.8)
            decoded_dir = Path(temp) / "decoded"
            decoded_dir.mkdir()
            subprocess.run(
                ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", str(output), "-fps_mode", "passthrough",
                 "-vsync", "0", str(decoded_dir / "frame-%02d.png")], check=True,
                capture_output=True,
            )
            decoded_frames = sorted(decoded_dir.glob("frame-*.png"))
            self.assertGreaterEqual(len(decoded_frames), 3)
            expected_colours = ((255, 0, 0), (0, 255, 0), (0, 0, 255))
            for decoded_frame, expected in zip(decoded_frames[:3], expected_colours):
                pixel = Image.open(decoded_frame).convert("RGB").getpixel((5, 5))
                self.assertEqual(max(range(3), key=pixel.__getitem__), max(range(3), key=expected.__getitem__))

    def test_refuses_overwrite_and_bad_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            folder = self.burst(Path(temp))
            output = folder.parent / "burst-special.mp4"
            output.write_bytes(b"keep")
            with self.assertRaises(clip.ClipError):
                clip.convert(folder)
            (folder / "burst.json").write_text(json.dumps({
                "schema_version": 1, "frames": [{"file": "frame-0001.png", "elapsed_seconds": 0.2},
                {"file": "frame-0002.png", "elapsed_seconds": 0.1}], "duration_seconds": 1,
                "target_fps": 12, "status": "complete"}), encoding="utf-8")
            output.unlink()
            with self.assertRaises(clip.ClipError):
                clip.convert(folder)

    def test_cancelled_burst_requires_explicit_and_missing_frame_is_actionable(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            folder = self.burst(Path(temp), status="cancelled")
            with self.assertRaises(clip.ClipError):
                clip.read_metadata(folder, allow_partial=False)
            (folder / "frame-0002.png").unlink()
            with self.assertRaisesRegex(clip.ClipError, "missing"):
                clip.convert(folder, explicit=True)

    def test_missing_ffmpeg_is_actionable(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            folder = self.burst(Path(temp))
            with mock.patch.object(clip.shutil, "which", return_value=None):
                with self.assertRaisesRegex(clip.ClipError, "ffmpeg"):
                    clip.convert(folder)


if __name__ == "__main__":
    unittest.main()
