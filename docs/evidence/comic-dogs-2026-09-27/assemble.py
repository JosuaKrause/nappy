"""Assemble source grids, candidates, review sheets, and pose-comparison GIFs.

Usage:
  uv run python assemble.py source-grids
  uv run python assemble.py candidates
  uv run python assemble.py verify

The source grids and all post-generation steps are deterministic. Image generation is not.
"""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RENDERS = HERE / "source-renders" / "art" / "events"
RAW = HERE / "raw"
CROPS = HERE / "crops"
CANDIDATES = HERE / "candidates"
TILES = ROOT / "art" / "illustrated" / "svg-transfer" / "tiles"
PAPER = (238, 235, 228, 255)
INK = (42, 34, 38, 255)
GOLD = (210, 164, 58, 255)
VIEWS = ["side", "front", "front diagonal", "back diagonal", "back"]
FAMILIES = {
    "dog": {
        "raw": "walked-dog-grid.png",
        "column_bounds": [0, 450, 780, 1230, 1660, 1983],
        "row_bounds": [0, 397, 793],
        "names": [
            "dog", "dog_b", "dog_front", "dog_front_b", "dog_front_diagonal",
            "dog_front_diagonal_b", "dog_back_diagonal", "dog_back_diagonal_b",
            "dog_back", "dog_back_b",
        ],
    },
    "charging-dog": {
        "raw": "charging-dog-grid.png",
        "column_bounds": [0, 530, 830, 1300, 1740, 2094],
        "row_bounds": [0, 376, 751],
        "names": [
            "charging_dog", "charging_dog_b", "charging_dog_front",
            "charging_dog_front_b", "charging_dog_front_diagonal",
            "charging_dog_front_diagonal_b", "charging_dog_back_diagonal",
            "charging_dog_back_diagonal_b", "charging_dog_back", "charging_dog_back_b",
        ],
    },
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_path(name: str) -> Path:
    return ROOT / "art" / "events" / f"{name}.svg"


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.convert("RGBA").getchannel("A").getbbox()
    if bbox is None:
        raise SystemExit("image has no visible alpha")
    return bbox


def source_grid(family: str, names: list[str]) -> dict[str, Any]:
    font = ImageFont.load_default()
    cell_w, cell_h = 252, 218
    left, top = 34, 28
    sheet = Image.new("RGBA", (left + cell_w * 5, top + cell_h * 2), PAPER)
    draw = ImageDraw.Draw(sheet)
    for column, view in enumerate(VIEWS):
        draw.text((left + column * cell_w + 6, 7), view, fill=INK, font=font)
    for row, phase in enumerate(("A", "B")):
        draw.text((8, top + row * cell_h + 8), phase, fill=INK, font=font)
    records: list[dict[str, Any]] = []
    for index, name in enumerate(names):
        column = index // 2
        row = index % 2
        x0 = left + column * cell_w
        y0 = top + row * cell_h
        draw.rectangle((x0, y0, x0 + cell_w - 1, y0 + cell_h - 1), outline=(166, 158, 151, 255))
        image_path = RENDERS / f"{name}@6.png"
        image = Image.open(image_path).convert("RGBA")
        x = x0 + (cell_w - image.width) // 2
        y = y0 + cell_h - 18 - image.height
        sheet.alpha_composite(image, (x, y))
        draw.line((x0 + 1, y0 + cell_h - 18, x0 + cell_w - 2, y0 + cell_h - 18), fill=GOLD)
        draw.text((x0 + 5, y0 + cell_h - 14), name, fill=INK, font=font)
        src = source_path(name)
        records.append({
            "cell": [column, row],
            "name": name,
            "source": str(src.relative_to(ROOT)),
            "source_sha256": sha256(src),
            "native_size": list(Image.open(RENDERS / f"{name}@1.png").size),
        })
    output = HERE / f"source-grid-{family}.png"
    sheet.convert("RGB").save(output, optimize=True)
    return {"family": family, "grid": output.name, "grid_size": list(sheet.size), "cells": records}


def build_source_grids() -> None:
    manifests = [source_grid(family, spec["names"]) for family, spec in FAMILIES.items()]
    path = HERE / "source-manifest.json"
    path.write_text(json.dumps({"families": manifests}, indent=2) + "\n", encoding="utf-8")
    for family in FAMILIES:
        print(HERE / f"source-grid-{family}.png")
    print(path)


def meaningful_alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.convert("RGBA").getchannel("A")
    meaningful = alpha.point(lambda value: 255 if value > 10 else 0)
    bbox = meaningful.getbbox()
    if bbox is None:
        raise SystemExit("image has no alpha above 10")
    return bbox


def padded_bbox(box: tuple[int, int, int, int], size: tuple[int, int]) -> tuple[int, int, int, int]:
    return (
        max(0, box[0] - 2),
        max(0, box[1] - 2),
        min(size[0], box[2] + 2),
        min(size[1], box[3] + 2),
    )


def extract_family(family: str, spec: dict[str, Any]) -> dict[str, Any]:
    raw_path = RAW / spec["raw"]
    raw = Image.open(raw_path).convert("RGBA")
    alpha_extrema = raw.getchannel("A").getextrema()
    if alpha_extrema[0] != 0 or alpha_extrema[1] == 0:
        raise SystemExit(f"{raw_path}: expected genuine transparent and visible pixels, got {alpha_extrema}")
    names: list[str] = spec["names"]
    records: list[dict[str, Any]] = []
    family_crops = CROPS / family
    family_candidates = CANDIDATES / family
    family_crops.mkdir(parents=True, exist_ok=True)
    family_candidates.mkdir(parents=True, exist_ok=True)
    trimmed: dict[str, Image.Image] = {}
    cell_records: dict[str, dict[str, Any]] = {}
    for index, name in enumerate(names):
        column = index // 2
        row = index % 2
        columns: list[int] = spec["column_bounds"]
        rows: list[int] = spec["row_bounds"]
        if columns[-1] != raw.width or rows[-1] != raw.height:
            raise SystemExit(f"{family}: recorded cell bounds do not match raw size {raw.size}")
        box = (columns[column], rows[row], columns[column + 1], rows[row + 1])
        cell = raw.crop(box)
        meaningful_bbox = meaningful_alpha_bbox(cell)
        crop_bbox = padded_bbox(meaningful_bbox, cell.size)
        crop = cell.crop(crop_bbox)
        crop_path = family_crops / f"{name}.png"
        crop.save(crop_path, optimize=True)
        trimmed[name] = crop
        cell_records[name] = {
            "grid_cell": [column, row],
            "grid_bounds": list(box),
            "meaningful_alpha_bounds_in_cell": list(meaningful_bbox),
            "crop_bounds_in_cell": list(crop_bbox),
            "crop": str(crop_path.relative_to(HERE)),
        }
    for view_index in range(5):
        pair = names[view_index * 2:view_index * 2 + 2]
        source_images = [Image.open(RENDERS / f"{name}@1.png").convert("RGBA") for name in pair]
        source_boxes = [alpha_bbox(image) for image in source_images]
        target = (
            min(box[0] for box in source_boxes),
            min(box[1] for box in source_boxes),
            max(box[2] for box in source_boxes),
            max(box[3] for box in source_boxes),
        )
        raw_width = max(trimmed[name].width for name in pair)
        raw_height = max(trimmed[name].height for name in pair)
        scale = min((target[2] - target[0]) / raw_width, (target[3] - target[1]) / raw_height)
        for name, source_image in zip(pair, source_images):
            crop = trimmed[name]
            size = (max(1, round(crop.width * scale)), max(1, round(crop.height * scale)))
            fitted = crop.resize(size, Image.Resampling.LANCZOS)
            canvas = Image.new("RGBA", source_image.size)
            x = round((target[0] + target[2] - fitted.width) / 2)
            y = target[3] - fitted.height
            canvas.alpha_composite(fitted, (x, y))
            candidate_path = family_candidates / f"{name}.png"
            canvas.save(candidate_path, optimize=True)
            record = {
                "name": name,
                "source": str(source_path(name).relative_to(ROOT)),
                "source_sha256": sha256(source_path(name)),
                "candidate": str(candidate_path.relative_to(HERE)),
                "candidate_sha256": sha256(candidate_path),
                "native_size": list(source_image.size),
                "source_pair_union_bounds": list(target),
                "shared_pair_scale": scale,
                "candidate_position": [x, y],
                "candidate_alpha_bounds": list(alpha_bbox(canvas)),
                **cell_records[name],
            }
            records.append(record)
    return {
        "family": family,
        "raw": str(raw_path.relative_to(HERE)),
        "raw_sha256": sha256(raw_path),
        "raw_size": list(raw.size),
        "raw_alpha_extrema": list(alpha_extrema),
        "grid_recipe": "family-specific inspected column and row boundaries; alpha > 10 locates each object; the selected crop preserves the original alpha unchanged",
        "cells": records,
    }


def tiled(kind: str, width: int, height: int, scale: int) -> Image.Image:
    tile = Image.open(TILES / f"{kind}.png").convert("RGBA")
    tile = tile.resize((tile.width * scale, tile.height * scale), Image.Resampling.NEAREST)
    result = Image.new("RGBA", (width, height))
    for y in range(0, height, tile.height):
        for x in range(0, width, tile.width):
            result.alpha_composite(tile, (x, y))
    return result


def facing_names(names: list[str], phase: int) -> list[tuple[str, bool, str]]:
    side, front, front_diag, back_diag, back = [names[index * 2 + phase] for index in range(5)]
    return [
        (side, False, "E"), (front_diag, False, "SE"), (front, False, "S"),
        (front_diag, True, "SW"), (side, True, "W"), (back_diag, True, "NW"),
        (back, False, "N"), (back_diag, False, "NE"),
    ]


def lineup(family: str, names: list[str], source: bool, phase: int, scale: int, ground: str) -> Image.Image:
    font = ImageFont.load_default()
    entries = facing_names(names, phase)
    images: list[Image.Image] = []
    for name, mirrored, _label in entries:
        path = RENDERS / f"{name}@1.png" if source else CANDIDATES / family / f"{name}.png"
        image = Image.open(path).convert("RGBA")
        if mirrored:
            image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        image = image.resize((image.width * scale, image.height * scale), Image.Resampling.NEAREST)
        images.append(image)
    gap = 8 * scale
    width = gap + sum(image.width + gap for image in images)
    height = max(image.height for image in images) + 24
    result = tiled(ground, width, height, scale)
    x = gap
    draw = ImageDraw.Draw(result)
    for image, (_name, _mirror, label) in zip(images, entries):
        result.alpha_composite(image, (x, height - 10 - image.height))
        draw.text((x, 2), label, fill=INK, font=font)
        x += image.width + gap
    return result


def labelled(image: Image.Image, label: str) -> Image.Image:
    font = ImageFont.load_default()
    result = Image.new("RGBA", (image.width, image.height + 18), PAPER)
    ImageDraw.Draw(result).text((3, 3), label, fill=INK, font=font)
    result.alpha_composite(image, (0, 18))
    return result


def enlarged_grid(family: str, names: list[str], source: bool) -> Image.Image:
    scale = 6
    cell_w, cell_h = 48 * scale, 36 * scale
    result = Image.new("RGBA", (cell_w * 5, cell_h * 2), PAPER)
    draw = ImageDraw.Draw(result)
    font = ImageFont.load_default()
    for index, name in enumerate(names):
        column = index // 2
        row = index % 2
        if source:
            image = Image.open(RENDERS / f"{name}@6.png").convert("RGBA")
        else:
            native = Image.open(CANDIDATES / family / f"{name}.png").convert("RGBA")
            image = native.resize((native.width * scale, native.height * scale), Image.Resampling.NEAREST)
        x0, y0 = column * cell_w, row * cell_h
        checker = Image.new("RGBA", (cell_w, cell_h), (224, 220, 214, 255))
        checker_draw = ImageDraw.Draw(checker)
        block = 12
        for y in range(0, cell_h, block):
            for x in range(0, cell_w, block):
                if (x // block + y // block) % 2:
                    checker_draw.rectangle((x, y, x + block - 1, y + block - 1), fill=(245, 242, 236, 255))
        result.alpha_composite(checker, (x0, y0))
        x = x0 + (cell_w - image.width) // 2
        y = y0 + cell_h - 18 - image.height
        result.alpha_composite(image, (x, y))
        draw.line((x0, y0 + cell_h - 18, x0 + cell_w - 1, y0 + cell_h - 18), fill=GOLD)
        draw.text((x0 + 3, y0 + cell_h - 14), name, fill=INK, font=font)
    return result


def stack(parts: list[Image.Image], path: Path) -> None:
    width = max(part.width for part in parts) + 16
    height = sum(part.height + 10 for part in parts) + 8
    sheet = Image.new("RGBA", (width, height), PAPER)
    y = 8
    for part in parts:
        sheet.alpha_composite(part, (8, y))
        y += part.height + 10
    sheet.convert("RGB").save(path, optimize=True)


def build_review(family: str, names: list[str]) -> None:
    parts: list[Image.Image] = []
    for phase, phase_name in enumerate(("A", "B")):
        parts.append(labelled(lineup(family, names, True, phase, 2, "sidewalk"),
                              f"SOURCE - phase {phase_name}, game scale 2x, all eight runtime facings"))
        parts.append(labelled(lineup(family, names, False, phase, 2, "sidewalk"),
                              f"CANDIDATE - phase {phase_name}, game scale 2x, all eight runtime facings"))
    parts.append(labelled(lineup(family, names, False, 0, 1, "road"),
                          "CANDIDATE - phase A at native 1x, all eight runtime facings"))
    parts.append(labelled(enlarged_grid(family, names, True),
                          "SOURCE - authored views and both phases enlarged 6x; yellow = ground anchor"))
    parts.append(labelled(enlarged_grid(family, names, False),
                          "CANDIDATE - native registered views enlarged 6x; checker = true transparency"))
    stack(parts, HERE / f"review-{family}.png")


def build_gif(family: str, names: list[str]) -> None:
    frames: list[Image.Image] = []
    title = "ASSEMBLED A/B POSE COMPARISON - NOT LIVE GAMEPLAY"
    for phase in range(2):
        frame = labelled(lineup(family, names, False, phase, 4, "sidewalk"), title)
        frames.append(frame.convert("RGB"))
    frames[0].save(HERE / f"pose-comparison-{family}.gif", save_all=True,
                   append_images=frames[1:], duration=450, loop=0, optimize=False)


def build_candidates() -> None:
    families = [extract_family(family, spec) for family, spec in FAMILIES.items()]
    manifest = {
        "recipe": "Inspected 5x2 raw-grid cells; alpha > 10 locates each object and a 2px pad preserves its original alpha; one shared scale and source-pair union registration per authored view; LANCZOS downsample; center and bottom align within the union. No SVG alpha mask is applied.",
        "families": families,
    }
    (HERE / "candidate-manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    for family, spec in FAMILIES.items():
        build_review(family, spec["names"])
        build_gif(family, spec["names"])
        print(HERE / f"review-{family}.png")
        print(HERE / f"pose-comparison-{family}.gif")


def verify() -> None:
    source_manifest = json.loads((HERE / "source-manifest.json").read_text(encoding="utf-8"))
    candidate_manifest = json.loads((HERE / "candidate-manifest.json").read_text(encoding="utf-8"))
    source_cells = [cell for family in source_manifest["families"] for cell in family["cells"]]
    candidate_cells = [cell for family in candidate_manifest["families"] for cell in family["cells"]]
    if len(source_cells) != 20 or len(candidate_cells) != 20:
        raise SystemExit(f"expected 20 sources and candidates, got {len(source_cells)} and {len(candidate_cells)}")
    by_name = {cell["name"]: cell for cell in source_cells}
    if len(by_name) != 20:
        raise SystemExit("source names are not unique")
    for cell in candidate_cells:
        source = ROOT / cell["source"]
        candidate = HERE / cell["candidate"]
        if cell["source_sha256"] != sha256(source) or cell["source_sha256"] != by_name[cell["name"]]["source_sha256"]:
            raise SystemExit(f"{cell['name']}: source hash drift")
        if cell["candidate_sha256"] != sha256(candidate):
            raise SystemExit(f"{cell['name']}: candidate hash drift")
        image = Image.open(candidate).convert("RGBA")
        if list(image.size) != cell["native_size"]:
            raise SystemExit(f"{cell['name']}: size {image.size}, expected {cell['native_size']}")
        low, high = image.getchannel("A").getextrema()
        if low != 0 or high == 0:
            raise SystemExit(f"{cell['name']}: alpha extrema {(low, high)}")
    for family in FAMILIES:
        review = HERE / f"review-{family}.png"
        gif = HERE / f"pose-comparison-{family}.gif"
        if not review.is_file() or not gif.is_file():
            raise SystemExit(f"{family}: missing review sheet or pose comparison")
    print("verified 20 source hashes, 20 native candidate sizes, true alpha, two review sheets, and two pose comparisons")


def main() -> None:
    if len(sys.argv) != 2 or sys.argv[1] in {"-h", "--help"}:
        print(__doc__)
        raise SystemExit(0 if len(sys.argv) == 2 else 2)
    command = sys.argv[1]
    if command == "source-grids":
        build_source_grids()
    elif command == "candidates":
        build_candidates()
    elif command == "verify":
        verify()
    else:
        raise SystemExit(f"unknown command: {command}")


if __name__ == "__main__":
    main()
