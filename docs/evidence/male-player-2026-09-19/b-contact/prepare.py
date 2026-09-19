"""Prepare the four whole-figure B-contact edit targets and SVG pose reference."""

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
VIEWS = ("front", "back", "side", "front_diagonal")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    if args.output_dir.exists():
        parser.error("output directory must be fresh")
    raw = Image.open(HERE.parent / "raw/pushing.png").convert("RGBA")
    target = raw.crop((0, 824, round(raw.width * 4 / 5), 1212))
    source = Image.new("RGBA", (4 * 288, 448), "white")
    inputs = {}
    args.output_dir.mkdir(parents=True)
    for col, view in enumerate(VIEWS):
        name = f"father_{view}_b"
        for scale in (1, 3, 8):
            path = args.source_dir / f"{name}-{scale}x.png"
            pixels = path.read_bytes()
            (args.output_dir / path.name).write_bytes(pixels)
        picture = Image.open(args.source_dir / f"{name}-8x.png").convert("RGBA")
        source.alpha_composite(picture, (col * 288 + (288 - picture.width) // 2, 40))
        path = ROOT / f"assets/rig/{name}.svg"
        inputs[str(path.relative_to(ROOT))] = hashlib.sha256(path.read_bytes()).hexdigest()
    target.save(args.output_dir / "edit-target.png")
    for col, view in enumerate(VIEWS):
        cell = raw.crop((round(col * raw.width / 5), 824, round((col + 1) * raw.width / 5), 1052))
        cell.save(args.output_dir / f"{view}-identity-upper.png")
    source.save(args.output_dir / "svg-targets-8x.png")
    views = ("back", "back_diagonal", "side", "front_diagonal", "front", "front_diagonal", "side", "back_diagonal")
    for scale in (1, 3):
        sheet = Image.new("RGBA", (324 * scale, 190 * scale), (100, 114, 120, 255))
        labels = Image.new("RGBA", (324, 190))
        draw = ImageDraw.Draw(labels)
        for col, label in enumerate(("N", "NE", "E", "SE", "S", "SW", "W", "NW")):
            draw.text((22 + col * 38, 1), label, fill="white")
        for row, pose in enumerate(("a", "c", "b")):
            draw.text((2, 36 + row * 56), pose.upper(), fill="white")
            for col, view in enumerate(views):
                picture = Image.open(args.source_dir / f"father_{view}_{pose}-{scale}x.png").convert("RGBA")
                if col >= 5:
                    picture = ImageOps.mirror(picture)
                sheet.alpha_composite(
                    picture, ((20 + col * 38) * scale + (38 * scale - picture.width) // 2, (22 + row * 56) * scale)
                )
        sheet.alpha_composite(labels.resize(sheet.size, Image.Resampling.NEAREST))
        sheet.save(args.output_dir / f"pushing-source-{scale}x.png")
    (args.output_dir / "sources.json").write_text(json.dumps(inputs, indent=2) + "\n")


if __name__ == "__main__":
    main()
