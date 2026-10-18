"""Four stills, each with its own crop, side by side with a label. Usage:
strip.py OUT.png PATH:LEFT,TOP:LABEL ... (crop size W,H as --size W,H)"""
import sys
from PIL import Image, ImageDraw, ImageFont
args = sys.argv[1:]
size = (560, 480)
if "--size" in args:
    i = args.index("--size"); size = tuple(int(v) for v in args[i+1].split(",")); del args[i:i+2]
out, specs = args[0], args[1:]
w, h = size
strip = Image.new("RGB", (w * len(specs), h))
try:
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 20)
except OSError:
    font = ImageFont.load_default()
for k, spec in enumerate(specs):
    path, corner, label = spec.split("|", 2)
    x, y = (int(v) for v in corner.split(","))
    im = Image.open(path).convert("RGB").crop((x, y, x + w, y + h))
    d = ImageDraw.Draw(im)
    box = d.textbbox((8, h - 32), label, font=font)
    d.rectangle((box[0] - 5, box[1] - 4, box[2] + 5, box[3] + 4), fill=(0, 0, 0))
    d.text((8, h - 32), label, fill=(255, 255, 255), font=font)
    strip.paste(im, (k * w, 0))
strip.save(out, optimize=True)
print("wrote", out, strip.size)
