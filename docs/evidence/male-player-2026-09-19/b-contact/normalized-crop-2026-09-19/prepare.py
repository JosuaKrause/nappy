"""Prepare high-resolution father/mother inputs for one generated join normalization."""

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
CANVAS = (26 * 12, 46 * 12)
PANEL_GAP = 40

SOURCE = {
    "side": {
        "father": ROOT
        / "docs/evidence/male-player-2026-09-19/registered/extracted/father_side_b.png",
        "father_sha256": "3fe82dc8e3e2c23578742ce35fb1dd34869081cdde3b8b5632457b84490bb7ae",
        "father_visible": (15, 11, 200, 365),
        "father_x": 11,
        "father_upper_source_y": 242,
        "mother": ROOT
        / "docs/evidence/comic-pushing-strides-2026-09-12/registered/p2-acb-pass4-side-ne-extracted.png",
        "mother_sha256": "b67f962870ee64cf4301c2eed1c448a47b6ab51259a086b5a8d1c5ae455db4a3",
        "mother_whole": (748, 623, 904, 911),
        "mother_x": 0,
        "mother_min_leg_y": 168,
    },
    "front_diagonal": {
        "father": ROOT
        / "docs/evidence/male-player-2026-09-19/registered/extracted/father_front_diagonal_b.png",
        "father_sha256": "3c2b3219bb71158a57078dcd782eaacb172f17f55bce09e43518e352488b323a",
        "father_visible": (41, 11, 186, 368),
        "father_x": 45,
        "father_upper_source_y": 242,
        "mother": ROOT
        / "docs/evidence/comic-pushing-strides-2026-09-12/registered/p2-acb-pass2-extracted.png",
        "mother_sha256": "f810a0b54821f7e3cb5669cce674c6c574d0f01656e9bc67bbd7fab5235b0c2d",
        "mother_whole": (1088, 625, 1203, 916),
        "mother_x": 48,
        "mother_min_leg_y": 168,
    },
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rgba(path):
    return Image.open(path).convert("RGBA")


def check_sources():
    for record in SOURCE.values():
        assert digest(record["father"]) == record["father_sha256"]
        assert digest(record["mother"]) == record["mother_sha256"]


def mother_figure(record):
    return rgba(record["mother"]).crop(record["mother_whole"])


def coat_contour_leg_mask(figure, minimum_y):
    """Keep artwork below the donor coat's painted lower contour, column by column."""
    pixels = figure.load()
    boundary = []
    for x in range(figure.width):
        red_rows = []
        for y in range(minimum_y, figure.height):
            red, green, blue, alpha = pixels[x, y]
            if alpha > 8 and red > 75 and red > green * 1.28 and red > blue * 1.18:
                red_rows.append(y)
        boundary.append(max(red_rows) if red_rows else minimum_y)

    painted = boundary[:]
    for x in range(figure.width):
        neighbors = [
            boundary[near]
            for near in range(max(0, x - 5), min(figure.width, x + 6))
            if boundary[near] > minimum_y
        ]
        if neighbors:
            painted[x] = max(neighbors) + 4

    result = figure.copy()
    alpha = result.getchannel("A")
    alpha_pixels = alpha.load()
    for x, coat_bottom in enumerate(painted):
        for y in range(0, min(figure.height, coat_bottom + 1)):
            alpha_pixels[x, y] = 0
    result.putalpha(alpha)
    assert result.getchannel("A").getbbox() is not None
    return result, painted


def fit_mother(record, picture):
    width = round(picture.width * (45 * 12) / picture.height)
    fitted = picture.resize((width, 45 * 12), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", CANVAS)
    canvas.alpha_composite(fitted, (record["mother_x"], 12))
    return canvas


def fit_father(record, upper_only=False):
    source = rgba(record["father"])
    left, top, right, bottom = record["father_visible"]
    figure = source.crop((left, top, right, bottom))
    width = round(figure.width * (45 * 12) / figure.height)
    fitted = figure.resize((width, 45 * 12), Image.Resampling.LANCZOS)
    if upper_only:
        source_cut = record["father_upper_source_y"] - top
        fitted_cut = round(source_cut * fitted.height / figure.height)
        alpha = fitted.getchannel("A")
        alpha.paste(0, (0, fitted_cut, fitted.width, fitted.height))
        fitted.putalpha(alpha)
    canvas = Image.new("RGBA", CANVAS)
    canvas.alpha_composite(fitted, (record["father_x"], 12))
    return canvas


def side_by_side(pictures):
    width = CANVAS[0] * len(pictures) + PANEL_GAP * (len(pictures) - 1)
    sheet = Image.new("RGBA", (width, CANVAS[1]))
    for index, picture in enumerate(pictures):
        sheet.alpha_composite(picture, (index * (CANVAS[0] + PANEL_GAP), 0))
    return sheet


def labeled_review(pictures, labels):
    sheet = Image.new("RGBA", (CANVAS[0] * len(pictures) + PANEL_GAP, CANVAS[1] + 34), (89, 105, 112, 255))
    draw = ImageDraw.Draw(sheet)
    for index, (picture, label) in enumerate(zip(pictures, labels, strict=True)):
        x = index * (CANVAS[0] + PANEL_GAP)
        sheet.alpha_composite(picture, (x, 0))
        draw.text((x + 8, CANVAS[1] + 9), label, fill="white")
    return sheet


def prepare(output):
    if output.exists():
        raise FileExistsError(f"output must be fresh: {output}")
    check_sources()
    output.mkdir(parents=True)
    composites = []
    father_refs = []
    mother_refs = []
    contour_records = {}
    for view in ("side", "front_diagonal"):
        record = SOURCE[view]
        mother = mother_figure(record)
        legs, boundary = coat_contour_leg_mask(mother, record["mother_min_leg_y"])
        mother_canvas = fit_mother(record, legs)
        father_canvas = fit_father(record)
        father_upper = fit_father(record, upper_only=True)
        composite = mother_canvas.copy()
        composite.alpha_composite(father_upper)
        composites.append(composite)
        father_refs.append(father_canvas)
        mother_refs.append(mother_canvas)
        legs.save(output / f"mother-{view}-legs-coat-contour.png")
        contour_records[view] = {
            "mother_whole_bounds": list(record["mother_whole"]),
            "minimum_search_y": record["mother_min_leg_y"],
            "coat_bottom_by_x": boundary,
            "father_visible_bounds": list(record["father_visible"]),
            "father_upper_source_y": record["father_upper_source_y"],
            "mother_registered_x_at_12x": record["mother_x"],
            "father_registered_x_at_12x": record["father_x"],
        }
    side_by_side(composites).save(output / "normalization-targets.png")
    side_by_side(father_refs).save(output / "father-high-resolution-reference.png")
    side_by_side(mother_refs).save(output / "mother-final-leg-reference.png")
    labeled_review(
        composites,
        ("E / W B · side", "SE / SW B · front diagonal"),
    ).save(output / "normalization-targets-review.png")
    manifest = {
        "operation": "high-resolution rough assembly for one generated normalization",
        "panel_order": ["side", "front_diagonal"],
        "canvas_per_panel": list(CANVAS),
        "panel_gap": PANEL_GAP,
        "sources": {
            view: {
                "father": str(record["father"].relative_to(ROOT)),
                "father_sha256": record["father_sha256"],
                "mother": str(record["mother"].relative_to(ROOT)),
                "mother_sha256": record["mother_sha256"],
            }
            for view, record in SOURCE.items()
        },
        "crops": contour_records,
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    prepare(args.output_dir)


if __name__ == "__main__":
    main()
