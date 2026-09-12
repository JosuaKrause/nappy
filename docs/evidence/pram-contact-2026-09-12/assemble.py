"""Assemble the registered pushing rig at the runtime's canonical draw positions."""

from __future__ import annotations

import argparse
import math
import os
import re
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
PNG_RIG = ROOT / "assets/illustrated/svg-transfer/rig"
SVG_RIG = ROOT / "assets/rig"
RASTERIZER = ROOT / "docs/evidence/style-transfer-2026-09-10/rasterize-svg.gd"
DEFAULT_GODOT = Path("/Applications/Godot.app/Contents/MacOS/Godot")
STROLLER = ROOT / "src/player/stroller.gd"
OBLIQUE_Y = 0.7
DIRECTIONS = (
    ("N", "back", False, -90),
    ("NE", "back_diagonal", False, -45),
    ("E", "side", False, 0),
    ("SE", "front_diagonal", False, 45),
    ("S", "front", False, 90),
    ("SW", "front_diagonal", True, 135),
    ("W", "side", True, 180),
    ("NW", "back_diagonal", True, 225),
)


@dataclass(frozen=True)
class Placement:
    horizontal: float
    north: float
    south: float
    lift: float

    @classmethod
    def parse(cls, value: str) -> Placement:
        parts = [float(part) for part in value.split(",")]
        if len(parts) == 1:
            return cls(parts[0], parts[0], parts[0], 0.0)
        assert len(parts) == 4, "placement must be DISTANCE or HORIZONTAL,NORTH,SOUTH,LIFT"
        return cls(*parts)

    def label(self) -> str:
        if self.horizontal == self.north == self.south and self.lift == 0.0:
            return f"{self.horizontal:g}px"
        return f"x{self.horizontal:g}/n{self.north:g}/s{self.south:g}/lift{self.lift:g}px"


BASELINE = Placement(34.0, 34.0, 34.0, 0.0)


def active_placement() -> Placement:
    source = STROLLER.read_text()
    values = []
    for name in (
        "PRAM_HORIZONTAL_DISTANCE",
        "PRAM_NORTH_DISTANCE",
        "PRAM_SOUTH_DISTANCE",
        "PRAM_VERTICAL_LIFT",
    ):
        match = re.search(rf"^const {name} := (-?[0-9.]+)$", source, re.MULTILINE)
        assert match, f"{name} is absent or no longer a literal"
        values.append(float(match.group(1)))
    return Placement(*values)


def texture(rig: Path, subject: str, view: str, frame: str, mirror: bool) -> Image.Image:
    suffix = f"_{frame}" if subject == "mother" else ""
    image = Image.open(rig / f"{subject}_{view}{suffix}.png").convert("RGBA")
    if mirror:
        image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return image


def draw_pose(
    sheet: Image.Image,
    center_x: int,
    ground_y: int,
    view: str,
    frame: str,
    mirror: bool,
    degrees: int,
    placement: Placement,
    rig: Path,
) -> None:
    angle = math.radians(degrees)
    vertical_distance = placement.south if math.sin(angle) > 0.0 else placement.north
    offset = (
        math.cos(angle) * placement.horizontal,
        math.sin(angle) * vertical_distance * OBLIQUE_Y + placement.lift,
    )
    mother = texture(rig, "mother", view, frame, mirror)
    pram = texture(rig, "pram", view, frame, mirror)
    parts = ((mother, (0.0, 0.0)), (pram, offset))
    if offset[1] < 0.0:
        parts = tuple(reversed(parts))
    for image, (offset_x, offset_y) in parts:
        sheet.alpha_composite(
            image,
            (
                round(center_x + offset_x - image.width / 2),
                round(ground_y + offset_y - image.height),
            ),
        )


def assemble(destination: Path, placements: list[Placement], rig: Path, family: str) -> None:
    cell_width = 78
    cell_height = 64
    label_width = 9
    header_height = 12
    footer_height = 18
    columns = [(placement, frame) for placement in placements for frame in ("a", "b")]
    block_width = label_width + cell_width * len(columns)
    sheet = Image.new(
        "RGBA",
        (block_width * 2, header_height + cell_height * 4 + footer_height),
        "#68767c",
    )
    draw = ImageDraw.Draw(sheet)
    phase_labels = ("before", "after")
    for block in range(2):
        for column, (_placement, frame) in enumerate(columns):
            draw.text(
                (block * block_width + label_width + column * cell_width + 1, 2),
                f"{phase_labels[column // 2]} / frame {frame}",
                fill="white",
            )
    for row, (label, view, mirror, degrees) in enumerate(DIRECTIONS):
        block = row // 4
        block_row = row % 4
        left = block * block_width
        top = header_height + block_row * cell_height
        draw.text((left + 1, top + 1), label, fill="white")
        for column, (placement, frame) in enumerate(columns):
            center_x = left + label_width + column * cell_width + cell_width // 2
            ground_y = top + 56
            draw_pose(sheet, center_x, ground_y, view, frame, mirror, degrees, placement, rig)
    draw.text(
        (1, header_height + cell_height * 4 + 1),
        f"before: {placements[0].label()}    after: {placements[1].label()}",
        fill="white",
    )
    draw.text(
        (1, header_height + cell_height * 4 + 9),
        f"Canonical {family} source assembly only; does not prove live turns or animation.",
        fill="white",
    )
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination)
    enlarged = destination.with_name(f"{destination.stem.removesuffix('-native')}-8x.png")
    sheet.resize((sheet.width * 8, sheet.height * 8), Image.Resampling.NEAREST).save(enlarged)


def rasterize_svg_rig(destination: Path) -> None:
    godot = Path(os.environ.get("GODOT", DEFAULT_GODOT))
    views = {view for _label, view, _mirror, _degrees in DIRECTIONS}
    names = [f"mother_{view}_{frame}" for view in views for frame in ("a", "b")]
    names.extend(f"pram_{view}" for view in views)
    for name in sorted(names):
        subprocess.run(
            [
                godot,
                "--headless",
                "--path",
                ROOT,
                "--script",
                RASTERIZER,
                "--",
                SVG_RIG / f"{name}.svg",
                destination / f"{name}.png",
                "1",
            ],
            check=True,
        )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    parser.add_argument("placements", nargs="*", type=Placement.parse)
    parser.add_argument("--family", choices=("png", "svg"), default="png")
    args = parser.parse_args()
    placements = args.placements or [BASELINE, active_placement()]
    if args.family == "png":
        assemble(args.destination, placements, PNG_RIG, args.family)
        return
    with tempfile.TemporaryDirectory(prefix="pram-svg-rig-") as temporary:
        rig = Path(temporary)
        rasterize_svg_rig(rig)
        assemble(args.destination, placements, rig, args.family)


if __name__ == "__main__":
    main()
