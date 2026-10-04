"""Compose a review sheet: rows = family x frame, columns = five views.
usage: sheet.py <renderdir> <out.png> <scale> <upscale> family[,family...]
Each cell: the SVG rendered at <scale>, upscaled by <upscale> nearest, on a sidewalk grey, bottom-aligned
on a shared baseline so heights compare (canvases share world scale)."""
import sys
from PIL import Image, ImageDraw
renderdir, out, scale, up, fams = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), sys.argv[5].split(",")
views = ["front", "front_diagonal", "side", "back_diagonal", "back"]
def name(fam, view, b):
    base = fam if view == "side" else f"{fam}_{view}"
    return f"{renderdir}/{base}{'_b' if b else ''}@{scale}.png"
rows = []
for fam in fams:
    for b in (False, True):
        rows.append((f"{fam} {'b' if b else 'a'}", [Image.open(name(fam, v, b)).convert("RGBA") for v in views]))
cw = max(im.width for _, r in rows for im in r) * up + 16
ch = max(im.height for _, r in rows for im in r) * up + 16
label_w = 0
W, H = label_w + cw * len(views), ch * len(rows) + 14
sheet = Image.new("RGBA", (W, H), (150, 146, 138, 255))
d = ImageDraw.Draw(sheet)
for c, v in enumerate(views):
    d.text((label_w + c * cw + 4, 2), v, fill=(30, 30, 30, 255))
for r, (label, ims) in enumerate(rows):
    y0 = 14 + r * ch
    d.text((4, y0 + 2), label, fill=(30, 30, 30, 255))
    # grid line
    d.line([(0, y0), (W, y0)], fill=(120, 116, 110, 255))
    for c, im in enumerate(ims):
        big = im.resize((im.width * up, im.height * up), Image.NEAREST)
        x = label_w + c * cw + (cw - big.width) // 2
        y = y0 + ch - 8 - big.height
        # baseline marker
        d.line([(label_w + c * cw + 4, y0 + ch - 8), (label_w + (c + 1) * cw - 4, y0 + ch - 8)], fill=(110, 106, 100, 255))
        sheet.alpha_composite(big, (x, y))
sheet.save(out)
print(out, sheet.size)
