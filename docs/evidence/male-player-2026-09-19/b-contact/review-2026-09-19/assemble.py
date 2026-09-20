"""Assemble an uninstalled four-pose diagnostic with protected source hashes."""

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from PIL import __version__ as pillow_version

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
REGISTERED = ROOT / "docs/evidence/male-player-2026-09-19/registered/rig"
VIEWS = ("front", "back", "side", "front_diagonal")
LABELS = ("S / front", "N / back", "E / side (W mirrors)", "SE / front diagonal (SW mirrors)")
NOTES = (
    (
        "Required leg leads",
        "Image-right leg advances;",
        "image-left leg recedes.",
        "Head and hands still need",
        "A/C proportion acceptance.",
    ),
    (
        "Depth is ambiguous",
        "Image-right foot is higher",
        "but its sole faces us.",
        "Does this read as advancing",
        "away or lifting behind?",
    ),
    (
        "Wrong overlap; too wide",
        "Foreground thigh connects",
        "down-right to front shoe.",
        "Required: near hip to LEFT",
        "trailing shoe, in front.",
    ),
    (
        "Wrong overlap",
        "Foreground thigh again runs",
        "down-right to front shoe.",
        "Required: image-right hip",
        "to LEFT trailing shoe.",
    ),
)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rgba(path):
    return Image.open(path).convert("RGBA")


def installed_path(view, pose):
    if pose == "b":
        return REGISTERED / f"father_{view}_{pose}.png"
    return ROOT / f"assets/illustrated/svg-transfer/rig/father_{view}_{pose}.png"


def inputs():
    result = [HERE / "candidate-raw.png", HERE / "prompt.txt"]
    result += [ROOT / "tools/remove-checkerboard.py", HERE.parent / "review-raster.py"]
    result += [HERE.parent / "inputs/svg-targets-8x.png", HERE.parent / "proof/identity-upper-only.png"]
    result += [ROOT / f"docs/evidence/graphics-reference-{name}.jpeg" for name in ("urban-01", "cardinal")]
    for view in VIEWS:
        result += [installed_path(view, pose) for pose in "acb"]
        result += [HERE.parent / f"inputs/father_{view}_b-{scale}x.png" for scale in (1, 3)]
    return result


