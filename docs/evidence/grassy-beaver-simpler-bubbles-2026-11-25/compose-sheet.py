"""Composes the thought-bubble comparison sheet from render-sources.gd's PNGs.

Usage: python compose-sheet.py RENDER_DIR OUTPUT_PNG   (needs Pillow)

Each hint is one row, its first icon (hint_X.svg) and its simple icon (hint_X_simple.svg) side by
side in the same frame, over the mother at the game's camera zoom on two grounds, then both at 4x.
The icon sits in the icon box the frame's comment gives: centred on (28,17.5), or on (21,17.5)
with the arrow centred on (41,17.5) for a hint that points. The arrow's turn here is only an
example of the runtime turn toward the way to go. LIFT is where the sheet stands the bubble's foot
over her ground point, beside the exclamation mark's 54px (Stroller.ALERT_HEIGHT); where the game
puts it is the mechanics' choice.
"""
import sys
from PIL import Image, ImageDraw, ImageFont

R = sys.argv[1]
out = sys.argv[2]
hints = ['hint_park', 'hint_back_to_route', 'hint_crosswalk', 'hint_cross_street',
         'hint_turn_back', 'hint_noise', 'hint_chalk', 'hint_hut']
pointing = {'hint_park', 'hint_back_to_route', 'hint_crosswalk', 'hint_cross_street'}
labels = {'hint_park': 'the way to the park (arrow along the route)',
          'hint_back_to_route': 'back to the route (arrow to nearest route tile)',
          'hint_crosswalk': 'use the crosswalk (arrow to nearest crosswalk)',
          'hint_cross_street': 'cross the street (arrow to nearest crosswalk)',
          'hint_turn_back': 'turn back', 'hint_noise': 'walk wide of the noise',
          'hint_chalk': 'the chalk mark', 'hint_hut': 'walk through the hut'}
angles = {'hint_park': 90, 'hint_back_to_route': 180, 'hint_crosswalk': 0,
          'hint_cross_street': -45}
LIFT = 52
S = 2
INK = (34, 31, 40)


def img(n: str, s: int) -> Image.Image:
    return Image.open(f"{R}/{n}@{s}x.png").convert('RGBA')


def bubble(hint: str | None, icon: str | None, s: int) -> Image.Image:
    f = img('thought_bubble', s).copy()
    if hint is None or icon is None:
        return f
    i = img(icon, s)
    points = hint in pointing
    cx = 21 if points else 28
    f.alpha_composite(i, (round((cx - 12) * s), round((17.5 - 10) * s)))
    if points:
        a = img('hint_arrow', 8).rotate(angles[hint], resample=Image.BICUBIC)
        a = a.resize((14 * s, 14 * s), Image.LANCZOS)
        f.alpha_composite(a, (round((41 - 7) * s), round((17.5 - 7) * s)))
    return f


font = ImageFont.load_default(size=13)
small = ImageFont.load_default(size=11)
grounds = [('sidewalk', (0x8b, 0x84, 0x78)), ('asphalt', (0x46, 0x46, 0x4f))]
versions = [('first', ''), ('simple', '_simple')]
cellw = 132
cellh = 226
detw = 56 * 4 + 12
W = 20 + cellw * len(grounds) * len(versions) + 2 * detw + 10
H = 58 + len(hints) * (cellh + 22) + 2 * 130
sheet = Image.new('RGBA', (W, H), (236, 232, 222, 255))
d = ImageDraw.Draw(sheet)
d.text((10, 10), "Thought bubbles at game scale (camera zoom 2): each hint's first icon and its simple "
       "icon side by side, over the mother on two grounds; right, both at 4x", fill=INK, font=font)
d.text((10, 30), "Columns: first / simple on the sidewalk, first / simple on the asphalt, first 4x, "
       "simple 4x", fill=INK, font=small)


def figure(cell: Image.Image, gx: int, gy: int, over: Image.Image) -> None:
    m = img('mother_front_a', S)
    p = img('pram_front', S)
    cell.alpha_composite(m, (gx - m.width // 2, gy - m.height))
    cell.alpha_composite(p, (gx - p.width // 2 + 10 * S, gy - p.height + 2))
    cell.alpha_composite(over, (gx - over.width // 2, gy - LIFT * S - over.height))


for r, hint in enumerate(hints):
    y0 = 52 + r * (cellh + 22)
    d.text((10, y0), labels[hint], fill=INK, font=font)
    c = 0
    for _gname, col in grounds:
        for vname, suffix in versions:
            cell = Image.new('RGBA', (cellw - 8, cellh), col + (255,))
            figure(cell, (cellw - 8) // 2, cellh - 8, bubble(hint, hint + suffix, S))
            ImageDraw.Draw(cell).text((4, 3), vname, fill=(247, 243, 232), font=small)
            sheet.alpha_composite(cell, (10 + c * cellw, y0 + 18))
            c += 1
    for v, (_vname, suffix) in enumerate(versions):
        b4 = bubble(hint, hint + suffix, 4)
        x = 20 + cellw * c + v * detw
        sheet.alpha_composite(b4, (x, y0 + 18 + (cellh - b4.height) // 2))
y0 = 52 + len(hints) * (cellh + 22)
for v, (vname, suffix) in enumerate(versions):
    yy = y0 + v * 130
    d.text((10, yy), f"Native size (1 world px = 1 px), on the sidewalk, the {vname} set: the frame "
           "alone, each bubble, the arrow and the exclamation mark", fill=INK, font=small)
    strip = Image.new('RGBA', (W - 20, 100), grounds[0][1] + (255,))
    x = 8
    for hint in [None] + hints:
        b = bubble(hint, None if hint is None else hint + suffix, 1)
        strip.alpha_composite(b, (x, 28))
        x += b.width + 8
    a = img('hint_arrow', 1)
    strip.alpha_composite(a, (x, 44))
    x += a.width + 12
    al = img('alert', 1)
    strip.alpha_composite(al, (x, 38))
    sheet.alpha_composite(strip, (10, yy + 18))
sheet.save(out)
