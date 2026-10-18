"""Builds a labelled strip of four frames from one burst, each cropped to the street the band
stands on. Usage: python3 bursts.py BURST_DIR OUT.png N:LABEL N:LABEL N:LABEL N:LABEL
[--crop LEFT,TOP,RIGHT,BOTTOM]"""
import sys
from PIL import Image, ImageDraw, ImageFont

args = sys.argv[1:]
crop = (300, 0, 900, 420)
if "--crop" in args:
    i = args.index("--crop")
    crop = tuple(int(v) for v in args[i + 1].split(","))
    del args[i:i + 2]
burst, out, frames = args[0], args[1], args[2:]
assert len(frames) == 4, "four N:LABEL frames"
w, h = crop[2] - crop[0], crop[3] - crop[1]
strip = Image.new("RGB", (w * 4, h), (0, 0, 0))
try:
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 20)
except OSError:
    font = ImageFont.load_default()
for k, spec in enumerate(frames):
    number, label = spec.split(":", 1)
    im = Image.open(f"{burst}/frame-{int(number):04d}.png").convert("RGB").crop(crop)
    draw = ImageDraw.Draw(im)
    box = draw.textbbox((8, h - 32), label, font=font)
    draw.rectangle((box[0] - 5, box[1] - 4, box[2] + 5, box[3] + 4), fill=(0, 0, 0))
    draw.text((8, h - 32), label, fill=(255, 255, 255), font=font)
    strip.paste(im, (k * w, 0))
strip.save(out, optimize=True)
print("wrote", out, strip.size)
