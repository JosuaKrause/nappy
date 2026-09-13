#!/usr/bin/env -S uv run --project .
"""Build deterministic F source strips, sheets, and eight-direction GIFs."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
SOURCE = HERE / "source"
FROZEN = SOURCE / "svg"
RENDERED = SOURCE / "rendered"
STRIPS = SOURCE / "strips"
MANIFEST = SOURCE / "source-manifest.json"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
FRAMES = ("a", "c", "b")
LOOP = ("a", "c", "b", "c")
DIRECTIONS = (
    ("N", "back", False),
    ("NE", "back_diagonal", False),
    ("E", "side", False),
    ("SE", "front_diagonal", False),
    ("S", "front", False),
    ("SW", "front_diagonal", True),
    ("W", "side", True),
    ("NW", "back_diagonal", True),
)
BG = (89, 105, 112, 255)
INK = (245, 247, 248, 255)
FONT_PATH = Path("/System/Library/Fonts/SFNS.ttf")
FONT_SHA256 = "2bfd40dc72e6759e248f82a52a40d551338979fffc9b5c070e685b4b7ad19e66"


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _font(size: int) -> ImageFont.FreeTypeFont:
    if not FONT_PATH.is_file() or _sha256(FONT_PATH) != FONT_SHA256:
        raise SystemExit(f"missing or changed review font: {FONT_PATH}")
    return ImageFont.truetype(FONT_PATH, size)


def _assert_inputs() -> None:
    manifest = json.loads(MANIFEST.read_text())
    expected = manifest["svg_sha256"]
    actual = {path.name: _sha256(path) for path in sorted(FROZEN.glob("*.svg"))}
    if actual != expected:
        raise SystemExit("frozen SVG inputs differ from source/source-manifest.json")
    expected_names = {
        f"mother_carrying_{view}_{frame}.svg" for view in VIEWS for frame in FRAMES
    }
    if set(actual) != expected_names:
        raise SystemExit("frozen SVG family is incomplete")
    if manifest["font_sha256"] != FONT_SHA256:
        raise SystemExit("manifest font hash differs from assembly script")


def _sprite(view: str, frame: str, scale: int, mirror: bool = False) -> Image.Image:
    suffix = "native" if scale == 1 else f"{scale}x"
    path = RENDERED / f"{view}_{frame}-{suffix}.png"
    image = Image.open(path).convert("RGBA")
    expected = (24 if view in {"front", "back"} else 26, 46)
    assert image.size == (expected[0] * scale, expected[1] * scale), (path, image.size)
    return image.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if mirror else image


def _strip(view: str, scale: int) -> None:
    margin = 18 * scale
    title_h = 17 * scale
    cell_w = 31 * scale
    cell_h = 50 * scale
    sheet = Image.new("RGBA", (margin * 2 + cell_w * 3, title_h + cell_h), BG)
    draw = ImageDraw.Draw(sheet)
    captions = {
        "front": "front · A left lead / C planted / B right lead",
        "back_diagonal": "back diagonal · A/C/B · NE axis",
    }
    caption = captions.get(view, f"{view.replace('_', ' ')} · A / C / B")
    draw.text((margin, 2 * scale), caption, font=_font(3 * scale), fill=INK)
    for column, frame in enumerate(FRAMES):
        sprite = _sprite(view, frame, scale)
        x = margin + column * cell_w + (cell_w - sprite.width) // 2
        y = title_h + cell_h - sprite.height
        sheet.alpha_composite(sprite, (x, y))
    STRIPS.mkdir(parents=True, exist_ok=True)
    name = view.replace("_", "-")
    sheet.save(STRIPS / f"{name}-acb-{scale}x.png")


def _diagonal_sheet(scale: int) -> None:
    label_w = 20 * scale
    title_h = 12 * scale
    cell_w = 31 * scale
    cell_h = 49 * scale
    sheet = Image.new("RGBA", (label_w + cell_w * 3, title_h + cell_h * 2), BG)
    draw = ImageDraw.Draw(sheet)
    font = _font(3 * scale)
    draw.text((2 * scale, 2 * scale), "F diagonals · A / C / B", font=font, fill=INK)
    for row, (label, view) in enumerate((("SE", "front_diagonal"), ("NE", "back_diagonal"))):
        draw.text((2 * scale, title_h + row * cell_h + 20 * scale), label, font=font, fill=INK)
        for column, frame in enumerate(FRAMES):
            sprite = _sprite(view, frame, scale)
            x = label_w + column * cell_w + (cell_w - sprite.width) // 2
            y = title_h + row * cell_h + cell_h - sprite.height
            sheet.alpha_composite(sprite, (x, y))
    sheet.save(SOURCE / f"diagonals-acb-{scale}x.png")


def _eight_direction_frame(frame: str, scale: int) -> Image.Image:
    margin = 4 * scale
    title_h = 10 * scale
    cell_w = 31 * scale
    cell_h = 52 * scale
    sheet = Image.new("RGBA", (margin * 2 + cell_w * 8, title_h + cell_h), BG)
    draw = ImageDraw.Draw(sheet)
    font = _font(3 * scale)
    for column, (label, view, mirror) in enumerate(DIRECTIONS):
        x0 = margin + column * cell_w
        draw.text((x0 + 2 * scale, 1 * scale), label, font=font, fill=INK)
        sprite = _sprite(view, frame, scale, mirror)
        x = x0 + (cell_w - sprite.width) // 2
        y = title_h + cell_h - sprite.height
        sheet.alpha_composite(sprite, (x, y))
    return sheet


def _eight_direction_outputs(scale: int) -> None:
    frames = [_eight_direction_frame(frame, scale) for frame in LOOP]
    static = Image.new("RGBA", (frames[0].width, frames[0].height * 4), BG)
    for row, frame in enumerate(frames):
        static.alpha_composite(frame, (0, row * frame.height))
    static.save(SOURCE / f"eight-direction-acbc-{scale}x.png")
    frames[0].save(
        SOURCE / f"eight-direction-acbc-{scale}x.gif",
        save_all=True,
        append_images=frames[1:],
        duration=[190, 190, 190, 190],
        loop=0,
        disposal=2,
    )


def main() -> None:
    global SOURCE, RENDERED, STRIPS
    parser = argparse.ArgumentParser(description=__doc__, epilog="Example: %(prog)s --output-dir /tmp/f-source-review")
    parser.add_argument("--rendered-dir", type=Path, default=RENDERED, help="directory of the 30 Godot source renders")
    parser.add_argument(
        "--output-dir", type=Path, required=True, help="new review directory; existing paths are refused"
    )
    args = parser.parse_args()
    if args.output_dir.exists():
        parser.error(f"refusing existing output: {args.output_dir}")
    _assert_inputs()
    RENDERED = args.rendered_dir.resolve()
    for view in VIEWS:
        for frame in FRAMES:
            for scale in (1, 6):
                _sprite(view, frame, scale).close()
    _font(18)
    SOURCE = args.output_dir.resolve()
    STRIPS = SOURCE / "strips"
    SOURCE.mkdir(parents=True)
    for scale in (1, 6):
        for view in VIEWS:
            _strip(view, scale)
        _diagonal_sheet(scale)
        _eight_direction_outputs(scale)
    print("assemble-source-review: wrote strips, diagonal sheets, and A/C/B/C source animations")


if __name__ == "__main__":
    main()
