"""Crop the dog out of each committed burst frame, as a sheet and a GIF at the burst's own timing.

    uv run python docs/evidence/m109-comic-dogs-in-game-2026-09-27/crop-bursts.py

Reads only the burst folders kept beside this script and writes, next to each burst's frames,
`dog-crops.png` (every frame's crop at 3x, labelled with its measured elapsed time) and
`dog-crops.gif` (the same crops, each shown for the time until the next frame's readback).
The crop window is fixed per burst: `--follow` keeps the followed event near one screen spot.
"""

from __future__ import annotations

import json
import sys
from itertools import pairwise
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
PAPER = (238, 235, 228)
SCALE = 3
BURSTS = {
    "rig-171340-seed4242-v0.20.0-46-gb6bfdbfc/asked/burst-12553526-001": (520, 290, 640, 380),
    "rig-171758-seed4242-v0.20.0-46-gb6bfdbfc/asked/burst-4085226-001": (560, 280, 700, 380),
}
COLUMNS = 9


def crop(folder: Path, window: tuple[int, int, int, int]) -> None:
    record = json.loads((folder / "burst.json").read_text())
    frames = record["frames"]
    if not frames:
        raise SystemExit(f"no frames recorded in {folder}")
    crops: list[Image.Image] = []
    for index in range(1, len(frames) + 1):
        path = folder / f"frame-{index:04d}.png"
        if not path.is_file():
            raise SystemExit(f"missing {path}")
        with Image.open(path) as frame:
            piece = frame.convert("RGB").crop(window)
        crops.append(piece.resize((piece.width * SCALE, piece.height * SCALE), Image.Resampling.NEAREST))
    width, height = crops[0].size
    rows = (len(crops) + COLUMNS - 1) // COLUMNS
    sheet = Image.new("RGB", (COLUMNS * (width + 4) + 4, rows * (height + 18) + 4), PAPER)
    draw = ImageDraw.Draw(sheet)
    for index, (picture, frame) in enumerate(zip(crops, frames, strict=True)):
        x = 4 + (index % COLUMNS) * (width + 4)
        y = 4 + (index // COLUMNS) * (height + 18)
        draw.text((x, y), f"{index + 1}: {frame['elapsed_seconds']:.2f}s", fill="black")
        sheet.paste(picture, (x, y + 14))
    sheet.save(folder / "dog-crops.png", optimize=True)
    elapsed = [float(frame["elapsed_seconds"]) for frame in frames]
    durations = [round((b - a) * 1000) for a, b in pairwise(elapsed)]
    durations.append(durations[-1] if durations else 100)
    crops[0].save(
        folder / "dog-crops.gif",
        save_all=True,
        append_images=crops[1:],
        duration=durations,
        loop=0,
        optimize=False,
    )


def main() -> None:
    if len(sys.argv) != 1:
        raise SystemExit(__doc__)
    for relative, window in BURSTS.items():
        crop(HERE / relative, window)
        print(f"cropped {relative}")


if __name__ == "__main__":
    main()
