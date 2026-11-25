"""Clear the water from the foot of the bulkhead's PNG transfer, keeping a contact shadow.

The transfer (art/illustrated/svg-transfer/tiles/bulkhead.png, 32x32) paints the stone in rows 0 to
16, a dark waterline in row 17 and water in rows 18 to 31. The south water is drawn beneath the
bulkhead row, so the water rows become fully transparent and the waterline becomes black at the
alpha that darkens the water under it as the painted line darkened the painted water (its mean
luminance over the water rows' mean is about 0.6, so alpha 102 of 255). Rows 0 to 16 are untouched.

Usage: uv run python -I bulkhead-foot.py <the transfer as committed before> <output png>
The input's sha-256 is checked, so the edit is only ever applied to the picture it was made for.
"""

import hashlib
import sys
from pathlib import Path

from PIL import Image

SOURCE_SHA256 = "ea0a6f8cacb48194991982e725f2d897da898e39fb8e8202859b6ead36f0c01c"
WATERLINE_ROW = 17
SHADOW_ALPHA = 102


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    source, output = Path(sys.argv[1]), Path(sys.argv[2])
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    if digest != SOURCE_SHA256:
        sys.exit(f"{source}: sha-256 {digest}, not the transfer this edit is for ({SOURCE_SHA256})")
    image = Image.open(source).convert("RGBA")
    if image.size != (32, 32):
        sys.exit(f"{source}: {image.size}, not 32x32")
    for x in range(32):
        image.putpixel((x, WATERLINE_ROW), (0, 0, 0, SHADOW_ALPHA))
        for y in range(WATERLINE_ROW + 1, 32):
            image.putpixel((x, y), (0, 0, 0, 0))
    image.save(output, optimize=True)
    print(hashlib.sha256(output.read_bytes()).hexdigest(), output)


if __name__ == "__main__":
    main()
