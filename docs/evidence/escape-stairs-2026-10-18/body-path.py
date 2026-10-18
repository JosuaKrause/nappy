"""Her centre's path down the left shaft's first flight, before and after, over the shaft's cells."""
import re
import sys
from PIL import Image, ImageDraw

ROWS = ["..........", ".D........", ".Ft.......", ".Fmt......", ".bcmt.....", "...cmt....",
        "....cmt...", ".....cmtD.", "......cmF.", ".......cF.", ".......TF.", "......TMF."]
FLIGHT = {"t": 1, "m": 1, "T": -1, "M": -1}
WALK = set("FDtmTM")
S = 44  # pixels per tile in the picture
HALF = 1.125

def trace(path):
    pts = []
    for line in open(path):
        m = re.match(r"TRACE (\d+) (-?[\d.]+) (-?[\d.]+)", line)
        if m:
            pts.append((1.5 + float(m.group(2)) / 32.0, 2.5 + float(m.group(3)) / 32.0))
    return pts

def cell(x, y):
    return ROWS[y][x] if 0 <= y < len(ROWS) and 0 <= x < len(ROWS[0]) else "."

def bands():
    seen, out = set(), []
    for y, row in enumerate(ROWS):
        for x, c in enumerate(row):
            if c not in FLIGHT or (x, y) in seen:
                continue
            slope, stack, cells, beside = FLIGHT[c], [(x, y)], [], set()
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                cells.append((cx, cy))
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        n = (cx + dx, cy + dy)
                        if n == (cx, cy):
                            continue
                        k = cell(*n)
                        if FLIGHT.get(k) == slope and n not in seen:
                            seen.add(n)
                            stack.append(n)
                        elif k not in WALK and FLIGHT.get(k) != slope:
                            beside.add(n)
            centre = sum(slope * (a + .5) - (b + .5) for a, b in cells) / len(cells)
            out.append((slope, centre, beside))
    return out

def clip(poly, nx, ny, limit):
    kept = []
    for i, a in enumerate(poly):
        b = poly[(i + 1) % len(poly)]
        da, db = nx * a[0] + ny * a[1] - limit, nx * b[0] + ny * b[1] - limit
        if da >= 0:
            kept.append(a)
        if (da >= 0) != (db >= 0):
            t = da / (da - db)
            kept.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    return kept

def panel(title, pts, cut):
    w, h = len(ROWS[0]) * S, len(ROWS) * S
    im = Image.new("RGB", (w, h + 30), (24, 24, 28))
    d = ImageDraw.Draw(im)
    d.text((6, 8), title, fill=(235, 225, 205))
    bs = bands()
    for y in range(len(ROWS)):
        for x in range(len(ROWS[0])):
            c = cell(x, y)
            box = [(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)]
            d.polygon([(px * S, py * S + 30) for px, py in box], fill=(196, 190, 178) if c in WALK else (24, 24, 28))
            if c in WALK:
                continue
            poly = box
            if cut:
                for slope, centre, beside in bs:
                    if (x, y) in beside:
                        side = 1 if slope * (x + .5) - (y + .5) > centre else -1
                        poly = clip(poly, side * slope, -side, side * centre + HALF)
            d.polygon([(px * S, py * S + 30) for px, py in box], fill=(196, 190, 178))
            if len(poly) >= 3:
                d.polygon([(px * S, py * S + 30) for px, py in poly], fill=(70, 66, 72))
    for y in range(len(ROWS) + 1):
        d.line([(0, y * S + 30), (w, y * S + 30)], fill=(150, 145, 135))
    for x in range(len(ROWS[0]) + 1):
        d.line([(x * S, 30), (x * S, h + 30)], fill=(150, 145, 135))
    xy = [(px * S, py * S + 30) for px, py in pts]
    d.line(xy, fill=(200, 40, 40), width=3)
    r = 14 / 32 * S
    for px, py in pts[::30]:
        d.ellipse([px * S - r, py * S + 30 - r, px * S + r, py * S + 30 + r], outline=(30, 90, 200), width=2)
    return im

before, after, out = sys.argv[1:4]
a = panel("before (main): whole-cell walls", trace(before), False)
b = panel("after: straight flight edges", trace(after), True)
sheet = Image.new("RGB", (a.width * 2 + 12, a.height), (24, 24, 28))
sheet.paste(a, (0, 0))
sheet.paste(b, (a.width + 12, 0))
sheet.save(out)
