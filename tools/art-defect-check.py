#!/usr/bin/env python3
"""Names the defects of a rendered picture where they are, and draws them on an overlay.

A rule the svg-art skill states in prose and a tool can check is checked here: a stray single
pixel, a colour outside the family's palette, two colours that are the same colour drawn twice, a
picture clipped by its own canvas, a hole one pixel wide, a checkerboard that was baked into the
pixels. The input is a PNG (render an SVG first with tools/svg-preview.sh, which keeps the raw
render this check reads next to the one with rulers).

Antialiasing is excused by construction: the palette and near-duplicate checks read only *flat*
pixels, those whose four neighbours are exactly their own colour, so the blended edge of a stroke
is never an "off-palette colour".

  tools/art-defect-check.py --overlay-dir out --palette 221f28,6b8f5e sprite@3x.png
  tools/art-defect-check.py --family art/buildings/*.png --scale 3 --tile ground@3x.png

Exit status: 0 clean, 1 defects found, 2 bad usage.
"""

from __future__ import annotations

import argparse
import struct
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OPAQUE = 128
"""Alpha from which a pixel counts as painted."""

KINDS = {
    "stray-pixel": (255, 0, 0),
    "speck": (255, 128, 0),
    "pinhole": (255, 0, 255),
    "off-palette": (0, 200, 255),
    "near-duplicate": (255, 230, 0),
    "edge-clip": (0, 255, 0),
    "gap": (0, 120, 255),
    "checkerboard": (160, 60, 255),
}
"""Every defect kind and the overlay colour of its boxes."""

MAX_LISTED = 12
"""Per file and kind, how many defects are printed and boxed before a count stands for the rest."""


@dataclass(frozen=True)
class Defect:
    kind: str
    x: int
    y: int
    w: int
    h: int
    detail: str


@dataclass(frozen=True)
class Options:
    palette: frozenset[tuple[int, int, int]]
    tolerance: int
    near: int
    min_pixels: int
    speck_delta: int
    tile: bool


Rgb = tuple[int, int, int]


class Picture:
    """An RGBA picture read once: width, height, and one (r, g, b, a) per pixel, row-major."""

    def __init__(self, image: Image.Image) -> None:
        rgba = image.convert("RGBA")
        self.width, self.height = rgba.size
        self.pixels: list[tuple[int, int, int, int]] = list(struct.iter_unpack("4B", rgba.tobytes()))

    def at(self, x: int, y: int) -> tuple[int, int, int, int]:
        return self.pixels[y * self.width + x]

    def painted(self, x: int, y: int) -> bool:
        """True inside the canvas on a pixel that is painted; outside the canvas is not painted."""
        return 0 <= x < self.width and 0 <= y < self.height and self.at(x, y)[3] >= OPAQUE

    def neighbours8(self, x: int, y: int) -> list[tuple[int, int]]:
        return [
            (x + dx, y + dy)
            for dy in (-1, 0, 1)
            for dx in (-1, 0, 1)
            if (dx or dy) and 0 <= x + dx < self.width and 0 <= y + dy < self.height
        ]


def distance(a: Rgb, b: Rgb) -> int:
    """The largest channel difference, so 'within 6' means no channel is off by more than 6."""
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]), abs(a[2] - b[2]))


def rgb_of(pixel: tuple[int, int, int, int]) -> Rgb:
    return pixel[0], pixel[1], pixel[2]


def is_flat(picture: Picture, x: int, y: int) -> bool:
    """A painted pixel whose four neighbours are all exactly its own colour: the inside of a fill."""
    here = picture.at(x, y)
    if here[3] < OPAQUE:
        return False
    for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
        if not (0 <= nx < picture.width and 0 <= ny < picture.height) or picture.at(nx, ny) != here:
            return False
    return True


def flat_colours(picture: Picture) -> dict[Rgb, list[tuple[int, int]]]:
    """Each flat colour, with the coordinates of its flat pixels."""
    found: dict[Rgb, list[tuple[int, int]]] = {}
    for y in range(picture.height):
        for x in range(picture.width):
            if is_flat(picture, x, y):
                found.setdefault(rgb_of(picture.at(x, y)), []).append((x, y))
    return found


def palette_of(pictures: list[Picture], min_pixels: int) -> frozenset[Rgb]:
    """The colours a family of pictures fills with: every flat colour of at least min_pixels."""
    counts: Counter[Rgb] = Counter()
    for picture in pictures:
        for colour, where in flat_colours(picture).items():
            counts[colour] += len(where)
    return frozenset(colour for colour, count in counts.items() if count >= min_pixels)


