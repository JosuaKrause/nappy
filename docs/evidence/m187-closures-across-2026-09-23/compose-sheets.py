"""Before/after review sheets for M187, a closure lies across the street it closes.

Usage: python3 docs/evidence/m187-closures-across-2026-09-23/compose-sheets.py
           --before-rev REV --out-dir DIR [SHEET ...]

Run from the repository root, after `./tools/check.sh` has imported the project; needs Pillow
(`uv run` provides it). It extracts `art/closures` and `art/events` as they stand at REV with
`git archive`, renders both revisions of every picture a sheet needs through the engine's own SVG
parser (the burst main's committed `docs/evidence/burst-main-redraw-2026-09-23/render-svgs.gd`, at
scales 1 and 4; set GODOT to the Godot binary if it is not
/Applications/Godot.app/Contents/MacOS/Godot), and writes DIR/<sheet>.png at game scale (the 1x
raster shown 2x nearest, the camera's zoom) and DIR/<sheet>-4x.png from the 4x raster, each
before above after:

  causes     every closure cause on a north-south street and on an east-west one, over the
             street's own 192px of sidewalk, carriageway and sidewalk, with the mother for scale.
             BEFORE draws the one picture on both axes, as `ClosureMarker._draw()` did at REV;
             AFTER draws the `_vertical` picture on the east-west street, standing half its
             across picture's width below the street's middle, with the capsule shadow
             `ClosureMarker._draw()` puts under it.
  roadworks  the `construction` barrier broadside and end-on, segments and end posts placed with
             `EventInstance._draw_spread`'s arithmetic: BEFORE insets an end-on post by half its
             picture's height and draws both posts over the board, AFTER insets it by half its
             own footprint, the post's width, and draws the far post behind the board.

With no SHEET named, both.
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
MOTHER = Path("art/illustrated/svg-transfer/rig/mother_front_a.png")
SHADOW_ALPHA = 0.22  # Palette.SHADOW
SQUASH = 0.4  # GroundShape.SHADOW_SQUASH
STREET = 192  # Tuning.STREET_WIDTH * Tuning.TILE_SIZE
SIDEWALK = 64  # Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE
KINDS = ["roadworks", "fallen_tree", "crashed_car", "rubble"]

SHEETS = {
    "causes": [f"art/closures/{k}.svg" for k in KINDS] + [f"art/closures/{k}_vertical.svg" for k in KINDS],
    "roadworks": ["art/events/barrier_segment.svg", "art/events/barrier_segment_vertical.svg",
                  "art/events/barrier_end.svg"],
}


def label(rel: str) -> str:
    return Path(rel).stem


def render(sheet: str, root: Path, work: Path, side: str) -> dict:
    out = work / f"{sheet}-{side}"
    present = [r for r in SHEETS[sheet] if (root / r).exists()]
    args = [f"{label(r)}={root / r}" for r in present]
    subprocess.run([GODOT, "--headless", "--path", ".", "--script", RENDER, "--",
                    "--output-dir", str(out), "--scales", "1,4", *args],
                   check=True, capture_output=True)
    return {label(r): (Image.open(out / f"{label(r)}@1x.png").convert("RGBA"),
                       Image.open(out / f"{label(r)}@4x.png").convert("RGBA"))
            for r in present}


def tile(name: str, scale: int) -> Image.Image:
    t = Image.open(TILES / name).convert("RGBA")
    return t.resize((t.width * scale, t.height * scale), Image.NEAREST)


def street(w: int, h: int, north_south: bool, scale: int, carriageway: bool = True) -> Image.Image:
    """A patch of street: sidewalk, carriageway, sidewalk across its width, in world px; or,
    without a carriageway, sidewalk throughout."""
    im = Image.new("RGBA", (w * scale, h * scale))
    road, walk = tile("road.png", scale), tile("sidewalk.png", scale)
    step = road.width
    for y in range(0, h * scale, step):
        for x in range(0, w * scale, step):
            across = x // scale if north_south else y // scale
            middle = (w if north_south else h) / 2
            on_road = carriageway and abs(across + 16 - middle) < STREET / 2 - SIDEWALK
            im.alpha_composite(road if on_road else walk, (x, y))
    return im


def standing(canvas, pic, ax, ay, w, h, scale):
    """`Sprites.draw_standing`: bottom centre at (ax, ay), drawn w x h world px, times scale."""
    W, H = max(1, round(w * scale)), max(1, round(h * scale))
    im = pic.resize((W, H), Image.BILINEAR)
    canvas.alpha_composite(im, (round(ax * scale - W / 2), round(ay * scale - H)))


def shadow(canvas, box, radius, scale):
    layer = Image.new("RGBA", canvas.size)
    ImageDraw.Draw(layer).rounded_rectangle([v * scale for v in box], radius=radius * scale,
                                            fill=(0, 0, 0, int(255 * SHADOW_ALPHA)))
    canvas.alpha_composite(layer)


def point_shadow(canvas, cx, cy, r, scale):
    """`Sprites.draw_shadow`: an ellipse r wide either way, squashed on y."""
    layer = Image.new("RGBA", canvas.size)
    ImageDraw.Draw(layer).ellipse([(cx - r) * scale, (cy - r * SQUASH) * scale,
                                   (cx + r) * scale, (cy + r * SQUASH) * scale],
                                  fill=(0, 0, 0, int(255 * SHADOW_ALPHA)))
    canvas.alpha_composite(layer)


def size(pics, name, s):
    p = pics[name]
    return p.size if s == 1 else (p.width / 4, p.height / 4)


def cause_patch(pics, kind, north_south, after, s, mother):
    """One cause on one street, drawn the way `ClosureMarker._draw()` draws it."""
    w, h = (STREET, 200) if north_south else (200, STREET)
    c = street(w, h, north_south, s)
    cx, cy = w / 2, h / 2
    across_w, across_h = size(pics, kind, s)
    vertical = f"{kind}_vertical"
    if north_south or not after or vertical not in pics:
        point_shadow(c, cx, cy, across_w * 0.32, s)
        standing(c, pics[kind], cx, cy, across_w, across_h, s)
    else:
        vw, vh = size(pics, vertical, s)
        radius = vw * 0.32
        half = max(0.0, across_w * 0.32 - radius)
        shadow(c, [cx - radius, cy - half - radius, cx + radius, cy + half + radius], radius, s)
        standing(c, pics[vertical], cx, cy + across_w / 2, vw, vh, s)
    mx, my = (18, h - 20) if north_south else (w - 24, 30)
    standing(c, mother, mx, my, mother.width, mother.height, s)
    return c


def causes_block(pics, after, s, mother):
    patches = []
    for kind in KINDS:
        patches.append(cause_patch(pics, kind, True, after, s, mother))
        patches.append(cause_patch(pics, kind, False, after, s, mother))
    gap = 8 * s
    W = sum(p.width for p in patches) + gap * (len(patches) - 1)
    H = max(p.height for p in patches)
    im = Image.new("RGBA", (W, H), (234, 230, 222, 255))
    x = 0
    for p in patches:
        im.alpha_composite(p, (x, 0))
        x += p.width + gap
    return im


def roadworks_block(pics, after, s):
    """`EventInstance._draw_spread(BARRIER_SEGMENT[_VERTICAL], BARRIER_END)` for `construction`."""
    c = street(260, 130, True, s, carriageway=False)
    half, seg = 32.0, 3  # construction: obstructs 32, 26px panels, three segments either way
    w = 2 * half / seg
    cap_w, cap_h = size(pics, "barrier_end", s)
    for i in range(seg):
        standing(c, pics["barrier_segment"], 60 - half + w * (i + 0.5), 70, w, 22, s)
    for side in (-1, 1):
        standing(c, pics["barrier_end"], 60 + side * (half - cap_w / 2), 70, cap_w, cap_h, s)
    inset = cap_w / 2 if after else cap_h / 2
    # `EventInstance._cap_sides`: end-on, AFTER draws the far post before the board and only the
    # near one over it; BEFORE drew both over it.
    behind, in_front = ((-1,), (1,)) if after else ((), (-1, 1))
    for side in behind:
        standing(c, pics["barrier_end"], 190, 72 + side * (half - inset), cap_w, cap_h, s)
    for i in range(seg):
        standing(c, pics["barrier_segment_vertical"], 190, 72 - half + w * (i + 0.5), 14, w, s)
    for side in in_front:
        standing(c, pics["barrier_end"], 190, 72 + side * (half - inset), cap_w, cap_h, s)
    # The obstruction's own extent, as two ticks either side of each run.
    d = ImageDraw.Draw(c)
    for x0, y0, x1, y1 in ((60 - half, 76, 60 + half, 76), (204, 72 - half, 204, 72 + half)):
        d.line([x0 * s, y0 * s, x1 * s, y1 * s], fill=(40, 120, 220, 255), width=s)
    return c


def sheet(name, before, after, out_dir: Path):
    mother = Image.open(MOTHER).convert("RGBA")
    for scale, what, suffix in ((1, "game scale (2x)", ""), (4, "4x raster", "-4x")):
        blocks = []
        for side, pics in (("BEFORE", before), ("AFTER", after)):
            p = {k: v[0 if scale == 1 else 1] for k, v in pics.items()}
            if name == "causes":
                block = causes_block(p, side == "AFTER", scale, mother)
                title = f"{side}: each cause on a north-south street, then an east-west one, {what}"
            else:
                block = roadworks_block(p, side == "AFTER", scale)
                title = (f"{side}: the construction barrier broadside, then end-on; blue marks the "
                         f"64px it obstructs, {what}")
            if scale == 1:
                block = block.resize((block.width * 2, block.height * 2), Image.NEAREST)
            blocks.append((title, block))
        font = ImageFont.load_default(size=16)
        W = max(max(b[1].width, round(font.getlength(b[0]))) for b in blocks) + 16
        H = sum(b[1].height + 30 for b in blocks) + 8
        im = Image.new("RGBA", (W, H), (234, 230, 222, 255))
        d = ImageDraw.Draw(im)
        y = 6
        for title, block in blocks:
            d.text((8, y), title, fill=(20, 20, 20, 255), font=font)
            im.alpha_composite(block, (8, y + 22))
            y += block.height + 30
        out = out_dir / f"{name}{suffix}.png"
        im.convert("RGB").save(out, optimize=True)
        print(out, im.size)


def main():
    args = sys.argv[1:]
    if args and args[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    rev = out = None
    names = []
    while args:
        word = args.pop(0)
        if word == "--before-rev" and args:
            rev = args.pop(0)
        elif word == "--out-dir" and args:
            out = Path(args.pop(0))
        elif word in SHEETS:
            names.append(word)
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
        for name in names or list(SHEETS):
            before = render(name, before_root, work, "before")
            after = render(name, Path.cwd(), work, "after")
            sheet(name, before, after, out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
