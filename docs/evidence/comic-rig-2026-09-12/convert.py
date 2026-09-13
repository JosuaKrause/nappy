"""Register redrawn comic rig atlases on the existing native canvases and ground anchors."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import math
import shutil
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CARDINAL = ROOT / "docs/evidence/style-transfer-2026-09-10"
DIAGONAL = ROOT / "docs/evidence/style-transfer-eight-directions-2026-09-10"
CARRYING = ROOT / "docs/evidence/style-transfer-player-family-2026-09-12/source"

VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
MOTHER_NAMES = [
    f"mother{state}_{view}_{frame}"
    for state in ("", "_carrying")
    for frame in ("a", "b")
    for view in VIEWS
]
PRAM_NAMES = [f"pram_{view}" for view in VIEWS]
NAMES = MOTHER_NAMES + PRAM_NAMES


def _module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _source_evidence(name: str) -> Path:
    if name.startswith("mother_carrying_"):
        return CARRYING
    if "diagonal" in name:
        return DIAGONAL
    return CARDINAL


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare(output: Path) -> None:
    """Collect the previously preserved SVG rasters and record the new atlas mapping."""
    assert not output.exists(), f"Choose a new source directory: {output}"
    output.mkdir(parents=True)
    manifest: list[dict[str, object]] = []
    for name in NAMES:
        evidence = _source_evidence(name)
        native_source = evidence / f"{name}-svg.png"
        enlarged_source = evidence / f"{name}-svg-8x.png"
        svg = ROOT / "assets/rig" / f"{name}.svg"
        assert native_source.is_file(), native_source
        assert enlarged_source.is_file(), enlarged_source
        assert svg.is_file(), svg
        native_destination = output / native_source.name
        enlarged_destination = output / enlarged_source.name
        shutil.copy2(native_source, native_destination)
        shutil.copy2(enlarged_source, enlarged_destination)
        with Image.open(native_destination) as opened:
            dimensions = list(opened.size)
        manifest.append(
            {
                "name": name,
                "svg": f"assets/rig/{name}.svg",
                "png": f"assets/illustrated/svg-transfer/rig/{name}.png",
                "svg_sha256": _sha256(svg),
                "dimensions": dimensions,
                "anchor": [dimensions[0] // 2, dimensions[1]],
                "generated_atlas": "mother-atlas-generated.png"
                if name.startswith("mother")
                else "pram-atlas-background-corrected.png",
                "generated_cell": _generated_cell(name),
            }
        )
    (output / "source-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def _generated_cell(name: str) -> list[int]:
    if name.startswith("pram_"):
        return [PRAM_NAMES.index(name), 0]
    state = 1 if name.startswith("mother_carrying_") else 0
    base = name.removeprefix("mother_carrying_").removeprefix("mother_")
    frame = base[-1]
    view = base[:-2]
    return [VIEWS.index(view), state * 2 + (1 if frame == "b" else 0)]


def _extract(source: Path, destination: Path) -> Image.Image:
    checker = _module("checker", ROOT / "tools/remove-checkerboard.py")
    checker.extract(source, destination)
    return Image.open(destination).convert("RGBA")


def _cell(image: Image.Image, column: int, row: int, columns: int, rows: int) -> Image.Image:
    x0 = round(column * image.width / columns)
    y0 = round(row * image.height / rows)
    x1 = round((column + 1) * image.width / columns)
    y1 = round((row + 1) * image.height / rows)
    return image.crop((x0, y0, x1, y1))


def _art_bounds(image: Image.Image) -> tuple[int, int, int, int]:
    bounds = image.getchannel("A").point(lambda alpha: 255 if alpha > 192 else 0).getbbox()
    assert bounds, "generated cell has no retained artwork"
    assert bounds[2] - bounds[0] >= image.width // 5, bounds
    assert bounds[3] - bounds[1] >= image.height // 5, bounds
    return bounds


def _make_palette(subjects: list[Image.Image], colors: int = 28) -> Image.Image:
    """Build one restrained palette so identity colors do not drift between frames."""
    pixels: list[tuple[int, int, int]] = []
    for subject in subjects:
        rgba = subject.convert("RGBA")
        pixels.extend(
            (red, green, blue)
            for red, green, blue, alpha in rgba.get_flattened_data()
            if alpha > 64
        )
    assert pixels
    width = 1024
    height = math.ceil(len(pixels) / width)
    pixels.extend([pixels[-1]] * (width * height - len(pixels)))
    samples = Image.new("RGB", (width, height))
    samples.putdata(pixels)
    return samples.quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)


def _register_one(
    name: str,
    subject: Image.Image,
    source_dir: Path,
    palette: Image.Image,
) -> tuple[Image.Image, dict[str, object]]:
    """Fit without stretching, preserve the redraw alpha, and align the original ground line."""
    native = Image.open(source_dir / f"{name}-svg.png").convert("RGBA")
    template = Image.open(source_dir / f"{name}-svg-8x.png").convert("RGBA")
    target = template.getchannel("A").getbbox()
    assert target
    if name.startswith("mother"):
        # A turn must not change the mother's apparent stature. The redraw was designed
        # narrow enough that every projection can use one 45 px high body on its native
        # 24-26 px canvas without squeezing or distorting its anatomy.
        target_height = (native.height - 1) * 8
        scale = target_height / subject.height
        assert round(subject.width * scale) <= template.width, (
            name,
            round(subject.width * scale),
            template.width,
        )
    else:
        target_width = target[2] - target[0]
        target_height = target[3] - target[1]
        scale = min(target_width / subject.width, target_height / subject.height)
    fitted_size = (
        max(1, round(subject.width * scale)),
        max(1, round(subject.height * scale)),
    )
    fitted = subject.resize(fitted_size, Image.Resampling.LANCZOS)
    x = round((template.width - fitted.width) / 2)
    # Every rig SVG declares its anchor at the native canvas bottom. Align the generated
    # feet/wheels to that same line instead of borrowing the SVG silhouette's upper geometry.
    y = template.height - fitted.height
    assert x >= 0 and y >= 0
    registered = Image.new("RGBA", template.size, (0, 0, 0, 0))
    registered.alpha_composite(fitted, (x, y))
    registered = registered.resize(native.size, Image.Resampling.LANCZOS)
    alpha = registered.getchannel("A")
    assert alpha.getbbox(), name
    previous = _module("previous_transfer", CARDINAL / "register-transfer.py")
    rgb = previous.extend_colors(registered)
    rgb = rgb.quantize(palette=palette, dither=Image.Dither.NONE).convert("RGB")
    final = rgb.convert("RGBA")
    final.putalpha(alpha)
    final_bounds = final.getchannel("A").getbbox()
    source_bounds = native.getchannel("A").getbbox()
    assert final_bounds and source_bounds
    assert final_bounds[3] == source_bounds[3], (name, final_bounds, source_bounds)
    assert any(value == 0 for value in final.getchannel("A").get_flattened_data()), name
    return final, {
        "name": name,
        "size": list(native.size),
        "generated_art_bounds": list(_art_bounds(subject)),
        "svg_8x_occupancy_bounds": list(target),
        "registered_alpha_bounds": list(final_bounds),
        "source_alpha_bounds": list(source_bounds),
        "ground_line_preserved": final_bounds[3] == native.height,
        "generated_alpha_preserved": True,
        "aspect_ratio_preserved": True,
        "fit_scale": scale,
    }


def register(output: Path, source_dir: Path, mother_raw: Path, pram_raw: Path) -> None:
    assert not output.exists(), f"Choose a new registration directory: {output}"
    assert source_dir.is_dir(), source_dir
    output.mkdir(parents=True)
    (output / "rig").mkdir()
    mother = _extract(mother_raw, output / "mother-atlas-extracted.png")
    pram = _extract(pram_raw, output / "pram-atlas-extracted.png")

    subjects: dict[str, Image.Image] = {}
    for name in MOTHER_NAMES:
        column, row = _generated_cell(name)
        cell = _cell(mother, column, row, 5, 4)
        subjects[name] = cell.crop(_art_bounds(cell))
    for name in PRAM_NAMES:
        column, row = _generated_cell(name)
        cell = _cell(pram, column, row, 5, 1)
        subjects[name] = cell.crop(_art_bounds(cell))

    palette = _make_palette(list(subjects.values()))
    palette.save(output / "shared-palette.png")
    measurements = []
    for name in NAMES:
        final, measurement = _register_one(name, subjects[name], source_dir, palette)
        destination = output / "rig" / f"{name}.png"
        assert not destination.exists(), destination
        final.save(destination)
        measurements.append(measurement)
    mother_heights = [
        measurement["registered_alpha_bounds"][3]
        - measurement["registered_alpha_bounds"][1]
        for measurement in measurements
        if str(measurement["name"]).startswith("mother")
    ]
    assert min(mother_heights) >= 44, mother_heights
    assert max(mother_heights) - min(mother_heights) <= 1, mother_heights
    (output / "registration.json").write_text(json.dumps(measurements, indent=2) + "\n")
    _family_comparison(output, source_dir)
    _direction_review(output)


def _family_comparison(output: Path, source_dir: Path) -> None:
    cell_width, cell_height = 300, 280
    sheet = Image.new("RGBA", (cell_width * 5, cell_height * 5), "#68767c")
    draw = ImageDraw.Draw(sheet)
    for index, name in enumerate(NAMES):
        column, row = index % 5, index // 5
        x, y = column * cell_width, row * cell_height
        draw.text((x + 6, y + 5), name, fill="white")
        source = Image.open(source_dir / f"{name}-svg.png").convert("RGBA")
        comic = Image.open(output / "rig" / f"{name}.png").convert("RGBA")
        for subcolumn, (label, image) in enumerate((("SVG", source), ("comic", comic))):
            draw.text((x + 20 + subcolumn * 145, y + 24), label, fill="white")
            enlarged = image.resize((image.width * 5, image.height * 5), Image.Resampling.NEAREST)
            image_x = x + subcolumn * 145 + (145 - enlarged.width) // 2
            image_y = y + 270 - enlarged.height
            sheet.alpha_composite(enlarged, (image_x, image_y))
    sheet.save(output / "family-comparison-5x.png")
    sheet.resize((sheet.width // 5, sheet.height // 5), Image.Resampling.LANCZOS).save(
        output / "family-comparison-native.png"
    )


def _direction_review(output: Path) -> None:
    directions = (
        ("N", "back", False, -90),
        ("NE", "back_diagonal", False, -45),
        ("E", "side", False, 0),
        ("SE", "front_diagonal", False, 45),
        ("S", "front", False, 90),
        ("SW", "front_diagonal", True, 135),
        ("W", "side", True, 180),
        ("NW", "back_diagonal", True, 225),
    )
    cell_width, cell_height = 112, 72
    sheet = Image.new("RGBA", (cell_width * 4 + 24, cell_height * 8 + 24), "#68767c")
    draw = ImageDraw.Draw(sheet)
    for column, label in enumerate(("push a", "push b", "carry a", "carry b")):
        draw.text((24 + column * cell_width + 3, 4), label, fill="white")
    for row, (label, view, mirror, degrees) in enumerate(directions):
        y = 24 + row * cell_height
        draw.text((3, y + 3), label, fill="white")
        angle = math.radians(degrees)
        pram_offset = (math.cos(angle) * 34, math.sin(angle) * 34 * 0.7)
        for column, (state, frame) in enumerate(
            (("", "a"), ("", "b"), ("_carrying", "a"), ("_carrying", "b"))
        ):
            parts: list[tuple[Image.Image, tuple[float, float]]] = []
            mother_name = f"mother{state}_{view}_{frame}"
            mother = Image.open(output / "rig" / f"{mother_name}.png").convert("RGBA")
            if mirror:
                mother = mother.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            parts.append((mother, (0.0, 0.0)))
            if not state:
                pram = Image.open(output / "rig" / f"pram_{view}.png").convert("RGBA")
                if mirror:
                    pram = pram.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                parts.append((pram, pram_offset))
                if pram_offset[1] < 0:
                    parts.reverse()
            origin_x = 24 + column * cell_width + cell_width // 2
            ground_y = y + 58
            for image, offset in parts:
                sheet.alpha_composite(
                    image,
                    (
                        round(origin_x + offset[0] - image.width / 2),
                        round(ground_y + offset[1] - image.height),
                    ),
                )
    sheet.save(output / "all-views-native.png")
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.Resampling.NEAREST).save(
        output / "all-views-4x.png"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="mode", required=True)
    prepare_parser = subparsers.add_parser("prepare")
    prepare_parser.add_argument("output", type=Path)
    register_parser = subparsers.add_parser("register")
    register_parser.add_argument("output", type=Path)
    register_parser.add_argument("source", type=Path)
    register_parser.add_argument("mother_raw", type=Path)
    register_parser.add_argument("pram_raw", type=Path)
    args = parser.parse_args()
    if args.mode == "prepare":
        prepare(args.output.resolve())
    else:
        register(
            args.output.resolve(),
            args.source.resolve(),
            args.mother_raw.resolve(),
            args.pram_raw.resolve(),
        )


if __name__ == "__main__":
    main()