def find_stray_pixels(picture: Picture) -> list[Defect]:
    """A painted pixel with no painted neighbour among its eight: a speck floating on nothing."""
    found = []
    for y in range(picture.height):
        for x in range(picture.width):
            if picture.painted(x, y) and not any(picture.painted(nx, ny) for nx, ny in picture.neighbours8(x, y)):
                found.append(Defect("stray-pixel", x, y, 1, 1, "a painted pixel with nothing painted around it"))
    return found


def find_specks(picture: Picture, delta: int) -> list[Defect]:
    """A pixel unlike all four neighbours, which agree with each other: a dot inside a flat fill."""
    found = []
    for y in range(1, picture.height - 1):
        for x in range(1, picture.width - 1):
            here = picture.at(x, y)
            around = [picture.at(x - 1, y), picture.at(x + 1, y), picture.at(x, y - 1), picture.at(x, y + 1)]
            if here[3] < OPAQUE or around[0][3] < OPAQUE or any(a != around[0] for a in around):
                continue
            if distance(rgb_of(here), rgb_of(around[0])) > delta:
                found.append(Defect("speck", x, y, 1, 1, f"{hex_of(rgb_of(here))} in flat {hex_of(rgb_of(around[0]))}"))
    return found


def find_pinholes(picture: Picture) -> list[Defect]:
    """A transparent pixel with painted pixels on all eight sides: a hole the fill missed."""
    found = []
    for y in range(1, picture.height - 1):
        for x in range(1, picture.width - 1):
            if picture.at(x, y)[3] < OPAQUE and all(picture.painted(nx, ny) for nx, ny in picture.neighbours8(x, y)):
                found.append(Defect("pinhole", x, y, 1, 1, "a transparent pixel inside painted ones"))
    return found


def box_of(where: list[tuple[int, int]]) -> tuple[int, int, int, int]:
    xs = [x for x, _ in where]
    ys = [y for _, y in where]
    return min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1


def find_off_palette(flat: dict[Rgb, list[tuple[int, int]]], options: Options) -> list[Defect]:
    """A flat colour of at least min_pixels no palette colour is within tolerance of."""
    found = []
    for colour, where in sorted(flat.items(), key=lambda item: -len(item[1])):
        if len(where) < options.min_pixels:
            continue
        nearest = min(distance(colour, p) for p in options.palette)
        if nearest > options.tolerance:
            x, y, w, h = box_of(where)
            found.append(
                Defect("off-palette", x, y, w, h, f"{hex_of(colour)}, {len(where)} flat px, {nearest} off the palette")
            )
    return found


def find_near_duplicates(flat: dict[Rgb, list[tuple[int, int]]], options: Options) -> list[Defect]:
    """Two different flat colours within `near` of each other: boxed where the rarer one is."""
    colours = [c for c, where in flat.items() if len(where) >= options.min_pixels]
    found = []
    for i, a in enumerate(colours):
        for b in colours[i + 1 :]:
            gap = distance(a, b)
            if 0 < gap <= options.near:
                rarer, commoner = (a, b) if len(flat[a]) <= len(flat[b]) else (b, a)
                x, y, w, h = box_of(flat[rarer])
                found.append(
                    Defect(
                        "near-duplicate",
                        x,
                        y,
                        w,
                        h,
                        f"{hex_of(rarer)} ({len(flat[rarer])} px) is {gap} from {hex_of(commoner)}",
                    )
                )
    return found


def find_edge_clips(picture: Picture) -> list[Defect]:
    """Runs of painted pixels on the canvas border: art that the canvas edge cut off."""
    found = []
    last_x, last_y = picture.width - 1, picture.height - 1
    for edge, cells in (
        ("top", [(x, 0) for x in range(picture.width)]),
        ("bottom", [(x, last_y) for x in range(picture.width)]),
        ("left", [(0, y) for y in range(picture.height)]),
        ("right", [(last_x, y) for y in range(picture.height)]),
    ):
        run: list[tuple[int, int]] = []
        for cell in [*cells, None]:
            if cell is not None and picture.painted(*cell):
                run.append(cell)
                continue
            if run:
                x, y, w, h = box_of(run)
                found.append(Defect("edge-clip", x, y, w, h, f"{len(run)} painted pixels on the {edge} edge"))
                run = []
    return found


def find_gaps(picture: Picture) -> list[Defect]:
    """For a tile: every transparent pixel, in runs per row, since a tile keeps its ground fill."""
    found = []
    for y in range(picture.height):
        start = -1
        for x in range(picture.width + 1):
            gap = x < picture.width and picture.at(x, y)[3] < OPAQUE
            if gap and start < 0:
                start = x
            elif not gap and start >= 0:
                found.append(Defect("gap", start, y, x - start, 1, f"{x - start} transparent pixels in a tile"))
                start = -1
    return found