def load_recipe():
    spec = importlib.util.spec_from_file_location("review_raster", HERE.parent / "review-raster.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--freeze-inputs", action="store_true", help="create the immutable input hash record once")
    parser.add_argument("--output-dir", type=Path, required=True, help="fresh output directory")
    args = parser.parse_args()
    if args.output_dir.exists():
        parser.error("output directory must be fresh")
    frozen = HERE / "inputs.json"
    current = {str(path.relative_to(ROOT)): sha(path) for path in inputs()}
    if args.freeze_inputs:
        if frozen.exists():
            parser.error("input hashes already exist")
        frozen.write_text(json.dumps(current, indent=2) + "\n")
    if current != json.loads(frozen.read_text()):
        raise ValueError("an input changed; restore the recorded inputs before rebuilding")
    args.output_dir.mkdir(parents=True)
    recipe = load_recipe()
    raw = rgba(HERE / "candidate-raw.png")
    if raw.getchannel("A").getextrema()[0] == 255:
        raise ValueError("candidate must have true alpha")
    sheet = Image.new("RGBA", (1430, 1280), "#edf0f1")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=17)
    small = ImageFont.load_default(size=14)
    heading = ImageFont.load_default(size=23)
    draw.text((24, 15), "M160 - Father's opposite contact: four-pose comparison", font=heading, fill="#182d3d")
    draw.text(
        (24, 47),
        "FRESH CANDIDATE - NOT INSTALLED. Side and diagonal anatomy fail; no complete family is accepted.",
        font=font,
        fill="#a42c28",
    )
    draw.text(
        (24, 73),
        "Every panel: native 1x beneath 3x. Detail uses raw alpha at 210px stature. "
        "Blue box = intended runtime canvas; overflow stays visible.",
        font=small,
        fill="#344b5b",
    )
    columns = (165, 285, 405, 540, 705)
    for x, label in zip(
        columns, ("Installed A", "Installed C", "Installed B", "Intended SVG B", "Candidate B"), strict=True
    ):
        draw.text((x - 44, 106), label, font=small, fill="#182d3d")
    draw.text((825, 106), "Candidate detail", font=small, fill="#182d3d")
    draw.text((1075, 106), "Anatomy inspection", font=small, fill="#182d3d")
    measurements = {}
    for row, (view, label) in enumerate(zip(VIEWS, LABELS, strict=True)):
        y = 137 + row * 277
        draw.rectangle((12, y, 1418, y + 263), fill="#dce2e5" if row % 2 == 0 else "#e5e9eb")
        draw.text((24, y + 10), label.split(" / ")[0], font=heading, fill="#182d3d")
        for index, piece in enumerate(label.split(" / ")[1].split(" ")):
            draw.text((24, y + 44 + index * 18), piece, font=small, fill="#344b5b")
        bounds = (round(row * raw.width / 4), 0, round((row + 1) * raw.width / 4), raw.height)
        cell = raw.crop(bounds)
        visible = cell.getchannel("A").point(lambda a: 255 if a > 1 else 0).getbbox()
        if visible is None:
            raise ValueError(f"empty candidate: {view}")
        figure = cell.crop(visible)
        width = 24 if view in ("front", "back") else 26
        installed = [rgba(installed_path(view, pose)) for pose in "acb"]
        fitted = figure.resize((round(figure.width * 540 / figure.height), 540), Image.Resampling.LANCZOS)
        x = round(recipe.centroid(installed[1]) * 12 - recipe.centroid(fitted))
        # Diagnostic padding exposes overflow. It never shrinks or clips the figure to pass registration.
        pad = 12
        high = Image.new("RGBA", ((width + 2 * pad) * 12, 552))
        if x + pad * 12 < 0 or x + pad * 12 + fitted.width > high.width:
            raise ValueError("diagnostic padding is insufficient")
        high.alpha_composite(fitted, (x + pad * 12, 12))
        candidate = high.resize((width + 2 * pad, 46), Image.Resampling.LANCZOS)
        candidate.save(args.output_dir / f"father_{view}_b-diagnostic-padded.png")
        source = rgba(HERE.parent / f"inputs/father_{view}_b-1x.png")
        panels = [*installed, source, candidate]
        for index, (cx, picture) in enumerate(zip(columns, panels, strict=True)):
            big = picture.resize((picture.width * 3, picture.height * 3), Image.Resampling.NEAREST)
            if index == 3:
                big = rgba(HERE.parent / f"inputs/father_{view}_b-3x.png")
            top = y + 25
            sheet.alpha_composite(big, (cx - big.width // 2, top))
            sheet.alpha_composite(picture, (cx - picture.width // 2, y + 190))
            draw.line((cx - 45, top + 138, cx + 45, top + 138), fill="#91a0a9")
            if index == 4:
                for scale, py in ((3, top), (1, y + 190)):
                    left = cx - picture.width * scale // 2 + pad * scale
                    draw.rectangle((left, py, left + width * scale - 1, py + 46 * scale - 1), outline="#658aab")
            draw.text((cx - 15, y + 241), "1x", font=small, fill="#344b5b")
        detail = figure.resize((round(figure.width * 210 / figure.height), 210), Image.Resampling.LANCZOS)
        sheet.alpha_composite(detail, (920 - detail.width // 2, y + 16))
        for line, note in enumerate(NOTES[row]):
            draw.text((1075, y + 25 + line * 25), note, font=font, fill="#a42c28" if line == 0 else "#253b4a")
        clips = x < 0 or x + fitted.width > width * 12
        measurements[view] = {
            "cell": bounds,
            "visible_bounds": visible,
            "x_at_12x": x,
            "width_at_12x": fitted.width,
            "native_canvas_width": width,
            "registration_clips": clips,
            "diagnostic_padding_each_side": pad,
        }
    draw.text(
        (24, 1256),
        "Static pose evidence only. No walking-motion or hand-to-stroller-contact acceptance. "
        "A/C and all runtime PNGs remain unchanged.",
        font=small,
        fill="#344b5b",
    )
    sheet.convert("RGB").save(args.output_dir / "comparison.png")
    record = {
        "pillow": pillow_version,
        "font": "Pillow bundled default",
        "raw_dimensions": raw.size,
        "measurements": measurements,
        "outputs": {p.name: sha(p) for p in sorted(args.output_dir.glob("*.png"))},
    }
    (args.output_dir / "measurements.json").write_text(json.dumps(record, indent=2) + "\n")
    print(json.dumps(measurements, indent=2))


if __name__ == "__main__":
    main()
