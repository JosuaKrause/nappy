#!/usr/bin/env -S uv run --project tools
"""Compose deterministic A/C/B SVG review sheets from Godot-rendered PNGs."""

import hashlib
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
RENDERED = ROOT / "source" / "svg-rendered"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
FRAMES = ("a", "c", "b")
BG = (89, 105, 112, 255)
INK = (245, 247, 248, 255)
FONT_PATH = Path("/System/Library/Fonts/SFNS.ttf")
FONT_SHA256 = "2bfd40dc72e6759e248f82a52a40d551338979fffc9b5c070e685b4b7ad19e66"


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    if not FONT_PATH.is_file() or hashlib.sha256(FONT_PATH.read_bytes()).hexdigest() != FONT_SHA256:
        raise SystemExit(f"missing or changed review font: {FONT_PATH}")
    return ImageFont.truetype(FONT_PATH, size)


def _compose(scale: int) -> None:
    cell_w, cell_h = 180, 310
    title_h, header_h, label_w = 55, 70, 180
    sheet = Image.new("RGBA", (label_w + cell_w * len(VIEWS), header_h + cell_h * len(FRAMES)), BG)
    draw = ImageDraw.Draw(sheet)
    font = _font(26)
    small = _font(20)
    draw.text((24, 12), "E — Clear strides · SVG source poses", font=font, fill=INK)
    for column, view in enumerate(VIEWS):
        draw.text((label_w + column * cell_w + 8, title_h), view.replace("_", "\n"), font=small, fill=INK)
    labels = {"a": "Contact 1 (A)", "c": "Passing (C)", "b": "Contact 2 (B)"}
    for row, frame in enumerate(FRAMES):
        draw.text((18, header_h + row * cell_h + 130), labels[frame], font=small, fill=INK)
        for column, view in enumerate(VIEWS):
            path = RENDERED / f"{view}_{frame}-{scale}x.png"
            if not path.exists():
                raise SystemExit(f"missing Godot render: {path}")
            sprite = Image.open(path).convert("RGBA")
            x = label_w + column * cell_w + (cell_w - sprite.width) // 2
            y = header_h + row * cell_h + (cell_h - sprite.height) // 2
            sheet.alpha_composite(sprite, (x, y))
    output = ROOT / "source" / f"svg-acb-{scale}x.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)


if __name__ == "__main__":
    _compose(6)
