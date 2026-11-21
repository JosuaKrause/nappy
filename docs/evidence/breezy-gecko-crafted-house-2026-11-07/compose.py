"""Composes the question sheet for breezy-gecko, her house is crafted: each draft of her home
block's front beside the escape's interiors it is matched to, labelled with the letter the
question uses.

Reads PNGs that render.gd wrote at scale 1 (the drafts and the interior tiles), scales them by a
whole number with nearest-neighbour so every pixel stays a square, and writes one PNG.

    python compose.py --renders RENDER_DIR --out SHEET.png
"""

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SCALE = 2
BACKGROUND = (34, 31, 38)
INK = (236, 228, 214)
SUBTLE = (170, 160, 148)
MARGIN = 24
GAP = 32

OPTIONS = [
    ("A", "home_front_a_plaster", "Plaster: the hallways' plaster wall, outside as inside."),
    ("B", "home_front_b_brick", "Brick: the basement's brick, trimmed in the hallways' plaster."),
    ("C", "home_front_c_brick_under_plaster", "Brick under plaster: basement brick on the ground floor, plaster above."),
]


def load(renders: Path, name: str) -> Image.Image:
    path = renders / f"{name}-1x.png"
    if not path.is_file():
        sys.exit(f"missing render: {path}")
    return Image.open(path).convert("RGBA")


def interior_panel(renders: Path) -> Image.Image:
    """The escape's own pieces at 1x: a hallway wall with its windows and lamps, the lobby's double
    entrance door standing on it, the hallway floor under it, and a run of basement brick."""
    wall = load(renders, "hallway_wall")
    window = load(renders, "hallway_wall_window")
    lamp = load(renders, "wall_lamp")
    floor = load(renders, "hallway_floor")
    brick = load(renders, "basement_wall_brick")
    door = load(renders, "entrance_door")
    cells = [window, wall, lamp, wall, lamp, wall, window]
    width = 32 * len(cells)
    panel = Image.new("RGBA", (width, 12 + 32 + 32 + 8 + 32), BACKGROUND + (255,))
    top = 12
    for index, cell in enumerate(cells):
        panel.alpha_composite(cell, (32 * index, top))
        panel.alpha_composite(floor, (32 * index, top + 32))
        panel.alpha_composite(brick, (32 * index, top + 32 + 32 + 8))
    # The door's ground anchor is its bottom centre, on the wall's foot in the middle column.
    panel.alpha_composite(door, (width // 2 - door.width // 2, top + 32 - door.height + 2))
    return panel


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--renders", type=Path, required=True, help="render.gd's output directory")
    parser.add_argument("--out", type=Path, required=True, help="the sheet PNG to write (must not exist)")
    args = parser.parse_args()
    if args.out.exists():
        sys.exit(f"refusing to overwrite {args.out}")

    big = ImageFont.load_default(size=28)
    text = ImageFont.load_default(size=16)
    small = ImageFont.load_default(size=13)
    panel = interior_panel(args.renders)
    panel = panel.resize((panel.width * SCALE, panel.height * SCALE), Image.Resampling.NEAREST)
    fronts = [(letter, load(args.renders, name), words) for letter, name, words in OPTIONS]
    front_w = max(front.width for _, front, _ in fronts) * SCALE
    front_h = max(front.height for _, front, _ in fronts) * SCALE
    label_w = 44
    row_h = 28 + max(front_h, panel.height + 18)
    width = MARGIN + label_w + front_w + GAP + panel.width + MARGIN
    height = MARGIN + (row_h + GAP) * len(fronts) - GAP + MARGIN
    sheet = Image.new("RGBA", (width, height), BACKGROUND + (255,))
    draw = ImageDraw.Draw(sheet)
    y = MARGIN
    for letter, front, words in fronts:
        draw.text((MARGIN, y + 26), letter, font=big, fill=INK)
        draw.text((MARGIN + label_w, y), words, font=text, fill=INK)
        scaled = front.resize((front.width * SCALE, front.height * SCALE), Image.Resampling.NEAREST)
        sheet.alpha_composite(scaled, (MARGIN + label_w, y + 28))
        px = MARGIN + label_w + front_w + GAP
        draw.text((px, y + 28), "the escape: hallway, lobby door, basement brick", font=small, fill=SUBTLE)
        sheet.alpha_composite(panel, (px, y + 28 + 18))
        y += row_h + GAP
    sheet.convert("RGB").save(args.out)
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
