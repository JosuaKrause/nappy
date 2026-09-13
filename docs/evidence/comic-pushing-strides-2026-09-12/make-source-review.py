#!/usr/bin/env -S uv run --project tools
"""Freeze P1 and compose deterministic P2 pushing source-art review evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
SOURCE = HERE / "source"
BASE = "f39bd59"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
P1_FRAMES = ("a", "b")
P2_FRAMES = ("a", "c", "b")
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
DIRECTION_DEGREES = {
    "N": -90,
    "NE": -45,
    "E": 0,
    "SE": 45,
    "S": 90,
    "SW": 135,
    "W": 180,
    "NW": 225,
}
BG = (89, 105, 112, 255)
INK = (245, 247, 248, 255)
FONT_PATH = Path("/System/Library/Fonts/SFNS.ttf")
FONT_SHA256 = "2bfd40dc72e6759e248f82a52a40d551338979fffc9b5c070e685b4b7ad19e66"


def _sha256(path: Path) -> str:
    assert path.is_file(), path
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    assert FONT_PATH.is_file() and _sha256(FONT_PATH) == FONT_SHA256, FONT_PATH
    return ImageFont.truetype(FONT_PATH, size)


def _git_blob(path: str) -> bytes:
    result = subprocess.run(
        ["git", "show", f"{BASE}:{path}"],
        cwd=REPO,
        check=True,
        capture_output=True,
    )
    assert result.stdout, path
    return result.stdout


def freeze_p1(destination: Path) -> None:
    """Preserve the named two-pose family directly from the branch base."""
    assert not destination.exists(), f"P1 evidence already exists: {destination}"
    destination.mkdir(parents=True)
    for view in VIEWS:
        for frame in P1_FRAMES:
            stem = f"mother_{view}_{frame}"
            svg = _git_blob(f"assets/rig/{stem}.svg")
            png = _git_blob(f"assets/illustrated/svg-transfer/rig/{stem}.png")
            assert svg.lstrip().startswith(b"<!--") and b"<svg" in svg, stem
            assert png.startswith(b"\x89PNG\r\n\x1a\n"), stem
            (destination / f"{stem}.svg").write_bytes(svg)
            (destination / f"{stem}.png").write_bytes(png)


def _render(
    render_dir: Path,
    version: str,
    view: str,
    frame: str,
    scale: str,
) -> Image.Image:
    stem = f"{view}_{frame}" if frame else view
    path = render_dir / version / f"{stem}-{scale}.png"
    assert path.is_file(), f"missing Godot render: {path}"
    return Image.open(path).convert("RGBA")


def _source_sheet(
    render_dir: Path,
    version: str,
    frames: tuple[str, ...],
    scale: str,
) -> Image.Image:
    factor = 1 if scale == "native" else 6
    cell_w, cell_h = 54 * factor, 58 * factor
    left, title, header = 80 * factor, 18 * factor, 20 * factor
    sheet = Image.new(
        "RGBA",
        (left + cell_w * len(VIEWS), title + header + cell_h * len(frames)),
        BG,
    )
    draw = ImageDraw.Draw(sheet)
    font = _font(10 * factor)
    small = _font(8 * factor)
    label = "P1 — Two-pose push" if version == "p1" else "P2 — Three-pose push"
    draw.text((4 * factor, 3 * factor), f"{label} · SVG source poses", font=font, fill=INK)
    for column, view in enumerate(VIEWS):
        draw.text(
            (left + column * cell_w + 2 * factor, title),
            view.replace("_", " "),
            font=small,
            fill=INK,
        )
    names = {"a": "Contact A", "b": "Contact B", "c": "Together C"}
    for row, frame in enumerate(frames):
        draw.text(
            (4 * factor, title + header + row * cell_h + 22 * factor),
            names[frame],
            font=small,
            fill=INK,
        )
        for column, view in enumerate(VIEWS):
            sprite = _render(render_dir, version, view, frame, scale)
            x = left + column * cell_w + (cell_w - sprite.width) // 2
            y = title + header + row * cell_h + cell_h - sprite.height
            sheet.alpha_composite(sprite, (x, y))
    return sheet


def _animation_frame(render_dir: Path, frame: str, scale: str) -> Image.Image:
    factor = 1 if scale == "native" else 6
    cell_w, cell_h = 54 * factor, 62 * factor
    title = 18 * factor
    sheet = Image.new("RGBA", (cell_w * 4, title + cell_h * 2), BG)
    draw = ImageDraw.Draw(sheet)
    draw.text(
        (3 * factor, 2 * factor),
        "P2 — Three-pose push · A/C/B/C SVG loop",
        font=_font(8 * factor),
        fill=INK,
    )
    for index, (label, view, mirror) in enumerate(DIRECTIONS):
        column, row = index % 4, index // 4
        draw.text(
            (column * cell_w + 2 * factor, title + row * cell_h + 2 * factor),
            label,
            font=_font(7 * factor),
            fill=INK,
        )
        sprite = _render(render_dir, "p2", view, frame, scale)
        if mirror:
            sprite = sprite.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        x = column * cell_w + (cell_w - sprite.width) // 2
        y = title + row * cell_h + cell_h - sprite.height
        sheet.alpha_composite(sprite, (x, y))
    return sheet


def _contact_sheet(render_dir: Path, scale: str) -> Image.Image:
    factor = 1 if scale == "native" else 6
    cell_w, cell_h = 112 * factor, 68 * factor
    left, title, header = 22 * factor, 18 * factor, 16 * factor
    sheet = Image.new(
        "RGBA",
        (left + cell_w * len(P2_FRAMES), title + header + cell_h * len(DIRECTIONS)),
        BG,
    )
    draw = ImageDraw.Draw(sheet)
    draw.text(
        (3 * factor, 2 * factor),
        "P2 — Three-pose push · grounded source contact",
        font=_font(8 * factor),
        fill=INK,
    )
    for column, frame in enumerate(P2_FRAMES):
        draw.text(
            (left + column * cell_w + 3 * factor, title),
            {"a": "Contact A", "c": "Together C", "b": "Contact B"}[frame],
            font=_font(7 * factor),
            fill=INK,
        )
    for row, (label, view, mirror) in enumerate(DIRECTIONS):
        draw.text(
            (2 * factor, title + header + row * cell_h + 24 * factor),
            label,
            font=_font(7 * factor),
            fill=INK,
        )
        angle = math.radians(DIRECTION_DEGREES[label])
        facing_x = 0.0 if abs(math.cos(angle)) < 1e-9 else math.cos(angle)
        facing_y = 0.0 if abs(math.sin(angle)) < 1e-9 else math.sin(angle)
        vertical = 9.0 if facing_y > 0.0 else 17.0
        offset = (facing_x * 24.0 * factor, facing_y * vertical * 0.7 * factor)
        for column, frame in enumerate(P2_FRAMES):
            center_x = left + column * cell_w + cell_w // 2
            ground_y = title + header + row * cell_h + 58 * factor
            draw.line(
                (
                    left + column * cell_w + 2 * factor,
                    ground_y,
                    left + (column + 1) * cell_w - 2 * factor,
                    ground_y,
                ),
                fill="#9fc2c9",
                width=factor,
            )
            mother = _render(render_dir, "p2", view, frame, scale)
            pram = _render(render_dir, "pram", view, "", scale)
            pram = pram.resize(
                (round(pram.width * 7.0 / 6.0), round(pram.height * 7.0 / 6.0)),
                Image.Resampling.NEAREST,
            )
            if mirror:
                mother = mother.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                pram = pram.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            parts = ((mother, (0.0, 0.0)), (pram, offset))
            if facing_y < 0.0:
                parts = tuple(reversed(parts))
            for image, (offset_x, offset_y) in parts:
                sheet.alpha_composite(
                    image,
                    (
                        round(center_x + offset_x - image.width / 2),
                        round(ground_y + offset_y - image.height),
                    ),
                )
    return sheet


def review(outputs: Path, render_dir: Path) -> None:
    """Compose source sheets and the exact four-phase eight-direction loop."""
    assert not outputs.exists(), f"review output already exists: {outputs}"
    outputs.mkdir(parents=True)
    for scale in ("native", "6x"):
        _source_sheet(render_dir, "p1", P1_FRAMES, scale).save(
            outputs / f"p1-source-{scale}.png"
        )
        _source_sheet(render_dir, "p2", P2_FRAMES, scale).save(
            outputs / f"p2-source-{scale}.png"
        )
        _contact_sheet(render_dir, scale).save(outputs / f"p2-source-contact-{scale}.png")
        frames = [
            _animation_frame(render_dir, frame, scale)
            for frame in ("a", "c", "b", "c")
        ]
        frames[0].save(
            outputs / f"p2-source-animation-{scale}.gif",
            save_all=True,
            append_images=frames[1:],
            duration=[190, 190, 190, 190],
            loop=0,
            disposal=2,
        )

    files = sorted(path for path in outputs.rglob("*") if path.is_file())
    manifest = {
        "p1_version": "P1 — Two-pose push",
        "p1_git_source": BASE,
        "p2_version": "P2 — Three-pose push",
        "p2_loop": ["a", "c", "b", "c"],
        "directions": [label for label, _view, _mirror in DIRECTIONS],
        "gif_phase_ms": [190, 190, 190, 190],
        "review_font": str(FONT_PATH),
        "review_font_sha256": FONT_SHA256,
        "files": {
            str(path.relative_to(outputs)): _sha256(path)
            for path in files
            if path.name != "source-manifest.json"
        },
    }
    (outputs / "source-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    freeze_parser = commands.add_parser("freeze-p1", help="freeze P1 into a fresh directory")
    freeze_parser.add_argument("--output-dir", required=True, type=Path)
    review_parser = commands.add_parser("review", help="compose sheets into a fresh directory")
    review_parser.add_argument("--render-dir", required=True, type=Path)
    review_parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    if args.command == "freeze-p1":
        freeze_p1(args.output_dir.resolve())
    else:
        review(args.output_dir.resolve(), args.render_dir.resolve())


if __name__ == "__main__":
    main()
