"""Assemble the registered pushing rig at the runtime's canonical draw positions."""

from __future__ import annotations

import argparse
import hashlib
import math
import os
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = Path(__file__).resolve().parent
PNG_RIG = EVIDENCE / "inputs/png"
SVG_RIG = EVIDENCE / "inputs/svg"
RASTERIZER = EVIDENCE / "rasterize-svg.gd"
CHECKSUMS = EVIDENCE / "SHA256SUMS"
DEFAULT_GODOT = Path("/Applications/Godot.app/Contents/MacOS/Godot")
EXPECTED_GODOT_VERSION = "4.7.2.stable.official.ed1daf0bf"
LABEL_FONT = ImageFont.load_default()
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

    def label(self) -> str:
        if self.horizontal == self.north == self.south and self.lift == 0.0:
            return f"{self.horizontal:g}px"
        return f"x{self.horizontal:g}/n{self.north:g}/s{self.south:g}/lift{self.lift:g}px"


BASELINE = Placement(34.0, 34.0, 34.0, 0.0)
CONTACT = Placement(22.0, 14.0, 8.0, -4.0)
PLACEMENTS = (BASELINE, CONTACT)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def checksums() -> dict[str, str]:
    result = {}
    for line in CHECKSUMS.read_text().splitlines():
        digest, relative = line.split("  ", maxsplit=1)
        result[relative] = digest
    return result


def verify_recipe_inputs(expected: dict[str, str]) -> None:
    recorded = {relative for relative in expected if relative.startswith("inputs/") or relative == RASTERIZER.name}
    present = {
        path.relative_to(EVIDENCE).as_posix()
        for directory in (PNG_RIG, SVG_RIG)
        for path in directory.iterdir()
        if path.is_file()
    }
    present.add(RASTERIZER.name)
    if present != recorded:
        raise RuntimeError("the preserved input set differs from SHA256SUMS")
    for relative in sorted(recorded):
        if sha256(EVIDENCE / relative) != expected[relative]:
            raise RuntimeError(f"stale input: {relative}")


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
    draw_order: str,
) -> None:
    angle = math.radians(degrees)
    facing_x = 0.0 if abs(math.cos(angle)) < 1e-9 else math.cos(angle)
    facing_y = 0.0 if abs(math.sin(angle)) < 1e-9 else math.sin(angle)
    vertical_distance = placement.south if facing_y > 0.0 else placement.north
    offset = (
        facing_x * placement.horizontal,
        facing_y * vertical_distance * OBLIQUE_Y + placement.lift,
    )
    mother = texture(rig, "mother", view, frame, mirror)
    pram = texture(rig, "pram", view, frame, mirror)
    parts = ((mother, (0.0, 0.0)), (pram, offset))
    pram_draws_first = facing_y < 0.0 if draw_order == "runtime" else offset[1] < 0.0
    if pram_draws_first:
        parts = tuple(reversed(parts))
    for image, (offset_x, offset_y) in parts:
        sheet.alpha_composite(
            image,
            (
                round(center_x + offset_x - image.width / 2),
                round(ground_y + offset_y - image.height),
            ),
        )


def assemble(
    destination: Path,
    placements: tuple[Placement, ...],
    rig: Path,
    family: str,
    draw_order: str,
) -> Path:
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
                font=LABEL_FONT,
            )
    for row, (label, view, mirror, degrees) in enumerate(DIRECTIONS):
        block = row // 4
        block_row = row % 4
        left = block * block_width
        top = header_height + block_row * cell_height
        draw.text((left + 1, top + 1), label, fill="white", font=LABEL_FONT)
        for column, (placement, frame) in enumerate(columns):
            center_x = left + label_width + column * cell_width + cell_width // 2
            ground_y = top + 56
            draw_pose(
                sheet,
                center_x,
                ground_y,
                view,
                frame,
                mirror,
                degrees,
                placement,
                rig,
                draw_order,
            )
    draw.text(
        (1, header_height + cell_height * 4 + 1),
        f"before: {placements[0].label()}    after: {placements[1].label()}",
        fill="white",
        font=LABEL_FONT,
    )
    draw.text(
        (1, header_height + cell_height * 4 + 9),
        f"Canonical {family} source assembly only; does not prove live turns or animation.",
        fill="white",
        font=LABEL_FONT,
    )
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination)
    enlarged = destination.with_name(f"{destination.stem.removesuffix('-native')}-8x.png")
    sheet.resize((sheet.width * 8, sheet.height * 8), Image.Resampling.NEAREST).save(enlarged)
    return enlarged


def verify_godot(godot: Path) -> None:
    version = subprocess.run([godot, "--version"], check=True, capture_output=True, text=True).stdout.strip()
    if version != EXPECTED_GODOT_VERSION:
        raise RuntimeError(f"Godot {EXPECTED_GODOT_VERSION} produced the recorded SVG rasters; found {version}")


def rasterize_svg_rig(destination: Path, godot: Path) -> None:
    verify_godot(godot)
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
            capture_output=True,
            text=True,
        )


def verify_outputs(
    family: str,
    draw_order: str,
    native: Path,
    enlarged: Path,
    expected: dict[str, str],
) -> None:
    if draw_order == "offset-snapshot":
        stem = f"review-snapshot-{family}"
    else:
        stem = "svg-comparison" if family == "svg" else "comparison"
    recorded_native = f"{stem}-native.png"
    recorded_enlarged = f"{stem}-8x.png"
    if sha256(native) != expected[recorded_native]:
        raise RuntimeError(f"output differs: {native}")
    if sha256(enlarged) != expected[recorded_enlarged]:
        raise RuntimeError(f"output differs: {enlarged}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--family", choices=("png", "svg"), default="png")
    parser.add_argument("--draw-order", choices=("runtime", "offset-snapshot"), default="runtime")
    parser.add_argument("--godot", type=Path, default=Path(os.environ.get("GODOT", DEFAULT_GODOT)))
    args = parser.parse_args()
    expected = checksums()
    verify_recipe_inputs(expected)
    if args.family == "png":
        enlarged = assemble(args.destination, PLACEMENTS, PNG_RIG, args.family, args.draw_order)
        verify_outputs(args.family, args.draw_order, args.destination, enlarged, expected)
        return
    with tempfile.TemporaryDirectory(prefix="pram-svg-rig-") as temporary:
        rig = Path(temporary)
        rasterize_svg_rig(rig, args.godot)
        enlarged = assemble(args.destination, PLACEMENTS, rig, args.family, args.draw_order)
        verify_outputs(args.family, args.draw_order, args.destination, enlarged, expected)


if __name__ == "__main__":
    main()
