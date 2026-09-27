"""Assemble source grids and fixed-grid review artifacts for the comic dog preview.

Usage:
  uv run python assemble.py source-grids

The generated source grids are deterministic inputs to image generation. Later commands in this
file extract and register the retained raw outputs; image generation itself is nondeterministic.
"""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RENDERS = HERE / "source-renders" / "art" / "events"
PAPER = (238, 235, 228, 255)
INK = (42, 34, 38, 255)
VIEWS = ["side", "front", "front diagonal", "back diagonal", "back"]
FAMILIES = {
    "dog": [
        "dog", "dog_b", "dog_front", "dog_front_b", "dog_front_diagonal",
        "dog_front_diagonal_b", "dog_back_diagonal", "dog_back_diagonal_b",
        "dog_back", "dog_back_b",
    ],
    "charging-dog": [
        "charging_dog", "charging_dog_b", "charging_dog_front",
        "charging_dog_front_b", "charging_dog_front_diagonal",
        "charging_dog_front_diagonal_b", "charging_dog_back_diagonal",
        "charging_dog_back_diagonal_b", "charging_dog_back", "charging_dog_back_b",
    ],
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_path(name: str) -> Path:
    return ROOT / "art" / "events" / f"{name}.svg"


def source_grid(family: str, names: list[str]) -> dict[str, object]:
    font = ImageFont.load_default()
    cell_w, cell_h = 252, 218
    left, top = 34, 28
    sheet = Image.new("RGBA", (left + cell_w * 5, top + cell_h * 2), PAPER)
    draw = ImageDraw.Draw(sheet)
    for column, view in enumerate(VIEWS):
        draw.text((left + column * cell_w + 6, 7), view, fill=INK, font=font)
    for row, phase in enumerate(("A", "B")):
        draw.text((8, top + row * cell_h + 8), phase, fill=INK, font=font)
    records: list[dict[str, object]] = []
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
        draw.line((x0 + 1, y0 + cell_h - 18, x0 + cell_w - 2, y0 + cell_h - 18), fill=(210, 164, 58, 255))
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


def main() -> None:
    if len(sys.argv) != 2 or sys.argv[1] in {"-h", "--help"}:
        print(__doc__)
        raise SystemExit(0 if len(sys.argv) == 2 else 2)
    if sys.argv[1] != "source-grids":
        raise SystemExit(f"unknown command: {sys.argv[1]}")
    manifests = [source_grid(family, names) for family, names in FAMILIES.items()]
    path = HERE / "source-manifest.json"
    path.write_text(json.dumps({"families": manifests}, indent=2) + "\n", encoding="utf-8")
    for family in FAMILIES:
        print(HERE / f"source-grid-{family}.png")
    print(path)


if __name__ == "__main__":
    main()
