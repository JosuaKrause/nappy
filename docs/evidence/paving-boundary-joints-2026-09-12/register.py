"""Reproduce reviewed paving joints by copying pixels from immutable material inputs."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import shutil
import subprocess
from pathlib import Path

import PIL
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
NAMES = ("sidewalk", "quiet_square", "plaza", "precinct", "courtyard", "alley", "stoop")
SIDEWALK_REVISION = "62d1c344dccbf77e7cb8052ea09b337a76ce994e"
MATERIAL_REVISION = "c48a544cd11c89946b4216ed61200b5aed8c6668"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_image(data: bytes) -> Image.Image:
    image = Image.open(io.BytesIO(data)).convert("RGBA")
    if image.size != (32, 32) or image.getchannel("A").getextrema() != (255, 255):
        raise ValueError("paving must be opaque and 32 by 32 pixels")
    return image


def pixels(image: Image.Image) -> list[tuple[int, int, int, int]]:
    return [image.getpixel((x, y)) for y in range(32) for x in range(32)]


def freeze(reviewed_dir: Path, output: Path) -> None:
    records = {}
    sources = {}
    for name in NAMES:
        revision = SIDEWALK_REVISION if name == "sidewalk" else MATERIAL_REVISION
        path = f"assets/illustrated/svg-transfer/tiles/{name}.png"
        source = subprocess.check_output(["git", "show", f"{revision}:{path}"], cwd=ROOT)
        svg = (ROOT / f"assets/tiles/{name}.svg").read_bytes()
        reviewed = (reviewed_dir / f"{name}.png").read_bytes()
        source_pixels = pixels(read_image(source))
        target_pixels = pixels(read_image(reviewed))
        palette: dict[tuple[int, int, int, int], list[int]] = {}
        for index, color in enumerate(source_pixels):
            palette.setdefault(color, []).append(index)
        copies = []
        for target, color in enumerate(target_pixels):
            if color == source_pixels[target]:
                continue
            if color not in palette:
                raise ValueError(f"review introduces a color absent from its material: {name}:{target}")
            origin = min(palette[color], key=lambda i: (
                abs(i % 32 - target % 32) + abs(i // 32 - target // 32), i))
            copies.append([target, origin])
        records[name] = {
            "source_revision": revision, "source_path": path,
            "source_sha256": digest(source), "svg_sha256": digest(svg),
            "reviewed_sha256": digest(reviewed), "copies": copies,
        }
        sources[f"{name}.png"] = source
        sources[f"{name}.svg"] = svg
    write_bundle(output, {"tiles": records}, sources)


def validate_inputs(manifest: dict, sources: dict[str, bytes]) -> None:
    for name in NAMES:
        row = manifest["tiles"][name]
        for extension, key in (("png", "source_sha256"), ("svg", "svg_sha256")):
            if digest(sources[f"{name}.{extension}"]) != row[key]:
                raise ValueError(f"frozen source hash mismatch: {name}.{extension}")
        for target, origin in row["copies"]:
            if not (0 <= target < 1024 and 0 <= origin < 1024):
                raise ValueError(f"invalid pixel copy: {name}:{target}:{origin}")


def write_bundle(output: Path, manifest: dict, sources: dict[str, bytes]) -> None:
    if output.exists():
        raise ValueError(f"refusing to replace existing output: {output}")
    validate_inputs(manifest, sources)
    for folder in ("frozen-inputs", "registered", "review"):
        (output / folder).mkdir(parents=True)
    for name, data in sources.items():
        (output / "frozen-inputs" / name).write_bytes(data)
    for name in NAMES:
        row = manifest["tiles"][name]
        source = read_image(sources[f"{name}.png"])
        result = source.copy()
        for target, origin in row["copies"]:
            result.putpixel((target % 32, target // 32), source.getpixel((origin % 32, origin // 32)))
        destination = output / "registered" / f"{name}.png"
        result.save(destination)
        row["registered_sha256"] = digest(destination.read_bytes())
        repeat = Image.new("RGBA", (128, 128))
        for y in range(4):
            for x in range(4):
                repeat.paste(result, (x * 32, y * 32))
        repeat.save(output / "review" / f"{name}-repeat-native.png")
        repeat.resize((512, 512), Image.Resampling.NEAREST).save(
            output / "review" / f"{name}-repeat-4x.png")
    manifest.update({"version": 1, "pillow": PIL.__version__,
                     "script_sha256": digest(Path(__file__).read_bytes()),
                     "method": "immutable-source pixel copies; indices are row-major on a 32x32 canvas"})
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def read_bundle(bundle: Path) -> tuple[dict, dict[str, bytes]]:
    manifest = json.loads((bundle / "manifest.json").read_text())
    if manifest["script_sha256"] != digest(Path(__file__).read_bytes()):
        raise ValueError("bundle belongs to a different registration script")
    sources = {f"{name}.{extension}": (bundle / "frozen-inputs" / f"{name}.{extension}").read_bytes()
               for name in NAMES for extension in ("png", "svg")}
    validate_inputs(manifest, sources)
    return manifest, sources


def verify(bundle: Path, target_dir: Path | None) -> None:
    manifest, _ = read_bundle(bundle)
    for name in NAMES:
        expected = manifest["tiles"][name]["registered_sha256"]
        paths = [bundle / "registered" / f"{name}.png"]
        if target_dir:
            paths.append(target_dir / f"{name}.png")
            if name in ("sidewalk", "alley"):
                paths.append(target_dir / "layers" / f"{name}_base.png")
        for path in paths:
            if digest(path.read_bytes()) != expected:
                raise ValueError(f"registered tile hash mismatch: {path}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    capture = commands.add_parser("freeze", help="record a reviewed pixel-copy registration")
    capture.add_argument("--reviewed-dir", type=Path, required=True)
    capture.add_argument("--output-dir", type=Path, required=True)
    build = commands.add_parser("build", help="rebuild from frozen inputs and recorded pixel copies")
    build.add_argument("--input-bundle", type=Path, required=True)
    build.add_argument("--output-dir", type=Path, required=True)
    check = commands.add_parser("verify", help="verify registered assets and optional runtime targets")
    check.add_argument("--bundle-dir", type=Path, required=True)
    check.add_argument("--target-dir", type=Path)
    args = parser.parse_args()
    if args.command == "freeze":
        freeze(args.reviewed_dir, args.output_dir)
    elif args.command == "build":
        manifest, sources = read_bundle(args.input_bundle)
        write_bundle(args.output_dir, manifest, sources)
    else:
        verify(args.bundle_dir, args.target_dir)


if __name__ == "__main__":
    main()
