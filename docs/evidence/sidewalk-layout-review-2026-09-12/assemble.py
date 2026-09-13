"""Capture and render actual-map sidewalk layout review evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
import platform
import shutil
import subprocess
from pathlib import Path
from typing import Any, Final, cast

from PIL import Image, ImageDraw, ImageFont
from PIL import __version__ as pillow_version

HERE: Final = Path(__file__).resolve().parent
ROOT: Final = HERE.parents[2]
SCENE: Final = HERE / "layout_capture.tscn"
GODOT: Final = Path("/Applications/Godot.app/Contents/MacOS/Godot")
TILE_SIZE: Final = 32
SCALE: Final = 4
BACKGROUND: Final = (37, 43, 47, 255)
GROUND_ABSENT: Final = (27, 31, 34, 255)
TEXT: Final = (245, 241, 228, 255)
CORE_INPUTS: Final = (
    "project.godot",
    "assets/ground_tileset.tres",
    "src/autoload/tuning.gd",
    "src/game_enums.gd",
    "src/city/city.gd",
    "src/city/city_generator.gd",
    "src/city/city_map.gd",
    "src/city/city_state.gd",
    "src/city/ground_tiles.gd",
    "src/visuals/texture_resolver.gd",
    "docs/evidence/sidewalk-layout-review-2026-09-12/layout_capture.gd",
    "docs/evidence/sidewalk-layout-review-2026-09-12/layout_capture.tscn",
    "docs/evidence/sidewalk-layout-review-2026-09-12/assemble.py",
)


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _fresh(path: Path) -> None:
    if path.exists():
        raise FileExistsError(f"refusing to overwrite existing output: {path}")


def _manifest(path: Path) -> dict[str, Any]:
    return cast(dict[str, Any], json.loads((path / "manifest.json").read_text()))


def _preflight(authority_dir: Path) -> None:
    authority = _manifest(authority_dir)
    if authority["python_version"] != platform.python_version():
        raise ValueError("Python version differs from retained authority")
    if authority["pillow_version"] != pillow_version:
        raise ValueError("Pillow version differs from retained authority")
    godot = subprocess.run([str(GODOT), "--version"], check=True, capture_output=True, text=True).stdout.strip()
    if authority["godot_version"] != godot:
        raise ValueError("Godot version differs from retained authority")
    for relative, expected in authority["core_inputs"].items():
        if _sha256(ROOT / relative) != expected:
            raise ValueError(f"core input differs from retained authority: {relative}")
    for record in authority["tile_inputs"].values():
        relative = record["resolved_path"].removeprefix("res://")
        if _sha256(ROOT / relative) != record["sha256"]:
            raise ValueError(f"tile input differs from retained authority: {relative}")


def _capture(destination: Path) -> None:
    subprocess.run(
        [
            str(GODOT),
            "--headless",
            "--path",
            str(ROOT),
            str(SCENE),
            "--",
            "--output",
            str(destination),
        ],
        check=True,
        timeout=60,
    )


def _tile_records(layout: dict[str, Any]) -> dict[str, dict[str, Any]]:
    used = {
        source_id for crop in layout["layouts"] for row in crop["source_ids"] for source_id in row if source_id >= 0
    }
    return {str(source_id): layout["sources"][str(source_id)] for source_id in sorted(used)}


def _freeze_tiles(output_dir: Path, layout: dict[str, Any], authority_dir: Path) -> dict[str, dict[str, Any]]:
    tile_dir = output_dir / "inputs" / "tiles"
    tile_dir.mkdir(parents=True)
    result: dict[str, dict[str, Any]] = {}
    authority = _manifest(authority_dir)
    for source_id, record in _tile_records(layout).items():
        live = ROOT / record["resolved_path"].removeprefix("res://")
        name = f"{int(source_id):02d}-{live.name}"
        frozen_relative = f"inputs/tiles/{name}"
        source = authority_dir / frozen_relative
        destination = output_dir / frozen_relative
        shutil.copyfile(source, destination)
        result[source_id] = {
            **record,
            "sha256": _sha256(live),
            "frozen_path": frozen_relative,
        }
        if result[source_id] != authority["tile_inputs"][source_id]:
            raise ValueError(f"tile record differs from retained authority: source {source_id}")
    return result


def _render_crop(crop: dict[str, Any], tile_inputs: dict[str, dict[str, Any]], output_dir: Path) -> Image.Image:
    width, height = crop["rect"][2:]
    image = Image.new("RGBA", (width * TILE_SIZE, height * TILE_SIZE), GROUND_ABSENT)
    for y, row in enumerate(crop["source_ids"]):
        for x, source_id in enumerate(row):
            if source_id < 0:
                continue
            tile = Image.open(output_dir / tile_inputs[str(source_id)]["frozen_path"]).convert("RGBA")
            if tile.size != (TILE_SIZE, TILE_SIZE):
                raise ValueError(f"source {source_id} is not a 32x32 tile")
            image.alpha_composite(tile, (x * TILE_SIZE, y * TILE_SIZE))
    return image


def _sheet(day: int, crops: dict[str, Image.Image]) -> Image.Image:
    sheet = Image.new("RGBA", (920, 1010), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    draw.text((16, 12), f"Seed 4242 · day {day} · actual GroundTiles + TextureResolver", fill=TEXT, font=font)
    draw.text(
        (16, 28), "Dark cells: no ground tile (building-covered). Labels stay outside tile areas.", fill=TEXT, font=font
    )
    placements = {
        "normal_junction": (16, 72),
        "main_junction": (420, 72),
        "normal_vertical_run": (16, 510),
        "main_vertical_run": (240, 510),
        "normal_horizontal_run": (456, 510),
    }
    labels = {
        "normal_junction": "normal junction · 12x12 · block corners",
        "main_junction": "main junction · 12x12 · block corners",
        "normal_vertical_run": "normal vertical · 6x14",
        "main_vertical_run": "main vertical · 6x14",
        "normal_horizontal_run": "normal horizontal · 14x6",
    }
    for name, at in placements.items():
        draw.text((at[0], at[1] - 18), labels[name], fill=TEXT, font=font)
        sheet.alpha_composite(crops[name], at)
    return sheet


def build(output_dir: Path, authority_dir: Path) -> None:
    _preflight(authority_dir)
    _fresh(output_dir)
    output_dir.mkdir(parents=True)
    layout_path = output_dir / "layout.json"
    _capture(layout_path)
    if layout_path.read_bytes() != (authority_dir / "layout.json").read_bytes():
        raise ValueError("actual game layout differs from retained authority")
    layout = cast(dict[str, Any], json.loads(layout_path.read_text()))
    tile_inputs = _freeze_tiles(output_dir, layout, authority_dir)
    crop_root = output_dir / "crops"
    crop_root.mkdir()
    outputs: dict[str, str] = {"layout.json": _sha256(layout_path)}
    for day in layout["days"]:
        day_dir = crop_root / f"day-{day:02d}"
        day_dir.mkdir()
        crops: dict[str, Image.Image] = {}
        for record in layout["layouts"]:
            if record["day"] != day:
                continue
            image = _render_crop(record, tile_inputs, output_dir)
            path = day_dir / f"{record['name']}.png"
            image.save(path)
            crops[record["name"]] = image
            outputs[str(path.relative_to(output_dir))] = _sha256(path)
        native = output_dir / f"day-{day:02d}-actual-layout-native.png"
        enlarged = output_dir / f"day-{day:02d}-actual-layout-4x.png"
        sheet = _sheet(day, crops)
        sheet.save(native)
        sheet.resize((sheet.width * SCALE, sheet.height * SCALE), Image.Resampling.NEAREST).save(enlarged)
        outputs[str(native.relative_to(output_dir))] = _sha256(native)
        outputs[str(enlarged.relative_to(output_dir))] = _sha256(enlarged)
    godot = subprocess.run([str(GODOT), "--version"], check=True, capture_output=True, text=True).stdout.strip()
    manifest = {
        "python_version": platform.python_version(),
        "pillow_version": pillow_version,
        "godot_version": godot,
        "font": "Pillow ImageFont.load_default()",
        "scale": SCALE,
        "core_inputs": {relative: _sha256(ROOT / relative) for relative in CORE_INPUTS},
        "tile_inputs": tile_inputs,
        "outputs": outputs,
    }
    manifest_path = output_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    if manifest_path.read_bytes() != (authority_dir / "manifest.json").read_bytes():
        raise ValueError("rebuilt manifest differs from retained authority")


def verify(rebuilt_dir: Path, compare_to: Path) -> None:
    authority = _manifest(compare_to)
    expected = {Path(relative) for relative in authority["outputs"]}
    expected.update(Path(record["frozen_path"]) for record in authority["tile_inputs"].values())
    expected.add(Path("manifest.json"))
    actual = {path.relative_to(rebuilt_dir) for path in rebuilt_dir.rglob("*") if path.is_file()}
    if actual != expected:
        raise ValueError(f"file sets differ: missing={sorted(expected - actual)}, extra={sorted(actual - expected)}")
    for relative in sorted(expected):
        if _sha256(rebuilt_dir / relative) != _sha256(compare_to / relative):
            raise ValueError(f"rebuilt file differs: {relative}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    build_parser = subparsers.add_parser("build", help="capture and assemble into a new directory")
    build_parser.add_argument("--output-dir", type=Path, required=True)
    build_parser.add_argument("--authority-dir", type=Path, default=HERE)
    verify_parser = subparsers.add_parser("verify", help="byte-compare rebuilt and retained evidence")
    verify_parser.add_argument("--rebuilt-dir", type=Path, required=True)
    verify_parser.add_argument("--compare-to", type=Path, default=HERE)
    arguments = parser.parse_args()
    if arguments.command == "build":
        build(arguments.output_dir, arguments.authority_dir)
    else:
        verify(arguments.rebuilt_dir, arguments.compare_to)


if __name__ == "__main__":
    main()
