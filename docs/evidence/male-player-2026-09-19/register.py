#!/usr/bin/env python3
"""Reproduce the male player's native sprites and family comparisons from saved generation."""

import argparse
import hashlib
import importlib.util
import io
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps
from PIL import __version__ as PILLOW_VERSION

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
POSES = ("a", "c", "b")
DIRECTIONS = ("back", "back_diagonal", "side", "front_diagonal", "front", "front_diagonal", "side", "back_diagonal")
LABELS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rgba(path):
    with Image.open(path) as source:
        return source.convert("RGBA")


def centroid(image):
    alpha = image.getchannel("A")
    limit = min(image.height, round(image.height * 0.68))
    weights = [(x, alpha.getpixel((x, y))) for y in range(limit) for x in range(image.width)]
    return sum((x + 0.5) * a for x, a in weights) / sum(a for _, a in weights)


def config():
    paths = [
        HERE / "raw/pushing.png",
        HERE / "raw/carrying.png",
        HERE / "reference-male-scene.jpeg",
        HERE / "prompt-pushing.txt",
        HERE / "prompt-carrying.txt",
        Path(__file__),
        HERE / "prepare.py",
        HERE / "render-sources.gd",
        ROOT / "tools/remove-checkerboard.py",
        ROOT / "docs/evidence/graphics-reference-urban-01.jpeg",
        ROOT / "docs/evidence/graphics-reference-cardinal.jpeg",
    ]
    paths += sorted((HERE / "inputs").glob("*.png"))
    paths += sorted((ROOT / "assets/rig").glob("father_*.svg"))
    paths += sorted((ROOT / "assets/illustrated/svg-transfer/rig").glob("mother_*.png"))
    paths += sorted((ROOT / "assets/illustrated/svg-transfer/rig").glob("pram_*.png"))
    return {
        "pillow_version": PILLOW_VERSION,
        "inputs": {str(p.relative_to(ROOT)): digest(p) for p in paths},
        "raw_dimensions": {state: list(rgba(HERE / f"raw/{state}.png").size) for state in ("pushing", "carrying")},
        "columns": list(VIEWS),
        "row_edges": {"pushing": [0, 420, 824, 1212], "carrying": [0, 430, 832, 1212]},
        "rows": list(POSES),
        "stature": 45,
        "anchor": "bottom center; horizontal placement uses the female upper-body centroid",
        "scale": "uniform whole-figure; no anatomical splice or SVG alpha stamping",
    }


