#!/usr/bin/env python3
"""Install the retained tree and layered water-main generations at native registration."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RAW = HERE / "raw"
SOURCE = HERE / "source-renders"
TRANSFER = ROOT / "art/illustrated/svg-transfer"
ALPHA_CUTOFF = 8
NEAR_OPAQUE = 248

RAW_INPUTS = {
    "trees-family-v2-cardinal.png": "1caa7f0fda1849a981c5b63a9327f00a8301721ce3b27ea0e8216fbb9cb52b2e",
    "water-horizontal-layers-v1.png": "ba470782beee03204c29edde97b9ac2c34385d89940c66e3f3285cab9f83f44f",
    "water-vertical-layers-v1.png": "86af2b3e2604ebd60b8c760d1680f55b369b7d0946e9f432ea675372fe847807",
}

TREE_SPECS = [
    ("events-fallen_tree.png", (0, 0, 1050, 520), "events/fallen_tree.png"),
    ("events-fallen_tree_vertical.png", (1050, 0, 1536, 600), "events/fallen_tree_vertical.png"),
    ("closures-fallen_tree.png", (0, 500, 1000, 1024), "closures/fallen_tree.png"),
    ("closures-fallen_tree_vertical.png", (1050, 600, 1536, 1024), "closures/fallen_tree_vertical.png"),
]

HORIZONTAL_NAMES = [
    "burst_water_main_static_0",
    "burst_water_main_motion_1",
    "burst_water_main_motion_1_b",
    "burst_water_main_static_2",
    "burst_water_main_motion_3",
    "burst_water_main_motion_3_b",
    "burst_water_main_static_4",
    "burst_water_main_motion_5",
    "burst_water_main_motion_5_b",
    "burst_water_main_static_6",
]
VERTICAL_NAMES = [
    "burst_water_main_vertical_static_0",
    "burst_water_main_vertical_motion_1",
    "burst_water_main_vertical_motion_1_b",
    "burst_water_main_vertical_static_2",
    "burst_water_main_vertical_motion_3",
    "burst_water_main_vertical_motion_3_b",
    "burst_water_main_vertical_static_4",
    "burst_water_main_vertical_motion_5",
    "burst_water_main_vertical_motion_5_b",
    "burst_water_main_vertical_static_6",
]

LAYERS = {
    "burst_water_main": [
        ("burst_water_main_static_0", 26, 21, False),
        ("burst_water_main_motion_1", 38, 29, True),
        ("burst_water_main_static_2", 62, 15, False),
        ("burst_water_main_motion_3", 76, 37, True),
        ("burst_water_main_static_4", 51, 22, False),
        ("burst_water_main_motion_5", 63, 1, True),
        ("burst_water_main_static_6", 3, 1, False),
    ],
    "burst_water_main_vertical": [
        ("burst_water_main_vertical_static_0", 3, 1, False),
        ("burst_water_main_vertical_motion_1", 8, 40, True),
        ("burst_water_main_vertical_static_2", 7, 49, False),
        ("burst_water_main_vertical_motion_3", 15, 114, True),
        ("burst_water_main_vertical_static_4", 0, 72, False),
        ("burst_water_main_vertical_motion_5", 0, 82, True),
        ("burst_water_main_vertical_static_6", 14, 166, False),
    ],
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def clean_alpha(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha <= ALPHA_CUTOFF:
                pixels[x, y] = (0, 0, 0, 0)
            elif alpha >= NEAR_OPAQUE:
                pixels[x, y] = (red, green, blue, 255)
    return image


def alpha_box(image: Image.Image) -> tuple[int, int, int, int]:
    box = image.getchannel("A").getbbox()
    if box is None:
        raise RuntimeError("generated cell contains no retained pixels")
    return box


def register(
    cell: Image.Image, reference: Image.Image, *, preserve_aspect: bool = True
) -> Image.Image:
    cell = clean_alpha(cell)
    art = cell.crop(alpha_box(cell))
    reference = reference.convert("RGBA")
    target_box = alpha_box(reference)
    target_width = target_box[2] - target_box[0]
    target_height = target_box[3] - target_box[1]
    if preserve_aspect:
        scale = min(target_width / art.width, target_height / art.height)
        size = (max(1, round(art.width * scale)), max(1, round(art.height * scale)))
    else:
        size = (target_width, target_height)
    art = art.resize(size, Image.Resampling.LANCZOS)
    art = clean_alpha(art)
    canvas = Image.new("RGBA", reference.size)
    x = target_box[0] + (target_width - art.width) // 2
    y = target_box[1] + (target_height - art.height) // 2
    canvas.alpha_composite(art, (x, y))
    return canvas


def register_horizontal_barriers(cell: Image.Image, reference: Image.Image) -> Image.Image:
    cell = clean_alpha(cell)
    art = cell.crop(alpha_box(cell))
    reference = reference.convert("RGBA")
    canvas = Image.new("RGBA", reference.size)
    for side in range(2):
        art_bounds = (side * art.width // 2, 0, (side + 1) * art.width // 2, art.height)
        ref_bounds = (
            side * reference.width // 2,
            0,
            (side + 1) * reference.width // 2,
            reference.height,
        )
        art_half = art.crop(art_bounds)
        ref_half = reference.crop(ref_bounds)
        registered = register(art_half, ref_half)
        canvas.alpha_composite(registered, (ref_bounds[0], 0))
    return canvas


def install_trees(records: list[dict[str, object]]) -> None:
    sheet = Image.open(RAW / "trees-family-v2-cardinal.png").convert("RGBA")
    if sheet.size != (1536, 1024):
        raise RuntimeError(f"unexpected tree sheet size: {sheet.size}")
    for source_name, crop, destination_name in TREE_SPECS:
        source = Image.open(SOURCE / source_name)
        installed = register(sheet.crop(crop), source, preserve_aspect=False)
        destination = TRANSFER / destination_name
        destination.parent.mkdir(parents=True, exist_ok=True)
        installed.save(destination)
        records.append(record(destination, source, installed, crop))


def grid_cell(sheet: Image.Image, index: int) -> Image.Image:
    column = index % 5
    row = index // 5
    left = round(column * sheet.width / 5)
    right = round((column + 1) * sheet.width / 5)
    top = round(row * sheet.height / 2)
    bottom = round((row + 1) * sheet.height / 2)
    return sheet.crop((left, top, right, bottom))


def install_layer_sheet(
    raw_name: str, names: list[str], records: list[dict[str, object]]
) -> None:
    sheet = Image.open(RAW / raw_name).convert("RGBA")
    for index, name in enumerate(names):
        source = Image.open(SOURCE / "water-layers-native" / f"{name}.png")
        cell = grid_cell(sheet, index)
        installed = (
            register_horizontal_barriers(cell, source)
            if name == "burst_water_main_static_6"
            else register(cell, source)
        )
        destination = TRANSFER / "events" / f"{name}.png"
        destination.parent.mkdir(parents=True, exist_ok=True)
        installed.save(destination)
        records.append(record(destination, source, installed, (index % 5, index // 5)))


def composite(stem: str, phase_b: bool) -> Image.Image:
    canvas_size = (50, 200) if stem.endswith("_vertical") else (200, 50)
    canvas = Image.new("RGBA", canvas_size)
    for name, x, y, moving in LAYERS[stem]:
        suffix = "_b" if phase_b and moving else ""
        layer = Image.open(TRANSFER / "events" / f"{name}{suffix}.png").convert("RGBA")
        canvas.alpha_composite(layer, (x, y))
    return canvas


def install_full_water(records: list[dict[str, object]]) -> None:
    for stem in LAYERS:
        for phase_b in (False, True):
            suffix = "_b" if phase_b else ""
            installed = composite(stem, phase_b)
            source = Image.open(SOURCE / f"events-{stem}{suffix}.png")
            destination = TRANSFER / "events" / f"{stem}{suffix}.png"
            installed.save(destination)
            records.append(record(destination, source, installed, "layer composition"))


def record(
    destination: Path,
    source: Image.Image,
    installed: Image.Image,
    extraction: object,
) -> dict[str, object]:
    return {
        "path": str(destination.relative_to(ROOT)),
        "size": list(installed.size),
        "source_size": list(source.size),
        "source_alpha_box": list(alpha_box(source.convert("RGBA"))),
        "installed_alpha_box": list(alpha_box(installed)),
        "extraction": extraction,
        "sha256": digest(destination),
    }


def contact_sheet(paths: list[Path], scale: int, output: Path) -> None:
    background = (221, 216, 202, 255)
    columns = 2
    label_height = 18
    cells: list[tuple[Path, Image.Image]] = []
    for path in paths:
        image = Image.open(path).convert("RGBA")
        if scale != 1:
            image = image.resize((image.width * scale, image.height * scale), Image.Resampling.NEAREST)
        cells.append((path, image))
    cell_width = max(image.width for _, image in cells) + 24
    cell_height = max(image.height for _, image in cells) + label_height + 24
    rows = (len(cells) + columns - 1) // columns
    sheet = Image.new("RGBA", (cell_width * columns, cell_height * rows), background)
    draw = ImageDraw.Draw(sheet)
    for index, (path, image) in enumerate(cells):
        origin = ((index % columns) * cell_width, (index // columns) * cell_height)
        label = str(path.relative_to(TRANSFER).with_suffix(""))
        draw.text((origin[0] + 8, origin[1] + 4), label, fill=(42, 34, 38, 255))
        x = origin[0] + (cell_width - image.width) // 2
        y = origin[1] + label_height + (cell_height - label_height - image.height) // 2
        sheet.alpha_composite(image, (x, y))
    sheet.convert("RGB").save(output)


def write_review_artifacts() -> None:
    paths = [
        TRANSFER / "events/fallen_tree.png",
        TRANSFER / "events/fallen_tree_vertical.png",
        TRANSFER / "closures/fallen_tree.png",
        TRANSFER / "closures/fallen_tree_vertical.png",
        TRANSFER / "events/burst_water_main.png",
        TRANSFER / "events/burst_water_main_b.png",
        TRANSFER / "events/burst_water_main_vertical.png",
        TRANSFER / "events/burst_water_main_vertical_b.png",
    ]
    contact_sheet(paths, 1, HERE / "review-native.png")
    contact_sheet(paths, 4, HERE / "review-enlarged.png")

    background = (221, 216, 202, 255)
    frames: list[Image.Image] = []
    for phase_b in (False, True):
        suffix = "_b" if phase_b else ""
        horizontal = Image.open(TRANSFER / "events" / f"burst_water_main{suffix}.png").convert("RGBA")
        vertical = Image.open(TRANSFER / "events" / f"burst_water_main_vertical{suffix}.png").convert("RGBA")
        frame = Image.new("RGBA", (320, 220), background)
        frame.alpha_composite(horizontal, (10, 85))
        frame.alpha_composite(vertical, (250, 10))
        frame = frame.resize((frame.width * 3, frame.height * 3), Image.Resampling.NEAREST)
        frames.append(frame.convert("P", palette=Image.Palette.ADAPTIVE))
    frames[0].save(
        HERE / "water-phases.gif",
        save_all=True,
        append_images=frames[1:],
        duration=500,
        loop=0,
        disposal=2,
    )


def main() -> None:
    for name, expected in RAW_INPUTS.items():
        actual = digest(RAW / name)
        if actual != expected:
            raise RuntimeError(f"raw input changed: {name}: expected {expected}, got {actual}")
    records: list[dict[str, object]] = []
    install_trees(records)
    install_layer_sheet("water-horizontal-layers-v1.png", HORIZONTAL_NAMES, records)
    install_layer_sheet("water-vertical-layers-v1.png", VERTICAL_NAMES, records)
    install_full_water(records)
    write_review_artifacts()
    source_paths = [
        ROOT / "docs/style-references/graphics-reference-urban-01.jpeg",
        ROOT / "docs/style-references/graphics-reference-cardinal.jpeg",
        ROOT / "art/events/fallen_tree.svg",
        ROOT / "art/events/fallen_tree_vertical.svg",
        ROOT / "art/closures/fallen_tree.svg",
        ROOT / "art/closures/fallen_tree_vertical.svg",
        ROOT / "art/events/burst_water_main.svg",
        ROOT / "art/events/burst_water_main_b.svg",
        ROOT / "art/events/burst_water_main_vertical.svg",
        ROOT / "art/events/burst_water_main_vertical_b.svg",
    ]
    source_paths.extend(ROOT / "art/events" / f"{name}.svg" for name in HORIZONTAL_NAMES)
    source_paths.extend(ROOT / "art/events" / f"{name}.svg" for name in VERTICAL_NAMES)
    manifest = {
        "raw_inputs": RAW_INPUTS,
        "source_inputs": {
            str(path.relative_to(ROOT)): digest(path) for path in source_paths
        },
        "alpha_cleanup": {"transparent_at_or_below": ALPHA_CUTOFF, "opaque_at_or_above": NEAR_OPAQUE},
        "outputs": records,
    }
    (HERE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"installed {len(records)} native PNGs and review artifacts")


if __name__ == "__main__":
    main()
