"""Before/after review sheets for the street-obstruction SVG redraw.

Usage: uv run python docs/evidence/svg-rework-obstructions-2026-09-23/compose-sheets.py
           --before-rev REV --out-dir DIR [FAMILY ...]

Run from the repository root, after `./tools/check.sh` has imported the project. It extracts
`art/closures` and `art/events` as they stand at REV with `git archive`, renders both revisions of
every picture in each FAMILY through the engine's own SVG parser (the burst main's committed
`docs/evidence/burst-main-redraw-2026-09-23/render-svgs.gd`, at scales 1 and 4; set GODOT to the
Godot binary if it is not /Applications/Godot.app/Contents/MacOS/Godot), and writes
DIR/<family>.png with, before above after:

  * each picture at game scale — its 1x raster shown 2x nearest, the camera's zoom — beside the
    illustrated mother for scale;
  * the family assembled the way the code draws it, at game scale: repeat counts, stretch,
    anchors and end caps copied from `City._spawn_barrier`, `ClosureMarker._draw_panel`,
    `EventInstance._draw_spread` and `_draw_wide_scene`, with the car accident's shadow files
    under it at `Palette.SHADOW`'s alpha and a stand-in ellipse where the code draws a point
    shadow;
  * the same assembly from the 4x raster, for joins and clipping.

Families: roadworks_barrier, closure_barriers, closure_causes, stall, delivery_van, fallen_tree,
car_accident. With none named, all of them. The ground is the illustrated sidewalk or road tile.
"""

import os
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

GODOT = os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot")
RENDER = "docs/evidence/burst-main-redraw-2026-09-23/render-svgs.gd"
TILES = Path("art/illustrated/svg-transfer/tiles")
MOTHER = Path("art/illustrated/svg-transfer/rig/mother_side_a.png")
SHADOW_ALPHA = 0.22  # Palette.SHADOW

FAMILIES = {
    "roadworks_barrier": ["art/events/barrier_segment.svg", "art/events/barrier_segment_vertical.svg",
                          "art/events/barrier_end.svg"],
    "closure_barriers": ["art/closures/barrier_across.svg", "art/closures/barrier_along.svg",
                         "art/closures/sign_closed.svg"],
    "closure_causes": ["art/closures/roadworks.svg", "art/closures/fallen_tree.svg",
                       "art/closures/crashed_car.svg", "art/closures/rubble.svg"],
    "stall": ["art/events/stall.svg"],
    "delivery_van": ["art/events/delivery_van.svg", "art/events/delivery_van_front.svg",
                     "art/events/delivery_van_back.svg", "art/events/delivery_van_front_diagonal.svg",
                     "art/events/delivery_van_back_diagonal.svg"],
    "fallen_tree": ["art/events/fallen_tree.svg", "art/events/fallen_tree_vertical.svg"],
    "car_accident": ["art/events/car_accident.svg", "art/events/car_accident_vertical.svg",
                     "art/events/car_accident_shadow.svg", "art/events/car_accident_vertical_shadow.svg"],
}


def label(rel: str) -> str:
    return Path(rel).stem


def render(family: str, root: Path, work: Path, side: str) -> dict:
    out = work / f"{family}-{side}"
    args = [f"{label(r)}={root / r}" for r in FAMILIES[family]]
    subprocess.run([GODOT, "--headless", "--path", ".", "--script", RENDER, "--",
                    "--output-dir", str(out), "--scales", "1,4", *args],
                   check=True, capture_output=True)
    return {label(r): (Image.open(out / f"{label(r)}@1x.png").convert("RGBA"),
                       Image.open(out / f"{label(r)}@4x.png").convert("RGBA"))
            for r in FAMILIES[family]}


def tiled(w: int, h: int, tile: str, scale: int) -> Image.Image:
    t = Image.open(TILES / tile).convert("RGBA")
    t = t.resize((t.width * scale, t.height * scale), Image.NEAREST)
    im = Image.new("RGBA", (w, h))
    for y in range(0, h, t.height):
        for x in range(0, w, t.width):
            im.alpha_composite(t, (x, y))
    return im


def standing(canvas, pic, ax, ay, w, h, scale, mirror=False, tint=None):
    """`Sprites.draw_standing`: bottom centre at (ax, ay), drawn w x h world px, times scale."""
    W, H = max(1, round(w * scale)), max(1, round(h * scale))
    im = pic.resize((W, H), Image.BILINEAR)
    if mirror:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    if tint is not None:
        alpha = im.getchannel("A").point(lambda v: int(v * tint))
        im = Image.new("RGBA", im.size, (0, 0, 0, 0))
        im.putalpha(alpha)
    canvas.alpha_composite(im, (round(ax * scale - W / 2), round(ay * scale - H)))


def point_shadow(canvas, cx, cy, r, scale):
    layer = Image.new("RGBA", canvas.size)
    ImageDraw.Draw(layer).ellipse([(cx - r) * scale, (cy - r * 0.35) * scale,
                                   (cx + r) * scale, (cy + r * 0.35) * scale],
                                  fill=(0, 0, 0, int(255 * SHADOW_ALPHA)))
    canvas.alpha_composite(layer)


