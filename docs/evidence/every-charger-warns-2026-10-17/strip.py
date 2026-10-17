"""Cuts labelled key frames from a recording into one strip: strip.py VIDEO OUT CROP(x,y,w,h) SCALE t:label ..."""
import sys, subprocess, tempfile, os
from PIL import Image, ImageDraw, ImageFont
video, out, crop = sys.argv[1], sys.argv[2], tuple(int(v) for v in sys.argv[3].split(','))
vertical = sys.argv[4].endswith('v')
scale = int(sys.argv[4].rstrip('v'))
assert not os.path.exists(out), "a delivered strip is never overwritten: " + out
panels = []
for spec in sys.argv[5:]:
    t, label = spec.split(':', 1)
    with tempfile.TemporaryDirectory() as d:
        frame = os.path.join(d, 'f.png')
        subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-ss', t, '-i', video, '-frames:v', '1', frame], check=True)
        im = Image.open(frame).convert('RGB')
    x, y, w, h = crop
    im = im.crop((x, y, x + w, y + h)).resize((w * scale, h * scale), Image.NEAREST)
    panels.append((im, f'{float(t):.2f}s  {label}'))
font = ImageFont.load_default(size=22)
W, H = panels[0][0].size
band = 34
if vertical:
    sheet = Image.new('RGB', (W, len(panels) * (H + band)), (30, 30, 30))
else:
    sheet = Image.new('RGB', (len(panels) * (W + 6) - 6, H + band), (30, 30, 30))
draw = ImageDraw.Draw(sheet)
for i, (im, label) in enumerate(panels):
    x, y = (0, i * (H + band)) if vertical else (i * (W + 6), 0)
    sheet.paste(im, (x, y + band))
    draw.text((x + 6, y + 5), label, fill=(240, 240, 240), font=font)
sheet.save(out)
print('wrote', out, sheet.size)
