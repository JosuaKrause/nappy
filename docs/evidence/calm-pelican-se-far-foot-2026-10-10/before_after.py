"""Stack the eastern row (NE, SE, E in A/B) of two current-candidate sheets, before above after."""

import sys
from pathlib import Path

from PIL import Image, ImageDraw

before_dir, after_dir, out_dir = (Path(a) for a in sys.argv[1:4])
for scale in (1, 6):
    cell_w, cell_h = 48 * scale, 52 * scale + 20
    rows = []
    for name, folder in (("before", before_dir), ("after", after_dir)):
        sheet = Image.open(folder / f"current-{scale}x.png").convert("RGBA")
        assert sheet.size == (cell_w * 6, cell_h * 2)
        row = sheet.crop((0, 0, cell_w * 6, cell_h))
        draw = ImageDraw.Draw(row)
        for column in range(6):
            label = f"{('NE', 'SE', 'E')[column // 2]} {'AB'[column % 2]}"
            draw.text((column * cell_w + 4, 3), f"{name}: {label}" if scale == 6 else label, fill="#221f28")
        rows.append(row)
    out = Image.new("RGBA", (cell_w * 6, cell_h * 2), "#96928a")
    out.paste(rows[0], (0, 0))
    out.paste(rows[1], (0, cell_h))
    out.save(out_dir / f"se-far-foot-before-after-{scale}x.png")
