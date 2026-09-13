"""Flip the side canopy while preserving the handle, chassis and wheel pixels."""

import argparse
import hashlib
import json
from pathlib import Path

import PIL
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
BOX = (11, 0, 33, 16)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    if args.output_dir.exists():
        parser.error("output directory must be fresh")
    source = HERE / "inputs/pram_side.png"
    svg = HERE / "inputs/pram_side.svg"
    expected = json.loads((HERE / "inputs/hashes.json").read_text())
    for path in (source, svg):
        if sha(path) != expected[path.name]:
            raise ValueError(f"input hash mismatch: {path}")
    original = Image.open(source).convert("RGBA")
    assert original.size == (36, 30)
    corrected = original.copy()
    corrected.paste(original.crop(BOX).transpose(Image.Transpose.FLIP_LEFT_RIGHT), BOX[:2])
    for y in range(30):
        for x in range(36):
            if not (BOX[0] <= x < BOX[2] and BOX[1] <= y < BOX[3]):
                assert original.getpixel((x, y)) == corrected.getpixel((x, y))
    args.output_dir.mkdir(parents=True)
    target = args.output_dir / "pram_side.png"
    corrected.save(target)
    review = Image.new("RGB", (36 * 12 * 2, 30 * 12 * 2 + 48), "#99958b")
    draw = ImageDraw.Draw(review)
    for row, (label, texture) in enumerate((("Source", original), ("Canopy corrected", corrected))):
        for col in range(2):
            sprite = texture if col == 0 else texture.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            sprite = sprite.resize((432, 360), Image.Resampling.NEAREST)
            review.paste(sprite, (col * 432, row * 384 + 24), sprite)
            draw.text((col * 432 + 10, row * 384 + 5), f"{label} - {'E' if col == 0 else 'W'}", fill="black")
    review.save(args.output_dir / "side-review-12x.png")
    (args.output_dir / "manifest.json").write_text(json.dumps({
        "inputs": expected, "script_sha256": sha(Path(__file__)),
        "pillow": PIL.__version__, "horizontal_flip_box_exclusive": BOX,
        "output_sha256": sha(target), "west": "mirror complete corrected east texture",
        "review": "static texture comparison; nearest-neighbor 12x; Pillow default font",
    }, indent=2) + "\n")


if __name__ == "__main__":
    main()
