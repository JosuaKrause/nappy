"""Register the generated handle-free south stroller and build comparison sheets."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
from types import ModuleType

from PIL import Image, ImageDraw
from PIL import __version__ as pillow_version

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
COMIC_RIG = ROOT / "docs/evidence/comic-rig-2026-09-12"
RIG = ROOT / "art/illustrated/svg-transfer/rig"

EXPECTED_HASHES = {
    "docs/evidence/comic-rig-2026-09-12/pram-atlas-background-corrected.png": (
        "549a1573c8f68d6216a703d2e033923a4e2109a9b3782eeb4804404728295d08"
    ),
    "docs/evidence/comic-rig-2026-09-12/registered/pram-atlas-extracted.png": (
        "e7d74176c74c80de4c99886d616e98a1e4fc86cadbf406cc62da7b518f0bb743"
    ),
    "art/illustrated/svg-transfer/rig/pram_back.png": (
        "c2e711adf9942321ac903168f696795219e6f6f02a93cdc9be307b841fdfb440"
    ),
    "docs/evidence/stroller-view-assignment-2026-09-12/inputs/pram_back.png": (
        "d2020ba1d2bf0407d50106bc81b441a79efec9b567c27ecd662acb0427419bb2"
    ),
    "art/illustrated/svg-transfer/rig/pram_front_diagonal.png": (
        "e60f151730e0ef0e56e9f42a088f32aa5105caf8c8d340453569aa6fb256dc63"
    ),
    "generated-pram-back-no-handle.png": ("87f955752307f2c71b5846b673ad8f66667ae5009449b2a495657df425ba34bc"),
}


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _checked(path: Path, expected: str) -> Path:
    assert path.is_file(), path
    actual = _sha256(path)
    assert actual == expected, (path, actual, expected)
    return path


def _load_comic_rig() -> ModuleType:
    path = COMIC_RIG / "convert.py"
    spec = importlib.util.spec_from_file_location("comic_rig_convert", path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _labeled_sheet(entries: list[tuple[str, Image.Image]], scale: int, destination: Path) -> None:
    label_height = 18 if scale == 1 else 24
    cell_width = 80 if scale == 1 else 310
    cell_height = 54 if scale == 1 else 278
    sheet = Image.new("RGBA", (cell_width * len(entries), cell_height), "#68767c")
    draw = ImageDraw.Draw(sheet)
    ground_y = cell_height - 5
    for index, (label, image) in enumerate(entries):
        draw.text((index * cell_width + 4, 4), label, fill="white")
        shown = image.resize((image.width * scale, image.height * scale), Image.Resampling.NEAREST)
        x = index * cell_width + (cell_width - shown.width) // 2
        y = ground_y - shown.height
        assert y >= label_height, (label, y)
        sheet.alpha_composite(shown, (x, y))
    sheet.save(destination)


def _source_comparison(before: Image.Image, after: Image.Image, destination: Path) -> None:
    entries = (("accepted source", before), ("handle removed", after))
    cell_width, cell_height = 520, 560
    sheet = Image.new("RGBA", (cell_width * 2, cell_height), "#68767c")
    draw = ImageDraw.Draw(sheet)
    for index, (label, image) in enumerate(entries):
        draw.text((index * cell_width + 8, 8), label, fill="white")
        bounds = image.getchannel("A").point(lambda alpha: 255 if alpha > 192 else 0).getbbox()
        assert bounds, label
        subject = image.crop(bounds)
        scale = min(480 / subject.width, 500 / subject.height)
        shown = subject.resize(
            (round(subject.width * scale), round(subject.height * scale)),
            Image.Resampling.LANCZOS,
        )
        x = index * cell_width + (cell_width - shown.width) // 2
        y = cell_height - 18 - shown.height
        sheet.alpha_composite(shown, (x, y))
    sheet.save(destination)


def register(raw: Path, output: Path) -> None:
    assert not output.exists(), f"Choose a new output directory: {output}"
    for relative, expected in EXPECTED_HASHES.items():
        path = HERE / relative if relative == "generated-pram-back-no-handle.png" else ROOT / relative
        _checked(path, expected)
    _checked(raw, EXPECTED_HASHES["generated-pram-back-no-handle.png"])

    raw_image = Image.open(raw).convert("RGBA")
    assert raw_image.size == (972, 1618), raw_image.size
    assert raw_image.getchannel("A").getextrema() == (0, 255)

    convert = _load_comic_rig()
    subject = raw_image.crop(convert._art_bounds(raw_image))
    palette = Image.open(COMIC_RIG / "registered/shared-palette.png")
    registered, measurement = convert._register_one("pram_back", subject, COMIC_RIG / "source", palette)
    assert registered.size == (30, 30)
    assert registered.getchannel("A").getbbox()
    assert registered.getchannel("A").getbbox()[3] == 30

    output.mkdir(parents=True)
    registered.save(output / "pram_front.png")

    north = Image.open(RIG / "pram_back.png").convert("RGBA")
    south_before = Image.open(ROOT / "docs/evidence/stroller-view-assignment-2026-09-12/inputs/pram_back.png").convert(
        "RGBA"
    )
    southeast = Image.open(RIG / "pram_front_diagonal.png").convert("RGBA")
    southwest = southeast.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    entries = [
        ("N", north),
        ("S before", south_before),
        ("S after", registered),
        ("SE", southeast),
        ("SW", southwest),
    ]
    _labeled_sheet(entries, 1, output / "comparison-native.png")
    _labeled_sheet(entries, 8, output / "comparison-8x.png")

    extracted = Image.open(COMIC_RIG / "registered/pram-atlas-extracted.png").convert("RGBA")
    assert extracted.size == (2172, 724), extracted.size
    original_cell = extracted.crop((434, 0, 869, 724))
    _source_comparison(original_cell, raw_image, output / "source-before-after.png")

    manifest = {
        "generator": "built-in image_gen.imagegen",
        "prompt_sha256": _sha256(HERE / "prompt.txt"),
        "generated_source": str(raw.relative_to(ROOT)),
        "generated_source_sha256": _sha256(raw),
        "generated_source_size": list(raw_image.size),
        "source_atlas": "docs/evidence/comic-rig-2026-09-12/pram-atlas-background-corrected.png",
        "source_cell": [434, 0, 869, 724],
        "source_cell_role": "upstream pram_back; installed as runtime south pram_front",
        "registered_output": "art/illustrated/svg-transfer/rig/pram_front.png",
        "registered_sha256": _sha256(output / "pram_front.png"),
        "registration_script_sha256": _sha256(Path(__file__)),
        "registration": measurement,
        "unchanged_context": {
            "north_sha256": _sha256(RIG / "pram_back.png"),
            "southeast_sha256": _sha256(RIG / "pram_front_diagonal.png"),
            "southwest": "runtime horizontal mirror of southeast",
        },
        "tool_versions": {
            "python": "3.14.7",
            "pillow": pillow_version,
        },
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--raw", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    register(args.raw.resolve(), args.output_dir.resolve())


if __name__ == "__main__":
    main()
