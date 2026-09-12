"""Build the labeled A-D carrying-version comparison from registered native PNGs."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
BACKGROUND = "#68767c"
DIVIDER = "#526066"
TEXT = "#ffffff"
SUBTEXT = "#dbe1e3"
SCALE = 6
SHEET_SIZE = (1400, 760)
COLUMN_WIDTH = SHEET_SIZE[0] // 4

VERSIONS = (
    (
        "A — Upright bundle",
        ROOT / "docs/evidence/comic-rig-2026-09-12/registered/rig",
    ),
    ("B — Round silhouette", HERE / "b/registered/rig"),
    ("C — Alternating stride", HERE / "c/registered/rig"),
    ("D — Matched proportions", HERE.parent / "registered/rig"),
)

POSES = (
    ("Front A", "mother_carrying_front_a.png", 0, 0),
    ("Front B", "mother_carrying_front_b.png", 1, 0),
    ("Right profile A", "mother_carrying_side_a.png", 0, 1),
    ("Right profile B", "mother_carrying_side_b.png", 1, 1),
)


def _centered(draw: ImageDraw.ImageDraw, text: str, center_x: int, y: int, font: ImageFont.ImageFont) -> None:
    bounds = draw.textbbox((0, 0), text, font=font)
    draw.text((center_x - (bounds[2] - bounds[0]) // 2, y), text, fill=TEXT, font=font)


def build(destination: Path) -> None:
    assert not destination.exists(), f"refusing to overwrite existing output: {destination}"
    destination.parent.mkdir(parents=True, exist_ok=True)
    font_root = Path("/System/Library/Fonts/Supplemental")
    title_font = ImageFont.truetype(font_root / "Arial Bold.ttf", size=22)
    coverage_font = ImageFont.truetype(font_root / "Arial.ttf", size=18)
    pose_font = ImageFont.truetype(font_root / "Arial.ttf", size=17)
    sheet = Image.new("RGB", SHEET_SIZE, BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    for column in range(1, 4):
        x = column * COLUMN_WIDTH
        draw.rectangle((x - 1, 0, x + 1, SHEET_SIZE[1]), fill=DIVIDER)

    coverage = "Front and right profile · both gait frames · 6×"
    _centered(draw, coverage, SHEET_SIZE[0] // 2, 48, coverage_font)

    cell_width = COLUMN_WIDTH // 2
    row_tops = (104, 426)
    ground_lines = (404, 726)
    for version_index, (version_label, folder) in enumerate(VERSIONS):
        center_x = version_index * COLUMN_WIDTH + COLUMN_WIDTH // 2
        _centered(draw, version_label, center_x, 14, title_font)
        for pose_label, filename, pose_column, pose_row in POSES:
            source = folder / filename
            assert source.is_file(), source
            with Image.open(source) as opened:
                sprite = opened.convert("RGBA")
            expected_width = 24 if "front" in filename else 26
            assert sprite.size == (expected_width, 46), (source, sprite.size)
            enlarged = sprite.resize(
                (sprite.width * SCALE, sprite.height * SCALE),
                Image.Resampling.NEAREST,
            )
            cell_x = version_index * COLUMN_WIDTH + pose_column * cell_width
            sprite_x = cell_x + (cell_width - enlarged.width) // 2
            sprite_y = ground_lines[pose_row] - enlarged.height
            sheet.paste(enlarged, (sprite_x, sprite_y), enlarged)
            label_bounds = draw.textbbox((0, 0), pose_label, font=pose_font)
            label_x = cell_x + (cell_width - (label_bounds[2] - label_bounds[0])) // 2
            draw.text((label_x, row_tops[pose_row]), pose_label, fill=SUBTEXT, font=pose_font)
            draw.line(
                (cell_x + 12, ground_lines[pose_row], cell_x + cell_width - 12, ground_lines[pose_row]),
                fill=DIVIDER,
                width=1,
            )
    sheet.save(destination, format="PNG", optimize=False)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    build(args.destination.resolve())


if __name__ == "__main__":
    main()
