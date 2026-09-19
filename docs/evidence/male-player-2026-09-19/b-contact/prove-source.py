"""Assemble source ownership, fixed contact, and pose-safe identity evidence."""

import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps
from PIL import __version__ as PILLOW_VERSION

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
VIEWS = ("front", "back", "side", "front_diagonal")
DIRECTIONS = ("back", "back_diagonal", "side", "front_diagonal", "front", "front_diagonal", "side", "back_diagonal")
LABELS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
# Source-space centerlines, hidden hip, visible knee, shoe. These annotate the
# actual path ownership; neither the lines nor their colors enter runtime assets.
CHAINS = {
    "front": {
        "a": [
            ("right / leads", [(9, 31), (10, 38), (7, 44)], True),
            ("left / trails", [(16, 31), (18, 37), (17, 43)], False),
        ],
        "b": [
            ("right / trails", [(9, 31), (9, 37), (8, 42)], False),
            ("left / leads", [(15, 31), (14, 38), (14, 44)], True),
        ],
    },
    "back": {
        "a": [
            ("left / leads away", [(9, 31), (10, 37), (8, 43)], False),
            ("right / trails near", [(15, 31), (16, 38), (17, 44)], True),
        ],
        "b": [
            ("left / trails near", [(9, 31), (8, 38), (7, 44)], True),
            ("right / leads away", [(15, 31), (15, 37), (15, 42)], False),
        ],
    },
    "side": {
        "a": [
            ("near / leads right", [(14, 31), (17, 38), (22, 44)], True),
            ("far / trails left", [(9, 31), (10, 37), (6, 43)], False),
        ],
        "b": [
            ("near / trails left", [(14, 31), (10, 37), (6, 44)], True),
            ("far / leads right", [(11, 31), (16, 38), (21, 44)], False),
        ],
    },
    "front_diagonal": {
        "a": [
            ("near / leads down-right", [(16, 31), (17, 38), (21, 44)], True),
            ("far / trails up-left", [(10, 31), (10, 37), (6, 42)], False),
        ],
        "b": [
            ("near / trails up-left", [(16, 31), (11, 37), (6, 42)], True),
            ("far / leads down-right", [(10, 31), (16, 38), (21, 44)], False),
        ],
    },
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def image(path):
    return Image.open(path).convert("RGBA")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--verify", type=Path, help="Require these frozen input and output hashes")
    args = parser.parse_args()
    if args.output_dir.exists():
        parser.error("output directory must be fresh")
    inputs = {}
    for pattern in (
        "assets/rig/father_*",
        "assets/rig/pram_*",
        "assets/illustrated/svg-transfer/rig/father_*",
        "assets/illustrated/svg-transfer/rig/pram_*",
    ):
        for path in sorted(ROOT.glob(pattern)):
            inputs[str(path.relative_to(ROOT))] = digest(path)
    for path in [Path(__file__), HERE.parent / "raw/pushing.png", *sorted(args.source_dir.glob("*.png"))]:
        key = "source-render/" + path.name if path.parent == args.source_dir else str(path.relative_to(ROOT))
        inputs[key] = digest(path)
    if args.verify and json.loads(args.verify.read_text())["inputs"] != inputs:
        raise ValueError("frozen source/protected input hashes differ")
    args.output_dir.mkdir(parents=True)
    font = ImageFont.load_default(size=15)
    sheet = Image.new("RGBA", (1120, 4 * 470 + 70), "#647278")
    draw = ImageDraw.Draw(sheet)
    draw.text((15, 10), "SOURCE OWNERSHIP: clean A / traced A / clean B / traced B", font=font, fill="white")
    draw.text(
        (15, 34),
        "Cyan = first named leg; amber = second. Hip under hem is dashed; near contour draws last.",
        font=font,
        fill="white",
    )
    for row, view in enumerate(VIEWS):
        y = 70 + row * 470
        for pose_col, pose in enumerate(("a", "b")):
            source = image(args.source_dir / f"father_{view}_{pose}-8x.png")
            for annotated in (False, True):
                x = pose_col * 560 + int(annotated) * 280 + 22
                sheet.alpha_composite(source, (x, y + 28))
                draw.text((x, y), f"{view} {pose.upper()}", font=font, fill="white")
                if not annotated:
                    continue
                indexed = list(enumerate(CHAINS[view][pose]))
                for index, (label, points, foreground) in sorted(indexed, key=lambda entry: entry[1][2]):
                    color = "#63ffff" if index == 0 else "#ffbf50"
                    scaled = [(x + px * 8, y + 28 + py * 8) for px, py in points]
                    # Hip is covered by the shirt; dash only this inferred segment.
                    start, end = scaled[:2]
                    for step in range(0, 4, 2):
                        a = tuple(start[i] + (end[i] - start[i]) * step / 8 for i in (0, 1))
                        b = tuple(start[i] + (end[i] - start[i]) * (step + 1) / 8 for i in (0, 1))
                        draw.line([a, b], fill=color, width=3)
                    emerge = tuple((start[i] + end[i]) / 2 for i in (0, 1))
                    if foreground:
                        draw.line([emerge, *scaled[1:]], fill="#253038", width=9)
                    draw.line([emerge, *scaled[1:]], fill=color, width=4)
                    for letter, (px, py) in zip("HKS", scaled, strict=True):
                        draw.ellipse((px - 4, py - 4, px + 4, py + 4), fill=color)
                        draw.text((px + 6, py - 9), letter, font=font, fill=color)
                    draw.text((x - 8, y + 408 + 21 * index), label, font=font, fill=color)
                draw.text((x - 8, y + 451), "Solid source edge governs overlap", font=font, fill="white")
    sheet.save(args.output_dir / "ownership-source-8x.png")
    b_only = Image.new("RGBA", (1120, 470), "#647278")
    for col in range(4):
        b_only.alpha_composite(sheet.crop((840, 70 + col * 470, 1120, 70 + (col + 1) * 470)), (col * 280, 0))
    b_only.save(args.output_dir / "ownership-b-only-8x.png")
    # Current source with the unchanged installed stroller: exact runtime canvas,
    # facing offsets and draw order; rounded pixels, no live-motion claim.
    for scale in (1, 3):
        contact = Image.new("RGBA", (640 * scale, 242 * scale), "#647278")
        labels = Image.new("RGBA", (640, 242))
        label_draw = ImageDraw.Draw(labels)
        for row, pose in enumerate(("a", "c", "b")):
            for col, view in enumerate(DIRECTIONS):
                angle = col * math.pi / 4
                fx, fy = math.sin(angle), -math.cos(angle)
                offset = (fx * 24, fy * (9 if fy > 0 else 17) * 0.7 + (8 * fx * fx * fy * fy if fy < 0 else 0))
                figure = image(args.source_dir / f"father_{view}_{pose}-{scale}x.png")
                stroller = image(ROOT / f"assets/illustrated/svg-transfer/rig/pram_{view}.png")
                stroller = stroller.resize(
                    (round(stroller.width * 7 / 6) * scale, 35 * scale), Image.Resampling.BILINEAR
                )
                if col >= 5:
                    figure, stroller = ImageOps.mirror(figure), ImageOps.mirror(stroller)
                anchor = ((col * 80 + 40) * scale, (row * 74 + 65) * scale)
                layers = [
                    (figure, (anchor[0] - figure.width // 2, anchor[1] - figure.height)),
                    (
                        stroller,
                        (
                            round(anchor[0] + offset[0] * scale - stroller.width / 2),
                            round(anchor[1] + offset[1] * scale - stroller.height),
                        ),
                    ),
                ]
                if fy < 0:
                    layers.reverse()
                for picture, position in layers:
                    contact.alpha_composite(picture, position)
                label_draw.text((col * 80 + 3, row * 74 + 3), f"{LABELS[col]} {pose.upper()}", fill="white")
        label_draw.text((3, 225), "SVG father + unchanged PNG stroller; static rounded runtime placement", fill="white")
        contact.alpha_composite(labels.resize(contact.size, Image.Resampling.NEAREST))
        contact.save(args.output_dir / f"source-contact-{scale}x.png")
    raw = image(HERE.parent / "raw/pushing.png")
    identity = Image.new("RGBA", (1040, 238), "white")
    for col, view in enumerate(VIEWS):
        # Stop above the pelvis: the previous 1052 row reaches the belt.
        crop = raw.crop((round(col * raw.width / 5), 824, round((col + 1) * raw.width / 5), 1032))
        crop.save(args.output_dir / f"{view}-identity-upper.png")
        identity.alpha_composite(crop, (col * 260, 24))
        ImageDraw.Draw(identity).text((col * 260 + 12, 4), view, fill="black", font=font)
    identity.save(args.output_dir / "identity-upper-only.png")
    record = {
        "pillow_version": PILLOW_VERSION,
        "inputs": inputs,
        "chains": CHAINS,
        "outputs": {p.name: digest(p) for p in sorted(args.output_dir.glob("*.png"))},
    }
    if args.verify and json.loads(args.verify.read_text()) != json.loads(json.dumps(record)):
        raise ValueError("evidence regeneration differs")
    (args.output_dir / "proof.json").write_text(json.dumps(record, indent=2) + "\n")
    print("Source ownership/contact evidence and protected hashes verified")


if __name__ == "__main__":
    main()
