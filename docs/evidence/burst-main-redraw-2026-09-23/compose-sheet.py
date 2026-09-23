"""Compose the burst-main review sheet from rasters made by render-svgs.gd.

Usage: uv run python compose-sheet.py RENDER_DIR OUT.png

RENDER_DIR must hold before_h, after_h, before_v and after_v at @1x and @4x. Each picture is
fitted to the extent `EventInstance._draw_wide_scene` gives it (192 along the obstruction, the
native thickness across) and pasted on a stand-in street: two tiles of pavement, two of
carriageway, two of pavement, sampled from a game still. The game-scale cells are the 1x
raster at the camera's zoom of 2; the 4x cells are the 4x raster on the same street at 4x.
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

PAVEMENT = (164, 142, 116)
GROUT = (136, 118, 96)
ASPHALT = (74, 69, 70)
KERB = (107, 97, 87)
LINE = (201, 166, 74)
INK = (30, 26, 28)
PAPER = (236, 232, 222)
TILE = 32
STREET = 6 * TILE
MARGIN = 28


def street(vertical: bool, scale: int) -> Image.Image:
    """A stand-in street crossed by the seal. `vertical` is the east-west street."""
    across = STREET
    along = 50 + 2 * MARGIN if not vertical else 50 + 2 * MARGIN
    w, h = (along, across) if vertical else (across, along)
    im = Image.new("RGB", (w * scale, h * scale), PAVEMENT)
    d = ImageDraw.Draw(im)
    step = TILE // 2 * scale
    for i in range(0, max(w, h) * scale, step):
        d.line([(i, 0), (i, h * scale)], fill=GROUT, width=max(1, scale // 2))
        d.line([(0, i), (w * scale, i)], fill=GROUT, width=max(1, scale // 2))
    lo, hi = 2 * TILE * scale, 4 * TILE * scale
    if vertical:
        d.rectangle([0, lo, w * scale, hi], fill=ASPHALT)
        d.line([(0, lo), (w * scale, lo)], fill=KERB, width=scale)
        d.line([(0, hi), (w * scale, hi)], fill=KERB, width=scale)
        mid = (lo + hi) // 2
        for x in range(0, w * scale, 16 * scale):
            d.line([(x, mid), (x + 8 * scale, mid)], fill=LINE, width=scale)
    else:
        d.rectangle([lo, 0, hi, h * scale], fill=ASPHALT)
        d.line([(lo, 0), (lo, h * scale)], fill=KERB, width=scale)
        d.line([(hi, 0), (hi, h * scale)], fill=KERB, width=scale)
        mid = (lo + hi) // 2
        for y in range(0, h * scale, 16 * scale):
            d.line([(mid, y), (mid, y + 8 * scale)], fill=LINE, width=scale)
    return im


def scene(render_dir: Path, label: str, scale: int) -> Image.Image:
    vertical = label.endswith("_v")
    picture = Image.open(render_dir / f"{label}@{scale}x.png").convert("RGBA")
    ground = street(vertical, scale)
    if vertical:
        fitted = picture.resize((50 * scale, STREET * scale), Image.Resampling.BILINEAR)
        at = (MARGIN * scale, 0)
    else:
        fitted = picture.resize((STREET * scale, 50 * scale), Image.Resampling.BILINEAR)
        at = (0, MARGIN * scale)
    ground.paste(fitted, at, fitted)
    if scale == 1:
        ground = ground.resize((ground.width * 2, ground.height * 2), Image.Resampling.BILINEAR)
    return ground


def main() -> int:
    if len(sys.argv) == 2 and sys.argv[1] in ("--help", "-h"):
        print(__doc__)
        return 0
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    render_dir, out = Path(sys.argv[1]), Path(sys.argv[2])
    font = ImageFont.load_default(size=18)
    small = ImageFont.load_default(size=14)
    game = {k: scene(render_dir, k, 1) for k in ("before_h", "after_h", "before_v", "after_v")}
    big = {k: scene(render_dir, k, 4) for k in ("before_h", "after_h", "before_v", "after_v")}
    pad = 24
    width = pad + big["after_h"].width + pad + big["after_v"].width * 2 + pad * 2
    game_row = max(im.height for im in game.values())
    height = pad * 3 + 30 + game_row + 30 + pad + big["after_h"].height * 2 + 60 + pad
    height = max(height, pad * 3 + 30 + game_row + 30 + pad + big["after_v"].height + 30 + pad)
    sheet = Image.new("RGB", (width, height), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((pad, pad), "Burst water main: after (proposal) against before", fill=INK, font=font)
    y = pad + 34
    d.text((pad, y), "Game scale: the 1x raster fitted to the 192px obstruction, at the camera's 2x zoom",
           fill=INK, font=small)
    y += 22
    x = pad
    for key, name in (("after_h", "after, north-south street"), ("before_h", "before"),
                      ("after_v", "after, east-west street"), ("before_v", "before")):
        sheet.paste(game[key], (x, y))
        d.text((x, y + game[key].height + 4), name, fill=INK, font=small)
        x += game[key].width + pad
    y += game_row + 30 + pad
    d.text((pad, y), "4x vector render, same fit and street", fill=INK, font=small)
    y += 22
    x = pad
    for key, name in (("after_h", "after, north-south street"), ("before_h", "before")):
        sheet.paste(big[key], (x, y))
        d.text((x, y + big[key].height + 4), name, fill=INK, font=small)
        y += big[key].height + 30
    x = pad + big["after_h"].width + pad
    y = pad + 34 + 22 + game_row + 30 + pad + 22
    for key, name in (("after_v", "after, east-west"), ("before_v", "before")):
        sheet.paste(big[key], (x, y))
        d.text((x, y + big[key].height + 4), name, fill=INK, font=small)
        x += big[key].width + pad
    sheet.save(out)
    print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
