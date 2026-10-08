"""Label Godot's current-candidate rasters without resampling the artwork."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("raster_directory", type=Path)
parser.add_argument("output_directory", type=Path)
args = parser.parse_args()
for scale in (1, 6):
    picture = Image.open(args.raster_directory / f"current-{scale}x.png").convert("RGBA")
    draw = ImageDraw.Draw(picture)
    cell_width, cell_height = 48 * scale, 52 * scale + 20
    assert picture.size == (cell_width * 6, cell_height * 2)
    for row, directions in enumerate((("NE", "SE", "E"), ("NW", "SW", "W"))):
        for column in range(6):
            phase = "A" if column % 2 == 0 else "B"
            label = f"{directions[column // 2]} {phase}"
            draw.text((column * cell_width + 4, row * cell_height + 3), label, fill="#221f28")
    picture.save(args.output_directory / f"candidate-2-{scale}x.png")
