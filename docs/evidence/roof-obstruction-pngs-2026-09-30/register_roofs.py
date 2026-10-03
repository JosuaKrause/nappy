#!/usr/bin/env python3
"""Rebuild the approved roof family into a fresh output directory."""

from __future__ import annotations

import argparse
import hashlib
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = Path(__file__).resolve().parent
RAW = EVIDENCE / "raw"
INSTALLED = ROOT / "art/illustrated/roof-equipment"
ASSET_RELATIVE = Path("art/illustrated/roof-equipment")
REVIEW_RELATIVE = Path("docs/evidence/roof-equipment-scale-2026-10-03/source-crops-4x.png")
COMMITTED_REVIEW = ROOT / REVIEW_RELATIVE

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
    Asset("condenser", FAMILY, (768, 0, 1110, 455), (32, 40), (30, 38)),
    Asset("skylight_long", FAMILY, (1105, 0, 1536, 455), (56, 24), (54, 22)),
    Asset("skylight_pyramid", FAMILY, (0, 455, 384, 720), (32, 28), (30, 26)),
    Asset("vent_stack", FAMILY, (384, 455, 720, 720), (40, 48), (38, 46)),
    Asset("industrial_vent", FAMILY, (0, 720, 384, 1024), (44, 44), (42, 42)),
    Asset("service_bulkhead", FAMILY, (384, 720, 768, 1024), (48, 52), (46, 50)),
    Asset("exhaust_fan", FAMILY, (768, 720, 1100, 1024), (32, 36), (30, 34)),
    Asset("pipe_manifold", FAMILY, (1105, 720, 1536, 1024), (52, 40), (50, 38)),
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
    if bbox[0] == 0 or bbox[2] == image.width:
        raise RuntimeError(f"{asset.name}: extraction cuts through the silhouette's side ({bbox})")
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


def verify_inputs() -> None:
    for path, expected in EXPECTED.items():
        actual = digest(path)
        if actual != expected:
            raise RuntimeError(f"{path.name}: expected {expected}, got {actual}")


def build(output: Path) -> None:
    output.mkdir(parents=True)
    for asset in ASSETS:
        registered(asset).save(output / f"{asset.name}.png", optimize=True)


def verify(output_root: Path) -> None:
    output = output_root / ASSET_RELATIVE
    failures: list[str] = []
    for asset in ASSETS:
        path = output / f"{asset.name}.png"
        if not path.exists():
            failures.append(f"missing {path.relative_to(output_root)}")
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
        committed = INSTALLED / path.name
        if path.read_bytes() != committed.read_bytes():
            failures.append(f"{asset.name}: bytes differ from {committed.relative_to(ROOT)}")
    review = output_root / REVIEW_RELATIVE
    if not review.exists():
        failures.append(f"missing {review.relative_to(output_root)}")
    elif review.read_bytes() != COMMITTED_REVIEW.read_bytes():
        failures.append(f"review sheet: bytes differ from {COMMITTED_REVIEW.relative_to(ROOT)}")
    if failures:
        raise RuntimeError("\n".join(failures))


def review(output: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True)
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
        image = Image.open(output / f"{asset.name}.png").convert("RGBA")
        image = image.resize((image.width * scale, image.height * scale), Image.Resampling.NEAREST)
        sheet.alpha_composite(image, (x, y + 180 - image.height))
        draw.text((x, y + 188), asset.name.replace("_", " "), fill="#201d1a")
    sheet.convert("RGB").save(destination, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "verify", "all"))
    parser.add_argument("output", type=Path, help="fresh rebuild root, or existing root to verify")
    args = parser.parse_args()
    output_root = args.output.expanduser().resolve()
    if args.command in ("build", "all") and output_root.exists():
        raise SystemExit(f"refusing existing output directory: {output_root}")
    verify_inputs()
    if args.command in ("build", "all"):
        output = output_root / ASSET_RELATIVE
        build(output)
        review(output, output_root / REVIEW_RELATIVE)
        print(f"rebuilt {len(ASSETS)} roof PNGs and review sheet in {output_root}")
    if args.command in ("verify", "all"):
        if not output_root.is_dir():
            raise SystemExit(f"missing output directory: {output_root}")
        verify(output_root)
        print("verified rebuilt files byte-for-byte against committed roof outputs")


if __name__ == "__main__":
    main()
