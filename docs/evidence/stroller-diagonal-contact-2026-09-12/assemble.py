"""Assemble the frozen P2 north-diagonal poses before and after the contact adjustment."""

from __future__ import annotations

import argparse
import hashlib
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = Path(__file__).resolve().parent
INPUTS = EVIDENCE / "inputs"
FONT = ImageFont.load_default()
OBLIQUE_Y = 0.7
HORIZONTAL = 24.0
NORTH = 17.0
SOUTH = 9.0
DIAGONAL_ADJUSTMENT = 2.0
SCALE = 7.0 / 6.0
POSES = ("a", "c", "b")
FACING = (("N", "back", 0.0, -1.0, False), ("NE", "back_diagonal", 1.0, -1.0, False),
          ("NW", "back_diagonal", -1.0, -1.0, True))


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_inputs() -> None:
    recorded = {}
    for line in (EVIDENCE / "SHA256SUMS").read_text().splitlines():
        checksum, relative = line.split("  ", maxsplit=1)
        if relative.startswith("inputs/"):
            recorded[relative] = checksum
    expected = {path.relative_to(EVIDENCE).as_posix() for path in INPUTS.iterdir()}
    if set(recorded) != expected:
        raise RuntimeError("the frozen input set differs from SHA256SUMS")
    for relative, checksum in recorded.items():
        if digest(EVIDENCE / relative) != checksum:
            raise RuntimeError(f"stale input: {relative}")


def offset(x: float, y: float, diagonal_adjustment: bool) -> tuple[float, float]:
    facing_x = x / math.sqrt(x * x + y * y)
    facing_y = y / math.sqrt(x * x + y * y)
    vertical_distance = SOUTH if facing_y > 0.0 else NORTH
    adjustment = 0.0
    if diagonal_adjustment and facing_y < 0.0:
        adjustment = 4.0 * facing_x * facing_x * facing_y * facing_y * DIAGONAL_ADJUSTMENT
    return (facing_x * HORIZONTAL,
            facing_y * vertical_distance * OBLIQUE_Y + adjustment)


def image(name: str) -> Image.Image:
    return Image.open(INPUTS / name).convert("RGBA")


def pose(view: str, frame: str, mirror: bool) -> tuple[Image.Image, Image.Image]:
    mother, pram = image(f"mother_{view}_{frame}.png"), image(f"pram_{view}.png")
    if mirror:
        mother = mother.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        pram = pram.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return mother, pram


def draw_cell(sheet: Image.Image, left: int, top: int, label: str, view: str,
              frame: str, x: float, y: float, mirror: bool, adjusted: bool) -> None:
    mother, pram = pose(view, frame, mirror)
    pram = pram.resize((round(pram.width * SCALE), round(pram.height * SCALE)),
                       Image.Resampling.NEAREST)
    pram_x, pram_y = offset(x, y, adjusted)
    center_x, ground_y = left + 43, top + 58
    ImageDraw.Draw(sheet).text((left + 2, top + 2), label, fill="white", font=FONT)
    # The source images are bottom-center registered. North views draw the stroller first.
    sheet.alpha_composite(pram, (round(center_x + pram_x - pram.width / 2),
                                  round(ground_y + pram_y - pram.height)))
    sheet.alpha_composite(mother, (round(center_x - mother.width / 2),
                                    round(ground_y - mother.height)))


def build(output: Path) -> None:
    if output.exists():
        raise RuntimeError(f"refusing to overwrite {output}")
    enlarged = output.with_name(output.stem + "-6x.png")
    if enlarged.exists():
        raise RuntimeError(f"refusing to overwrite {enlarged}")
    cell_width, cell_height = 92, 74
    sheet = Image.new("RGBA", (cell_width * 6, cell_height * 3), "#68767c")
    for row, (label, view, x, y, mirror) in enumerate(FACING):
        for column, frame in enumerate(POSES):
            draw_cell(sheet, column * cell_width, row * cell_height,
                      f"{label} {frame} before", view, frame, x, y, mirror, False)
            draw_cell(sheet, (column + 3) * cell_width, row * cell_height,
                      f"{label} {frame} after", view, frame, x, y, mirror, True)
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)
    sheet.resize((sheet.width * 6, sheet.height * 6), Image.Resampling.NEAREST).save(enlarged)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    verify_inputs()
    build(args.output)


if __name__ == "__main__":
    main()
