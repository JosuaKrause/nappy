"""Builds a labelled before/after pair from two stills of the same moment, each cropped to the
same box. Usage: python3 pair.py BEFORE.png AFTER.png OUT.png "LABEL A" "LABEL B"
[--crop LEFT,TOP,RIGHT,BOTTOM]"""
import sys
from PIL import Image, ImageDraw, ImageFont

args = sys.argv[1:]
crop = (640, 150, 1280, 720)
if "--crop" in args:
    i = args.index("--crop")
    crop = tuple(int(v) for v in args[i + 1].split(","))
    del args[i:i + 2]
before, after, out, label_a, label_b = args
w, h = crop[2] - crop[0], crop[3] - crop[1]
pair = Image.new("RGB", (w * 2 + 8, h), (0, 0, 0))
try:
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 20)
except OSError:
    font = ImageFont.load_default()
for k, (path, label) in enumerate([(before, label_a), (after, label_b)]):
    im = Image.open(path).convert("RGB").crop(crop)
    draw = ImageDraw.Draw(im)
    box = draw.textbbox((8, h - 32), label, font=font)
    draw.rectangle((box[0] - 5, box[1] - 4, box[2] + 5, box[3] + 4), fill=(0, 0, 0))
    draw.text((8, h - 32), label, fill=(255, 255, 255), font=font)
    pair.paste(im, (k * (w + 8), 0))
pair.save(out, optimize=True)
print("wrote", out, pair.size)
