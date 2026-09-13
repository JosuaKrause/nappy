"""Prepare and register the seven litter and garbage prop PNGs."""
import argparse
import hashlib
import importlib.util
import json
import os
import re
import subprocess
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
TEMPLATE_SOURCE = SOURCE.parent / "style-transfer-litter-2026-09-12"
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
                                           "docs/evidence/comic-props-2026-09-12/comparisons/comic-props-comparison-native-unmasked.png",
                                           "docs/evidence/comic-props-2026-09-12/comparisons/comic-props-comparison-3x-unmasked.png"]})
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
    normalized = output / "comic-props-atlas-background-clean.png"
    Image.open(generated).convert("RGBA").save(normalized)
    _remove_connected_white(normalized)
    checker.extract(normalized, output / "litter-sheet-extracted.png")
    _remove_connected_white(output / "litter-sheet-extracted.png")
    atlas = Image.open(output / "litter-sheet-extracted.png").convert("RGBA").resize(SHEET, Image.Resampling.LANCZOS)
    (output / "props").mkdir()
    measurements = []
    for index, name in enumerate(NAMES):
        native = Image.open(TEMPLATE_SOURCE / "source" / f"{name}-svg.png").convert("RGBA")
        template = Image.open(TEMPLATE_SOURCE / "source" / f"{name}-svg-8x.png").convert("RGBA")
        x, y = index % 4 * CELL[0], index // 4 * CELL[1]
        cell = atlas.crop((x, y, x + CELL[0], y + CELL[1]))
        bounds = cell.getchannel("A").point(lambda alpha: 255 if alpha > 192 else 0).getbbox()
        target = template.getchannel("A").getbbox()
        assert bounds and target
        cropped = cell.crop(bounds)
        generated = previous.extend_colors(cropped).convert("RGBA")
        generated.putalpha(cropped.getchannel("A"))
        target_width = target[2] - target[0]
        target_height = target[3] - target[1]
        scale = min(target_width / generated.width, target_height / generated.height)
        fitted_size = (max(1, round(generated.width * scale)), max(1, round(generated.height * scale)))
        fitted = generated.resize(fitted_size, Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", template.size, (0, 0, 0, 0))
        center_x = (target[0] + target[2]) // 2
        if name.startswith("garbage_"):
            position = (center_x - fitted.width // 2, target[3] - fitted.height)
        else:
            center_y = (target[1] + target[3]) // 2
            position = (center_x - fitted.width // 2, center_y - fitted.height // 2)
        canvas.alpha_composite(fitted, position)
        final = previous.extend_colors(canvas).resize(native.size, Image.Resampling.LANCZOS)
        final.putalpha(canvas.getchannel("A").resize(native.size, Image.Resampling.LANCZOS))
        final.save(output / "props" / f"{name}.png")
        assert final.getchannel("A").getbbox()
        measurements.append({"name": name, "size": native.size, "generated_cell_bounds": bounds,
                             "svg_8x_bounds": target, "generated_alpha_preserved": True,
                             "placement_scale": scale, "placement_position_8x": position})
    (output / "registration.json").write_text(json.dumps(measurements, indent=2) + "\n")
    _comparison(output)


def _remove_connected_white(path: Path) -> None:
    """Remove only white regions connected to the atlas edges, preserving white interiors."""
    image = Image.open(path).convert("RGBA")
    pixels = image.load()
    width, height = image.size
    queue = deque()
    seen = set()
    for x in range(width):
        queue.extend(((x, 0), (x, height - 1)))
    for y in range(height):
        queue.extend(((0, y), (width - 1, y)))
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen:
            continue
        seen.add((x, y))
        r, g, b, a = pixels[x, y]
        if min(r, g, b) < 245 or max(r, g, b) - min(r, g, b) > 12:
            continue
        pixels[x, y] = (r, g, b, 0)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in seen:
                queue.append((nx, ny))
    image.save(path)


def _comparison(output: Path) -> None:
    sheet = Image.new("RGBA", (512, 256), "#68767c")
    draw = ImageDraw.Draw(sheet)
    for index, name in enumerate(NAMES):
        native = Image.open(TEMPLATE_SOURCE / "source" / f"{name}-svg.png").convert("RGBA")
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
