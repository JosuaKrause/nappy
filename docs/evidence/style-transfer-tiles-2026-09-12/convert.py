"""Prepare and register the complete 32px outdoor tile catalogue."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
RASTERIZER = ROOT / "docs/evidence/style-transfer-2026-09-10/rasterize-svg.gd"
NATIVE_SIZE = (32, 32)
SCALE = 8
CELL = (NATIVE_SIZE[0] * SCALE, NATIVE_SIZE[1] * SCALE)
SHEET_GRID = (4, 4)
SHEET_SIZE = (CELL[0] * SHEET_GRID[0], CELL[1] * SHEET_GRID[1])
BACKGROUND = (55, 64, 69, 255)

# Keep each family in catalogue order. Families crossing a sheet boundary remain contiguous.
ROAD_MARKINGS = (
    "road_line_e",
    "road_line_n",
    "road_line_s",
    "road_line_w",
    "road_main_line_e",
    "road_main_line_n",
    "road_main_line_s",
    "road_main_line_w",
    "crossing_h",
    "crossing_v",
    "crossing_main_e",
    "crossing_main_n",
    "crossing_main_s",
    "crossing_main_w",
)
SIDEWALK = (
    "sidewalk",
    "sidewalk_kerb_e",
    "sidewalk_kerb_n",
    "sidewalk_kerb_s",
    "sidewalk_kerb_w",
    "sidewalk_kerb_main_e",
    "sidewalk_kerb_main_n",
    "sidewalk_kerb_main_s",
    "sidewalk_kerb_main_w",
)
DAMAGE = tuple(
    f"{ground}_cracked_{severity}_{frame}"
    for ground in ("alley", "road", "sidewalk")
    for severity in ("hairline", "cracked", "broken")
    for frame in ("a", "b")
)
OUTDOOR = (
    "road",
    "road_main",
    "alley",
    "alley_draft",
    "bulkhead",
    "courtyard",
    "fence",
    "forest",
    "grass",
    "mountain",
    "plaza",
    "precinct",
    "quiet_square",
    "sand",
    "scree",
    "spoiled",
    "stoop",
    "water",
)
NAMES = ROAD_MARKINGS + SIDEWALK + DAMAGE + OUTDOOR
assert len(NAMES) == 59
SHEETS = tuple(NAMES[index : index + 16] for index in range(0, len(NAMES), 16))
SHEET_NAMES = tuple(f"tiles-sheet-{index:02d}" for index in range(1, len(SHEETS) + 1))


def _svg_path(name: str) -> Path:
    path = ROOT / "assets/tiles" / f"{name}.svg"
    if not path.is_file():
        raise FileNotFoundError(f"missing tile SVG: {path}")
    return path


def _rasterize(svg: Path, destination: Path, scale: int) -> None:
    subprocess.run(
        [
            "/Applications/Godot.app/Contents/MacOS/Godot",
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


def _dimensions(svg: Path) -> list[int]:
    match = re.search(r'viewBox="0 0 ([0-9]+) ([0-9]+)"', svg.read_text())
    if match is None:
        raise ValueError(f"tile SVG has no integer viewBox: {svg}")
    dimensions = [int(match.group(1)), int(match.group(2))]
    if tuple(dimensions) != NATIVE_SIZE:
        raise ValueError(f"tile SVG is not 32x32: {svg} ({dimensions})")
    return dimensions


def _position(index: int) -> tuple[int, int, int, int]:
    sheet = index // 16
    cell = index % 16
    return sheet, cell % 4, cell // 4, cell


def _manifest() -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    for index, name in enumerate(NAMES):
        svg = _svg_path(name)
        sheet, column, row, _cell = _position(index)
        entries.append(
            {
                "name": name,
                "svg": f"assets/tiles/{name}.svg",
                "png": f"assets/illustrated/svg-transfer/tiles/{name}.png",
                "svg_sha256": hashlib.sha256(svg.read_bytes()).hexdigest(),
                "dimensions": _dimensions(svg),
                "anchor": [16, 16],
                "usage": (
                    "prepared alley alternative; no runtime binding"
                    if name == "alley_draft"
                    else "assets/ground_tileset.tres via GroundTiles; direct CityEdge terrain"
                    if name == "mountain"
                    else "assets/ground_tileset.tres via GroundTiles"
                ),
                "source_sheet": SHEET_NAMES[sheet],
                "cell": [column, row],
                "normalized_cell": [column / 4, row / 4, (column + 1) / 4, (row + 1) / 4],
                "cell_pixels_at_8x": [column * CELL[0], row * CELL[1], (column + 1) * CELL[0], (row + 1) * CELL[1]],
                "review_evidence": [
                    f"docs/evidence/style-transfer-tiles-2026-09-12/source/{SHEET_NAMES[sheet]}.png",
                    "docs/evidence/style-transfer-tiles-2026-09-12/registered/tiles-comparison-native.png",
                    "docs/evidence/style-transfer-tiles-2026-09-12/registered/tiles-comparison-4x.png",
                ],
            }
        )
    return entries


def _fresh_directory(output: Path) -> None:
    if output.exists():
        raise FileExistsError(f"refusing to overwrite existing output: {output}")
    output.mkdir(parents=True)


def prepare(output: Path) -> None:
    _fresh_directory(output)
    source = output / "source"
    source.mkdir()
    for name in NAMES:
        svg = _svg_path(name)
        _rasterize(svg, source / f"{name}-svg.png", 1)
        _rasterize(svg, source / f"{name}-svg-8x.png", SCALE)
        assert Image.open(source / f"{name}-svg.png").size == NATIVE_SIZE
        assert Image.open(source / f"{name}-svg-8x.png").size == CELL

    for sheet_index, names in enumerate(SHEETS):
        sheet = Image.new("RGBA", SHEET_SIZE, BACKGROUND)
        for cell, name in enumerate(names):
            image = Image.open(source / f"{name}-svg-8x.png").convert("RGBA")
            x, y = cell % 4 * CELL[0], cell // 4 * CELL[1]
            sheet.alpha_composite(image, (x, y))
        sheet.save(source / f"{SHEET_NAMES[sheet_index]}.png")
    manifest = {"sheets": SHEET_NAMES, "tiles": _manifest()}
    (source / "source-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def _generated_paths(arguments: list[Path]) -> dict[str, Path]:
    if len(arguments) == 1 and arguments[0].suffix == ".json":
        mapping = json.loads(arguments[0].read_text())
        if not isinstance(mapping, dict):
            raise ValueError("generated mapping must be a JSON object")
        paths = {name: Path(str(mapping[name])) for name in SHEET_NAMES}
    else:
        if len(arguments) != len(SHEETS):
            raise ValueError(f"provide exactly {len(SHEETS)} generated sheets, in {SHEET_NAMES} order")
        paths = dict(zip(SHEET_NAMES, arguments, strict=True))
    for name, path in paths.items():
        if not path.is_file():
            raise FileNotFoundError(f"missing generated sheet {name}: {path}")
    return paths


def register(output: Path, generated_arguments: list[Path]) -> None:
    _fresh_directory(output)
    generated = _generated_paths(generated_arguments)
    source = SOURCE / "source"
    registered = output / "tiles"
    registered.mkdir()
    measurements: list[dict[str, Any]] = []
    for index, name in enumerate(NAMES):
        sheet_index, column, row, _ = _position(index)
        with Image.open(generated[SHEET_NAMES[sheet_index]]) as opened:
            sheet = opened.convert("RGBA")
        if sheet.width != sheet.height:
            raise ValueError(f"generated sheet must be square: {sheet.size}")
        generated_cell = sheet.width / 4
        bounds = (
            round(column * generated_cell),
            round(row * generated_cell),
            round((column + 1) * generated_cell),
            round((row + 1) * generated_cell),
        )
        cell = sheet.crop(bounds)
        native = Image.open(source / f"{name}-svg.png").convert("RGBA")
        template = Image.open(source / f"{name}-svg-8x.png").convert("RGBA")
        if native.getchannel("A").getextrema() != (255, 255):
            raise ValueError(f"tile source is not fully opaque: {name}")
        resized = cell.resize(native.size, Image.Resampling.LANCZOS)
        resized.putalpha(native.getchannel("A"))
        destination = registered / f"{name}.png"
        resized.save(destination)
        assert resized.size == NATIVE_SIZE
        assert resized.getchannel("A").tobytes() == native.getchannel("A").tobytes()
        measurements.append(
            {
                "name": name,
                "source_sheet": SHEET_NAMES[sheet_index],
                "normalized_cell": [column / 4, row / 4, (column + 1) / 4, (row + 1) / 4],
                "generated_cell_pixels": bounds,
                "native_size": native.size,
                "svg_8x_size": template.size,
                "registered_size": resized.size,
                "alpha_identical_to_native_svg": True,
                "opaque_source_tile": native.getchannel("A").getextrema() == (255, 255),
            }
        )
    (output / "registration.json").write_text(json.dumps(measurements, indent=2) + "\n")
    _comparisons(output, registered, source)


def _comparisons(output: Path, registered: Path, source: Path) -> None:
    panel = Image.new("RGBA", (8 * 64, ((len(NAMES) + 7) // 8) * 64), BACKGROUND)
    for index, name in enumerate(NAMES):
        native = Image.open(source / f"{name}-svg.png").convert("RGBA")
        final = Image.open(registered / f"{name}.png").convert("RGBA")
        x, y = index % 8 * 64, index // 8 * 64
        panel.alpha_composite(native, (x + 16, y))
        panel.alpha_composite(final, (x + 16, y + 32))
    panel.save(output / "tiles-comparison-native.png")
    panel.resize((panel.width * 4, panel.height * 4), Image.Resampling.NEAREST).save(output / "tiles-comparison-4x.png")

    comparison_names = (
        "road",
        "road_line_e",
        "road_line_n",
        "road_line_s",
        "road_line_w",
        "road_main_line_e",
        "road_main_line_n",
        "road_main_line_s",
        "road_main_line_w",
        "crossing_h",
        "crossing_v",
        "crossing_main_e",
        "crossing_main_n",
        "crossing_main_s",
        "crossing_main_w",
        "sidewalk",
        "alley",
        "grass",
        "water",
    )
    repetition = Image.new("RGBA", (len(comparison_names) * 128, 128), BACKGROUND)
    draw = ImageDraw.Draw(repetition)
    for index, name in enumerate(comparison_names):
        image = Image.open(registered / f"{name}.png").convert("RGBA")
        for repeat_y in range(4):
            for repeat_x in range(4):
                repetition.alpha_composite(image, (index * 128 + repeat_x * 32, repeat_y * 32))
        draw.text((index * 128 + 2, 2), name, fill="white")
    repetition.save(output / "tiles-repetition.png")
    enlarged = repetition.resize((repetition.width * 2, repetition.height * 2), Image.Resampling.NEAREST)
    enlarged.save(output / "tiles-repetition-2x.png")

    # Assemble opposite edge halves as runtime neighbors; repeating a half-dash alone cannot
    # reveal whether the pair joins. Each example has SVG above PNG at identical native scale.
    layouts = {
        "road vertical": [["road_line_e", "road_line_w"]] * 4,
        "road horizontal": [["road_line_s"] * 4, ["road_line_n"] * 4],
        "main vertical": [["road_main_line_e", "road_main_line_w"]] * 4,
        "main horizontal": [["road_main_line_s"] * 4, ["road_main_line_n"] * 4],
        "crosswalk": [["crossing_h"] * 4] * 4,
        "sidewalk": [["sidewalk_kerb_n"] * 4, ["sidewalk"] * 4,
                     ["sidewalk"] * 4, ["sidewalk_kerb_s"] * 4],
    }
    paired = Image.new("RGBA", (len(layouts) * 144, 290), BACKGROUND)
    labels = ImageDraw.Draw(paired)
    for index, (label, rows) in enumerate(layouts.items()):
        labels.text((index * 144 + 2, 2), label, fill="white")
        for mode in range(2):
            for y, row in enumerate(rows):
                for x, name in enumerate(row):
                    path = source / f"{name}-svg.png" if mode == 0 else registered / f"{name}.png"
                    paired.alpha_composite(Image.open(path).convert("RGBA"),
                                           (index * 144 + x * 32, 18 + mode * 136 + y * 32))
    paired.save(output / "tiles-neighbors-native.png")
    paired.resize((paired.width * 2, paired.height * 2), Image.Resampling.NEAREST).save(
        output / "tiles-neighbors-2x.png")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="mode", required=True)
    prepare_parser = subparsers.add_parser("prepare")
    prepare_parser.add_argument("output", type=Path)
    register_parser = subparsers.add_parser("register")
    register_parser.add_argument("output", type=Path)
    register_parser.add_argument("generated", type=Path, nargs="+")
    args = parser.parse_args()
    if args.mode == "prepare":
        prepare(args.output.resolve())
    else:
        register(args.output.resolve(), [path.resolve() for path in args.generated])


if __name__ == "__main__":
    main()
