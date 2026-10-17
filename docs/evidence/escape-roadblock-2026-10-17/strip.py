import sys
from PIL import Image, ImageDraw, ImageFont
d = sys.argv[1]
names = [("a-posted-4.6s.png", "A  posted: the guard on her side"),
         ("b-lured-5.9s.png", "B  he charges; she runs"),
         ("c-run-off-6.5s.png", "C  run off: he walks away"),
         ("d-walking-past-13.2s.png", "D  walking past: no mark over her")]
w, h = 640, 360
strip = Image.new("RGB", (w * 2, h * 2 + 0), (0, 0, 0))
try:
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 22)
except OSError:
    font = ImageFont.load_default()
for i, (name, label) in enumerate(names):
    im = Image.open(f"{d}/{name}").convert("RGB").resize((w, h), Image.LANCZOS)
    draw = ImageDraw.Draw(im)
    box = draw.textbbox((10, 8), label, font=font)
    draw.rectangle((box[0] - 6, box[1] - 4, box[2] + 6, box[3] + 4), fill=(0, 0, 0))
    draw.text((10, 8), label, fill=(255, 255, 255), font=font)
    strip.paste(im, ((i % 2) * w, (i // 2) * h))
strip.save(f"{d}/strip.png", optimize=True)
print("wrote", f"{d}/strip.png", strip.size)
