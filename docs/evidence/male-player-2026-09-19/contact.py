#!/usr/bin/env python3
"""Assemble exact native male sprites with the shared stroller in runtime order."""

import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
VIEWS = ("back", "back_diagonal", "side", "front_diagonal", "front", "front_diagonal", "side", "back_diagonal")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registered-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    if args.output_dir.exists():
        parser.error("output must be fresh")
    manifest = json.loads((args.registered_dir / "manifest.json").read_text())
    config = json.loads((HERE / "registration.json").read_text())
    for path, expected in manifest["outputs"].items():
        if hashlib.sha256((args.registered_dir / path).read_bytes()).hexdigest() != expected:
            raise ValueError(f"registered input changed: {path}")
    sheet = Image.new("RGBA", (640, 238), (100, 114, 120, 255))
    draw = ImageDraw.Draw(sheet)
    for row, pose in enumerate(("a", "c", "b")):
        for col, view in enumerate(VIEWS):
            angle = col * math.pi / 4
            x, y = math.sin(angle), -math.cos(angle)
            vertical = 9 if y > 0 else 17
            offset = (x * 24, y * vertical * 0.7 + (8 * x * x * y * y if y < 0 else 0))
            parent = Image.open(args.registered_dir / f"rig/father_{view}_{pose}.png").convert("RGBA")
            pram_path = f"assets/illustrated/svg-transfer/rig/pram_{view}.png"
            if hashlib.sha256((ROOT / pram_path).read_bytes()).hexdigest() != config["inputs"][pram_path]:
                raise ValueError(f"pram input changed: {pram_path}")
            pram = Image.open(ROOT / pram_path).convert("RGBA")
            pram = pram.resize((round(pram.width * 7 / 6), 35), Image.Resampling.BILINEAR)
            if col >= 5:
                parent, pram = ImageOps.mirror(parent), ImageOps.mirror(pram)
            anchor = (col * 80 + 40, row * 74 + 65)
            placed = [
                (parent, (anchor[0] - parent.width // 2, anchor[1] - parent.height)),
                (pram, (round(anchor[0] + offset[0] - pram.width / 2), round(anchor[1] + offset[1] - pram.height))),
            ]
            if y < 0:
                placed.reverse()
            for picture, position in placed:
                sheet.alpha_composite(picture, position)
            draw.text(
                (col * 80 + 3, row * 74 + 3),
                f"{('N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW')[col]} {pose.upper()}",
                fill="white",
            )
    draw.text((3, 225), "Static assembly; placement rounded to pixels. No live-motion claim.", fill="white")
    args.output_dir.mkdir(parents=True)
    sheet.save(args.output_dir / "contact-native.png")
    sheet.resize((1920, 714), Image.Resampling.NEAREST).save(args.output_dir / "contact-3x.png")


if __name__ == "__main__":
    main()
