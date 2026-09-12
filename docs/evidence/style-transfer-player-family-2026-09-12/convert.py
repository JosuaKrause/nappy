"""Prepare the carrying mother atlas and register a saved generator output."""
import argparse
import hashlib
import importlib.util
import json
import os
import re
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
RASTERIZER = ROOT / "docs/evidence/style-transfer-2026-09-10/rasterize-svg.gd"
PUSHING = ROOT / "assets/illustrated/svg-transfer/rig"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
NAMES = [f"mother_carrying_{view}_{frame}" for frame in ("a", "b") for view in VIEWS]
CELL = (384, 512)
SHEET = (CELL[0] * len(VIEWS), CELL[1] * 2)


def _module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _rasterize(svg: Path, destination: Path, scale: int) -> None:
    godot = os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot")
    subprocess.run(
        [godot, "--headless", "--path", str(ROOT), "--script", str(RASTERIZER), "--",
         str(svg), str(destination), str(scale)],
        check=True,
        timeout=30,
    )


def _manifest() -> list[dict[str, object]]:
    result = []
    for name in NAMES:
        svg = ROOT / "assets/rig" / f"{name}.svg"
        assert svg.is_file(), svg
        match = re.search(r'viewBox="0 0 ([0-9]+) ([0-9]+)"', svg.read_text())
        assert match, svg
        dimensions = [int(match.group(1)), int(match.group(2))]
        result.append({
            "svg": f"assets/rig/{name}.svg",
            "png": f"assets/illustrated/svg-transfer/rig/{name}.png",
            "svg_sha256": hashlib.sha256(svg.read_bytes()).hexdigest(),
            "dimensions": dimensions,
            "anchor": [dimensions[0] // 2, dimensions[1]],
            "usage": "src/player/stroller.gd carrying mother state, eight-direction view and gait frame",
            "review_evidence": [
                "docs/evidence/style-transfer-player-family-2026-09-12/source/carrying-sheet-svg.png",
                "docs/evidence/style-transfer-player-family-2026-09-12/source/pushing-family-reference-sheet.png",
                "docs/evidence/style-transfer-player-family-2026-09-12/registered/eight-directions-both-states-native.png",
                "docs/evidence/style-transfer-player-family-2026-09-12/registered/eight-directions-both-states-3x.png",
            ],
        })
    return result


def prepare(output: Path) -> None:
    assert not output.exists(), f"Choose a new output directory: {output}"
    output.mkdir(parents=True)
    manifest = _manifest()
    for name in NAMES:
        svg = ROOT / "assets/rig" / f"{name}.svg"
        _rasterize(svg, output / f"{name}-svg.png", 1)
        _rasterize(svg, output / f"{name}-svg-8x.png", 8)

    sheet = Image.new("RGBA", SHEET, (0, 0, 0, 0))
    for index, name in enumerate(NAMES):
        raster = Image.open(output / f"{name}-svg-8x.png").convert("RGBA")
        column = index % len(VIEWS)
        row = index // len(VIEWS)
        x = column * CELL[0] + (CELL[0] - raster.width) // 2
        y = row * CELL[1] + 448 - raster.height
        sheet.alpha_composite(raster, (x, y))
    sheet.save(output / "carrying-sheet-svg.png")

    comparison = Image.new("RGBA", SHEET, (104, 118, 124, 255))
    draw = ImageDraw.Draw(comparison)
    for index, view in enumerate(VIEWS):
        for row, frame in enumerate(("a", "b")):
            source = PUSHING / f"mother_{view}_{frame}.png"
            assert source.is_file(), source
            raster = Image.open(source).convert("RGBA").resize(
                (Image.open(source).width * 8, Image.open(source).height * 8), Image.Resampling.NEAREST
            )
            x = index * CELL[0] + (CELL[0] - raster.width) // 2
            y = row * CELL[1] + 448 - raster.height
            comparison.alpha_composite(raster, (x, y))
            draw.text((index * CELL[0] + 8, row * CELL[1] + 8), f"pushing {view} {frame}", fill="white")
    comparison.save(output / "pushing-family-reference-sheet.png")
    (output / "source-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def register(output: Path, generated: Path) -> None:
    assert not output.exists(), f"Choose a new output directory: {output}"
    output.mkdir(parents=True)
    checker = _module("checker", ROOT / "tools/remove-checkerboard.py")
    previous = _module("previous_transfer", ROOT / "docs/evidence/style-transfer-2026-09-10/register-transfer.py")
    checker.extract(generated, output / "carrying-sheet-extracted.png")
    atlas = Image.open(output / "carrying-sheet-extracted.png").convert("RGBA").resize(SHEET, Image.Resampling.LANCZOS)
    (output / "rig").mkdir()
    measurements = []
    comparison = Image.new("RGB", (len(NAMES) * 240, 440), "#68767c")
    draw = ImageDraw.Draw(comparison)
    for index, name in enumerate(NAMES):
        native = Image.open(SOURCE / "source" / f"{name}-svg.png").convert("RGBA")
        template = Image.open(SOURCE / "source" / f"{name}-svg-8x.png").convert("RGBA")
        x, y = (index % len(VIEWS)) * CELL[0], (index // len(VIEWS)) * CELL[1]
        cell = atlas.crop((x, y, x + CELL[0], y + CELL[1]))
        bounds = cell.getchannel("A").point(lambda alpha: 255 if alpha > 192 else 0).getbbox()
        target = template.getchannel("A").getbbox()
        assert bounds and target
        filled = previous.extend_colors(cell.crop(bounds))
        fitted = Image.new("RGB", template.size)
        fitted.paste(
            filled.resize((target[2] - target[0], target[3] - target[1]), Image.Resampling.LANCZOS),
            target[:2],
        )
        fitted.putalpha(template.getchannel("A"))
        final = previous.extend_colors(fitted).resize(native.size, Image.Resampling.LANCZOS)
        final.putalpha(native.getchannel("A"))
        final.save(output / "rig" / f"{name}.png")
        assert final.getchannel("A").tobytes() == native.getchannel("A").tobytes()
        measurements.append({"name": name, "size": native.size, "generated_cell_bounds": bounds,
                             "svg_8x_bounds": target, "alpha_identical_to_native_svg": True})
        cx = index * 240
        draw.text((cx + 4, 4), name.removeprefix("mother_carrying_"), fill="white")
        for column, image in enumerate((native, final)):
            enlarged = image.resize((image.width * 4, image.height * 4), Image.Resampling.NEAREST)
            comparison.paste(enlarged, (cx + column * 120 + (120 - enlarged.width) // 2, 250 - enlarged.height), enlarged)
    (output / "registration.json").write_text(json.dumps(measurements, indent=2) + "\n")
    comparison.save(output / "carrying-comparison.png")
    _direction_review(output)


def _direction_review(output: Path) -> None:
    """Assemble both mother states at native size and 3x with runtime mirrors."""
    directions = (("N", "back", False), ("NE", "back_diagonal", False), ("E", "side", False),
                  ("SE", "front_diagonal", False), ("S", "front", False), ("SW", "front_diagonal", True),
                  ("W", "side", True), ("NW", "back_diagonal", True))
    frames = (("pushing", PUSHING), ("carrying", output / "rig"))
    header_height = 32
    sheet = Image.new("RGBA", (344, header_height + 512), "#68767c")
    draw = ImageDraw.Draw(sheet)
    for column, label in enumerate(("push a", "push b", "carry a", "carry b")):
        draw.text((24 + column * 80 + 2, 2), label, fill="white")
    for row, (direction, view, mirror) in enumerate(directions):
        row_y = header_height + row * 64
        draw.text((2, row_y + 1), direction, fill="white")
        for state, (family, folder) in enumerate(frames):
            for frame_index, frame in enumerate(("a", "b")):
                name = f"mother_{view}_{frame}.png" if family == "pushing" else f"mother_carrying_{view}_{frame}.png"
                raster = Image.open(folder / name).convert("RGBA")
                if mirror:
                    raster = raster.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                x = 24 + (state * 2 + frame_index) * 80
                sheet.alpha_composite(raster, (x + (80 - raster.width) // 2, row_y + 58 - raster.height))
    sheet.save(output / "eight-directions-both-states-native.png")
    sheet.resize((sheet.width * 3, sheet.height * 3), Image.Resampling.NEAREST).save(output / "eight-directions-both-states-3x.png")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="mode", required=True)
    prepare_parser = subparsers.add_parser("prepare")
    prepare_parser.add_argument("output", type=Path)
    register_parser = subparsers.add_parser("register")
    register_parser.add_argument("output", type=Path)
    register_parser.add_argument("generated", type=Path, nargs="?", default=SOURCE / "carrying-sheet-generated.png")
    args = parser.parse_args()
    if args.mode == "prepare":
        prepare(args.output.resolve())
    else:
        register(args.output.resolve(), args.generated.resolve())


if __name__ == "__main__":
    main()
