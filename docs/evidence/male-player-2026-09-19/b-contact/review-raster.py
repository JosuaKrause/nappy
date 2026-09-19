"""Register a four-column B candidate outside runtime and assemble its protected A/C comparisons."""

import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
VIEWS = ("front", "back", "side", "front_diagonal")
DIRECTIONS = ("back", "back_diagonal", "side", "front_diagonal", "front", "front_diagonal", "side", "back_diagonal")
LABELS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rgba(path):
    return Image.open(path).convert("RGBA")


def centroid(picture):
    # Above pelvis only; leg spread and the rejected runtime B lower body cannot
    # move the candidate's hands. C supplies the stable standing upper-body anchor.
    alpha = picture.getchannel("A")
    pixels = [(x, alpha.getpixel((x, y))) for y in range(round(picture.height * 0.57)) for x in range(picture.width)]
    return sum((x + 0.5) * a for x, a in pixels) / sum(a for _, a in pixels)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--raw", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    if args.output_dir.exists():
        parser.error("output directory must be fresh")
    raw = rgba(args.raw)
    spec = importlib.util.spec_from_file_location("neutral", ROOT / "tools/remove-checkerboard.py")
    neutral = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(neutral)
    args.output_dir.mkdir(parents=True)
    pictures, measurements = {}, {}
    for col, view in enumerate(VIEWS):
        cell_bounds = (round(col * raw.width / 4), 0, round((col + 1) * raw.width / 4), raw.height)
        cell = raw.crop(cell_bounds)
        extraction = "original alpha"
        if cell.getchannel("A").getextrema() == (255, 255):
            mask = neutral.neutral_background_mask(cell)
            alpha = cell.getchannel("A")
            alpha.putdata([0 if bg else a for bg, a in zip(mask, alpha.tobytes(), strict=True)])
            cell.putalpha(alpha)
            extraction = "authorized neutral-region extraction"
        bounds = cell.getchannel("A").point(lambda a: 255 if a > 1 else 0).getbbox()
        if bounds is None:
            raise ValueError(f"empty figure: {view}")
        figure = cell.crop(bounds)
        width = 24 if view in ("front", "back") else 26
        target = rgba(ROOT / f"assets/illustrated/svg-transfer/rig/father_{view}_c.png")
        scale = 45 / figure.height
        fitted_width = round(figure.width * scale * 12)
        figure = figure.resize((fitted_width, 540), Image.Resampling.LANCZOS)
        x = round(centroid(target) * 12 - centroid(figure))
        if x < 0 or x + fitted_width > width * 12:
            raise ValueError(f"full-stature figure clips: {view}: x={x} width={fitted_width}")
        high = Image.new("RGBA", (width * 12, 552))
        high.alpha_composite(figure, (x, 12))
        native = high.resize((width, 46), Image.Resampling.LANCZOS)
        name = f"father_{view}_b"
        native.save(args.output_dir / f"{name}.png")
        high.save(args.output_dir / f"{name}-12x.png")
        cell.save(args.output_dir / f"{name}-extracted.png")
        pictures[view] = native
        measurements[view] = {
            "cell": cell_bounds,
            "visible_bounds": bounds,
            "scale": scale,
            "x_at_12x": x,
            "extraction": extraction,
            "native_alpha_bounds": native.getchannel("A").getbbox(),
        }
    for contact in (False, True):
        cell_width, cell_height = (80, 74) if contact else (38, 74)
        sheet = Image.new("RGBA", (20 + 8 * cell_width, 24 + 3 * cell_height), "#647278")
        draw = ImageDraw.Draw(sheet)
        for row, pose in enumerate(("a", "c", "b")):
            for col, view in enumerate(DIRECTIONS):
                figure = (
                    pictures[view]
                    if pose == "b" and view in pictures
                    else rgba(ROOT / f"assets/illustrated/svg-transfer/rig/father_{view}_{pose}.png")
                )
                if col >= 5:
                    figure = ImageOps.mirror(figure)
                anchor = (20 + col * cell_width + cell_width // 2, 20 + row * cell_height + 46)
                layers = [(figure, (anchor[0] - figure.width // 2, anchor[1] - 46))]
                if contact:
                    angle = col * math.pi / 4
                    fx, fy = math.sin(angle), -math.cos(angle)
                    offset = (fx * 24, fy * (9 if fy > 0 else 17) * 0.7 + (8 * fx * fx * fy * fy if fy < 0 else 0))
                    stroller = rgba(ROOT / f"assets/illustrated/svg-transfer/rig/pram_{view}.png")
                    stroller = stroller.resize((round(stroller.width * 7 / 6), 35), Image.Resampling.BILINEAR)
                    if col >= 5:
                        stroller = ImageOps.mirror(stroller)
                    layers.append(
                        (
                            stroller,
                            (round(anchor[0] + offset[0] - stroller.width / 2), round(anchor[1] + offset[1] - 35)),
                        )
                    )
                    if fy < 0:
                        layers.reverse()
                for picture, location in layers:
                    sheet.alpha_composite(picture, location)
                draw.text((20 + col * cell_width, row * cell_height + 3), f"{LABELS[col]} {pose.upper()}", fill="white")
        name = "contact" if contact else "pushing"
        sheet.save(args.output_dir / f"{name}-native.png")
        sheet.resize((sheet.width * 3, sheet.height * 3), Image.Resampling.NEAREST).save(
            args.output_dir / f"{name}-3x.png"
        )
    record = {
        "raw_sha256": digest(args.raw),
        "raw_dimensions": raw.size,
        "measurements": measurements,
        "outputs": {p.name: digest(p) for p in sorted(args.output_dir.glob("*.png"))},
    }
    (args.output_dir / "manifest.json").write_text(json.dumps(record, indent=2) + "\n")
    print(json.dumps(measurements, indent=2))


if __name__ == "__main__":
    main()
