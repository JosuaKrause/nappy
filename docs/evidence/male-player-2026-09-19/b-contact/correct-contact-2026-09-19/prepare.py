"""Prepare the carrying-F correct-contact donors for one father normalization attempt."""

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
RAW = ROOT / "docs/evidence/comic-carrying-hip-motion-2026-09-12/raw/carrying-f-selected.png"
REMOVER = ROOT / "tools/remove-checkerboard.py"
CANVAS = (26 * 12, 46 * 12)
GAP = 40
SOURCE = {
    "side": {
        "cell": (552, 755, 828, 1140),
        "visible": (49, 9, 220, 360),
        "leg_crop": (45, 232, 224, 365),
        "registered": ROOT / "docs/evidence/comic-carrying-hip-motion-2026-09-12/registered/extracted/mother_carrying_side_b.png",
        "registered_sha256": "1f097869a20714f8aa61227ddd017c2b462fe80c6e01e0cae72414b43bc8d62b",
        "father": ROOT / "docs/evidence/male-player-2026-09-19/registered/extracted/father_side_b.png",
        "father_sha256": "3fe82dc8e3e2c23578742ce35fb1dd34869081cdde3b8b5632457b84490bb7ae",
        "father_visible": (15, 11, 200, 365),
        "father_upper_y": 208,
        "father_x": 11,
        "near_chain": ((140, 224), (113, 274), (78, 335)),
        "far_chain": ((124, 224), (153, 279), (190, 339)),
    },
    "front_diagonal": {
        "cell": (828, 0, 1104, 400),
        "visible": (67, 21, 196, 392),
        "leg_crop": (84, 245, 164, 395),
        "registered": ROOT / "docs/evidence/comic-carrying-hip-motion-2026-09-12/registered/extracted/mother_carrying_front_diagonal_a.png",
        "registered_sha256": "72bdff73c001cdef4886a0dca9f97ab10f1737f549fe4fd932a80415a3010745",
        "father": ROOT / "docs/evidence/male-player-2026-09-19/registered/extracted/father_front_diagonal_b.png",
        "father_sha256": "3c2b3219bb71158a57078dcd782eaacb172f17f55bce09e43518e352488b323a",
        "father_visible": (41, 11, 186, 368),
        "father_upper_y": 208,
        "father_x": 45,
        "near_chain": ((118, 246), (111, 302), (106, 356)),
        "far_chain": ((143, 246), (145, 316), (145, 382)),
    },
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rgba(path):
    return Image.open(path).convert("RGBA")


def remover_module():
    spec = importlib.util.spec_from_file_location("correct_contact_neutral", REMOVER)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def extract_cell(raw, record, neutral):
    cell = raw.crop(record["cell"]).convert("RGBA")
    mask = neutral.neutral_background_mask(cell)
    assert any(mask), "neutral remover found no background"
    alpha = cell.getchannel("A")
    original = alpha.tobytes()
    alpha.putdata([0 if mask[index] else original[index] for index in range(len(mask))])
    cell.putalpha(alpha)
    assert cell.tobytes() == rgba(record["registered"]).tobytes()
    return cell


def contour_legs(cell, record):
    left, top, right, bottom = record["leg_crop"]
    crop = cell.crop((left, top, right, bottom))
    pixels = crop.load()
    red_bottom = []
    for x in range(crop.width):
        rows = []
        for y in range(crop.height):
            red, green, blue, alpha = pixels[x, y]
            if alpha > 8 and red > 75 and red > green * 1.28 and red > blue * 1.18:
                rows.append(y)
        red_bottom.append(max(rows) if rows else -1)
    boundary = red_bottom[:]
    for x in range(crop.width):
        nearby = [
            red_bottom[n]
            for n in range(max(0, x - 5), min(crop.width, x + 6))
            if red_bottom[n] >= 0
        ]
        if nearby:
            boundary[x] = max(nearby) + 4
    alpha = crop.getchannel("A")
    plane = alpha.load()
    for x, coat_bottom in enumerate(boundary):
        if coat_bottom >= 0:
            for y in range(min(crop.height, coat_bottom + 1)):
                plane[x, y] = 0
    crop.putalpha(alpha)
    assert crop.getchannel("A").getbbox() is not None
    return crop, boundary


def donor_canvas(record, legs):
    visible_left, visible_top, visible_right, visible_bottom = record["visible"]
    scale = (45 * 12) / (visible_bottom - visible_top)
    left, top, _, _ = record["leg_crop"]
    width = round(legs.width * scale)
    height = round(legs.height * scale)
    fitted = legs.resize((width, height), Image.Resampling.LANCZOS)
    fitted_visible_width = round((visible_right - visible_left) * scale)
    visible_x = round((CANVAS[0] - fitted_visible_width) / 2)
    x = round(visible_x + (left - visible_left) * scale)
    y = round(12 + (top - visible_top) * scale)
    canvas = Image.new("RGBA", CANVAS)
    canvas.alpha_composite(fitted, (x, y))
    return canvas, {"scale": scale, "placement_at_12x": [x, y], "fit_at_12x": [width, height]}


def father_upper_canvas(record):
    source = rgba(record["father"])
    left, top, right, bottom = record["father_visible"]
    upper = source.crop((left, top, right, record["father_upper_y"]))
    scale = (45 * 12) / (bottom - top)
    fitted = upper.resize(
        (round(upper.width * scale), round(upper.height * scale)),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", CANVAS)
    canvas.alpha_composite(fitted, (record["father_x"], 12))
    return canvas


def sheet(pictures):
    result = Image.new("RGBA", (CANVAS[0] * 2 + GAP, CANVAS[1]))
    for index, picture in enumerate(pictures):
        result.alpha_composite(picture, (index * (CANVAS[0] + GAP), 0))
    return result


def review_sheet(pictures, labels):
    result = Image.new("RGBA", (CANVAS[0] * 2 + GAP, CANVAS[1] + 34), (89, 105, 112, 255))
    draw = ImageDraw.Draw(result)
    for index, (picture, label) in enumerate(zip(pictures, labels, strict=True)):
        x = index * (CANVAS[0] + GAP)
        result.alpha_composite(picture, (x, 0))
        draw.text((x + 7, CANVAS[1] + 9), label, fill="white")
    return result


def contact_proof(cells):
    panels = []
    labels = []
    for view in ("side", "front_diagonal"):
        record = SOURCE[view]
        cell = cells[view]
        panel = Image.new("RGBA", cell.size, (89, 105, 112, 255))
        panel.alpha_composite(cell)
        draw = ImageDraw.Draw(panel)
        draw.line(record["far_chain"], fill=(255, 195, 65, 255), width=4)
        draw.line(record["near_chain"], fill=(73, 225, 146, 255), width=4)
        for point in record["far_chain"]:
            draw.ellipse((point[0] - 4, point[1] - 4, point[0] + 4, point[1] + 4), fill=(255, 195, 65, 255))
        for point in record["near_chain"]:
            draw.ellipse((point[0] - 4, point[1] - 4, point[0] + 4, point[1] + 4), fill=(73, 225, 146, 255))
        panels.append(panel)
        labels.append("SIDE · green near trails" if view == "side" else "DIAGONAL · green near trails higher")
    height = max(panel.height for panel in panels)
    result = Image.new("RGBA", (sum(panel.width for panel in panels) + GAP, height + 30), (89, 105, 112, 255))
    draw = ImageDraw.Draw(result)
    x = 0
    for panel, label in zip(panels, labels, strict=True):
        result.alpha_composite(panel, (x, 0))
        draw.text((x + 5, height + 8), label, fill="white")
        x += panel.width + GAP
    return result


def prepare(output):
    if output.exists():
        raise FileExistsError(f"output must be fresh: {output}")
    assert digest(RAW) == "27ba7489bf0efbf9e475c72bbd7f7670841c7111a0703355641122873ad8f7fb"
    assert digest(REMOVER) == "34e03aefd5aa2b3ed0025ce5801cb25bc3fa6ab9ce00669727e57c9b8fe71716"
    for record in SOURCE.values():
        assert digest(record["registered"]) == record["registered_sha256"]
        assert digest(record["father"]) == record["father_sha256"]
    output.mkdir(parents=True)
    raw = Image.open(RAW).convert("RGBA")
    neutral = remover_module()
    cells = {}
    donors = []
    fathers = []
    targets = []
    records = {}
    for view in ("side", "front_diagonal"):
        record = SOURCE[view]
        cells[view] = extract_cell(raw, record, neutral)
        legs, boundary = contour_legs(cells[view], record)
        donor, placement = donor_canvas(record, legs)
        father = father_upper_canvas(record)
        target = donor.copy()
        target.alpha_composite(father)
        legs.save(output / f"{view}-selected-legs.png")
        cells[view].save(output / f"{view}-selected-whole-source.png")
        donors.append(donor)
        fathers.append(father)
        targets.append(target)
        records[view] = {
            "source_role": "desired father B contact",
            "raw_cell": list(record["cell"]),
            "visible_bounds": list(record["visible"]),
            "leg_and_hem_crop": list(record["leg_crop"]),
            "coat_bottom_by_crop_x": boundary,
            "father_source": str(record["father"].relative_to(ROOT)),
            "father_above_pelvis_source_y": record["father_upper_y"],
            "donor_transform": placement,
        }
    sheet(targets).save(output / "normalization-targets.png")
    sheet(fathers).save(output / "father-above-pelvis-reference.png")
    sheet(donors).save(output / "correct-donor-leg-reference.png")
    review_sheet(targets, ("E / W desired B", "SE / SW desired B")).save(output / "normalization-targets-review.png")
    review_sheet(donors, ("SIDE · near trails left", "DIAGONAL · near trails higher")).save(output / "correct-donor-leg-review.png")
    contact_proof(cells).save(output / "correct-donor-contact-proof.png")
    manifest = {
        "raw_source": str(RAW.relative_to(ROOT)),
        "raw_source_sha256": digest(RAW),
        "neutral_remover": str(REMOVER.relative_to(ROOT)),
        "neutral_remover_sha256": digest(REMOVER),
        "panel_order": ["side desired B", "front diagonal desired B"],
        "canvas_per_panel": list(CANVAS),
        "records": records,
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    prepare(args.output_dir)


if __name__ == "__main__":
    main()
