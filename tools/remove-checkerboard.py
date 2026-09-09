#!/usr/bin/env python3
"""Extract painted pixels from a neutral checkerboard PNG without changing geometry.

This is intentionally bounded to neutral, bright connected regions.  It does not claim
mathematically lossless removal of an arbitrary checkerboard or background.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image

NEUTRAL_SPREAD = 9
FRINGE_SPREAD = 16
MIN_BACKGROUND_LUMA = 170
MIN_COMPONENT_PIXELS = 12


def neutral_background_mask(image: Image.Image) -> bytearray:
    rgb = image.convert("RGB")
    width, height = rgb.size
    # The raw byte plane rather than per-pixel access: three bytes per pixel, row-major, which
    # is both the cheap way to walk a whole image and the one whose element type is plainly int.
    raw = rgb.tobytes()

    def pixel_at(index: int) -> tuple[int, int, int]:
        offset = index * 3
        return raw[offset], raw[offset + 1], raw[offset + 2]

    candidate = bytearray(width * height)
    for index in range(width * height):
        r, g, b = pixel_at(index)
        if max(r, g, b) - min(r, g, b) <= NEUTRAL_SPREAD and (r + g + b) // 3 >= MIN_BACKGROUND_LUMA:
            candidate[index] = 1

    transparent = bytearray(width * height)
    seen = bytearray(width * height)
    for start in range(width * height):
        if not candidate[start] or seen[start]:
            continue
        component: list[int] = []
        queue = deque([start])
        seen[start] = 1
        while queue:
            current = queue.popleft()
            component.append(current)
            x, y = current % width, current // width
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < width and 0 <= ny < height:
                    neighbor = ny * width + nx
                    if candidate[neighbor] and not seen[neighbor]:
                        seen[neighbor] = 1
                        queue.append(neighbor)
        if len(component) >= MIN_COMPONENT_PIXELS:
            for index in component:
                transparent[index] = 1
    # Remove one-pixel neutral contamination immediately outside the retained
    # artwork. The luma floor protects dark anti-aliased ink; warm pixels remain.
    base_transparent = transparent[:]
    for index in range(width * height):
        if transparent[index]:
            continue
        x, y = index % width, index // width
        r, g, b = pixel_at(index)
        if max(r, g, b) - min(r, g, b) > FRINGE_SPREAD or (r + g + b) // 3 < MIN_BACKGROUND_LUMA:
            continue
        for nx, ny in (
            (x - 1, y),
            (x + 1, y),
            (x, y - 1),
            (x, y + 1),
            (x - 1, y - 1),
            (x + 1, y - 1),
            (x - 1, y + 1),
            (x + 1, y + 1),
        ):
            if 0 <= nx < width and 0 <= ny < height and base_transparent[ny * width + nx]:
                transparent[index] = 1
                break
    return transparent


def extract(source: Path, destination: Path) -> None:
    if not source.is_file():
        raise FileNotFoundError(f"input does not exist: {source}")
    if destination.exists():
        raise FileExistsError(f"refusing to overwrite existing output: {destination}")
    with Image.open(source) as opened:
        image = opened.convert("RGBA")
        original_size = image.size
        mask = neutral_background_mask(image)
        alpha = image.getchannel("A")
        original_alpha = alpha.tobytes()
        alpha.putdata([0 if mask[index] else original_alpha[index] for index in range(len(mask))])
        if not any(mask):
            raise ValueError("no neutral background was detected; refusing an unverified extraction")
        if not any(value > 0 for value in alpha.tobytes()):
            raise ValueError("extraction removed every pixel")
        image.putalpha(alpha)
        if image.size != original_size:
            raise RuntimeError("extraction changed image geometry")
        destination.parent.mkdir(parents=True, exist_ok=True)
        image.save(destination, format="PNG", optimize=False)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    extract(args.source, args.destination)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
