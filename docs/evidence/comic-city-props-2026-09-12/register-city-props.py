"""Prepare the reviewed comic prop atlases and register their PNG derivatives."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import subprocess
from collections import deque
from pathlib import Path
from typing import Any

from PIL import Image

EVIDENCE = Path(__file__).resolve().parent
ROOT = EVIDENCE.parents[2]
SOURCE_RASTERS = Path("/tmp/nappy-city-props-source")
RASTERIZER = ROOT / "docs/evidence/style-transfer-2026-09-10/rasterize-svg.gd"
NAMES = (
    "tree_a",
    "tree_b",
    "tree_pit",
    "bollard",
    "roof_water_tank",
    "roof_hvac_unit",
    "roof_hvac_unit_b",
    "roof_vent_stack",
    "roof_skylight",
    "roof_skylight_b",
    "roof_duct_straight",
    "roof_duct_corner",
)
ROOF_NAMES = NAMES[4:]
TREE_ATLAS_INDEX = {"tree_a": 0, "tree_b": 1, "bollard": 2}
ROOF_BOXES = (
    (100, 20, 450, 535),
    (570, 100, 1000, 512),
    (1080, 100, 1530, 512),
    (1650, 180, 1990, 535),
    (40, 600, 500, 1024),
    (500, 600, 950, 1024),
    (980, 600, 1600, 1024),
    (1640, 600, 2048, 1024),
)
USAGE = {
    "tree_a": "src/city/prop.gd via Prop.TREES, park/street tree variation",
    "tree_b": "src/city/prop.gd via Prop.TREES, park/street tree variation",
    "tree_pit": "src/city/city_decals.gd via CityDecals, flat street-tree bed",
    "bollard": "src/city/prop.gd via Prop.BOLLARD, precinct mouth decoration",
    "roof_water_tank": "src/city/building.gd via residential/commercial roof furniture",
    "roof_hvac_unit": "src/city/building.gd via industrial roof furniture",
    "roof_hvac_unit_b": "src/city/building.gd via industrial roof furniture variant",
    "roof_vent_stack": "src/city/building.gd via industrial roof furniture",
    "roof_skylight": "src/city/building.gd via civic roof furniture",
    "roof_skylight_b": "src/city/building.gd via civic roof furniture variant",
    "roof_duct_straight": "src/city/building.gd via industrial roof duct run",
    "roof_duct_corner": "src/city/building.gd via industrial roof duct run",
}


def load_module(name: str, path: Path) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def rasterize(svg: Path, destination: Path, scale: int) -> None:
    godot = os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot")
    subprocess.run(
        [
            godot,
            "--headless",
            "--path",
            str(ROOT),
            "--script",
            str(RASTERIZER),
            "--",
            str(svg),
            str(destination),
            str(scale),
        ],
        check=True,
        timeout=30,
    )


def source_manifest(source: Path) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    for name in NAMES:
        svg = ROOT / "assets/props" / f"{name}.svg"
        with Image.open(source / f"{name}-1.png") as native:
            dimensions = list(native.size)
        result.append(
            {
                "svg": f"assets/props/{name}.svg",
                "png": f"assets/illustrated/svg-transfer/props/{name}.png",
                "svg_sha256": hashlib.sha256(svg.read_bytes()).hexdigest(),
                "native_dimensions": dimensions,
                "anchor": (
                    [dimensions[0] // 2, dimensions[1] // 2]
                    if name in ("tree_pit",)
                    else [dimensions[0] // 2, dimensions[1]]
                ),
                "source_center": ([dimensions[0] // 2, dimensions[1] // 2] if name == "bollard" else None),
                "usage": USAGE[name],
                "review_evidence": [
                    "docs/evidence/comic-city-props-2026-09-12/comparisons/props-native.png",
                    "docs/evidence/comic-city-props-2026-09-12/comparisons/props-4x.png",
                ],
            }
        )
    return result


def prepare(source: Path) -> None:
    if source.exists():
        raise FileExistsError(source)
    source.mkdir(parents=True)
    for name in NAMES:
        svg = ROOT / "assets/props" / f"{name}.svg"
        rasterize(svg, source / f"{name}-1.png", 1)
        rasterize(svg, source / f"{name}-8.png", 8)
    (source / "source-manifest.json").write_text(json.dumps(source_manifest(source), indent=2) + "\n")


def extend_colors(image: Image.Image) -> Image.Image:
    pixels = list(image.convert("RGBA").get_flattened_data())
    width, height = image.size
    seen = bytearray(int(pixel[3] > 0) for pixel in pixels)
    pending = deque(index for index, value in enumerate(seen) if value)
    assert pending, "empty generated subject"
    while pending:
        index = pending.popleft()
        x, y = index % width, index // width
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height:
                other = ny * width + nx
                if not seen[other]:
                    seen[other] = 1
                    pixels[other] = pixels[index]
                    pending.append(other)
    rgb = Image.new("RGB", image.size)
    rgb.putdata([pixel[:3] for pixel in pixels])
    return rgb


def register(output: Path, generated: Path, trees_generated: Path, pit_generated: Path) -> None:
    if output.exists():
        raise FileExistsError(output)
    output.mkdir(parents=True)
    source = output / "source"
    prepare(source)
    checker = load_module("checker", ROOT / "tools/remove-checkerboard.py")
    cleaned = output / "registration" / "atlas-clean.png"
    cleaned.parent.mkdir()
    checker.extract(generated, cleaned)
    roof = Image.open(cleaned).convert("RGBA").resize((2048, 1024), Image.Resampling.LANCZOS)
    trees = Image.open(EVIDENCE / "raw/trees.png").convert("RGBA")
    tree_clean = output / "registration" / "trees-clean.png"
    checker.extract(trees_generated, tree_clean)
    trees = Image.open(tree_clean).convert("RGBA").resize((1536, 512), Image.Resampling.LANCZOS)
    pit = Image.open(pit_generated).convert("RGBA").resize((32, 32), Image.Resampling.LANCZOS)
    runtime = ROOT / "assets/illustrated/svg-transfer/props"
    runtime.mkdir(parents=True, exist_ok=True)
    (output / "comparisons").mkdir(exist_ok=True)
    measurements: list[dict[str, Any]] = []
    for name in NAMES:
        native = Image.open(source / f"{name}-1.png").convert("RGBA")
        template = Image.open(source / f"{name}-8.png").convert("RGBA")
        if name == "tree_pit":
            final = pit
            alpha_bounds = final.getchannel("A").getbbox()
        else:
            if name in ("tree_a", "tree_b", "bollard"):
                cell_width = 512
                tree_index = TREE_ATLAS_INDEX[name]
                cell = trees.crop((tree_index * cell_width, 0, (tree_index + 1) * cell_width, 512))
                crop_box = (tree_index * cell_width, 0, (tree_index + 1) * cell_width, 512)
            else:
                roof_index = ROOF_NAMES.index(name)
                crop_box = ROOF_BOXES[roof_index]
                cell = roof.crop(crop_box)
            bounds = cell.getchannel("A").point(lambda alpha: 255 if alpha > 192 else 0).getbbox()
            target = template.getchannel("A").point(lambda alpha: 255 if alpha > 192 else 0).getbbox()
            assert bounds and target, (name, bounds, target)
            subject = cell.crop(bounds)
            target_size = (target[2] - target[0], target[3] - target[1])
            if name in ("tree_a", "tree_b"):
                scale = target_size[1] / subject.height
                fit_width = min(round(subject.width * scale), template.width)
                fit = subject.resize((fit_width, target_size[1]), Image.Resampling.LANCZOS)
            else:
                height_scale = target_size[1] / subject.height
                width_scale = target_size[0] / subject.width
                scale = height_scale if subject.width * height_scale <= template.width else width_scale
                fit = subject.resize(
                    (max(1, round(subject.width * scale)), max(1, round(subject.height * scale))),
                    Image.Resampling.LANCZOS,
                )
            filled = extend_colors(fit).convert("RGBA")
            filled.putalpha(fit.getchannel("A"))
            canvas = Image.new("RGBA", template.size, (0, 0, 0, 0))
            x = (template.width - filled.width) // 2
            y = target[3] - filled.height
            canvas.alpha_composite(filled, (x, y))
            final = extend_colors(canvas).resize(native.size, Image.Resampling.LANCZOS)
            final.putalpha(canvas.getchannel("A").resize(native.size, Image.Resampling.LANCZOS))
            alpha_bounds = final.getchannel("A").point(lambda alpha: 255 if alpha > 2 else 0).getbbox()
            measurements.append(
                {
                    "name": name,
                    "atlas_crop": crop_box,
                    "generated_bounds_8x": bounds,
                    "source_bounds_8x": target,
                    "fit_size_8x": list(fit.size),
                    "placement_8x": [x, y],
                    "alpha_bounds_native": alpha_bounds,
                    "true_alpha_preserved": True,
                }
            )
        assert final.size == native.size and final.getchannel("A").getbbox()
        final.save(runtime / f"{name}.png")
        enlarged = final.resize((native.width * 4, native.height * 4), Image.Resampling.NEAREST)
        enlarged.save(output / "comparisons" / f"{name}-4x.png")
    _sheet(output / "comparisons", source)
    (output / "registration" / "manifest.json").write_text(json.dumps(measurements, indent=2) + "\n")
    (output / "source" / "source-manifest.json").write_text(json.dumps(source_manifest(source), indent=2) + "\n")


def _sheet(directory: Path, source: Path) -> None:
    sheet = Image.new("RGBA", (768, 384), "#68767c")
    for index, name in enumerate(NAMES):
        x, y = index % 4 * 192, index // 4 * 128
        native = Image.open(source / f"{name}-1.png").convert("RGBA")
        registered = Image.open(ROOT / "assets/illustrated/svg-transfer/props" / f"{name}.png").convert("RGBA")
        for column, image in enumerate((native, registered)):
            scale = min(80 / image.width, 92 / image.height)
            shown = image.resize(
                (max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.NEAREST
            )
            sheet.alpha_composite(shown, (x + column * 92 + (92 - shown.width) // 2, y + 112 - shown.height))
    sheet.save(directory / "props-native.png")
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.Resampling.NEAREST).save(directory / "props-4x.png")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("generated", type=Path, help="clean roof atlas")
    parser.add_argument("trees_generated", type=Path, help="clean tree atlas")
    parser.add_argument("pit_generated", type=Path, help="tree pit tile")
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    register(
        args.output.resolve(), args.generated.resolve(), args.trees_generated.resolve(), args.pit_generated.resolve()
    )


if __name__ == "__main__":
    main()
