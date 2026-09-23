"""Compose the before/after sheets for the street-animal redraw from render-svgs.gd's rasters.

Usage: uv run python compose-sheets.py BEFORE_DIR AFTER_DIR OUT_DIR

BEFORE_DIR and AFTER_DIR are render-svgs.gd output folders (art/events/<name>@1.png and @6.png)
for the old and the new pictures. Writes sheet-dog.png, sheet-charging-dog.png, sheet-cat.png,
sheet-pigeon.png and sheet-dogs-compared.png into OUT_DIR.

Each family sheet has the game-scale strips first: the 1x raster doubled with nearest-neighbour
sampling (the camera's zoom of 2) on the illustrated sidewalk and road tiles, bottom edge on one
ground line, with the illustrated mother on the left for scale. Below them, every picture's 6x
raster on a sidewalk cell, bottom-aligned, with a yellow line at the canvas bottom, which is the
ground anchor Sprites.draw_standing() puts on the event's position. Cells are not a shared world
scale between different canvases; the strips are.
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parents[3]
TILES = REPO / "art/illustrated/svg-transfer/tiles"
MOTHER = REPO / "art/illustrated/svg-transfer/rig/mother_side_a.png"
PAPER = (235, 232, 225, 255)
INK = (0, 0, 0)
VIEWS = ["", "_front", "_front_diagonal", "_back_diagonal", "_back"]


def names(family: str) -> list[str]:
    if family in ("dog", "charging_dog"):
        return [family + v + s for v in VIEWS for s in ("", "_b")]
    if family == "cat":
        return (["cat_crouched" + v for v in VIEWS]
                + ["cat_running" + v + s for v in VIEWS for s in ("", "_b")])
    if family == "pigeon":
        return [p + v for v in VIEWS for p in ("pigeon", "pigeon_down")]
    raise SystemExit(f"unknown family {family}")


def tiled(kind: str, w: int, h: int, k: int = 2) -> Image.Image:
    src = Image.open(TILES / f"{kind}.png").convert("RGBA")
    src = src.resize((src.width * k, src.height * k), Image.NEAREST)
    bg = Image.new("RGBA", (w, h))
    for y in range(0, h, src.height):
        for x in range(0, w, src.width):
            bg.paste(src, (x, y))
    return bg


def labelled(img: Image.Image, label: str, font) -> Image.Image:
    out = Image.new("RGBA", (img.width, img.height + 16), PAPER)
    ImageDraw.Draw(out).text((2, 2), label, fill=INK, font=font)
    out.alpha_composite(img, (0, 16))
    return out


def strip(root: Path, ns: list[str], kind: str, font, label: str) -> Image.Image:
    mother = Image.open(MOTHER).convert("RGBA")
    ims = [mother] + [Image.open(root / "art/events" / f"{n}@1.png").convert("RGBA") for n in ns]
    ims = [i.resize((i.width * 2, i.height * 2), Image.NEAREST) for i in ims]
    gap = 14
    w = sum(i.width + gap for i in ims) + gap
    h = max(i.height for i in ims) + 20
    bg = tiled(kind, w, h)
    x = gap
    for i in ims:
        bg.alpha_composite(i, (x, h - 10 - i.height))
        x += i.width + gap
    return labelled(bg, label, font)


def grid(root: Path, ns: list[str], font, label: str, cols: int) -> Image.Image:
    ims = [Image.open(root / "art/events" / f"{n}@6.png").convert("RGBA") for n in ns]
    cw = max(i.width for i in ims) + 12
    ch = max(i.height for i in ims) + 26
    rows = (len(ims) + cols - 1) // cols
    out = Image.new("RGBA", (cols * cw + 8, rows * ch + 18), PAPER)
    d = ImageDraw.Draw(out)
    d.text((2, 2), label, fill=INK, font=font)
    for k, (n, im) in enumerate(zip(ns, ims)):
        cx, cy = 4 + (k % cols) * cw, 18 + (k // cols) * ch
        out.paste(tiled("sidewalk", cw - 6, ch - 14, 6), (cx, cy))
        out.alpha_composite(im, (cx + (cw - 6 - im.width) // 2, cy + ch - 18 - im.height))
        d.line([(cx, cy + ch - 18), (cx + cw - 7, cy + ch - 18)], fill=(255, 255, 0, 255), width=1)
        d.text((cx, cy + ch - 13), n, fill=INK, font=font)
    return out


def stack(parts: list[Image.Image], dst: Path) -> None:
    w = max(p.width for p in parts) + 16
    h = sum(p.height + 10 for p in parts) + 10
    sheet = Image.new("RGBA", (w, h), PAPER)
    y = 8
    for p in parts:
        sheet.alpha_composite(p, (8, y))
        y += p.height + 10
    sheet.convert("RGB").save(dst, optimize=True)
    print(dst, sheet.size)


def main() -> None:
    if len(sys.argv) != 4 or sys.argv[1] in ("-h", "--help"):
        print(__doc__)
        raise SystemExit(0 if len(sys.argv) == 2 else 2)
    before, after, out = (Path(a) for a in sys.argv[1:])
    font = ImageFont.load_default()
    for family in ("dog", "charging_dog", "cat", "pigeon"):
        ns = names(family)
        cols = 5 if family == "cat" else 10
        stack([
            strip(before, ns, "sidewalk", font, f"BEFORE  {family}: game scale (2x, nearest), sidewalk, the mother for scale"),
            strip(after, ns, "sidewalk", font, f"AFTER  {family}: game scale (2x, nearest), sidewalk"),
            strip(after, ns, "road", font, f"AFTER  {family}: game scale (2x, nearest), road"),
            grid(before, ns, font, "BEFORE: 6x source render; yellow line = canvas bottom (the ground anchor)", cols),
            grid(after, ns, font, "AFTER: 6x source render; yellow line = canvas bottom (the ground anchor)", cols),
        ], out / f"sheet-{family.replace('_', '-')}.png")
    stack([
        strip(after, names("dog"), "sidewalk", font, "AFTER  the walked or loose dog, every view and frame, game scale"),
        strip(after, names("charging_dog"), "sidewalk", font, "AFTER  the charging dog, every view and frame, game scale"),
        strip(after, names("dog"), "road", font, "AFTER  the walked or loose dog on the road"),
        strip(after, names("charging_dog"), "road", font, "AFTER  the charging dog on the road"),
    ], out / "sheet-dogs-compared.png")


main()
