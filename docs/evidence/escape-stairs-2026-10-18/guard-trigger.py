"""Where the stairwell guard starts his run, by route: the landing (this branch) and a 343px circle.

python3 guard-trigger.py guard-trigger.txt out.png (Pillow). Reads the TRIGGER lines of both runs
the text file holds, the first with the landing, the second with TRIGGER_RADIUS=343.
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
TOP = 8
FOOT = (8.5, 24.5)
COLOURS = {"flight-mid": (200, 40, 40), "flight-high": (40, 120, 220), "flight-low": (230, 140, 20),
           "door": (40, 160, 70)}

def runs(path):
    out, block = [[], []], -1
    for line in open(path):
        if line.startswith("#"):
            block += 1
        m = re.match(r"TRIGGER seed \d+ (\S+) (walk|run) charged at \(([\d.]+), ([\d.]+)\)", line)
        if m and block >= 0:
            out[block].append((m.group(1), float(m.group(3)), float(m.group(4))))
    return out

def panel(title, points, radius):
    w, h = len(ROWS[0]) * S, (len(ROWS) - TOP) * S
    im = Image.new("RGB", (w, h + 40), (24, 24, 28))
    d = ImageDraw.Draw(im)
    d.text((6, 6), title, fill=(235, 225, 205))
    def at(x, y):
        return (x * S, (y - TOP) * S + 40)
    for y in range(TOP, len(ROWS)):
        for x, c in enumerate(ROWS[y]):
            fill = (196, 190, 178) if c in WALK else (24, 24, 28)
            if c == "F" and x == 1 and 16 <= y <= 19:
                fill = (150, 200, 150)
            if c == "D":
                fill = (120, 80, 70)
            d.rectangle([at(x, y), at(x + 1, y + 1)], fill=fill, outline=(150, 145, 135))
    fx, fy = at(*FOOT)
    d.ellipse([fx - 7, fy - 7, fx + 7, fy + 7], fill=(10, 10, 10), outline=(255, 255, 255))
    if radius:
        r = radius / 32 * S
        d.ellipse([fx - r, fy - r, fx + r, fy + r], outline=(200, 40, 40), width=2)
    for route, x, y in points:
        px, py = at(x, y)
        d.ellipse([px - 5, py - 5, px + 5, py + 5], fill=COLOURS[route], outline=(0, 0, 0))
    return im

landing, circle = runs(sys.argv[1])
a = panel("he runs: on the landing (this branch)", landing, 0)
b = panel("he runs: a 343px circle (not built)", circle, 343)
legend = Image.new("RGB", (a.width * 2 + 12, 72), (24, 24, 28))
d = ImageDraw.Draw(legend)
x = 6
for route, c in COLOURS.items():
    d.ellipse([x, 10, x + 10, 20], fill=c)
    d.text((x + 16, 8), route, fill=(235, 225, 205))
    x += 140
d.text((6, 34), "green: the first-floor landing; dark red: doors; black dot: where he waits", fill=(235, 225, 205))
d.text((6, 50), "flight-mid and flight-low start him at the same point, so one dot hides the other",
       fill=(235, 225, 205))
sheet = Image.new("RGB", (a.width * 2 + 12, a.height + 72), (24, 24, 28))
sheet.paste(a, (0, 0))
sheet.paste(b, (a.width + 12, 0))
sheet.paste(legend, (0, a.height))
sheet.save(sys.argv[2])
