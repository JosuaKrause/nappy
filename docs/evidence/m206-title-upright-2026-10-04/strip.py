import json, sys
from PIL import Image, ImageDraw, ImageFont
# usage: strip.py OUT RUN_DIR frame-index:caption ...
out, run = sys.argv[1], sys.argv[2]
frames = json.load(open(f"{run}/frames.json"))
items = []
for arg in sys.argv[3:]:
    i, cap = arg.split(":", 1)
    f = frames[int(i)]
    items.append((Image.open(f"{run}/frames/{f['name']}").convert("RGB"), f"{f['ms']} ms: {cap}"))
w, h = items[0][0].size
bar = 28
img = Image.new("RGB", (len(items) * (w + 8) - 8, h + bar), "white")
d = ImageDraw.Draw(img)
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 15)
except Exception:
    font = ImageFont.load_default()
for k, (im, cap) in enumerate(items):
    x = k * (w + 8)
    img.paste(im, (x, bar))
    d.text((x + 4, 6), cap, fill="black", font=font)
img.save(out, quality=82)
