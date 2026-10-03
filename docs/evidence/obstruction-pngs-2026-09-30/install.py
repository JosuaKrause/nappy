#!/usr/bin/env python3
"""Rebuild retained tree and layered water-main PNGs in a fresh directory."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RAW = HERE / "raw"
SOURCE = HERE / "source-renders"
ALPHA_CUTOFF = 8
NEAR_OPAQUE = 248

RAW_INPUTS = {
    "trees-family-v2-cardinal.png": "1caa7f0fda1849a981c5b63a9327f00a8301721ce3b27ea0e8216fbb9cb52b2e",
    "water-horizontal-layers-v1.png": "ba470782beee03204c29edde97b9ac2c34385d89940c66e3f3285cab9f83f44f",
    "water-vertical-layers-v1.png": "86af2b3e2604ebd60b8c760d1680f55b369b7d0946e9f432ea675372fe847807",
}

SOURCE_RENDER_INPUTS = {
    "closures-fallen_tree.png": "370d710554598febc3f3b8b2cf2415c9ae48a5aed21e562d611d0aed88308c10",
    "closures-fallen_tree_vertical.png": "977147353fe782f460de158b4a13c7c9d54abc8a1c961f42cfccc0c9143c1413",
    "events-burst_water_main.png": "64997a39280fc5fc8cf7583cf2f910e8e8a8c109cde7b6705a2dd631be1ea517",
    "events-burst_water_main_b.png": "b861d25e76475e28d838847363722bea438c657cb21870eaa1c02ef73942bc36",
    "events-burst_water_main_vertical.png": "88a5285b5b88cfc9c28663ee70eefa71c61fe8bc698548af20fb91bcdc41ba5b",
    "events-burst_water_main_vertical_b.png": "e2ce5d82dc2528e27fb48bc8bafbe41fc1f1760d0b1b8e4c4aed229164fa8bd5",
    "events-fallen_tree.png": "8bfdc25175a9bed64fec69a746ee78d4188a8a90b60871cd44469f0d265bb97d",
    "events-fallen_tree_vertical.png": "70f3bab8475fd167a7ca4305e269f1d84851463776d20ccb43971cdfadc3e561",
    "water-layers-native/burst_water_main_motion_1.png": "62941584c5391accaf0b140f5675f273e19593ac2cbe653d3e2ab3932a7ff122",
    "water-layers-native/burst_water_main_motion_1_b.png": "d9050b487a37f42c2a9ea4b98f18f8d8ad8b3d3fce28b51a7962353d8acabd16",
    "water-layers-native/burst_water_main_motion_3.png": "1328af78f9aaf34e5059e1cba591d7e40bfc1186620c8c6f50ca58b46b70c8a1",
    "water-layers-native/burst_water_main_motion_3_b.png": "d49860f56b10204c6888a84e2a909c34876f5fd9b76a93c4322827a9ba207a1f",
    "water-layers-native/burst_water_main_motion_5.png": "10a42ec33f309cdef3aebfdef21ee957a23b2e3cc3157d5af726b436eec2a2a9",
    "water-layers-native/burst_water_main_motion_5_b.png": "8d956e1873485ef41fd138ba9b76d2fadb9d9e1561bdee34db4ce58ace5ac36e",
    "water-layers-native/burst_water_main_static_0.png": "9576666189eed1109efd8d15aab9db109033ffc57bbfca958d6e758767fe01dc",
    "water-layers-native/burst_water_main_static_2.png": "3b57a65210ab5fb21c621e68795533c87e6e6a14898e0681201667310b89c86e",
    "water-layers-native/burst_water_main_static_4.png": "eafacad9ba5298d5d6e79975fa02470d9ab0c0f7c2ed1de75a073b6893b766e6",
    "water-layers-native/burst_water_main_static_6.png": "8bb12688fea493fb017144276a9c2af2a4b758f1110c7d53fa91566a0f0fe0cc",
    "water-layers-native/burst_water_main_vertical_motion_1.png": "419ad7b937b0724109edb5468af751d577ced823cedf70cb2d60245ddb65773d",
    "water-layers-native/burst_water_main_vertical_motion_1_b.png": "91284242a5d57b011cc3bf0b0d64bbecb1874563a49c3234f30ea89d377ad7fd",
    "water-layers-native/burst_water_main_vertical_motion_3.png": "7c246661f9728c0e98d0cf768554e79121eb4ee7dce4393546ce8982fb9cb32f",
    "water-layers-native/burst_water_main_vertical_motion_3_b.png": "489d9f3f4e712f7b25642a908ea877da29fd6ee70378f273a775503f39093e3e",
    "water-layers-native/burst_water_main_vertical_motion_5.png": "ec031479bba5f70951646ae19b85227686ce4625aa92467e6648d480023fed33",
    "water-layers-native/burst_water_main_vertical_motion_5_b.png": "975d7d4d92f33629d7cf5ce6c25f282119c87a0f78bce5558d0b6b2d7710f847",
    "water-layers-native/burst_water_main_vertical_static_0.png": "8af837f3e23c19172e999ec9eaadb28a168113865b89ecc939447b486e35180d",
    "water-layers-native/burst_water_main_vertical_static_2.png": "7296c379f2be5838f138d4f4793172f2e2e1af981ad5246f63eb41717d9ec49e",
    "water-layers-native/burst_water_main_vertical_static_4.png": "7b1536679507348a22b25f5b8d83720072caddbae6df7e57460c533c30aad027",
    "water-layers-native/burst_water_main_vertical_static_6.png": "0d923869495ec60999adb403b6a02fc4f4937573bdbd5a092549b874dc595e08",
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


def install_trees(transfer: Path, output_root: Path, records: list[dict[str, object]]) -> None:
    sheet = Image.open(RAW / "trees-family-v2-cardinal.png").convert("RGBA")
    if sheet.size != (1536, 1024):
        raise RuntimeError(f"unexpected tree sheet size: {sheet.size}")
    for source_name, crop, destination_name in TREE_SPECS:
        source = Image.open(SOURCE / source_name)
        installed = register(sheet.crop(crop), source, preserve_aspect=False)
        destination = transfer / destination_name
        destination.parent.mkdir(parents=True, exist_ok=True)
        installed.save(destination)
        records.append(record(destination, output_root, source, installed, crop))


def grid_cell(sheet: Image.Image, index: int) -> Image.Image:
    column = index % 5
    row = index // 5
    left = round(column * sheet.width / 5)
    right = round((column + 1) * sheet.width / 5)
    top = round(row * sheet.height / 2)
    bottom = round((row + 1) * sheet.height / 2)
    return sheet.crop((left, top, right, bottom))


def install_layer_sheet(
    raw_name: str,
    names: list[str],
    transfer: Path,
    output_root: Path,
    records: list[dict[str, object]],
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
        destination = transfer / "events" / f"{name}.png"
        destination.parent.mkdir(parents=True, exist_ok=True)
        installed.save(destination)
        records.append(
            record(destination, output_root, source, installed, (index % 5, index // 5))
        )


def composite(stem: str, phase_b: bool, transfer: Path) -> Image.Image:
    canvas_size = (50, 200) if stem.endswith("_vertical") else (200, 50)
    canvas = Image.new("RGBA", canvas_size)
    for name, x, y, moving in LAYERS[stem]:
        suffix = "_b" if phase_b and moving else ""
        layer = Image.open(transfer / "events" / f"{name}{suffix}.png").convert("RGBA")
        canvas.alpha_composite(layer, (x, y))
    return canvas


def install_full_water(
    transfer: Path, output_root: Path, records: list[dict[str, object]]
) -> None:
    for stem in LAYERS:
        for phase_b in (False, True):
            suffix = "_b" if phase_b else ""
            installed = composite(stem, phase_b, transfer)
            source = Image.open(SOURCE / f"events-{stem}{suffix}.png")
            destination = transfer / "events" / f"{stem}{suffix}.png"
            installed.save(destination)
            records.append(
                record(destination, output_root, source, installed, "layer composition")
            )


def record(
    destination: Path,
    output_root: Path,
    source: Image.Image,
    installed: Image.Image,
    extraction: object,
) -> dict[str, object]:
    return {
        "path": str(destination.relative_to(output_root)),
        "size": list(installed.size),
        "source_size": list(source.size),
        "source_alpha_box": list(alpha_box(source.convert("RGBA"))),
        "installed_alpha_box": list(alpha_box(installed)),
        "extraction": extraction,
        "sha256": digest(destination),
    }


def contact_sheet(paths: list[Path], transfer: Path, scale: int, output: Path) -> None:
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
        label = str(path.relative_to(transfer).with_suffix(""))
        draw.text((origin[0] + 8, origin[1] + 4), label, fill=(42, 34, 38, 255))
        x = origin[0] + (cell_width - image.width) // 2
        y = origin[1] + label_height + (cell_height - label_height - image.height) // 2
        sheet.alpha_composite(image, (x, y))
    sheet.convert("RGB").save(output)


def write_review_artifacts(transfer: Path, evidence: Path) -> None:
    paths = [
        transfer / "events/fallen_tree.png",
        transfer / "events/fallen_tree_vertical.png",
        transfer / "closures/fallen_tree.png",
        transfer / "closures/fallen_tree_vertical.png",
        transfer / "events/burst_water_main.png",
        transfer / "events/burst_water_main_b.png",
        transfer / "events/burst_water_main_vertical.png",
        transfer / "events/burst_water_main_vertical_b.png",
    ]
    evidence.mkdir(parents=True, exist_ok=True)
    contact_sheet(paths, transfer, 1, evidence / "review-native.png")
    contact_sheet(paths, transfer, 4, evidence / "review-enlarged.png")

    background = (221, 216, 202, 255)
    frames: list[Image.Image] = []
    for phase_b in (False, True):
        suffix = "_b" if phase_b else ""
        horizontal = Image.open(transfer / "events" / f"burst_water_main{suffix}.png").convert("RGBA")
        vertical = Image.open(transfer / "events" / f"burst_water_main_vertical{suffix}.png").convert("RGBA")
        frame = Image.new("RGBA", (320, 220), background)
        frame.alpha_composite(horizontal, (10, 85))
        frame.alpha_composite(vertical, (250, 10))
        frame = frame.resize((frame.width * 3, frame.height * 3), Image.Resampling.NEAREST)
        frames.append(frame.convert("P", palette=Image.Palette.ADAPTIVE))
    frames[0].save(
        evidence / "water-phases.gif",
        save_all=True,
        append_images=frames[1:],
        duration=500,
        loop=0,
        disposal=2,
    )


def verify_inputs(paths: dict[str, str], parent: Path, kind: str) -> None:
    for name, expected in paths.items():
        actual = digest(parent / name)
        if actual != expected:
            raise RuntimeError(f"{kind} changed: {name}: expected {expected}, got {actual}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Rebuild obstruction PNGs into a new, otherwise nonexistent directory."
    )
    parser.add_argument("output", type=Path, help="fresh output directory")
    args = parser.parse_args()
    output_root = args.output.expanduser().resolve()
    if output_root.exists():
        raise SystemExit(f"refusing existing output directory: {output_root}")

    verify_inputs(RAW_INPUTS, RAW, "raw input")
    verify_inputs(SOURCE_RENDER_INPUTS, SOURCE, "frozen source render")
    transfer = output_root / "art/illustrated/svg-transfer"
    evidence = output_root / "docs/evidence/obstruction-pngs-2026-09-30"
    output_root.mkdir(parents=True)
    records: list[dict[str, object]] = []
    install_trees(transfer, output_root, records)
    install_layer_sheet(
        "water-horizontal-layers-v1.png", HORIZONTAL_NAMES, transfer, output_root, records
    )
    install_layer_sheet(
        "water-vertical-layers-v1.png", VERTICAL_NAMES, transfer, output_root, records
    )
    install_full_water(transfer, output_root, records)
    write_review_artifacts(transfer, evidence)
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
        "frozen_source_renders": SOURCE_RENDER_INPUTS,
        "source_inputs": {
            str(path.relative_to(ROOT)): digest(path) for path in source_paths
        },
        "alpha_cleanup": {"transparent_at_or_below": ALPHA_CUTOFF, "opaque_at_or_above": NEAR_OPAQUE},
        "outputs": records,
    }
    (evidence / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"rebuilt {len(records)} native PNGs and review artifacts in {output_root}")


if __name__ == "__main__":
    main()
