"""Compose M185's door and storefront review sheets from rasters made by render-svgs.gd.

Usage:
  uv run python compose-sheet.py doors RENDER_DIR OUT.png
  uv run python compose-sheet.py storefronts BEFORE_DIR AFTER_DIR OUT.png

RENDER_DIR (and each of BEFORE_DIR/AFTER_DIR) holds `<name>@1x.png` and `<name>@4x.png` for the
`art/buildings/` pictures named below, rendered by
`docs/evidence/burst-main-redraw-2026-09-23/render-svgs.gd` — the engine's own SVG parser, the one
the atlas bake uses. Each facade is assembled the way `Building._draw()` assembles one: the
near-white wall multiplied by a variant's wall colour (`Palette.building_wall`, the roof colour
darkened by 0.42), the plinth on the ground row, upper windows lifted two pixels on the row above
a 36px ground-floor picture, the corner edges, one row of roof, and the ground-floor picture
standing on the ground line. Game-scale cells are the 1x rasters composed and enlarged 2x with
nearest-neighbour sampling, which is the camera's ordinary zoom and the project's texture filter;
the enlarged cells are the 4x rasters composed at 4x.
"""

import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

TILE = 32
ROOFS = ["c2a179", "b08968", "a8907a", "cbb391", "9d7f68", "bda386"]
PAVEMENT = (164, 142, 116)
GROUT = (136, 118, 96)
INK = (30, 26, 28)
PAPER = (236, 232, 222)
KINDS = ("a", "b", "c", "d")
KIND_NAMES = {"a": "grocer", "b": "cafe", "c": "pharmacy", "d": "sign shop"}


def hex_rgb(value: str) -> tuple[int, int, int]:
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))


def wall_colour(variant: int) -> tuple[int, int, int]:
    r, g, b = hex_rgb(ROOFS[variant % len(ROOFS)])
    return (round(r * 0.58), round(g * 0.58), round(b * 0.58))


class Pictures:
    def __init__(self, directory: Path, scale: int) -> None:
        self.directory = directory
        self.scale = scale
        self.cache: dict[str, Image.Image] = {}

    def get(self, name: str) -> Image.Image:
        if name not in self.cache:
            path = self.directory / f"{name}@{self.scale}x.png"
            self.cache[name] = Image.open(path).convert("RGBA")
        return self.cache[name]


def tinted(picture: Image.Image, colour: tuple[int, int, int]) -> Image.Image:
    solid = Image.new("RGBA", picture.size, (*colour, 255))
    out = ImageChops.multiply(picture, solid)
    out.putalpha(picture.getchannel("A"))
    return out


