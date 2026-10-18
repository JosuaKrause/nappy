"""Where the stairwell guard starts his run at 426px, by the row she takes the second flight from.

python3 guard-trigger-2.py guard-trigger-2.txt out.png (Pillow). Reads the walk lines of the first
block of TRIGGER lines (this branch's 426px) and draws them over the right shaft's lower cells with
the 426px circle round where he waits.
"""
import re
import sys
from PIL import Image, ImageDraw

ROWS = ["..........", ".D........", ".Ft.......", ".Fmt......", ".bcmt.....", "...cmt....",
        "....cmt...", ".....cmtD.", "......cmF.", ".......cF.", ".......TF.", "......TMF.",
        ".....TMCb.", "....TMC...", "...TMC....", ".DTMC.....", ".FMC......", ".FC.......",
        ".Ft.......", ".Fmt......", ".bcmt.....", "...cmt....", "....cmt...", ".....cmtD.",
        "......cmF.", ".......cF."]
WALK = set("FDtmTM")
S = 30
TOP = 6
FOOT = (8.5, 24.5)
RADIUS = 426
COLOURS = {"turn-10": (200, 40, 40), "turn-11": (230, 140, 20), "turn-9": (40, 120, 220)}

points, block = [], -1
for line in open(sys.argv[1]):
    if line.startswith("#"):
        block += 1
    m = re.match(r"TRIGGER seed \d+ (turn-\d+) walk charged at \(([\d.]+), ([\d.]+)\)", line)
    if m and block == 0:
        points.append((m.group(1), float(m.group(2)), float(m.group(3))))

w, h = len(ROWS[0]) * S, (len(ROWS) - TOP) * S
im = Image.new("RGB", (w + 230, h + 40), (24, 24, 28))
d = ImageDraw.Draw(im)
d.text((6, 6), "he runs once she is within 426px", fill=(235, 225, 205))
def at(x, y):
    return (x * S, (y - TOP) * S + 40)
for y in range(TOP, len(ROWS)):
    for x, c in enumerate(ROWS[y]):
        fill = (196, 190, 178) if c in WALK else (24, 24, 28)
        if c == "D":
            fill = (120, 80, 70)
        d.rectangle([at(x, y), at(x + 1, y + 1)], fill=fill, outline=(150, 145, 135))
fx, fy = at(*FOOT)
d.ellipse([fx - 7, fy - 7, fx + 7, fy + 7], fill=(10, 10, 10), outline=(255, 255, 255))
r = RADIUS / 32 * S
d.ellipse([fx - r, fy - r, fx + r, fy + r], outline=(200, 40, 40), width=2)
for route, x, y in points:
    px, py = at(x, y)
    d.ellipse([px - 5, py - 5, px + 5, py + 5], fill=COLOURS[route], outline=(0, 0, 0))
ly = 50
for route, c in COLOURS.items():
    d.ellipse([w + 12, ly, w + 22, ly + 10], fill=c)
    d.text((w + 28, ly - 2), "took the flight from row %s" % route[5:], fill=(235, 225, 205))
    ly += 22
d.text((w + 12, ly + 6), "dark red: doors", fill=(235, 225, 205))
d.text((w + 12, ly + 24), "black dot: where he waits", fill=(235, 225, 205))
d.text((w + 12, ly + 42), "red circle: 426px from him", fill=(235, 225, 205))
im.save(sys.argv[2])
