"""The roadblock's end-on segment beside its broadside one, and its guards at their posts.

Usage: uv run --with pillow python docs/evidence/m196-roadblock-end-on-2026-09-25/compose-sheet.py OUT.png

Run from the repository root, after `./tools/check.sh` has imported the project. It renders the
roadblock's pictures and the guard's standing views through the engine's own SVG parser (the burst
main's committed `docs/evidence/burst-main-redraw-2026-09-23/render-svgs.gd`, at scales 1 and 4;
set GODOT to the Godot binary if it is not /Applications/Godot.app/Contents/MacOS/Godot) and writes
OUT.png with:

  * each picture at game scale -- its 1x raster shown 2x nearest, the camera's zoom -- beside the
    illustrated mother for scale;
  * the band assembled the way `EventInstance._draw_spread` draws it for a roadblock (60px each
    side of its centre, the segment count, stretch and end posts copied from that function), at
    game scale and from the 4x raster: broadside with a guard at each of its north and south
    posts, and down a north-south column as it was drawn before (the broadside picture stacked,
    one guard at the centre) and as it is now (the end-on picture), with a guard at each of its
    west and east posts. The guards' feet stand at `EventInstance._guard_post_offset()`'s
    arithmetic, copied here.

The ground is the illustrated road tile.
"""

import os
import subprocess
import sys
import tempfile
from math import ceil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

GODOT = os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot")
RENDER = "docs/evidence/burst-main-redraw-2026-09-23/render-svgs.gd"
ROAD = Path("art/illustrated/svg-transfer/tiles/road.png")
MOTHER = Path("art/illustrated/svg-transfer/rig/mother_side_a.png")
SOURCES = {
    "roadblock_segment": "art/events/roadblock_segment.svg",
    "roadblock_segment_vertical": "art/events/roadblock_segment_vertical.svg",
    "roadblock_end": "art/events/roadblock_end.svg",
    "guard_front": "art/checkpoints/guard_standing_front.svg",
    "guard_back": "art/checkpoints/guard_standing_back.svg",
    "guard_side": "art/checkpoints/guard_standing_side.svg",
}
HALF = 60.0  # roadblock: obstructs_radius 60
CLEARANCE = 2.0  # EventInstance._GUARD_POST_CLEARANCE


def render(work: Path) -> dict:
    out = work / "render"
    args = [f"{k}={v}" for k, v in SOURCES.items()]
    subprocess.run([GODOT, "--headless", "--path", ".", "--script", RENDER, "--",
                    "--output-dir", str(out), "--scales", "1,4", *args],
                   check=True, capture_output=True)
    return {k: (Image.open(out / f"{k}@1x.png").convert("RGBA"),
                Image.open(out / f"{k}@4x.png").convert("RGBA")) for k in SOURCES}


def road(w: int, h: int, scale: int) -> Image.Image:
    t = Image.open(ROAD).convert("RGBA")
    t = t.resize((t.width * scale, t.height * scale), Image.NEAREST)
    im = Image.new("RGBA", (w, h))
    for y in range(0, h, t.height):
        for x in range(0, w, t.width):
            im.alpha_composite(t, (x, y))
    return im


def standing(canvas, pic, ax, ay, w, h, scale, mirror=False):
    """`Sprites.draw_standing`: bottom centre at (ax, ay), drawn w x h world px, times scale."""
    W, H = max(1, round(w * scale)), max(1, round(h * scale))
    im = pic.resize((W, H), Image.BILINEAR)
    if mirror:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    canvas.alpha_composite(im, (round(ax * scale - W / 2), round(ay * scale - H)))


def native(pics, name):
    return pics[name][0].size


def spread(c, pics, s, seg_name, cx, cy, vertical, before=False):
    """`EventInstance._draw_spread` for a roadblock, from the raster at scale `s`.

    End-on, each segment stands its feet at the near end of its slice
    (`EventInstance._spread_slice_feet`); `before` stands them at the middle, as it was drawn
    before, half a segment up the screen from its own ground."""
    seg_w, seg_h = native(pics, seg_name)
    cap_w, cap_h = native(pics, "roadblock_end")
    along, thick = (seg_h, seg_w) if vertical else (seg_w, seg_h)
    n = max(1, ceil(HALF * 2 / along))
    width = HALF * 2 / n
    cap_off = HALF - cap_w * 0.5

    def at(offset):
        return (cx, cy + offset) if vertical else (cx + offset, cy)

    idx = 0 if s == 1 else 1
    if vertical:
        standing(c, pics["roadblock_end"][idx], *at(-cap_off), cap_w, cap_h, s)
    for i in range(n):
        size = (thick, width) if vertical else (width, thick)
        feet = 0.5 if before or not vertical else 1.0
        standing(c, pics[seg_name][idx], *at(-HALF + width * (i + feet)), *size, s)
    for side in ((1,) if vertical else (-1, 1)):
        standing(c, pics["roadblock_end"][idx], *at(side * cap_off), cap_w, cap_h, s)


