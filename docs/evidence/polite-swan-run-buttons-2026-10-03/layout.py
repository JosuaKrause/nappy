"""Draws layout.png: the 1280x720 touch layout with candidate run-button positions.

Run: python3 layout.py layout.png   (needs Pillow; headless, no engine).
The numbers are the game's own, copied from the source named beside each:
  focal points, STOP_RADIUS, RUN_RADIUS/RUN_CATCH_RADIUS, PAUSE_*   src/ui/touch_controls.gd
  badge bounds MARGIN (104,116,104,148), ICON 34 -> disc 24           src/ui/danger_edge.gd
  arrow MARGIN 96                                                      src/ui/home_arrow.gd
  touch meters column x18-298 y40-154                                  src/ui/hud.gd
  day-hint label x120-1160 y514-574                                    scenes/ui/hud.tscn
"""
import sys
from PIL import Image, ImageDraw, ImageFont

S = 2
W, H, LEG = 1280, 720, 330
FOCUS = {"L": (240, 480), "R": (1040, 480)}
STOP_R, RUN_R, CATCH_R = 48, 34, 46
BAND = (640 - 48, 640 + 48)
img = Image.new("RGB", (W * S, (H + LEG) * S), (40, 42, 48))
d = ImageDraw.Draw(img, "RGBA")


def F(n):
    try:
        return ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", n * S)
    except OSError:  # not macOS: Pillow's bundled default font
        return ImageFont.load_default(size=n * S)


f_s, f_m, f_b = F(11), F(13), F(16)


def sc(*v):
    return [x * S for x in v]


def rect(x0, y0, x1, y1, fill=None, outline=None, w=1):
    d.rectangle(sc(x0, y0, x1, y1), fill=fill, outline=outline, width=w * S)


def circle(c, r, fill=None, outline=None, w=1):
    d.ellipse(sc(c[0] - r, c[1] - r, c[0] + r, c[1] + r), fill=fill, outline=outline, width=w * S)


def text(x, y, s, font, fill=(235, 235, 235), anchor="la"):
    d.text((x * S, y * S), s, font=font, fill=fill, anchor=anchor)


rect(0, 0, W, H, fill=(70, 74, 82))
# steering reach: every press on a half aims from that half's focus, bar the stop band
rect(0, 0, BAND[0], H, fill=(90, 160, 110, 40))
rect(BAND[1], 0, W, H, fill=(90, 160, 110, 40))
rect(BAND[0], 0, BAND[1], H, fill=(200, 80, 80, 60))
text(640, 20, "stop band", f_s, anchor="ma")
text(300, 20, "steering reach: any press here is a heading from the left ring", f_s, anchor="ma")
text(980, 20, "...from the right ring", f_s, anchor="ma")
# edge-cue tracks: DangerEdge badges at x=104/1176, y 116-572 (disc 24); arrows at x=96/1184
for x in (104, 1176):
    rect(x - 24, 116, x + 24, 572, fill=(230, 160, 40, 90), outline=(230, 160, 40), w=1)
for x in (96, 1184):
    d.line(sc(x, 96, x, 624), fill=(120, 190, 255), width=2 * S)
text(104, 600, "badge", f_s, anchor="ma")
text(1176, 600, "badge", f_s, anchor="ma")
text(70, 100, "arrow x=96", f_s, anchor="ra")
text(1210, 100, "arrow x=1184", f_s)
# HUD
rect(18, 40, 298, 154, fill=(120, 120, 220, 90), outline=(150, 150, 255))
text(158, 86, "HUD meters (touch)", f_s, anchor="ma")
rect(120, 514, 1160, 574, outline=(200, 200, 200, 120))
text(640, 544, "day hint label", f_s, anchor="mm")
circle((1218, 62), 26, fill=(255, 255, 255, 80), outline=(255, 255, 255))
text(1186, 56, "pause", f_s, anchor="ra")
# foci
for k, c in FOCUS.items():
    circle(c, STOP_R, outline=(255, 255, 255), w=2)
    circle(c, 7, fill=(255, 255, 255))
text(240, 421, "left ring", f_s, anchor="ma")
# candidates: label -> offset from a focus, mirrored on the right (dx flips)
CAND = {"A": (-110, 0, (235, 90, 60)), "B": (110, 0, (60, 160, 235)),
        "C": (0, 110, (180, 120, 235)), "D": (0, -110, (240, 210, 70))}
for k, (dx, dy, col) in CAND.items():
    for side, (fx, fy) in FOCUS.items():
        mx = -1 if side == "R" else 1
        c = (fx + dx * mx, fy + dy)
        circle(c, CATCH_R, outline=col + (255,), w=2)
        circle(c, RUN_R, fill=col + (150,))
        text(c[0], c[1], k, f_b, fill=(0, 0, 0), anchor="mm")

L = [
    ("A  outward (the first spot, (130,480) / (1150,480))", (235, 90, 60),
     "takes the due-away walk heading, 64-156px out of the ring (a +/-25 degree wedge); sits on the badge strip x=104 (y 116-572) and the arrow strip x=96, under the thumb."),
    ("B  inward ((350,480) / (930,480)) -- CHOSEN by the player (quiet-yak, inbox #477)", (60, 160, 235),
     "takes the due-toward-the-middle heading, 64-156px out of the ring; clear of badges, arrows and the HUD; ends 196px short of the stop band; just above the day hint text."),
    ("C  below the ring ((240,590) / (1040,590))", (180, 120, 235),
     "takes the due-south heading, 64-156px out; clear of the badge strip (x 194-286 vs 80-128) and the HUD; its top 18px sit inside the day hint's label box (y 514-574), not its text."),
    ("D  above the ring ((240,370) / (1040,370))", (240, 210, 70),
     "takes the due-north heading, 64-156px out; clear of badges, arrows, HUD (y 40-154) and hint; the one spot with nothing under it."),
]
y = H + 14
text(14, y, "Run-button candidates, mirrored on the right ring. Disc = drawn button (r34), outline = catch circle (r46).", f_m)
y += 28
for title, col, body in L:
    circle((22, y + 9), 8, fill=col + (255,))
    text(40, y, title, f_b)
    text(40, y + 22, body, f_s, fill=(215, 215, 215))
    y += 56
text(14, y + 6, "Legend: green = steering reach, red = stop band, orange = DangerEdge badge track, blue line = home/task arrow, violet = HUD meters.", f_s, fill=(190, 190, 190))
img.save(sys.argv[1] if len(sys.argv) > 1 else "layout.png")
