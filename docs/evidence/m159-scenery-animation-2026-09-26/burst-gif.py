"""Convert retained runtime burst frames to a GIF using their actual capture timestamps."""

import argparse
import json
from pathlib import Path

from PIL import Image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("burst", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--width", type=int, default=960)
    args = parser.parse_args()
    metadata = json.loads((args.burst / "burst.json").read_text())
    assert metadata["status"] == "complete"
    entries = metadata["frames"]
    frames = []
    durations = []
    for index, entry in enumerate(entries):
        image = Image.open(args.burst / entry["file"]).convert("RGB")
        if args.width != image.width:
            image = image.resize((args.width, round(image.height * args.width / image.width)),
                                 Image.Resampling.LANCZOS)
        frames.append(image)
        end = (entries[index + 1]["elapsed_seconds"] if index + 1 < len(entries)
               else metadata["duration_seconds"])
        # Quantize boundaries, not each interval: rounding every 1/12s interval loses time.
        durations.append(max(10, (round(end * 100)
                                  - round(entry["elapsed_seconds"] * 100)) * 10))
    frames[0].save(args.output, save_all=True, append_images=frames[1:], duration=durations,
                   loop=0, optimize=False, disposal=2)
    print(json.dumps({"output": str(args.output), "frames": len(frames),
                      "durations_ms": durations, "total_ms": sum(durations)}))


if __name__ == "__main__":
    main()
