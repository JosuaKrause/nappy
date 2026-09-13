#!/usr/bin/env python3
"""Reproducibly mirror the diagonal stroller wheel/axle regions in native pixels."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


EXPECTED_SHA256 = "8e09e8447d9f4398d735b91542351b8e754f53903f8b4eb12a8f95800e160611"
DONOR_SHA256 = "11f278b6c7e584d7d4250365ad808c9142e9a65f576ef68ebad7115a50ad5699"
MASKS = ((5, 22, 13, 29), (13, 23, 23, 30), (24, 21, 32, 29))
SCALE = 6


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def donor_masks(image: Image.Image, donor: Image.Image, mirror: bool) -> Image.Image:
    result = image.copy()
    for left, top, right, bottom in MASKS:
        crop = donor.crop((left, top, right, bottom))
        if mirror:
            crop = crop.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        result.paste(crop, (left, top))
    return result


def sheet(before: Image.Image, after: Image.Image, scale: int) -> Image.Image:
    font = ImageFont.load_default()
    gap = 12 * scale
    label_h = 12 * scale
    cell_w = before.width * scale
    cell_h = before.height * scale
    canvas = Image.new("RGBA", (cell_w * 2 + gap, cell_h + label_h), (156, 153, 144, 255))
    for index, (label, image) in enumerate((("before", before), ("after", after))):
        x = index * (cell_w + gap)
        enlarged = image.resize((cell_w, cell_h), Image.Resampling.NEAREST)
        canvas.alpha_composite(enlarged, (x, label_h))
        draw = ImageDraw.Draw(canvas)
        draw.text((x + 2 * scale, 2 * scale), label, fill=(0, 0, 0, 255), font=font)
    return canvas


def direction_sheet(before: Image.Image, after: Image.Image) -> Image.Image:
    font = ImageFont.load_default()
    scale = SCALE
    labels = (("SE before", before), ("SW before", before.transpose(Image.Transpose.FLIP_LEFT_RIGHT)),
              ("SE after", after), ("SW after", after.transpose(Image.Transpose.FLIP_LEFT_RIGHT)))
    cell_w, cell_h = before.width * scale, before.height * scale
    canvas = Image.new("RGBA", (cell_w * 2, (cell_h + 12 * scale) * 2), (156, 153, 144, 255))
    draw = ImageDraw.Draw(canvas)
    for index, (label, image) in enumerate(labels):
        x = (index % 2) * cell_w
        y = (index // 2) * (cell_h + 12 * scale)
        draw.text((x + 2 * scale, y + 2 * scale), label, fill=(0, 0, 0, 255), font=font)
        enlarged = image.resize((cell_w, cell_h), Image.Resampling.NEAREST)
        canvas.alpha_composite(enlarged, (x, y + 12 * scale))
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--donor", type=Path)
    parser.add_argument("--mirror-donor", action="store_true")
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    if sha256(args.input) != EXPECTED_SHA256:
        raise SystemExit("input hash changed; refusing to mirror a different asset")
    before = Image.open(args.input).convert("RGBA")
    if before.size != (36, 30):
        raise SystemExit(f"unexpected native dimensions: {before.size}")
    if not args.donor:
        raise SystemExit("--donor is required for this trial")
    donor = Image.open(args.donor).convert("RGBA")
    if sha256(args.donor) != DONOR_SHA256:
        raise SystemExit("donor hash changed; refusing to use a different asset")
    if donor.size != before.size:
        raise SystemExit(f"donor dimensions differ: {donor.size}")
    if args.output_dir.exists():
        raise SystemExit(f"output already exists: {args.output_dir}")
    args.output_dir.mkdir(parents=True)
    if args.donor:
        after = donor_masks(before, donor, args.mirror_donor)
    after.save(args.output_dir / "pram_front_diagonal.png")
    sheet(before, after, 1).save(args.output_dir / "before-after-native.png")
    sheet(before, after, SCALE).save(args.output_dir / "before-after-6x.png")
    direction_sheet(before, after).save(args.output_dir / "se-sw-before-after-6x.png")
    (args.output_dir / "input.sha256").write_text(f"{EXPECTED_SHA256}  {args.input.name}\n")
    (args.output_dir / "donor.sha256").write_text(f"{DONOR_SHA256}  {args.donor.name}\n")


if __name__ == "__main__":
    main()
