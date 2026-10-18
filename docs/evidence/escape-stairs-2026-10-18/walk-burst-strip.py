import sys
from PIL import Image, ImageDraw
before, after, out = sys.argv[1:4]
picks = [1, 6, 11, 16, 21, 26, 31, 36]
crop = (470, 170, 810, 510)
cw, ch = crop[2] - crop[0], crop[3] - crop[1]
scale = 0.6
tw, th = int(cw * scale), int(ch * scale)
pad = 28
sheet = Image.new("RGB", (len(picks) * tw, 2 * (th + pad)), (20, 20, 24))
d = ImageDraw.Draw(sheet)
for row, (label, folder) in enumerate([("before (main): held right from the top landing", before),
                                        ("after: the same press", after)]):
    y0 = row * (th + pad)
    d.text((6, y0 + 8), label, fill=(235, 225, 205))
    for k, i in enumerate(picks):
        im = Image.open(f"{folder}/frame-{i:04d}.png").convert("RGB").crop(crop).resize((tw, th))
        sheet.paste(im, (k * tw, y0 + pad))
sheet.save(out)