def facade(pics: Pictures, cols: int, wall_rows: int, variant: int, ground: list[tuple[int, str]],
           overlays: list[tuple[int, str]], upper: str = "window_dark", lit: set[int] | None = None,
           shop_row: bool = False) -> Image.Image:
    """One building front standing on a strip of pavement.

    `ground` lists (column, picture) substitutions for the plinth, as `_ground_floor_texture()`
    returns them; a 64px picture spans its column and the next. `overlays` lists (column,
    picture) drawn standing on the ground line at that column's centre, as
    `_draw_front_overlay()` draws a door. `lit` is the set of upper cells (row * cols + col) whose
    window is lit.
    """
    s = pics.scale
    lit = lit or set()
    roof_rows = 1
    pavement = TILE // 2
    width, height = cols * TILE * s, (wall_rows + roof_rows) * TILE * s + pavement * s
    im = Image.new("RGBA", (width, height), (*PAVEMENT, 255))
    d = ImageDraw.Draw(im)
    ground_y = (wall_rows + roof_rows) * TILE * s
    for x in range(0, width, TILE // 2 * s):
        d.line([(x, ground_y), (x, height)], fill=GROUT, width=max(1, s // 2))
    wall = tinted(pics.get("wall"), wall_colour(variant))
    roof = tinted(pics.get("roof"), hex_rgb(ROOFS[variant % len(ROOFS)]))
    lifted = shop_row or bool(overlays)

    def cell(col: int, row: int) -> tuple[int, int]:
        return (col * TILE * s, ground_y - (row + 1) * TILE * s)

    substituted = {col for col, _ in ground}
    for row in range(wall_rows):
        for col in range(cols):
            at = cell(col, row)
            im.alpha_composite(wall, at)
            if row > 0:
                name = upper.replace("_dark", "_lit") if row * cols + col in lit else upper
                window_at = (at[0], at[1] - (2 * s if row == 1 and lifted else 0))
                im.alpha_composite(pics.get(name), window_at)
            if col == 0:
                im.alpha_composite(pics.get("wall_edge_w"), at)
            if col == cols - 1:
                im.alpha_composite(pics.get("wall_edge_e"), at)
    for col in range(cols):
        if col in substituted:
            continue
        im.alpha_composite(pics.get("wall_base"), cell(col, 0))
    for col, name in ground:
        picture = pics.get(name)
        x, y = cell(col, 0)
        im.alpha_composite(picture, (x, y + TILE * s - picture.height))
    for col, name in overlays:
        picture = pics.get(name)
        x = col * TILE * s + TILE * s // 2 - picture.width // 2
        im.alpha_composite(picture, (x, ground_y - picture.height))
    for col in range(cols):
        at = cell(col, wall_rows)
        im.alpha_composite(roof, at)
        im.alpha_composite(pics.get("roof_edge_s"), at)
    return im


def game_scale(im: Image.Image) -> Image.Image:
    return im.resize((im.width * 2, im.height * 2), Image.Resampling.NEAREST)


def paste_row(sheet: Image.Image, d: ImageDraw.ImageDraw, font: ImageFont.ImageFont, x: int, y: int,
              cells: list[tuple[Image.Image, str]], pad: int) -> tuple[int, int]:
    row_h = 0
    for im, label in cells:
        sheet.paste(im, (x, y), im)
        d.text((x, y + im.height + 4), label, fill=INK, font=font)
        x += im.width + pad
        row_h = max(row_h, im.height)
    return x, y + row_h + 26


def doors(render_dir: Path, out: Path) -> int:
    one, four = Pictures(render_dir, 1), Pictures(render_dir, 4)
    font = ImageFont.load_default(size=18)
    small = ImageFont.load_default(size=14)
    pad = 24
    specs = [
        ("entrance_door", 1, {4, 8}, "window_dark", "entrance_door.svg, residential"),
        ("entrance_door", 4, {5}, "window_tall_dark", "entrance_door.svg, another wall"),
        ("entrance_door_industrial", 2, {3}, "window_dark", "entrance_door_industrial.svg"),
        ("entrance_door_industrial", 5, set(), "window_shuttered_dark", "industrial, another wall"),
    ]
    game = [(game_scale(facade(one, 3, 3, v, [], [(1, door)], upper, lit)), label)
            for door, v, lit, upper, label in specs]
    big = [(facade(four, 3, 3, v, [], [(1, door)], upper, lit), label)
           for door, v, lit, upper, label in specs[::2]]
    raw = [(four.get(name), label) for name, label in (("entrance_door", "door alone"),
                                                       ("entrance_door_industrial", "steel door alone"))]
    width = pad + sum(im.width + pad for im, _ in big) + sum(im.width + pad for im, _ in raw)
    width = max(width, pad + sum(im.width + pad for im, _ in game))
    height = pad + 34 + 22 + game[0][0].height + 26 + pad + 22 + big[0][0].height + 26 + pad
    sheet = Image.new("RGB", (width, height), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((pad, pad), "Entrance doors: a multi-story front with no storefront has one", fill=INK, font=font)
    y = pad + 34
    d.text((pad, y), "Game scale: 1x rasters on a three-column facade, 2x nearest (the camera's ordinary zoom)",
           fill=INK, font=small)
    y += 22
    _, y = paste_row(sheet, d, small, pad, y, game, pad)
    y += pad
    d.text((pad, y), "Enlarged: 4x vector render, same facade; and each door alone", fill=INK, font=small)
    y += 22
    paste_row(sheet, d, small, pad, y, big + raw, pad)
    sheet.save(out)
    print(out)
    return 0


def storefronts(before_dir: Path, after_dir: Path, out: Path) -> int:
    font = ImageFont.load_default(size=18)
    small = ImageFont.load_default(size=14)
    pad = 24
    sets = {"before": (Pictures(before_dir, 1), Pictures(before_dir, 4)),
            "after": (Pictures(after_dir, 1), Pictures(after_dir, 4))}

    def front(pics: Pictures, suffix: str, variant: int) -> Image.Image:
        ground = [(0, f"storefront_a{suffix}"), (2, f"storefront_b{suffix}"),
                  (4, f"storefront_c{suffix}"), (6, f"storefront_d{suffix}")]
        return facade(pics, 8, 3, variant, ground, [], "window_dark", {9, 12, 18, 21}, shop_row=True)

    rows = []
    for suffix, name in (("", "plain"), ("_awning", "awning"), ("_shuttered", "shuttered")):
        cells = [(game_scale(front(sets[when][0], suffix, 1)), f"{when}, {name}")
                 for when in ("after", "before")]
        rows.append(cells)
    big_rows = []
    for suffix, name in (("", "plain"), ("_awning", "awning"), ("_shuttered", "shuttered")):
        cells = [(sets["after"][1].get(f"storefront_{k}{suffix}"), f"after, {KIND_NAMES[k]} {name}")
                 for k in KINDS]
        big_rows.append(cells)
    before_big = [(sets["before"][1].get(f"storefront_{k}"), f"before, {KIND_NAMES[k]}") for k in KINDS]
    width = pad + max(sum(im.width + pad for im, _ in r) for r in [*rows, *big_rows, before_big])
    height = pad + 34
    height += sum(22 + max(im.height for im, _ in r) + 26 for r in rows)
    height += pad + 22 + sum(max(im.height for im, _ in r) + 26 for r in [*big_rows, before_big]) + pad
    sheet = Image.new("RGB", (width, height), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((pad, pad), "Storefronts: after (proposal) against before. Grocer, cafe, pharmacy, sign shop",
           fill=INK, font=font)
    y = pad + 34
    for r in rows:
        d.text((pad, y), "Game scale: 1x rasters on an eight-column facade, 2x nearest", fill=INK, font=small)
        y += 22
        _, y = paste_row(sheet, d, small, pad, y, r, pad)
    y += pad
    d.text((pad, y), "Enlarged: each 64x36 storefront alone, 4x vector render", fill=INK, font=small)
    y += 22
    for r in [*big_rows, before_big]:
        _, y = paste_row(sheet, d, small, pad, y, r, pad)
    sheet.save(out)
    print(out)
    return 0


def main() -> int:
    args = sys.argv[1:]
    if len(args) == 1 and args[0] in ("--help", "-h"):
        print(__doc__)
        return 0
    if len(args) == 3 and args[0] == "doors":
        return doors(Path(args[1]), Path(args[2]))
    if len(args) == 4 and args[0] == "storefronts":
        return storefronts(Path(args[1]), Path(args[2]), Path(args[3]))
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
