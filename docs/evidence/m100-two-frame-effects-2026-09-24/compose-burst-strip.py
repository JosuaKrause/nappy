"""Scratch: crop the same box out of a burst's frames and lay them out as a labelled grid.

usage: strip.py BURST_DIR X0 Y0 X1 Y1 SCALE EVERY OUT.png
"""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

burst = Path(sys.argv[1])
box = tuple(int(v) for v in sys.argv[2:6])
scale = int(sys.argv[6])
every = int(sys.argv[7])
out_path = sys.argv[8]
frames = sorted(burst.glob("frame-*.png"))
record = json.loads((burst / "burst.json").read_text())
times = [f.get("elapsed", f.get("t")) for f in record.get("frames", [])] if isinstance(record, dict) else []
picked = frames[::every][:12]
font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 16)
w = (box[2] - box[0]) * scale
h = (box[3] - box[1]) * scale
cols = 4
rows = (len(picked) + cols - 1) // cols
sheet = Image.new("RGB", (cols * (w + 8) + 8, rows * (h + 30) + 8), (236, 233, 226))
draw = ImageDraw.Draw(sheet)
for i, frame in enumerate(picked):
    crop = Image.open(frame).convert("RGB").crop(box).resize((w, h), Image.NEAREST)
    x = 8 + (i % cols) * (w + 8)
    y = 8 + (i // cols) * (h + 30)
    sheet.paste(crop, (x, y))
    index = frames.index(frame)
    label = frame.stem
    if index < len(times) and times[index] is not None:
        label += f"  t={float(times[index]):.2f}s"
    draw.text((x, y + h + 4), label, fill=(40, 34, 38), font=font)
sheet.save(out_path)
print(out_path, sheet.size, len(frames), "frames", list(record)[:6] if isinstance(record, dict) else "")
