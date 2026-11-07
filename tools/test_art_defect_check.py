#!/usr/bin/env python3
"""Tests for tools/art-defect-check.py on small fixture images drawn in memory."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import ModuleType
from typing import Any

from PIL import Image

TOOLS = Path(__file__).resolve().parent
SCRIPT = TOOLS / "art-defect-check.py"


def load() -> ModuleType:
    spec = importlib.util.spec_from_file_location("art_defect_check", SCRIPT)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules["art_defect_check"] = module
    spec.loader.exec_module(module)
    return module


check = load()
GREEN = (60, 140, 60, 255)
BROWN = (120, 80, 40, 255)
CLEAR = (0, 0, 0, 0)


def sprite(size: int = 16, fill: tuple[int, int, int, int] = GREEN) -> Image.Image:
    """A filled square with a transparent margin of two pixels."""
    image = Image.new("RGBA", (size, size), CLEAR)
    for y in range(2, size - 2):
        for x in range(2, size - 2):
            image.putpixel((x, y), fill)
    return image


def options(**changes: Any) -> Any:
    values: dict[str, Any] = {
        "palette": frozenset(),
        "tolerance": 12,
        "near": 6,
        "min_pixels": 8,
        "speck_delta": 24,
        "tile": False,
    }
    values.update(changes)
    return check.Options(**values)


def kinds(image: Image.Image, **changes: Any) -> dict[str, list[Any]]:
    found: dict[str, list[Any]] = {}
    for defect in check.check(check.Picture(image), options(**changes)):
        found.setdefault(defect.kind, []).append(defect)
    return found


class DefectTests(unittest.TestCase):
    def test_clean_sprite_has_no_defects(self) -> None:
        self.assertEqual(kinds(sprite()), {})

    def test_stray_pixel_is_named_at_its_coordinates(self) -> None:
        image = sprite()
        image.putpixel((0, 0), BROWN)
        found = kinds(image)["stray-pixel"]
        self.assertEqual([(d.x, d.y) for d in found], [(0, 0)])

    def test_touching_pixel_is_not_stray(self) -> None:
        image = sprite()
        image.putpixel((1, 1), BROWN)  # diagonal neighbour of the square
        self.assertNotIn("stray-pixel", kinds(image))

    def test_speck_inside_a_flat_fill(self) -> None:
        image = sprite()
        image.putpixel((8, 8), BROWN)
        found = kinds(image)["speck"]
        self.assertEqual([(d.x, d.y) for d in found], [(8, 8)])

    def test_pinhole(self) -> None:
        image = sprite()
        image.putpixel((7, 9), CLEAR)
        found = kinds(image)["pinhole"]
        self.assertEqual([(d.x, d.y) for d in found], [(7, 9)])

    def test_off_palette_colour_reports_its_box(self) -> None:
        image = sprite()
        for y in range(4, 10):
            for x in range(4, 10):
                image.putpixel((x, y), BROWN)
        palette = frozenset({(60, 140, 60)})
        found = kinds(image, palette=palette)["off-palette"]
        self.assertEqual([(d.x, d.y, d.w, d.h) for d in found], [(5, 5, 4, 4)])

    def test_colour_within_tolerance_is_on_palette(self) -> None:
        palette = frozenset({(64, 140, 60)})
        self.assertNotIn("off-palette", kinds(sprite(), palette=palette))

    def test_no_palette_means_no_palette_check(self) -> None:
        image = sprite()
        self.assertNotIn("off-palette", kinds(image))

    def test_antialiased_edge_is_not_off_palette(self) -> None:
        image = sprite(24)
        for y in range(2, 22):
            image.putpixel((2, y), (90, 110, 50, 255))  # a one-pixel blended edge column
        palette = frozenset({(60, 140, 60)})
        self.assertNotIn("off-palette", kinds(image, palette=palette))

    def test_near_duplicate_boxes_the_rarer_colour(self) -> None:
        image = sprite()
        for y in range(4, 10):
            for x in range(4, 10):
                image.putpixel((x, y), (62, 140, 60, 255))
        found = kinds(image)["near-duplicate"]
        self.assertEqual([(d.x, d.y, d.w, d.h) for d in found], [(5, 5, 4, 4)])
        self.assertIn("#3e8c3c", found[0].detail)

    def test_distinct_colours_are_not_near_duplicates(self) -> None:
        image = sprite()
        for y in range(4, 10):
            for x in range(4, 10):
                image.putpixel((x, y), BROWN)
        self.assertNotIn("near-duplicate", kinds(image))

    def test_edge_clip_names_the_edge(self) -> None:
        image = sprite()
        for x in range(4, 10):
            image.putpixel((x, 0), GREEN)
        found = kinds(image)["edge-clip"]
        self.assertEqual([(d.x, d.y, d.w, d.h) for d in found], [(4, 0, 6, 1)])
        self.assertIn("top edge", found[0].detail)

    def test_tile_reports_gaps_not_edge_clips(self) -> None:
        image = Image.new("RGBA", (8, 8), GREEN)
        image.putpixel((3, 3), CLEAR)
        image.putpixel((4, 3), CLEAR)
        found = kinds(image, tile=True)
        self.assertNotIn("edge-clip", found)
        self.assertEqual([(d.x, d.y, d.w) for d in found["gap"]], [(3, 3, 2)])

    def test_baked_checkerboard_is_one_defect(self) -> None:
        image = Image.new("RGBA", (12, 12), CLEAR)
        for y in range(2, 10):
            for x in range(2, 10):
                shade = 200 if (x + y) % 2 == 0 else 255
                image.putpixel((x, y), (shade, shade, shade, 255))
        found = kinds(image)["checkerboard"]
        self.assertEqual([(d.x, d.y, d.w, d.h) for d in found], [(2, 2, 8, 8)])

    def test_family_palette_is_the_flat_colours_of_its_pictures(self) -> None:
        palette = check.palette_of([check.Picture(sprite()), check.Picture(sprite(fill=BROWN))], 8)
        self.assertEqual(palette, frozenset({(60, 140, 60), (120, 80, 40)}))

    def test_asset_units_are_printed_with_a_scale(self) -> None:
        defect = check.Defect("speck", 6, 9, 1, 1, "x")
        self.assertIn("(asset units 2,3)", check.describe(defect, 3.0))


class CommandTests(unittest.TestCase):
    def run_tool(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True, check=False)

    def test_exit_status_and_overlay(self) -> None:
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch)
            image = sprite()
            image.putpixel((0, 0), BROWN)
            dirty = root / "dirty.png"
            image.save(dirty)
            clean = root / "clean.png"
            sprite().save(clean)
            result = self.run_tool("--overlay-dir", str(root / "out"), str(dirty))
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertIn("stray-pixel at 0,0", result.stdout)
            self.assertTrue((root / "out" / "dirty-defects.png").is_file())
            result = self.run_tool("--overlay-dir", str(root / "out"), str(clean))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse((root / "out" / "clean-defects.png").exists())

    def test_svg_is_refused_before_any_work(self) -> None:
        with tempfile.TemporaryDirectory() as scratch:
            source = Path(scratch) / "a.svg"
            source.write_text("<svg/>")
            result = self.run_tool("--overlay-dir", str(Path(scratch) / "out"), str(source))
            self.assertEqual(result.returncode, 2)
            self.assertIn("svg-preview.sh", result.stderr)
            self.assertFalse((Path(scratch) / "out").exists())


if __name__ == "__main__":
    unittest.main()