def find_checkerboards(picture: Picture) -> list[Defect]:
    """A 4x4 window of two neutral colours alternating like a checkerboard: a baked-in background."""
    found = []
    for y in range(picture.height - 3):
        for x in range(picture.width - 3):
            if is_checker_window(picture, x, y):
                found.append(Defect("checkerboard", x, y, 4, 4, "two neutral colours alternating"))
    return merge_adjacent(found)


def is_checker_window(picture: Picture, x: int, y: int) -> bool:
    first = picture.at(x, y)
    second = picture.at(x + 1, y)
    if first[3] < OPAQUE or second[3] < OPAQUE or first == second:
        return False
    for colour in (first, second):
        if max(colour[:3]) - min(colour[:3]) > 12:
            return False
    return all(
        picture.at(x + dx, y + dy) == (first if (dx + dy) % 2 == 0 else second) for dy in range(4) for dx in range(4)
    )


def merge_adjacent(defects: list[Defect]) -> list[Defect]:
    """Overlapping or touching boxes of one kind become one box, so a checkerboard is one defect."""
    merged: list[Defect] = []
    for defect in defects:
        for index, other in enumerate(merged):
            if (
                defect.x <= other.x + other.w
                and other.x <= defect.x + defect.w
                and defect.y <= other.y + other.h
                and other.y <= defect.y + defect.h
            ):
                x0, y0 = min(defect.x, other.x), min(defect.y, other.y)
                x1 = max(defect.x + defect.w, other.x + other.w)
                y1 = max(defect.y + defect.h, other.y + other.h)
                merged[index] = Defect(other.kind, x0, y0, x1 - x0, y1 - y0, other.detail)
                break
        else:
            merged.append(defect)
    return merged


def hex_of(colour: Rgb) -> str:
    return "#{:02x}{:02x}{:02x}".format(*colour)


def check(picture: Picture, options: Options) -> list[Defect]:
    """Every defect of one picture, in a fixed order of kinds."""
    defects = find_stray_pixels(picture)
    defects += find_specks(picture, options.speck_delta)
    defects += find_pinholes(picture)
    flat = flat_colours(picture)
    if options.palette:
        defects += find_off_palette(flat, options)
    defects += find_near_duplicates(flat, options)
    defects += find_gaps(picture) if options.tile else find_edge_clips(picture)
    defects += find_checkerboards(picture)
    return defects


def overlay(picture: Picture, shown: list[Defect], zoom: int) -> Image.Image:
    """The picture enlarged over neutral grey with each defect boxed in its kind's colour."""
    base = Image.new("RGBA", (picture.width, picture.height), (128, 128, 128, 255))
    layer = Image.new("RGBA", (picture.width, picture.height))
    layer.putdata(picture.pixels)
    base.alpha_composite(layer)
    big = base.resize((picture.width * zoom, picture.height * zoom), Image.Resampling.NEAREST)
    draw = ImageDraw.Draw(big)
    for defect in shown:
        colour = (*KINDS[defect.kind], 255)
        left, top = defect.x * zoom - 2, defect.y * zoom - 2
        right, bottom = (defect.x + defect.w) * zoom + 1, (defect.y + defect.h) * zoom + 1
        draw.rectangle((left, top, right, bottom), outline=colour, width=2)
    legend = sorted({d.kind for d in shown})
    if legend:
        font = ImageFont.load_default(14)
        strip = Image.new("RGBA", (big.width, 20 * len(legend) + 6), (30, 30, 30, 255))
        strip_draw = ImageDraw.Draw(strip)
        for row, kind in enumerate(legend):
            strip_draw.rectangle((6, 6 + row * 20, 18, 18 + row * 20), fill=(*KINDS[kind], 255))
            strip_draw.text((26, 4 + row * 20), kind, fill=(235, 235, 235, 255), font=font)
        sheet = Image.new("RGBA", (big.width, big.height + strip.height))
        sheet.paste(big, (0, 0))
        sheet.paste(strip, (0, big.height))
        return sheet
    return big


