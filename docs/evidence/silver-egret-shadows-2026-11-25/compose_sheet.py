
import sys, os
from PIL import Image, ImageDraw, ImageFont
src, out, scale = sys.argv[1], sys.argv[2], float(sys.argv[3])
rows = sys.argv[4:]
ims = [Image.open(os.path.join(src, r + '.png')).convert('RGB') for r in rows]
ims = [im.resize((int(im.width*scale), int(im.height*scale)), Image.NEAREST) for im in ims]
label_h = 22
w = max(im.width for im in ims)
sheet = Image.new('RGB', (w, sum(im.height + label_h for im in ims)), 'white')
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 16)
except Exception:
    font = ImageFont.load_default()
y = 0
for r, im in zip(rows, ims):
    d.text((6, y + 3), r, fill='black', font=font)
    y += label_h
    sheet.paste(im, (0, y)); y += im.height
sheet.save(out)
