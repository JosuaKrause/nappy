"""Reproduce the stroller view assignment from immutable illustrated inputs."""

import argparse
import hashlib
import json
from pathlib import Path

import PIL
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ASSIGNMENTS = {
    "pram_side": ("pram_side", False),
    "pram_front": ("pram_back", False),
    "pram_back": ("pram_front", False),
    "pram_front_diagonal": ("pram_back_diagonal", True),
    "pram_back_diagonal": ("pram_front_diagonal", True),
}
# Runtime selection: front is south, back is north; west views mirror east-authored slots.
VIEWS = (
    ("N", "pram_back", False), ("NE", "pram_back_diagonal", False),
    ("E", "pram_side", False), ("SE", "pram_front_diagonal", False),
    ("S", "pram_front", False), ("SW", "pram_front_diagonal", True),
    ("W", "pram_side", True), ("NW", "pram_back_diagonal", True),
)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def panel(textures: dict[str, Image.Image]) -> Image.Image:
    result = Image.new("RGBA", (192, 96), "#99958b")
    draw = ImageDraw.Draw(result)
    for index, (direction, name, mirrored) in enumerate(VIEWS):
        texture = textures[name]
        if mirrored:
            texture = texture.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        x, y = index % 4 * 48, index // 4 * 48
        draw.text((x + 4, y + 2), direction, fill="black")
        result.alpha_composite(texture, (x + (48 - texture.width) // 2, y + 16))
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    if args.output_dir.exists():
        parser.error("output directory must be fresh")
    inputs = HERE / "inputs"
    authority = json.loads((inputs / "manifest.json").read_text())
    for name, expected in authority["files"].items():
        if digest(inputs / name) != expected:
            raise ValueError(f"frozen input hash mismatch: {name}")
    originals = {name: Image.open(inputs / f"{name}.png").convert("RGBA") for name in ASSIGNMENTS}
    for name, texture in originals.items():
        expected_size = (30, 30) if name in ("pram_front", "pram_back") else (36, 30)
        assert texture.size == expected_size, (name, texture.size)
    args.output_dir.mkdir(parents=True)
    registered = args.output_dir / "registered"
    registered.mkdir()
    textures = {}
    records = {}
    for target, (source, mirrored) in ASSIGNMENTS.items():
        texture = originals[source]
        path = registered / f"{target}.png"
        if mirrored:
            texture = texture.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            texture.save(path)
        else:
            path.write_bytes((inputs / f"{source}.png").read_bytes())
        textures[target] = texture
        records[target] = {"source": source, "horizontal_mirror": mirrored, "sha256": digest(path)}
    for label, family in (("source-assignment", originals), ("runtime-assignment", textures)):
        sheet = panel(family)
        sheet.save(args.output_dir / f"{label}-native.png")
        sheet.resize((1152, 576), Image.Resampling.NEAREST).save(args.output_dir / f"{label}-6x.png")
    (args.output_dir / "manifest.json").write_text(json.dumps({
        "inputs": authority, "script_sha256": digest(Path(__file__)), "pillow": PIL.__version__,
        "assignments": records, "review": "N NE E SE / S SW W NW; native and nearest-neighbor 6x; Pillow default font",
        "preserved": "native dimensions, RGBA pixels, bottom-center anchors, side-view bytes",
    }, indent=2) + "\n")


if __name__ == "__main__":
    main()