def native(pics, name, s):
    return pics[name].size if s == 1 else (pics[name].width // 4, pics[name].height // 4)


def assemble(family, pics, s):
    if family == "closure_barriers":
        c = tiled(470 * s, 250 * s, "road.png", s)
        span = 192 / 9  # City._spawn_barrier: 192px of street over barrier_across's 22px
        for i in range(9):
            x = 20 + span * (i + 0.5)
            standing(c, pics["barrier_across"], x, 60, span, 24, s)
            if i == 4:
                standing(c, pics["sign_closed"], x, 62, 20, 34, s)
        for i in range(9):
            y = 30 + span * (i + 1)
            standing(c, pics["barrier_along"], 320, y, 14, span, s)
            if i == 4:
                standing(c, pics["sign_closed"], 320, y + 2, 20, 34, s)
        return c
    if family == "roadworks_barrier":
        c = tiled(260 * s, 130 * s, "sidewalk.png", s)
        half, seg = 32.0, 3  # construction: obstructs 32, three segments either way
        w = 2 * half / seg
        for i in range(seg):
            standing(c, pics["barrier_segment"], 60 - half + w * (i + 0.5), 70, w, 22, s)
        for side in (-1, 1):
            standing(c, pics["barrier_end"], 60 + side * (half - 3), 70, 6, 26, s)
        for i in range(seg):
            standing(c, pics["barrier_segment_vertical"], 190, 75 - half + w * (i + 0.5), 14, w, s)
        for side in (-1, 1):
            standing(c, pics["barrier_end"], 190, 75 + side * (half - 13), 6, 26, s)
        return c
    if family == "stall":
        c = tiled(200 * s, 120 * s, "sidewalk.png", s)
        half = 28.0  # market_stall: obstructs 28
        w = 2 * half / 3
        for i in range(3):
            standing(c, pics["stall"], 50 - half + w * (i + 0.5), 70, w, 36, s)
        w = 2 * half / 2
        for i in range(2):
            standing(c, pics["stall"], 150, 55 - half + w * (i + 0.5), 26, w, s)
        return c
    if family == "delivery_van":
        c = tiled(330 * s, 70 * s, "road.png", s)
        point_shadow(c, 40, 60, 22, s)
        standing(c, pics["delivery_van"], 40, 60, 48, 30, s, mirror=True)
        standing(c, pics["delivery_van"], 100, 60, 48, 30, s)
        x = 160
        for name in ("delivery_van_front_diagonal", "delivery_van_front", "delivery_van_back_diagonal"):
            w, h = native(pics, name, s)
            standing(c, pics[name], x, 60, w, h, s)
            x += 60
        return c
    if family in ("fallen_tree", "car_accident"):
        c = tiled(300 * s, 230 * s, "road.png", s)
        h, v = family, family + "_vertical"
        if family == "car_accident":
            standing(c, pics[h + "_shadow"], 106, 110, 192, 50, s, tint=SHADOW_ALPHA)
            standing(c, pics[v + "_shadow"], 250, 110 + 96, 50, 192, s, tint=SHADOW_ALPHA)
        standing(c, pics[h], 106, 110, 192, 50, s)
        standing(c, pics[v], 250, 110 + 96, 50, 192, s)
        return c
    if family == "closure_causes":
        c = tiled(400 * s, 60 * s, "road.png", s)
        x = 10
        for name in ("roadworks", "fallen_tree", "crashed_car", "rubble"):
            w, h = native(pics, name, s)
            point_shadow(c, x + w / 2, 52, w * 0.32, s)
            standing(c, pics[name], x + w / 2, 52, w, h, s)
            x += w + 12
        return c
    raise KeyError(family)


def singles(pics, mother):
    bg = (118, 114, 108, 255)
    w = 40 + sum(p[0].width * 2 + 12 for p in pics.values()) + mother.width * 2
    h = max([p[0].height * 2 for p in pics.values()] + [mother.height * 2]) + 24
    row = Image.new("RGBA", (w, h), bg)
    row.alpha_composite(mother.resize((mother.width * 2, mother.height * 2), Image.NEAREST),
                        (8, h - mother.height * 2 - 4))
    x = mother.width * 2 + 20
    for p in pics.values():
        big = p[0].resize((p[0].width * 2, p[0].height * 2), Image.NEAREST)
        row.alpha_composite(big, (x, h - big.height - 4))
        x += big.width + 12
    return row


def sheet(family, before, after, out: Path):
    mother = Image.open(MOTHER).convert("RGBA")
    blocks = []
    for side, pics in (("BEFORE", before), ("AFTER", after)):
        blocks.append((f"{side}: each picture at game scale (1x raster at 2x), mother for scale",
                       singles(pics, mother)))
    for side, pics in (("BEFORE", before), ("AFTER", after)):
        a = assemble(family, {k: v[0] for k, v in pics.items()}, 1)
        blocks.append((f"{side}: assembled as the code draws it, game scale (2x)",
                       a.resize((a.width * 2, a.height * 2), Image.NEAREST)))
    for side, pics in (("BEFORE", before), ("AFTER", after)):
        blocks.append((f"{side}: assembled, 4x raster", assemble(family, {k: v[1] for k, v in pics.items()}, 4)))
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


def main():
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        return 0 if args else 2
    rev = out = None
    families = []
    while args:
        word = args.pop(0)
        if word == "--before-rev" and args:
            rev = args.pop(0)
        elif word == "--out-dir" and args:
            out = Path(args.pop(0))
        elif word in FAMILIES:
            families.append(word)
        else:
            print(f"unknown argument: {word}\n{__doc__}", file=sys.stderr)
            return 2
    if rev is None or out is None:
        print(__doc__, file=sys.stderr)
        return 2
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp)
        before_root = work / "before"
        before_root.mkdir()
        archive = subprocess.run(["git", "archive", rev, "art/closures", "art/events"],
                                 check=True, capture_output=True).stdout
        subprocess.run(["tar", "-x", "-C", str(before_root)], input=archive, check=True)
        for family in families or list(FAMILIES):
            before = render(family, before_root, work, "before")
            after = render(family, Path.cwd(), work, "after")
            sheet(family, before, after, out / f"{family}.png")
    return 0


if __name__ == "__main__":
    sys.exit(main())
