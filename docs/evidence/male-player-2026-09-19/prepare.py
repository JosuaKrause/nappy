#!/usr/bin/env python3
"""Assemble SVG generation targets and frozen female style/registration references."""

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
POSES = ("a", "c", "b")
ROOT = Path(__file__).resolve().parents[3]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--render-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    if args.output_dir.exists():
        parser.error("output directory must be fresh")
    inputs = {}
    sheets = {}
    for state in ("", "carrying_"):
        for kind in ("source", "female"):
            for scale in (1, 3, 8):
                sheet = Image.new("RGBA", (180 * scale, 168 * scale), "white")
                for row, pose in enumerate(POSES):
                    for col, view in enumerate(VIEWS):
                        name = f"{state}{view}_{pose}"
                        path = (
                            args.render_dir / f"father_{name}-{scale}x.png"
                            if kind == "source"
                            else ROOT / "assets/illustrated/svg-transfer/rig" / f"mother_{name}.png"
                        )
                        inputs[str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path)] = (
                            hashlib.sha256(path.read_bytes()).hexdigest()
                        )
                        with Image.open(path) as source:
                            picture = source.convert("RGBA")
                        if kind == "female":
                            picture = picture.resize(
                                (picture.width * scale, picture.height * scale), Image.Resampling.NEAREST
                            )
                        sheet.alpha_composite(
                            picture,
                            (col * 36 * scale + (36 * scale - picture.width) // 2, row * 56 * scale + 5 * scale),
                        )
                sheets[f"{state or 'pushing_'}{kind}-{scale}x.png"] = sheet
    args.output_dir.mkdir(parents=True)
    for name, sheet in sheets.items():
        sheet.save(args.output_dir / name)
    (args.output_dir / "inputs.json").write_text(json.dumps(inputs, indent=2) + "\n")


if __name__ == "__main__":
    main()
