"""Assemble deterministic D carrying walking-rollout evidence from registered pixels."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
RIG = ROOT / "registered" / "rig"
OUT = Path(__file__).resolve().parent
SCALE = 6
SLATE = (38, 45, 54)
TEXT = (235, 239, 242)
MUTED = (170, 181, 190)

# EightDirection sector order, clockwise from east. The booleans reproduce
# Stroller._mother_is_mirrored() for sectors 3, 4 and 5.
DIRECTIONS = (
    ("E", "side", False),
    ("SE", "front_diagonal", False),
    ("S", "front", False),
    ("SW", "front_diagonal", True),
    ("W", "side", True),
    ("NW", "back_diagonal", True),
    ("N", "back", False),
    ("NE", "back_diagonal", False),
)


def font(size: int):
    for candidate in ("/System/Library/Fonts/SFNS.ttf", "/System/Library/Fonts/Helvetica.ttc"):
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


LABEL = font(14)
SMALL = font(10)


def source(name: str, frame: str, mirrored: bool) -> Image.Image:
    image = Image.open(RIG / f"mother_carrying_{name}_{frame}.png").convert("RGBA")
    if mirrored:
        image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return image


def paste_sprite(canvas: Image.Image, sprite: Image.Image, x: int, baseline: int) -> None:
    canvas.alpha_composite(sprite, (x - sprite.width // 2, baseline - sprite.height))


def label(draw: ImageDraw.ImageDraw, text: str, x: int, y: int, anchor: str = "mm", fill=TEXT) -> None:
    draw.text((x, y), text, font=LABEL, anchor=anchor, fill=fill)


def build_static() -> Image.Image:
    cell_w, cell_h = 192, 84
    title_h = 30
    canvas = Image.new("RGBA", (4 * cell_w, title_h + 2 * cell_h), SLATE + (255,))
    draw = ImageDraw.Draw(canvas)
    draw.text((canvas.width // 2, 8), "D — MATCHED PROPORTIONS", font=LABEL, anchor="ma", fill=TEXT)
    draw.text((canvas.width // 2, 22), "SOURCE-FRAME WALKING ROLLOUT", font=SMALL, anchor="ma", fill=MUTED)
    for index, (direction, view, mirrored) in enumerate(DIRECTIONS):
        col, row = index % 4, index // 4
        left, top = col * cell_w, title_h + row * cell_h
        label(draw, direction, left + cell_w // 2, top + 8)
        draw.text((left + cell_w // 2, top + 24), "A → B → A → B", font=SMALL,
                  anchor="mm", fill=MUTED)
        baseline = top + 77
        frames = [source(view, frame, mirrored) for frame in ("a", "b", "a", "b")]
        spacing = cell_w // 5
        for frame_index, sprite in enumerate(frames):
            paste_sprite(canvas, sprite, left + spacing * (frame_index + 1), baseline)
        draw.line((left + 8, baseline, left + cell_w - 8, baseline), fill=(92, 104, 115), width=1)
    return canvas.resize((canvas.width * SCALE, canvas.height * SCALE), Image.Resampling.NEAREST)


def build_animation() -> tuple[Image.Image, Image.Image]:
    cell_w, cell_h = 192, 92
    frames: list[Image.Image] = []
    for frame_name in ("a", "b"):
        canvas = Image.new("RGBA", (4 * cell_w, 2 * cell_h), SLATE + (255,))
        draw = ImageDraw.Draw(canvas)
        draw.text((canvas.width // 2, 7), "D CARRYING · SOURCE WALK ANIMATION",
                  font=LABEL, anchor="ma", fill=TEXT)
        for index, (direction, view, mirrored) in enumerate(DIRECTIONS):
            col, row = index % 4, index // 4
            left, top = col * cell_w, row * cell_h
            label(draw, direction, left + 14, top + 28, anchor="lm")
            baseline = top + 83
            paste_sprite(canvas, source(view, frame_name, mirrored), left + cell_w // 2 + 20, baseline)
            draw.line((left + 8, baseline, left + cell_w - 8, baseline), fill=(92, 104, 115), width=1)
        frames.append(canvas.resize((canvas.width * SCALE, canvas.height * SCALE), Image.Resampling.NEAREST).convert("RGB"))
    return frames[0], frames[1]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    static = build_static()
    static.save(OUT / "walking-rollout-D-static-6x.png")
    a, b = build_animation()
    a.save(OUT / "walking-rollout-D.gif", save_all=True, append_images=[b], duration=190,
           loop=0, optimize=False, disposal=2)
    a.save(OUT / "walking-rollout-D-A.png")
    b.save(OUT / "walking-rollout-D-B.png")
    manifest = {
        "source": "registered/rig/*.png",
        "scale": "6x nearest-neighbor",
        "directions": [
            {"direction": d, "view": v, "mirrored": m, "frames": ["a", "b", "a", "b"]}
            for d, v, m in DIRECTIONS
        ],
        "timing": {"duration_ms_per_frame": 190, "phase_rule": "_walk_phase += 92*dt*.09; sin(phase*2)>0"},
        "note": "Source animation preview in place; it does not claim gameplay travel or approval. D is the two-frame loop and retains the insufficient stride under review.",
        "sha256": {},
    }
    for path in sorted(RIG.glob("mother_carrying_*.png")):
        manifest["sha256"][path.name] = hashlib.sha256(path.read_bytes()).hexdigest()
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main()
