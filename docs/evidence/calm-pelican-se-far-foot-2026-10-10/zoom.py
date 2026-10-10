"""Crop both southeast feet from the 6x sheets and enlarge them 4x more, nearest-neighbour."""

import sys
from pathlib import Path

from PIL import Image, ImageDraw

before_dir, after_dir, out_dir = (Path(a) for a in sys.argv[1:4])
scale, cell_w, cell_h = 6, 48 * 6, 52 * 6 + 20
box = (15, 26, 29, 38)  # art coordinates around both feet
crops = []
for name, folder in (("before", before_dir), ("after", after_dir)):
    sheet = Image.open(folder / "current-6x.png").convert("RGBA")
    for column, phase in ((2, "A"), (3, "B")):
        left = column * cell_w + 4 * scale
        top = cell_h - 4 * scale - 44 * scale
        region = sheet.crop((left + box[0] * scale, top + box[1] * scale, left + box[2] * scale, top + box[3] * scale))
        region = region.resize((region.width * 4, region.height * 4), Image.Resampling.NEAREST)
        crops.append((f"{name}: SE {phase}", region))
w, h = crops[0][1].size
out = Image.new("RGBA", (w * 2 + 8, (h + 16) * 2), "#96928a")
for i, (label, region) in enumerate(crops):
    x, y = (i % 2) * (w + 8), (i // 2) * (h + 16)
    out.paste(region, (x, y + 16))
    ImageDraw.Draw(out).text((x + 4, y + 2), label, fill="#221f28")
out.save(out_dir / "se-far-foot-zoom.png")
