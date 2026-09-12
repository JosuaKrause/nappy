"""Prepare and register the seven litter and garbage prop PNGs."""
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
NAMES = ("garbage_sack", "garbage_sacks_pile", "litter_can", "litter_apple", "litter_bag",
         "litter_newspaper", "litter_cup")
CELL = (384, 384)
SHEET = (CELL[0] * 4, CELL[1] * 2)


def module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def rasterize(svg: Path, destination: Path, scale: int) -> None:
    subprocess.run(
        [os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot"), "--headless",
         "--path", str(ROOT), "--script", str(RASTERIZER), "--", str(svg), str(destination), str(scale)],
        check=True, timeout=30)


def manifest() -> list[dict[str, object]]:
    result = []
    for name in NAMES:
        svg = ROOT / "assets/props" / f"{name}.svg"
        text = svg.read_text()
        match = re.search(r'viewBox="0 0 ([0-9]+) ([0-9]+)"', text)
        assert match, svg
        dimensions = [int(match.group(1)), int(match.group(2))]
        bottom = name.startswith("garbage_")
        result.append({"svg": f"assets/props/{name}.svg", "png": f"assets/illustrated/svg-transfer/props/{name}.png",
                       "svg_sha256": hashlib.sha256(svg.read_bytes()).hexdigest(), "dimensions": dimensions,
                       "anchor": [dimensions[0] // 2, dimensions[1] if bottom else dimensions[1] // 2],
                       "usage": "src/city/garbage_sacks.gd via Prop" if bottom else "src/city/litter.gd via CityDecals",
                       "review_evidence": ["docs/evidence/style-transfer-litter-2026-09-12/source/litter-sheet-svg.png",
                                           "docs/evidence/style-transfer-litter-2026-09-12/registered/litter-comparison-native.png",
                                           "docs/evidence/style-transfer-litter-2026-09-12/registered/litter-comparison-3x.png"]})
    return result


def prepare(output: Path) -> None:
    assert not output.exists(), output
    output.mkdir(parents=True)
    for name in NAMES:
        svg = ROOT / "assets/props" / f"{name}.svg"
        rasterize(svg, output / f"{name}-svg.png", 1)
        rasterize(svg, output / f"{name}-svg-8x.png", 8)
    sheet = Image.new("RGBA", SHEET, (0, 0, 0, 0))
    for index, name in enumerate(NAMES):
        image = Image.open(output / f"{name}-svg-8x.png").convert("RGBA")
        x = index % 4 * CELL[0] + (CELL[0] - image.width) // 2
        bottom = name.startswith("garbage_")
        y = index // 4 * CELL[1] + (320 if bottom else 192) - (image.height if bottom else image.height // 2)
        assert x >= index % 4 * CELL[0] and x + image.width <= (index % 4 + 1) * CELL[0]
        assert y >= index // 4 * CELL[1] and y + image.height <= (index // 4 + 1) * CELL[1]
        assert image.getchannel("A").getbbox()
        sheet.alpha_composite(image, (x, y))
    sheet.save(output / "litter-sheet-svg.png")
    (output / "source-manifest.json").write_text(json.dumps(manifest(), indent=2) + "\n")


def register(output: Path, generated: Path) -> None:
    assert not output.exists(), output
    output.mkdir(parents=True)
    checker = module("checker", ROOT / "tools/remove-checkerboard.py")
    previous = module("previous", ROOT / "docs/evidence/style-transfer-2026-09-10/register-transfer.py")
    checker.extract(generated, output / "litter-sheet-extracted.png")
    atlas = Image.open(output / "litter-sheet-extracted.png").convert("RGBA").resize(SHEET, Image.Resampling.LANCZOS)
    (output / "props").mkdir()
    measurements = []
    for index, name in enumerate(NAMES):
        native = Image.open(SOURCE / "source" / f"{name}-svg.png").convert("RGBA")
        template = Image.open(SOURCE / "source" / f"{name}-svg-8x.png").convert("RGBA")
        x, y = index % 4 * CELL[0], index // 4 * CELL[1]
        cell = atlas.crop((x, y, x + CELL[0], y + CELL[1]))
        bounds = cell.getchannel("A").point(lambda alpha: 255 if alpha > 192 else 0).getbbox()
        target = template.getchannel("A").getbbox()
        assert bounds and target
        filled = previous.extend_colors(cell.crop(bounds))
        fitted = Image.new("RGB", template.size)
        fitted.paste(
            filled.resize((target[2] - target[0], target[3] - target[1]), Image.Resampling.LANCZOS),
            target[:2])
        fitted.putalpha(template.getchannel("A"))
        final = previous.extend_colors(fitted).resize(native.size, Image.Resampling.LANCZOS)
        final.putalpha(native.getchannel("A"))
        final.save(output / "props" / f"{name}.png")
        assert final.getchannel("A").tobytes() == native.getchannel("A").tobytes()
        measurements.append({"name": name, "size": native.size, "generated_cell_bounds": bounds,
                             "svg_8x_bounds": target, "alpha_identical_to_native_svg": True})
    (output / "registration.json").write_text(json.dumps(measurements, indent=2) + "\n")
    _comparison(output)


def _comparison(output: Path) -> None:
    sheet = Image.new("RGBA", (512, 256), "#68767c")
    draw = ImageDraw.Draw(sheet)
    for index, name in enumerate(NAMES):
        native = Image.open(SOURCE / "source" / f"{name}-svg.png").convert("RGBA")
        final = Image.open(output / "props" / f"{name}.png").convert("RGBA")
        x = index % 4 * 128
        y = index // 4 * 128
        draw.text((x + 2, y + 2), name, fill="white")
        for col, image in enumerate((native, final)):
            big = image
            sheet.alpha_composite(big, (x + col * 64 + (64 - big.width) // 2, y + 112 - big.height))
    sheet.save(output / "litter-comparison-native.png")
    enlarged = sheet.resize((sheet.width * 3, sheet.height * 3), Image.Resampling.NEAREST)
    enlarged.save(output / "litter-comparison-3x.png")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="mode", required=True)
    prep = sub.add_parser("prepare")
    prep.add_argument("output", type=Path)
    reg = sub.add_parser("register")
    reg.add_argument("output", type=Path)
    reg.add_argument("generated", type=Path, nargs="?", default=SOURCE / "litter-sheet-generated.png")
    args = parser.parse_args()
    if args.mode == "prepare":
        prepare(args.output.resolve())
    else:
        register(args.output.resolve(), args.generated.resolve())


if __name__ == "__main__":
    main()
