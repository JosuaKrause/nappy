"""Scratch: compose the vent review sheet from the renders written by
`../m100-vent-pipe-2026-09-24/render-svgs.gd`.

usage: compose-sheet.py RENDER_DIR OUT.png

Three states side by side on the basement floor tile: the vent between blows (the grate alone),
and the vent blowing in each of its two frames (the grate, then the cloud over it, drawn in the
order the game draws them). The grate is a ground decal centred on the vent's point; the cloud
is a standing picture whose bottom centre is that same point. One row at 4x for the joins, one
at 2x, which is play size under the game's 2x camera, and one at play size under the basement's
own lighting (`Palette.ESCAPE_BASEMENT_GLOOM`, multiplied in the way the scene's `modulate` is).
"""

import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

OUT = Path(sys.argv[1])
PAPER = (236, 233, 226, 255)
INK = (40, 34, 38, 255)
PAD = 16
GLOOM = (round(0.33 * 255), round(0.34 * 255), round(0.44 * 255), 255)

try:
    FONT = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 18)
    SMALL = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 14)
except OSError:
    FONT = SMALL = ImageFont.load_default()


def picture(name: str, scale: int) -> Image.Image:
    return Image.open(OUT / f"{name}@{scale}.png").convert("RGBA")


def floor(scale: int, tiles_across: int, tiles_down: int) -> Image.Image:
    tile = picture("basement_floor", scale)
    base = Image.new("RGBA", (tile.width * tiles_across, tile.height * tiles_down))
    for x in range(tiles_across):
        for y in range(tiles_down):
            base.alpha_composite(tile, (x * tile.width, y * tile.height))
    return base


def state(layers: list[str], scale: int, gloom: bool) -> Image.Image:
    """The grate centred on the middle tile of a 3x3-tile floor, which is where a vent stands,
    and each cloud frame standing on that same point."""
    base = floor(scale, 3, 3)
    tile = 32 * scale
    at = (base.width // 2, tile + tile // 2)
    for name in layers:
        art = picture(name, scale)
        if name == "steam_grate":
            base.alpha_composite(art, (at[0] - art.width // 2, at[1] - art.height // 2))
        else:
            base.alpha_composite(art, (at[0] - art.width // 2, at[1] - art.height))
    if gloom:
        base = ImageChops.multiply(base, Image.new("RGBA", base.size, GLOOM))
    return base


STATES = [
    ("between blows", ["steam_grate"]),
    ("blowing, frame a", ["steam_grate", "steam"]),
    ("blowing, frame b", ["steam_grate", "steam_b"]),
]


def row(title: str, scale: int, gloom: bool = False) -> Image.Image:
    cells = [(label, state(layers, scale, gloom)) for label, layers in STATES]
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


rows = [
    row("the basement vent at 4x", 4),
    row("at play size (2x, the game's camera)", 2),
    row("at play size under the basement's lighting", 2, gloom=True),
]
sheet = Image.new("RGBA", (max(r.width for r in rows), sum(r.height for r in rows)), PAPER)
at = 0
for r in rows:
    sheet.alpha_composite(r, (0, at))
    at += r.height
sheet.convert("RGB").save(sys.argv[2])
print(sys.argv[2], sheet.size)
