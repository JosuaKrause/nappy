#!/usr/bin/env python3
"""Tests for tools/art-rulers.py: the ruler step, where ticks fall, and that the picture is kept."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import ModuleType

from PIL import Image

TOOLS = Path(__file__).resolve().parent
SCRIPT = TOOLS / "art-rulers.py"


def load() -> ModuleType:
    spec = importlib.util.spec_from_file_location("art_rulers", SCRIPT)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules["art_rulers"] = module
    spec.loader.exec_module(module)
    return module


rulers = load()
INK = (20, 20, 20, 255)


class RulerTests(unittest.TestCase):
    def test_step_grows_as_scale_shrinks(self) -> None:
        self.assertEqual(rulers.tick_step(10), 5)
        self.assertEqual(rulers.tick_step(3), 20)
        self.assertEqual(rulers.tick_step(1), 50)
        self.assertEqual(rulers.tick_step(0.1), 500)

    def test_labelled_ticks_are_at_least_a_gap_apart(self) -> None:
        for scale in (0.25, 0.7, 1, 1.5, 2, 3, 4, 8, 16):
            self.assertGreaterEqual(rulers.tick_step(scale) * scale, rulers.MIN_LABEL_GAP)

    def test_minor_step_is_none_when_dense(self) -> None:
        self.assertIsNone(rulers.minor_step(1, 3))
        self.assertEqual(rulers.minor_step(20, 3), 4)

    def test_picture_sits_untouched_inside_the_margin(self) -> None:
        picture = Image.new("RGBA", (60, 40), (10, 200, 30, 255))
        picture.putpixel((5, 7), (255, 0, 0, 255))
        sheet = rulers.with_rulers(picture, 3.0, (138, 138, 138), grid=False)
        self.assertEqual(sheet.size, (60 + rulers.MARGIN_LEFT, 40 + rulers.MARGIN_TOP))
        self.assertEqual(sheet.getpixel((rulers.MARGIN_LEFT + 5, rulers.MARGIN_TOP + 7)), (255, 0, 0, 255))
        self.assertEqual(sheet.getpixel((rulers.MARGIN_LEFT + 6, rulers.MARGIN_TOP + 7)), (10, 200, 30, 255))

    def test_transparency_shows_the_background(self) -> None:
        sheet = rulers.with_rulers(Image.new("RGBA", (20, 20)), 1.0, (1, 2, 3), grid=False)
        self.assertEqual(sheet.getpixel((rulers.MARGIN_LEFT + 4, rulers.MARGIN_TOP + 4)), (1, 2, 3, 255))

    def test_a_tick_stands_at_each_labelled_step(self) -> None:
        sheet = rulers.with_rulers(Image.new("RGBA", (100, 100)), 3.0, (0, 0, 0), grid=False)
        # Step 20 at scale 3: labelled ticks at pixel 0 and 60 along the top margin, 10 high.
        for unit_pixels in (0, 60):
            self.assertEqual(sheet.getpixel((rulers.MARGIN_LEFT + unit_pixels, rulers.MARGIN_TOP - 2)), INK)
        self.assertNotEqual(sheet.getpixel((rulers.MARGIN_LEFT + 30, rulers.MARGIN_TOP - 2)), INK)

    def test_grid_lines_cross_the_picture_only_when_asked(self) -> None:
        picture = Image.new("RGBA", (100, 100), (255, 255, 255, 255))
        plain = rulers.with_rulers(picture, 3.0, (0, 0, 0), grid=False)
        gridded = rulers.with_rulers(picture, 3.0, (0, 0, 0), grid=True)
        at = (rulers.MARGIN_LEFT + 60, rulers.MARGIN_TOP + 50)
        self.assertEqual(plain.getpixel(at), (255, 255, 255, 255))
        self.assertNotEqual(gridded.getpixel(at), (255, 255, 255, 255))


class CommandTests(unittest.TestCase):
    def run_tool(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True, check=False)

    def test_writes_a_new_file(self) -> None:
        with tempfile.TemporaryDirectory() as scratch:
            source = Path(scratch) / "a@3x.png"
            Image.new("RGBA", (30, 30), (9, 9, 9, 255)).save(source)
            destination = Path(scratch) / "out" / "a@3x-rulers.png"
            result = self.run_tool("--scale", "3", str(source), str(destination))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(destination.is_file())

    def test_refuses_to_overwrite_its_source(self) -> None:
        with tempfile.TemporaryDirectory() as scratch:
            source = Path(scratch) / "a.png"
            Image.new("RGBA", (30, 30), (9, 9, 9, 255)).save(source)
            before = source.read_bytes()
            result = self.run_tool("--scale", "3", str(source), str(source))
            self.assertEqual(result.returncode, 2)
            self.assertEqual(source.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
