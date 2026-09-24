"""Scratch: compose the two-frame review sheet from /tmp/tfe/out renders.

Each row is one picture: frame a and frame b at 4x, then both at native size, on asphalt grey
(the street the seals stand on) or basement concrete (the steam's corridor).
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path("/tmp/tfe/out")
ASPHALT = (78, 78, 84, 255)
CONCRETE = (104, 100, 96, 255)
PAPER = (236, 233, 226, 255)
INK = (40, 34, 38, 255)
PAD = 16

try:
    FONT = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 18)
    SMALL = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 14)
except OSError:
    FONT = SMALL = ImageFont.load_default()


def tile(name: str, scale: int, ground: tuple[int, int, int, int]) -> Image.Image:
    art = Image.open(OUT / f"{name}@{scale}.png").convert("RGBA")
    base = Image.new("RGBA", (art.width + 8, art.height + 8), ground)
    base.alpha_composite(art, (4, 4))
    return base


def row(title: str, name: str, ground: tuple[int, int, int, int]) -> Image.Image:
    cells = [
        ("a  (4x)", tile(name, 4, ground)),
        ("b  (4x)", tile(f"{name}_b", 4, ground)),
        ("a  (1x)", tile(name, 1, ground)),
        ("b  (1x)", tile(f"{name}_b", 1, ground)),
    ]
    width = PAD + sum(c.width + PAD for _, c in cells)
    height = 34 + max(c.height for _, c in cells) + 22 + PAD
    out = Image.new("RGBA", (width, height), PAPER)
    draw = ImageDraw.Draw(out)
    draw.text((PAD, 8), title, fill=INK, font=FONT)
    x = PAD
    for label, cell in cells:
        out.alpha_composite(cell, (x, 34))
        draw.text((x, 34 + cell.height + 4), label, fill=INK, font=SMALL)
        x += cell.width + PAD
    return out


def stack(rows: list[Image.Image], across: bool = False) -> Image.Image:
    if across:
        width = sum(r.width for r in rows)
        height = max(r.height for r in rows)
    else:
        width = max(r.width for r in rows)
        height = sum(r.height for r in rows)
    out = Image.new("RGBA", (width, height), PAPER)
    at = 0
    for r in rows:
        out.alpha_composite(r, (at, 0) if across else (0, at))
        at += r.width if across else r.height
    return out


wide = stack([
    row("burst_water_main  (north-south street)", "burst_water_main", ASPHALT),
    row("car_accident  (north-south street)", "car_accident", ASPHALT),
])
tall = stack([
    row("burst_water_main_vertical  (east-west street)", "burst_water_main_vertical", ASPHALT),
    row("car_accident_vertical  (east-west street)", "car_accident_vertical", ASPHALT),
    row("steam  (basement vent)", "steam", CONCRETE),
], across=True)
sheet = stack([wide, tall])
sheet.convert("RGB").save(sys.argv[1])
print(sys.argv[1], sheet.size)
