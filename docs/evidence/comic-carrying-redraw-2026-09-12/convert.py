"""Prepare and register the carrying redraw while preserving its extracted alpha."""

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
SOURCE_ORIGIN = ROOT / "docs/evidence/style-transfer-player-family-2026-09-12/source"
RIG_RECORD = ROOT / "docs/evidence/comic-rig-2026-09-12"
PUSHING = ROOT / "assets/illustrated/svg-transfer/rig"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
NAMES = [f"mother_carrying_{view}_{frame}" for frame in ("a", "b") for view in VIEWS]


def _module(name: str, path: Path):
    assert path.is_file(), path
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _sha256(path: Path) -> str:
    assert path.is_file(), path
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _manifest(path: Path) -> list[dict[str, object]]:
    assert path.is_file(), path
    parsed = json.loads(path.read_text())
    assert isinstance(parsed, list), path
    rows = [row for row in parsed if row.get("name") in NAMES]
    assert [row["name"] for row in rows] == NAMES, "carrying rows changed or reordered"
    return rows


def _verify_svg(row: dict[str, object]) -> None:
    svg = ROOT / str(row["svg"])
    assert _sha256(svg) == row["svg_sha256"], f"stale SVG raster: {svg}"


def prepare(output: Path) -> None:
    """Copy reviewed SVG rasters only if their source hashes still match."""
    assert not output.exists(), f"Choose a new source directory: {output}"
    rows = _manifest(RIG_RECORD / "source/source-manifest.json")
    output.mkdir(parents=True)
    prepared: list[dict[str, object]] = []
    for row in rows:
        _verify_svg(row)
        name = str(row["name"])
        native = SOURCE_ORIGIN / f"{name}-svg.png"
        enlarged = SOURCE_ORIGIN / f"{name}-svg-8x.png"
        assert native.is_file() and enlarged.is_file(), name
        with Image.open(native) as image:
            assert list(image.size) == row["dimensions"], name
        shutil.copy2(native, output / native.name)
        shutil.copy2(enlarged, output / enlarged.name)
        prepared.append(
            {
                "name": name,
                "svg": row["svg"],
                "png": row["png"],
                "svg_sha256": row["svg_sha256"],
                "native_raster_sha256": _sha256(native),
                "enlarged_raster_sha256": _sha256(enlarged),
                "dimensions": row["dimensions"],
                "anchor": row["anchor"],
                "generated_atlas": "carrying-atlas-selected.png",
                "generated_cell": [
                    VIEWS.index(name.removeprefix("mother_carrying_")[:-2]),
                    int(name.endswith("_b")),
                ],
            }
        )
    shutil.copy2(SOURCE_ORIGIN / "carrying-sheet-svg.png", output / "carrying-sheet-svg.png")
    identity_source = RIG_RECORD / "mother-atlas-generated.png"
    with Image.open(identity_source) as atlas:
        assert atlas.size == (1194, 1317), "pushing atlas geometry changed"
        identity_target = atlas.crop((0, 0, atlas.width, atlas.height // 2))
    identity_path = output / "pushing-atlas-edit-target.png"
    identity_target.save(identity_path)
    (output / "input-manifest.json").write_text(
        json.dumps(
            {
                "pushing_source": "docs/evidence/comic-rig-2026-09-12/mother-atlas-generated.png",
                "pushing_source_sha256": _sha256(identity_source),
                "pushing_crop": [0, 0, 1194, 658],
                "pushing_crop_sha256": _sha256(identity_path),
                "carrying_pose": "source/carrying-sheet-svg.png",
                "style_references": [
                    "docs/evidence/graphics-reference-urban-01.jpeg",
                    "docs/evidence/graphics-reference-cardinal.jpeg",
                ],
            },
            indent=2,
        )
        + "\n"
    )
    (output / "source-manifest.json").write_text(json.dumps(prepared, indent=2) + "\n")


def _verify_prepared(source: Path) -> list[dict[str, object]]:
    rows = _manifest(source / "source-manifest.json")
    inputs = json.loads((source / "input-manifest.json").read_text())
    identity_source = ROOT / inputs["pushing_source"]
    assert _sha256(identity_source) == inputs["pushing_source_sha256"], "pushing source changed"
    assert _sha256(source / "pushing-atlas-edit-target.png") == inputs["pushing_crop_sha256"]
    for row in rows:
        _verify_svg(row)
        name = str(row["name"])
        assert _sha256(source / f"{name}-svg.png") == row["native_raster_sha256"]
        assert _sha256(source / f"{name}-svg-8x.png") == row["enlarged_raster_sha256"]
    return rows


def _cell(image: Image.Image, column: int, row: int) -> Image.Image:
    return image.crop(
        (
            round(column * image.width / 5),
            round(row * image.height / 2),
            round((column + 1) * image.width / 5),
            round((row + 1) * image.height / 2),
        )
    )


def _bounds(image: Image.Image) -> tuple[int, int, int, int]:
    bounds = image.getchannel("A").point(lambda value: 255 if value > 192 else 0).getbbox()
    assert bounds, "empty generated cell"
    assert bounds[2] - bounds[0] >= image.width // 5, bounds
    assert bounds[3] - bounds[1] >= image.height // 2, bounds
    return bounds


def _palette(subjects: list[Image.Image]) -> Image.Image:
    pixels: list[tuple[int, int, int]] = []
    pushing = [PUSHING / f"mother_{view}_{frame}.png" for frame in ("a", "b") for view in VIEWS]
    for path in pushing:
        assert path.is_file(), path
    for image in subjects + [Image.open(path).convert("RGBA") for path in pushing]:
        pixels.extend(
            (red, green, blue)
            for red, green, blue, alpha in image.get_flattened_data()
            if alpha > 64
        )
    width = 1024
    pixels.extend([pixels[-1]] * (math.ceil(len(pixels) / width) * width - len(pixels)))
    samples = Image.new("RGB", (width, len(pixels) // width))
    samples.putdata(pixels)
    return samples.quantize(colors=28, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)


def _register(
    name: str,
    subject: Image.Image,
    source: Path,
    palette: Image.Image,
) -> tuple[Image.Image, dict[str, object]]:
    native = Image.open(source / f"{name}-svg.png").convert("RGBA")
    template = Image.open(source / f"{name}-svg-8x.png").convert("RGBA")
    scale = ((native.height - 1) * 8) / subject.height
    size = (round(subject.width * scale), round(subject.height * scale))
    assert size[0] <= template.width, (name, size, template.size)
    fitted = subject.resize(size, Image.Resampling.LANCZOS)
    x, y = round((template.width - fitted.width) / 2), template.height - fitted.height
    assert x >= 0 and y >= 0
    registered = Image.new("RGBA", template.size, (0, 0, 0, 0))
    registered.alpha_composite(fitted, (x, y))
    registered = registered.resize(native.size, Image.Resampling.LANCZOS)
    generated_alpha = registered.getchannel("A")
    alpha_bytes = generated_alpha.tobytes()
    extender = _module(
        "color_extender",
        ROOT / "docs/evidence/style-transfer-2026-09-10/register-transfer.py",
    )
    final = extender.extend_colors(registered).quantize(
        palette=palette,
        dither=Image.Dither.NONE,
    ).convert("RGBA")
    final.putalpha(generated_alpha)
    assert final.getchannel("A").tobytes() == alpha_bytes, name
    final_bounds = generated_alpha.getbbox()
    assert final_bounds and final_bounds[3] == native.height, (name, final_bounds)
    assert any(value == 0 for value in generated_alpha.get_flattened_data()), name
    return final, {
        "name": name,
        "size": list(native.size),
        "generated_cell_bounds": list(_bounds(subject)),
        "registered_alpha_bounds": list(final_bounds),
        "ground_line_preserved": True,
        "generated_alpha_preserved": True,
        "aspect_ratio_preserved": True,
        "fit_scale": scale,
    }


def _place(sheet: Image.Image, image: Image.Image, center_x: int, ground_y: int) -> None:
    sheet.alpha_composite(image, (center_x - image.width // 2, ground_y - image.height))


def _review_carrying(output: Path) -> None:
    cell_width, cell_height = 52, 62
    sheet = Image.new("RGBA", (cell_width * 5, cell_height * 2), "#68767c")
    draw = ImageDraw.Draw(sheet)
    for index, name in enumerate(NAMES):
        column, row = index % 5, index // 5
        draw.text((column * cell_width + 2, row * cell_height + 2), f"{VIEWS[column][:5]} {name[-1]}", fill="white")
        image = Image.open(output / "rig" / f"{name}.png").convert("RGBA")
        _place(sheet, image, column * cell_width + cell_width // 2, row * cell_height + 60)
    sheet.save(output / "carrying-native.png")
    sheet.resize((sheet.width * 6, sheet.height * 6), Image.Resampling.NEAREST).save(
        output / "carrying-6x.png"
    )


def _review_identity(output: Path) -> None:
    directions = (
        ("N", "back", False),
        ("NE", "back_diagonal", False),
        ("E", "side", False),
        ("SE", "front_diagonal", False),
        ("S", "front", False),
        ("SW", "front_diagonal", True),
        ("W", "side", True),
        ("NW", "back_diagonal", True),
    )
    width, height = 52, 58
    sheet = Image.new("RGBA", (18 + width * 4, 18 + height * 8), "#68767c")
    draw = ImageDraw.Draw(sheet)
    for column, label in enumerate(("push a", "push b", "carry a", "carry b")):
        draw.text((18 + column * width + 2, 2), label, fill="white")
    for row, (label, view, mirror) in enumerate(directions):
        draw.text((2, 18 + row * height + 2), label, fill="white")
        for column, (state, frame) in enumerate(
            (("push", "a"), ("push", "b"), ("carry", "a"), ("carry", "b"))
        ):
            folder = PUSHING if state == "push" else output / "rig"
            prefix = "mother" if state == "push" else "mother_carrying"
            image = Image.open(folder / f"{prefix}_{view}_{frame}.png").convert("RGBA")
            if mirror:
                image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            _place(sheet, image, 18 + column * width + width // 2, 18 + row * height + 56)
    sheet.save(output / "identity-family-native.png")
    sheet.resize((sheet.width * 5, sheet.height * 5), Image.Resampling.NEAREST).save(
        output / "identity-family-5x.png"
    )


def _review_sources(output: Path, source: Path) -> None:
    width, height = 68, 62
    sheet = Image.new("RGBA", (width * 10, height * 2), "#68767c")
    draw = ImageDraw.Draw(sheet)
    for index, name in enumerate(NAMES):
        for row, (label, folder, suffix) in enumerate(
            (("svg", source, "-svg.png"), ("comic", output / "rig", ".png"))
        ):
            image = Image.open(folder / f"{name}{suffix}").convert("RGBA")
            draw.text((index * width + 2, row * height + 2), f"{name[-8:]} {label}", fill="white")
            _place(sheet, image, index * width + width // 2, row * height + 60)
    sheet.save(output / "source-comparison-native.png")
    sheet.resize((sheet.width * 5, sheet.height * 5), Image.Resampling.NEAREST).save(
        output / "source-comparison-5x.png"
    )


def register(output: Path, source: Path, generated: Path) -> None:
    assert not output.exists(), f"Choose a new registration directory: {output}"
    _verify_prepared(source)
    assert generated.is_file(), generated
    output.mkdir(parents=True)
    (output / "rig").mkdir()
    checker = _module("checker", ROOT / "tools/remove-checkerboard.py")
    extracted_path = output / "carrying-atlas-extracted.png"
    checker.extract(generated, extracted_path)
    atlas = Image.open(extracted_path).convert("RGBA")
    subjects = {
        name: (lambda cell: cell.crop(_bounds(cell)))(_cell(atlas, index % 5, index // 5))
        for index, name in enumerate(NAMES)
    }
    palette = _palette(list(subjects.values()))
    palette.save(output / "shared-palette.png")
    measurements = []
    for name in NAMES:
        final, row = _register(name, subjects[name], source, palette)
        final.save(output / "rig" / f"{name}.png")
        measurements.append(row)
    heights = [row["registered_alpha_bounds"][3] - row["registered_alpha_bounds"][1] for row in measurements]
    assert min(heights) >= 44 and max(heights) - min(heights) <= 1, heights
    (output / "registration.json").write_text(json.dumps(measurements, indent=2) + "\n")
    _review_carrying(output)
    _review_identity(output)
    _review_sources(output, source)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    prepare_parser = commands.add_parser("prepare")
    prepare_parser.add_argument("output", type=Path)
    register_parser = commands.add_parser("register")
    register_parser.add_argument("output", type=Path)
    register_parser.add_argument("source", type=Path)
    register_parser.add_argument("generated", type=Path)
    args = parser.parse_args()
    if args.command == "prepare":
        prepare(args.output.resolve())
    else:
        register(args.output.resolve(), args.source.resolve(), args.generated.resolve())


if __name__ == "__main__":
    main()
