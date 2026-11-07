#!/usr/bin/env python3
"""Puts rulers in asset units around a rendered picture, so a position is read off it, not guessed.

The picture is an SVG rendered at a scale (tools/svg-preview.sh renders it and calls this), so one
asset unit, a user unit of the SVG's own coordinates, is `scale` pixels. The output is the picture
over a neutral flat background (so transparency is readable) inside a margin that carries a ruler
along the top and the left edge: a labelled tick at every nice step, small ticks between, and
with --grid a faint line across the picture at each labelled step. The picture's own pixels are
never covered by a ruler.

  tools/art-rulers.py --scale 3 --grid sprite@3x.png sprite@3x-rulers.png
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

MARGIN_LEFT = 44
MARGIN_TOP = 24
MIN_LABEL_GAP = 36
"""Pixels between two labelled ticks, at the least, so labels never touch."""
STEPS = (1, 2, 5)
INK = (20, 20, 20, 255)
PAPER = (236, 236, 236, 255)


def tick_step(scale: float) -> int:
    """The smallest 1/2/5 x 10^n number of asset units whose ticks are MIN_LABEL_GAP pixels apart."""
    magnitude = 1
    while True:
        for base in STEPS:
            step = base * magnitude
            if step * scale >= MIN_LABEL_GAP:
                return step
        magnitude *= 10


def minor_step(step: int, scale: float) -> int | None:
    """The unit between small ticks, a fifth or a half of the labelled step, or None if too dense."""
    for divisor in (5, 2):
        if step % divisor == 0 and step // divisor * scale >= 6:
            return step // divisor
    return None


def with_rulers(picture: Image.Image, scale: float, background: tuple[int, int, int], grid: bool) -> Image.Image:
    """The ruled sheet: margin, rulers, and the picture composited over the background."""
    width, height = picture.size
    sheet = Image.new("RGBA", (MARGIN_LEFT + width, MARGIN_TOP + height), PAPER)
    ground = Image.new("RGBA", (width, height), (*background, 255))
    ground.alpha_composite(picture.convert("RGBA"))
    sheet.paste(ground, (MARGIN_LEFT, MARGIN_TOP))
    draw = ImageDraw.Draw(sheet, "RGBA")
    font = ImageFont.load_default(11)
    step = tick_step(scale)
    small = minor_step(step, scale)
    for axis, length in (("x", width), ("y", height)):
        units = int(length / scale) + 1
        for unit in range(0, units + 1):
            offset = round(unit * scale)
            if offset > length:
                break
            labelled = unit % step == 0
            if not labelled and not (small and unit % small == 0):
                continue
            size = 10 if labelled else 4
            if axis == "x":
                at = MARGIN_LEFT + offset
                draw.line((at, MARGIN_TOP - size, at, MARGIN_TOP - 1), fill=INK)
                if labelled:
                    draw.text((at + 2, 1), str(unit), fill=INK, font=font)
                    if grid:
                        draw.line((at, MARGIN_TOP, at, MARGIN_TOP + height), fill=(0, 0, 0, 70))
            else:
                at = MARGIN_TOP + offset
                draw.line((MARGIN_LEFT - size, at, MARGIN_LEFT - 1, at), fill=INK)
                if labelled:
                    draw.text((2, at + 1), str(unit), fill=INK, font=font)
                    if grid:
                        draw.line((MARGIN_LEFT, at, MARGIN_LEFT + width, at), fill=(0, 0, 0, 70))
    return sheet


def parse_colour(text: str) -> tuple[int, int, int]:
    word = text.lstrip("#")
    if len(word) != 6 or any(c not in "0123456789abcdefABCDEF" for c in word):
        raise argparse.ArgumentTypeError(f"not a six-digit hex colour: {text!r}")
    return int(word[0:2], 16), int(word[2:4], 16), int(word[4:6], 16)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="example: tools/art-rulers.py --scale 3 --grid sprite@3x.png sprite@3x-rulers.png",
    )
    parser.add_argument("source", type=Path, help="the rendered PNG")
    parser.add_argument("destination", type=Path, help="the PNG to write (a new file; never the source)")
    parser.add_argument("--scale", type=float, required=True, help="pixels per asset unit the picture was rendered at")
    parser.add_argument("--grid", action="store_true", help="a faint line across the picture at each labelled step")
    parser.add_argument(
        "--background", type=parse_colour, default=(138, 138, 138), help="hex colour under transparency"
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    problems = []
    if args.scale <= 0:
        problems.append("--scale must be positive")
    if not args.source.is_file():
        problems.append(f"{args.source}: no such file")
    if args.destination.resolve() == args.source.resolve():
        problems.append("the destination is the source: write the ruled picture to a new file")
    if problems:
        print("\n".join(problems), file=sys.stderr)
        parser.print_usage(sys.stderr)
        return 2
    with Image.open(args.source) as picture:
        sheet = with_rulers(picture, args.scale, args.background, args.grid)
    args.destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(args.destination)
    print(f"{args.destination}: {sheet.width}x{sheet.height}, a tick every {tick_step(args.scale)} units")
    return 0


if __name__ == "__main__":
    sys.exit(main())