def guard(c, pics, s, name, x, y, mirror=False):
    idx = 0 if s == 1 else 1
    w, h = native(pics, name)
    standing(c, pics[name][idx], x, y, w, h, s, mirror)


def assemble(pics, s, column_segment, with_guards=True):
    """Broadside band with guards north and south; a column with guards west and east.

    `with_guards` false draws the before state instead: one guard at each band's own centre."""
    c = road(420 * s, 230 * s, s)
    gw, gh = native(pics, "guard_front")
    # Broadside, centred at (80, 120): the north post, then the band, then the south post.
    if with_guards:
        guard(c, pics, s, "guard_back", 80, 120 - (native(pics, "roadblock_segment")[1] + CLEARANCE))
    spread(c, pics, s, "roadblock_segment", 80, 120, False)
    if with_guards:
        guard(c, pics, s, "guard_front", 80, 120 + gh + CLEARANCE)
    # Down a column, centred at (300, 140).
    spread(c, pics, s, column_segment, 300, 140, True, before=not with_guards)
    if with_guards:
        col_w = native(pics, column_segment)[0]
        dx = col_w * 0.5 + gw * 0.5 + CLEARANCE
        guard(c, pics, s, "guard_side", 300 - dx, 140, mirror=True)
        guard(c, pics, s, "guard_side", 300 + dx, 140)
    else:
        # As it was drawn before: one guard at each band's own centre, over the barrier.
        guard(c, pics, s, "guard_front", 80, 120)
        guard(c, pics, s, "guard_side", 300, 140)
    return c


def singles(pics, mother):
    names = ["roadblock_segment", "roadblock_segment_vertical", "roadblock_end"]
    bg = (118, 114, 108, 255)
    w = 40 + sum(pics[n][0].width * 2 + 12 for n in names) + mother.width * 2
    h = max([pics[n][0].height * 2 for n in names] + [mother.height * 2]) + 24
    row = Image.new("RGBA", (w, h), bg)
    row.alpha_composite(mother.resize((mother.width * 2, mother.height * 2), Image.NEAREST),
                        (8, h - mother.height * 2 - 4))
    x = mother.width * 2 + 20
    for n in names:
        big = pics[n][0].resize((pics[n][0].width * 2, pics[n][0].height * 2), Image.NEAREST)
        row.alpha_composite(big, (x, h - big.height - 4))
        x += big.width + 12
    return row


def main():
    args = sys.argv[1:]
    if len(args) != 1 or args[0] in ("-h", "--help"):
        print(__doc__)
        return 0 if args and args[0] in ("-h", "--help") else 2
    out = Path(args[0])
    with tempfile.TemporaryDirectory() as tmp:
        pics = render(Path(tmp))
    mother = Image.open(MOTHER).convert("RGBA")
    blocks = [
        ("broadside, end-on (new) and end post at game scale (1x raster at 2x), mother for scale",
         singles(pics, mother)),
    ]
    for title, seg in (("AFTER", "roadblock_segment_vertical"), ("BEFORE", "roadblock_segment")):
        a = assemble(pics, 1, seg, with_guards=title == "AFTER")
        blocks.append((f"{title}: broadside band (left) and north-south column (right), game scale"
                       + (", a guard at each post" if title == "AFTER"
                          else ", guard at the band's centre"),
                       a.resize((a.width * 2, a.height * 2), Image.NEAREST)))
    blocks.append(("AFTER: the same, 4x raster", assemble(pics, 4, "roadblock_segment_vertical")))
    font = ImageFont.load_default(size=16)
    W = max(b[1].width for b in blocks) + 16
    H = sum(b[1].height + 30 for b in blocks) + 8
    im = Image.new("RGBA", (W, H), (234, 230, 222, 255))
    d = ImageDraw.Draw(im)
    y = 6
    for title, block in blocks:
        d.text((8, y), title, fill=(20, 20, 20, 255), font=font)
        im.alpha_composite(block, (8, y + 22))
        y += block.height + 30
    im.convert("RGB").save(out, optimize=True)
    print(out, im.size)
    return 0


if __name__ == "__main__":
    sys.exit(main())
