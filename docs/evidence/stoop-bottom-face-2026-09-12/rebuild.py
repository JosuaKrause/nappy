"""Append the selected stoop step-face row and compress the tile back to 32px."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path

import PIL
from PIL import Image

NAMES = ("sidewalk", "quiet_square", "plaza", "precinct", "courtyard", "alley", "stoop")
STOOP_BAND = (19, 25)
SIZE = (32, 32)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def tile(data: bytes) -> Image.Image:
    image = Image.open(io.BytesIO(data)).convert("RGBA")
    if image.size != SIZE or image.getchannel("A").getextrema() != (255, 255):
        raise ValueError("stoop must be opaque and 32 by 32 pixels")
    return image


def registered_source(bundle: Path) -> bytes:
    manifest = json.loads((bundle / "manifest.json").read_text())
    source = (bundle / "registered" / "stoop.png").read_bytes()
    if digest(source) != manifest["tiles"]["stoop"]["registered_sha256"]:
        raise ValueError("registered stoop source hash mismatch")
    return source


def refine(source: Image.Image) -> Image.Image:
    strip = source.crop((0, STOOP_BAND[0], 32, STOOP_BAND[1]))
    extended = Image.new("RGBA", (32, 32 + STOOP_BAND[1] - STOOP_BAND[0]))
    extended.paste(source, (0, 0))
    extended.paste(strip, (0, 32))
    return extended.resize(SIZE, Image.Resampling.NEAREST)


def build(bundle: Path, output: Path) -> None:
    if output.exists():
        raise ValueError(f"refusing to replace existing output: {output}")
    source_bytes = registered_source(bundle)
    result = refine(tile(source_bytes))
    output.mkdir(parents=True)
    (output / "stoop.png").write_bytes(_png_bytes(result))
    before = tile(source_bytes).resize((320, 320), Image.Resampling.NEAREST)
    after = result.resize((320, 320), Image.Resampling.NEAREST)
    before.save(output / "stoop-before-10x.png")
    after.save(output / "stoop-after-10x.png")
    metadata = {
        "source": "docs/evidence/paving-boundary-joints-2026-09-12/bundle/registered/stoop.png",
        "source_sha256": digest(source_bytes),
        "strip_bounds": [0, STOOP_BAND[0], 32, STOOP_BAND[1]],
        "append_bounds": [0, 32, 32, 32 + STOOP_BAND[1] - STOOP_BAND[0]],
        "resampling": "Pillow Image.Resampling.NEAREST, 32x38 to 32x32",
        "script_sha256": digest(Path(__file__).read_bytes()),
        "pillow": PIL.__version__,
        "output_sha256": digest((output / "stoop.png").read_bytes()),
    }
    (output / "recipe.json").write_text(json.dumps(metadata, indent=2) + "\n")


def _png_bytes(image: Image.Image) -> bytes:
    stream = io.BytesIO()
    image.save(stream, format="PNG")
    return stream.getvalue()


def verify(bundle: Path, target: Path) -> None:
    manifest = json.loads((bundle / "manifest.json").read_text())
    for name in NAMES[:-1]:
        expected = manifest["tiles"][name]["registered_sha256"]
        path = target / f"{name}.png"
        if digest(path.read_bytes()) != expected:
            raise ValueError(f"registered tile hash mismatch: {path}")
    for name in ("sidewalk", "alley"):
        expected = manifest["tiles"][name]["registered_sha256"]
        path = target / "layers" / f"{name}_base.png"
        if digest(path.read_bytes()) != expected:
            raise ValueError(f"registered layer base hash mismatch: {path}")
    expected_stoop = refine(tile(registered_source(bundle)))
    path = target / "stoop.png"
    if path.read_bytes() != _png_bytes(expected_stoop):
        raise ValueError(f"refined stoop pixels mismatch: {path}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    build_parser = commands.add_parser("build", help="rebuild the refined stoop and review stills")
    build_parser.add_argument("--input-bundle", type=Path, required=True)
    build_parser.add_argument("--output-dir", type=Path, required=True)
    verify_parser = commands.add_parser("verify", help="verify runtime paving assets against frozen inputs")
    verify_parser.add_argument("--bundle-dir", type=Path, required=True)
    verify_parser.add_argument("--target-dir", type=Path, required=True)
    args = parser.parse_args()
    if args.command == "build":
        build(args.input_bundle, args.output_dir)
    else:
        verify(args.bundle_dir, args.target_dir)


if __name__ == "__main__":
    main()