def build(data, input_paths=None):
    if data["pillow_version"] != PILLOW_VERSION:
        raise ValueError("Pillow version differs from the registration record")
    input_paths = input_paths or {}
    for path, expected in data["inputs"].items():
        source = ROOT / input_paths.get(path, path)
        if digest(source) != expected:
            raise ValueError(f"changed input: {path} ({source.relative_to(ROOT)})")
    module_spec = importlib.util.spec_from_file_location("neutral", ROOT / "tools/remove-checkerboard.py")
    neutral = importlib.util.module_from_spec(module_spec)
    module_spec.loader.exec_module(neutral)
    pictures, measurements, outputs = {}, {}, {}
    for state in ("pushing", "carrying"):
        atlas = rgba(HERE / f"raw/{state}.png")
        if list(atlas.size) != data["raw_dimensions"][state]:
            raise ValueError(f"raw dimensions changed: {state}")
        prefix = "carrying_" if state == "carrying" else ""
        for row, pose in enumerate(POSES):
            for col, view in enumerate(VIEWS):
                name = f"father_{prefix}{view}_{pose}"
                bounds = (
                    round(col * atlas.width / 5),
                    data["row_edges"][state][row],
                    round((col + 1) * atlas.width / 5),
                    data["row_edges"][state][row + 1],
                )
                cell = atlas.crop(bounds)
                extraction = "original alpha"
                if cell.getchannel("A").getextrema() == (255, 255):
                    mask = neutral.neutral_background_mask(cell)
                    alpha = cell.getchannel("A")
                    alpha.putdata([0 if background else a for background, a in zip(mask, alpha.tobytes(), strict=True)])
                    cell.putalpha(alpha)
                    extraction = "authorized neutral-region removal"
                # Sub-visible alpha-1 specks in the generator's empty margins are not a body
                # landmark. Crop around visible ink; retain the original alpha inside it.
                visible = cell.getchannel("A").point(lambda value: 255 if value > 1 else 0).getbbox()
                if visible is None:
                    raise ValueError(f"empty generated cell: {name}")
                figure = cell.crop(visible)
                factor = 45 / figure.height
                native_width = 24 if view in ("front", "back") else 26
                width = round(figure.width * factor * 12)
                if width > native_width * 12:
                    raise ValueError(f"pose too wide at full stature: {name}")
                figure = figure.resize((width, 45 * 12), Image.Resampling.LANCZOS)
                reference = rgba(ROOT / f"assets/illustrated/svg-transfer/rig/mother_{prefix}{view}_{pose}.png")
                x = round(centroid(reference) * 12 - centroid(figure))
                if x < 0 or x + width > native_width * 12:
                    raise ValueError(f"registered silhouette clips: {name}: {x}, {width}")
                high = Image.new("RGBA", (native_width * 12, 46 * 12))
                high.alpha_composite(figure, (x, 12))
                picture = high.resize((native_width, 46), Image.Resampling.LANCZOS)
                pictures[name] = picture
                outputs[f"rig/{name}.png"] = picture
                outputs[f"extracted/{name}.png"] = cell
                measurements[name] = {
                    "cell": bounds,
                    "visible_bounds": visible,
                    "generated_dimensions": cell.size,
                    "extraction": extraction,
                    "scale": factor,
                    "x_at_12x": x,
                    "y_at_12x": 12,
                    "native_dimensions": picture.size,
                    "native_alpha_bounds": picture.getchannel("A").getbbox(),
                }
    for state in ("pushing", "carrying"):
        prefix = "carrying_" if state == "carrying" else ""
        for compare in (False, True):
            cell_width = 76 if compare else 38
            sheet = Image.new("RGBA", (20 + cell_width * 8, 22 + 56 * 3), (100, 114, 120, 255))
            draw = ImageDraw.Draw(sheet)
            for col, label in enumerate(LABELS):
                draw.text((22 + col * cell_width, 1), label, fill="white")
            for row, pose in enumerate(POSES):
                draw.text((2, 36 + row * 56), pose.upper(), fill="white")
                for col, view in enumerate(DIRECTIONS):
                    male = pictures[f"father_{prefix}{view}_{pose}"]
                    members = [male]
                    if compare:
                        members.insert(
                            0, rgba(ROOT / f"assets/illustrated/svg-transfer/rig/mother_{prefix}{view}_{pose}.png")
                        )
                    for offset, member in enumerate(members):
                        if col >= 5:
                            member = ImageOps.mirror(member)
                        sheet.alpha_composite(
                            member, (20 + col * cell_width + offset * 38 + (38 - member.width) // 2, 22 + row * 56)
                        )
            name = f"{state}-{'female-male' if compare else 'male'}"
            outputs[f"{name}-native.png"] = sheet
            outputs[f"{name}-3x.png"] = sheet.resize((sheet.width * 3, sheet.height * 3), Image.Resampling.NEAREST)
    return outputs, measurements


def encoded(image):
    stream = io.BytesIO()
    image.save(stream, format="PNG")
    return stream.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    freeze = sub.add_parser("freeze", help="record current source hashes before registration")
    freeze.add_argument("--config", type=Path, required=True)
    for command in ("register", "verify"):
        child = sub.add_parser(command)
        child.add_argument("--config", type=Path, required=True)
        child.add_argument(
            "--historical-inputs",
            type=Path,
            help="explicit overlay that preserves changed historical input paths",
        )
        child.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    if args.command == "freeze":
        if args.config.exists():
            parser.error("config must be fresh")
        args.config.write_text(json.dumps(config(), indent=2) + "\n")
        return
    data = json.loads(args.config.read_text())
    input_paths = {}
    if args.historical_inputs:
        historical = json.loads(args.historical_inputs.read_text())
        expected_config = historical.get("config_sha256")
        if not isinstance(expected_config, str) or digest(args.config) != expected_config:
            raise ValueError("registration config differs from the historical input record")
        expected_hashes = historical.get("updated_input_hashes")
        if not isinstance(expected_hashes, dict):
            raise ValueError("historical input record omits updated input hashes")
        for path, expected in expected_hashes.items():
            if path not in data["inputs"]:
                raise ValueError(f"historical hash names unknown input: {path}")
            data["inputs"][path] = expected
        input_paths = historical.get("input_paths")
        if not isinstance(input_paths, dict):
            raise ValueError("historical input record omits input paths")
        unknown_paths = set(input_paths) - set(data["inputs"])
        if unknown_paths:
            raise ValueError(f"historical input paths name unknown inputs: {sorted(unknown_paths)}")
    outputs, measurements = build(data, input_paths)
    if args.command == "register":
        if args.output_dir.exists():
            parser.error("output directory must be fresh")
        args.output_dir.mkdir(parents=True)
    for name, picture in outputs.items():
        path = args.output_dir / name
        pixels = encoded(picture)
        if args.command == "register":
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(pixels)
        elif path.read_bytes() != pixels:
            raise ValueError(f"byte mismatch: {name}")
    record = (
        json.dumps(
            {
                "measurements": measurements,
                "outputs": {name: hashlib.sha256(encoded(picture)).hexdigest() for name, picture in outputs.items()},
            },
            indent=2,
        )
        + "\n"
    )
    if args.command == "register":
        (args.output_dir / "manifest.json").write_text(record)
    elif (args.output_dir / "manifest.json").read_text() != record:
        raise ValueError("manifest mismatch")
    print(f"{args.command}: 30 native sprites and complete family comparisons")


if __name__ == "__main__":
    main()
