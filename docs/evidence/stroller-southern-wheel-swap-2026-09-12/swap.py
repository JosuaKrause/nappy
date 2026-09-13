#!/usr/bin/env python3
"""Reproducibly exchange the SE stroller's wheel assembly with its displayed SW mirror."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


EXPECTED_SHA256 = "adb38bc65fd1b3850ec7e45847e0224a9bf26700b4afa899531b362378db322d"
MASKS = ((5, 22, 13, 29), (13, 23, 23, 30), (24, 21, 32, 29))
SCALE = 6


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def reflected_masks(width: int) -> tuple[tuple[int, int, int, int], ...]:
    """Return the original footprints plus their canvas-center reflections."""
    reflected = tuple((width - right, top, width - left, bottom) for left, top, right, bottom in MASKS)
    return tuple(dict.fromkeys(MASKS + reflected))


def swap_wheel_assembly(image: Image.Image) -> Image.Image:
    """Reflect the complete masked assembly in one simultaneous RGBA pixel assignment."""
    masks = reflected_masks(image.width)
    mask = Image.new("1", image.size, 0)
    draw = ImageDraw.Draw(mask)
    for bounds in masks:
        left, top, right, bottom = bounds
        draw.rectangle((left, top, right - 1, bottom - 1), fill=1)
    source = image.load()
    result = image.copy()
    target = result.load()
    for y in range(image.height):
        for x in range(image.width):
            if mask.getpixel((x, y)):
                target[x, y] = source[image.width - 1 - x, y]
    for y in range(image.height):
        for x in range(image.width):
            expected = source[image.width - 1 - x, y] if mask.getpixel((x, y)) else source[x, y]
            if target[x, y] != expected:
                raise SystemExit("pixel guard failed; refusing an incomplete wheel swap")
    return result


def labeled_sheet(images: tuple[tuple[str, Image.Image], ...], scale: int) -> Image.Image:
    font = ImageFont.load_default()
    gap = 12 * scale
    label_h = 12 * scale
    cell_w = images[0][1].width * scale
    cell_h = images[0][1].height * scale
    cols = 2
    rows = (len(images) + cols - 1) // cols
    canvas = Image.new("RGBA", (cell_w * cols + gap, (cell_h + label_h) * rows), (156, 153, 144, 255))
    draw = ImageDraw.Draw(canvas)
    for index, (label, image) in enumerate(images):
        x = (index % cols) * (cell_w + gap)
        y = (index // cols) * (cell_h + label_h)
        draw.text((x + 2 * scale, y + 2 * scale), label, fill=(0, 0, 0, 255), font=font)
        enlarged = image.resize((cell_w, cell_h), Image.Resampling.NEAREST)
        canvas.alpha_composite(enlarged, (x, y + label_h))
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="frozen SE source PNG")
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    if sha256(args.input) != EXPECTED_SHA256:
        raise SystemExit("input hash changed; refusing to transform a different asset")
    before = Image.open(args.input).convert("RGBA")
    if before.size != (36, 30):
        raise SystemExit(f"unexpected native dimensions: {before.size}")
    if args.output_dir.exists():
        raise SystemExit(f"output already exists: {args.output_dir}")
    args.output_dir.mkdir(parents=True)
    after = swap_wheel_assembly(before)
    after.save(args.output_dir / "pram_front_diagonal.png")
    labeled_sheet((("SE before", before), ("SW before", before.transpose(Image.Transpose.FLIP_LEFT_RIGHT)),
                   ("SE after", after), ("SW after", after.transpose(Image.Transpose.FLIP_LEFT_RIGHT))), 1).save(
        args.output_dir / "se-sw-before-after-native.png")
    labeled_sheet((("SE before", before), ("SW before", before.transpose(Image.Transpose.FLIP_LEFT_RIGHT)),
                   ("SE after", after), ("SW after", after.transpose(Image.Transpose.FLIP_LEFT_RIGHT))), SCALE).save(
        args.output_dir / "se-sw-before-after-6x.png")
    (args.output_dir / "input.sha256").write_text(f"{EXPECTED_SHA256}  {args.input.name}\n")


if __name__ == "__main__":
    main()