def auto_zoom(picture: Picture) -> int:
    """An integer zoom that brings the longer side to about 512 pixels, between 1 and 16."""
    return max(1, min(16, 512 // max(picture.width, picture.height, 1)))


def describe(defect: Defect, scale: float | None) -> str:
    where = (
        f"{defect.x},{defect.y}" if defect.w == 1 and defect.h == 1 else f"{defect.x},{defect.y} {defect.w}x{defect.h}"
    )
    if scale:
        units = f"{defect.x / scale:g},{defect.y / scale:g}"
        if not (defect.w == 1 and defect.h == 1):
            units += f" {defect.w / scale:g}x{defect.h / scale:g}"
        where += f" (asset units {units})"
    return f"{defect.kind} at {where}: {defect.detail}"


def run(path: Path, options: Options, scale: float | None, overlay_dir: Path | None, zoom: int | None) -> int:
    with Image.open(path) as image:
        picture = Picture(image)
    defects = check(picture, options)
    by_kind: dict[str, list[Defect]] = {}
    for defect in defects:
        by_kind.setdefault(defect.kind, []).append(defect)
    shown: list[Defect] = []
    for kind in KINDS:
        listed = by_kind.get(kind, [])
        for defect in listed[:MAX_LISTED]:
            print(f"{path}: {describe(defect, scale)}")
            shown.append(defect)
        if len(listed) > MAX_LISTED:
            print(f"{path}: {kind}: {len(listed) - MAX_LISTED} more not listed ({len(listed)} in all)")
    if not defects:
        print(f"{path}: clean")
    if overlay_dir is not None and defects:
        overlay_dir.mkdir(parents=True, exist_ok=True)
        destination = overlay_dir / f"{path.stem}-defects.png"
        overlay(picture, shown, zoom or auto_zoom(picture)).save(destination)
        print(f"{path}: overlay {destination}")
    return len(defects)


def parse_palette(text: str) -> frozenset[Rgb]:
    colours = set()
    for word in text.split(","):
        word = word.strip().lstrip("#")
        if len(word) != 6 or any(c not in "0123456789abcdefABCDEF" for c in word):
            raise argparse.ArgumentTypeError(f"not a six-digit hex colour: {word!r}")
        colours.add((int(word[0:2], 16), int(word[2:4], 16), int(word[4:6], 16)))
    return frozenset(colours)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="example: tools/art-defect-check.py --overlay-dir out --palette 221f28,6b8f5e sprite@3x.png",
    )
    parser.add_argument("images", nargs="+", type=Path, help="rendered PNGs to check")
    parser.add_argument("--palette", type=parse_palette, help="comma-separated hex colours the picture may fill with")
    parser.add_argument(
        "--family",
        nargs="+",
        type=Path,
        metavar="PNG",
        help="PNGs whose flat colours are the palette",
    )
    parser.add_argument("--tolerance", type=int, default=12, help="largest channel difference still on-palette (12)")
    parser.add_argument("--near", type=int, default=6, help="largest channel difference of a near-duplicate pair (6)")
    parser.add_argument("--min-pixels", type=int, default=8, help="flat pixels a colour needs to be judged (8)")
    parser.add_argument("--speck-delta", type=int, default=24, help="channel difference that makes a dot a speck (24)")
    parser.add_argument("--tile", action="store_true", help="the picture is a tile: report gaps, not edge clips")
    parser.add_argument("--scale", type=float, help="render scale, to also print coordinates in asset units")
    parser.add_argument("--overlay-dir", type=Path, help="write <name>-defects.png here for each picture with defects")
    parser.add_argument("--zoom", type=int, help="overlay zoom, a whole number (default: about 512 pixels)")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    problems = []
    if args.tolerance < 0 or args.near < 0 or args.min_pixels < 1 or args.speck_delta < 0:
        problems.append("--tolerance, --near, --speck-delta must be >= 0 and --min-pixels >= 1")
    if args.scale is not None and args.scale <= 0:
        problems.append("--scale must be positive")
    if args.zoom is not None and args.zoom < 1:
        problems.append("--zoom must be a whole number >= 1")
    for path in [*args.images, *(args.family or [])]:
        if path.suffix.lower() == ".svg":
            problems.append(f"{path}: render the SVG first with tools/svg-preview.sh and check the PNG")
        elif not path.is_file():
            problems.append(f"{path}: no such file")
    if problems:
        print("\n".join(problems), file=sys.stderr)
        parser.print_usage(sys.stderr)
        return 2
    palette = args.palette or frozenset()
    if args.family:
        pictures = []
        for path in args.family:
            with Image.open(path) as image:
                pictures.append(Picture(image))
        palette = palette | palette_of(pictures, args.min_pixels)
    options = Options(palette, args.tolerance, args.near, args.min_pixels, args.speck_delta, args.tile)
    total = sum(run(path, options, args.scale, args.overlay_dir, args.zoom) for path in args.images)
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
