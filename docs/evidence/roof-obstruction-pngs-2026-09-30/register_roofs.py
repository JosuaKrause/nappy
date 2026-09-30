#!/usr/bin/env python3
"""Register the approved generated roof family at native game scale."""

from __future__ import annotations

import argparse
import hashlib
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = Path(__file__).resolve().parent
RAW = EVIDENCE / "raw"
OUT = ROOT / "art/illustrated/roof-equipment"
REVIEW = EVIDENCE / "review"

FAMILY = RAW / "roof-family-cardinal-v2.png"
DUCT = RAW / "roof-duct-run-cardinal-v2.png"
EXPECTED = {
    FAMILY: "18bf57e7da22c4db095d1490a69010cdfa32519057399cab177f1a0d1995dc2e",
    DUCT: "aef595d6170d395baf2f65bc0a69d0446fb6d6d7b6f7e8dc62afd838d58e6cda",
}


@dataclass(frozen=True)
class Asset:
    name: str
    source: Path
    crop: tuple[int, int, int, int]
    canvas: tuple[int, int]
    max_content: tuple[int, int]


ASSETS = (
    Asset("water_tank", FAMILY, (0, 0, 384, 455), (40, 72), (38, 70)),
    Asset("hvac_large", FAMILY, (384, 0, 768, 455), (48, 40), (46, 38)),
    Asset("condenser", FAMILY, (768, 0, 1110, 455), (40, 40), (38, 38)),
    Asset("skylight_long", FAMILY, (1152, 0, 1536, 455), (56, 24), (54, 22)),
    Asset("skylight_pyramid", FAMILY, (0, 455, 384, 720), (44, 28), (42, 26)),
    Asset("vent_stack", FAMILY, (384, 455, 720, 720), (40, 48), (38, 46)),
    Asset("industrial_vent", FAMILY, (0, 720, 384, 1024), (44, 44), (42, 42)),
    Asset("service_bulkhead", FAMILY, (384, 720, 768, 1024), (48, 52), (46, 50)),
    Asset("exhaust_fan", FAMILY, (768, 720, 1100, 1024), (40, 36), (38, 34)),
    Asset("pipe_manifold", FAMILY, (1152, 720, 1536, 1024), (52, 40), (50, 38)),
    Asset("duct_run", DUCT, (0, 0, 1536, 1024), (64, 64), (62, 62)),
)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def cleaned_crop(asset: Asset) -> Image.Image:
    image = Image.open(asset.source).convert("RGBA").crop(asset.crop)
    pixels = image.load()
    # The generator's transparent output retains a low-alpha neutral preview glow. Its visible
    # ink/material begins well above this cutoff; zeroing the fringe keeps atlas bounds honest.
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            pixels[x, y] = (r, g, b, 0 if a < 72 else a)
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError(f"{asset.name}: empty alpha after cleanup")
    return image.crop(bbox)


def registered(asset: Asset) -> Image.Image:
    content = cleaned_crop(asset)
    scale = min(asset.max_content[0] / content.width, asset.max_content[1] / content.height)
    size = (max(1, round(content.width * scale)), max(1, round(content.height * scale)))
    content = content.resize(size, Image.Resampling.LANCZOS)
    alpha = content.getchannel("A").point(lambda value: 0 if value < 12 else value)
    content.putalpha(alpha)
    canvas = Image.new("RGBA", asset.canvas, (0, 0, 0, 0))
    # Every sprite is registered bottom-center. Runtime places this point at the roof foot.
    canvas.alpha_composite(content, ((asset.canvas[0] - size[0]) // 2, asset.canvas[1] - size[1]))
    return canvas


def build() -> None:
    for path, expected in EXPECTED.items():
        actual = digest(path)
        if actual != expected:
            raise RuntimeError(f"{path.name}: expected {expected}, got {actual}")
    OUT.mkdir(parents=True, exist_ok=True)
    for asset in ASSETS:
        registered(asset).save(OUT / f"{asset.name}.png", optimize=True)


def verify() -> None:
    failures: list[str] = []
    for asset in ASSETS:
        path = OUT / f"{asset.name}.png"
        if not path.exists():
            failures.append(f"missing {path.relative_to(ROOT)}")
            continue
        image = Image.open(path).convert("RGBA")
        if image.size != asset.canvas:
            failures.append(f"{asset.name}: {image.size} != {asset.canvas}")
        bbox = image.getchannel("A").getbbox()
        if bbox is None:
            failures.append(f"{asset.name}: empty alpha")
            continue
        if bbox[3] != image.height:
            failures.append(f"{asset.name}: foot is not registered to bottom edge ({bbox})")
        corners = (image.getpixel((0, 0))[3], image.getpixel((image.width - 1, 0))[3])
        if any(corners):
            failures.append(f"{asset.name}: nontransparent upper canvas corner {corners}")
    if failures:
        raise RuntimeError("\n".join(failures))


def review() -> None:
    REVIEW.mkdir(parents=True, exist_ok=True)
    scale = 4
    width, height = 896, 760
    sheet = Image.new("RGBA", (width, height), "#c8c4ba")
    draw = ImageDraw.Draw(sheet)
    cell = 16
    for y in range(0, height, cell):
        for x in range(0, width, cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill="#aaa69d")
    for index, asset in enumerate(ASSETS):
        col, row = index % 4, index // 4
        x, y = 20 + col * 220, 20 + row * 240
        image = Image.open(OUT / f"{asset.name}.png").convert("RGBA")
        image = image.resize((image.width * scale, image.height * scale), Image.Resampling.NEAREST)
        sheet.alpha_composite(image, (x, y + 180 - image.height))
        draw.text((x, y + 188), asset.name.replace("_", " "), fill="#201d1a")
    sheet.convert("RGB").save(REVIEW / "roof-family-native-4x.png", optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "verify", "review", "all"))
    args = parser.parse_args()
    if args.command in ("build", "all"):
        build()
    if args.command in ("verify", "all"):
        verify()
    if args.command in ("review", "all"):
        review()


if __name__ == "__main__":
    main()
