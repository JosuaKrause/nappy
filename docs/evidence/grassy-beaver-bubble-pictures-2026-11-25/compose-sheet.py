"""Composes the thought-bubble review sheet from render-sources.gd's PNGs.

Usage: python compose-sheet.py RENDER_DIR OUTPUT_PNG   (needs Pillow)

Each bubble is the frame with its icon in the icon box the frame's comment gives: centred on
(28,17.5), or on (21,17.5) with the arrow centred on (41,17.5) for a hint that points. The arrow's
turn here is only an example of the runtime turn toward the way to go. LIFT is where the sheet
stands the bubble's foot over her ground point, beside the exclamation mark's 54px
(Stroller.ALERT_HEIGHT); where the game puts it is the mechanics' choice.
"""
import sys
from PIL import Image, ImageDraw, ImageFont
R = sys.argv[1]
out = sys.argv[2]
icons = ['hint_park', 'hint_back_to_route', 'hint_crosswalk', 'hint_cross_street',
         'hint_turn_back', 'hint_noise', 'hint_chalk', 'hint_hut']
pointing = {'hint_park': True, 'hint_back_to_route': True, 'hint_crosswalk': True,
            'hint_cross_street': True}
labels = {'hint_park': 'the way to the park (arrow along the route)',
          'hint_back_to_route': 'back to the route (arrow to nearest route tile)',
          'hint_crosswalk': 'use the crosswalk (arrow to nearest crosswalk)',
          'hint_cross_street': 'cross the street (arrow to nearest crosswalk)',
          'hint_turn_back': 'turn back', 'hint_noise': 'walk wide of the noise',
          'hint_chalk': 'the chalk mark in its alley', 'hint_hut': 'walk through the hut'}
angles = {'hint_park': 90, 'hint_back_to_route': 180, 'hint_crosswalk': 0, 'hint_cross_street': -45}
LIFT = 52
def img(n,s): return Image.open(f"{R}/{n}@{s}x.png").convert('RGBA')
def bubble(icon,s,angle=0):
    f=img('thought_bubble',s).copy()
    if icon is None: return f
    i=img(icon,s)
    cx=21 if pointing.get(icon) else 28
    f.alpha_composite(i,(round((cx-12)*s),round((17.5-10)*s)))
    if pointing.get(icon):
        a=img('hint_arrow',8).rotate(angle,resample=Image.BICUBIC)
        a=a.resize((14*s,14*s),Image.LANCZOS)
        f.alpha_composite(a,(round((41-7)*s),round((17.5-7)*s)))
    return f
font=ImageFont.load_default(size=13); small=ImageFont.load_default(size=11)
grounds=[('sidewalk',(0x8b,0x84,0x78)),('asphalt',(0x46,0x46,0x4f)),('grass',(0x6d,0x91,0x59))]
S=2
cellw=140; cellh=232
detw=56*4+20
W=20+cellw*len(grounds)+detw+10; H=40+len(icons)*(cellh+22)+150
sheet=Image.new('RGBA',(W,H),(236,232,222,255)); d=ImageDraw.Draw(sheet)
d.text((10,10),"Thought bubbles at game scale (camera zoom 2), over the mother on three grounds; right, 4x",fill=(34,31,40),font=font)
def figure(cell,gx,gy,over):
    m=img('mother_front_a',S); p=img('pram_front',S)
    cell.alpha_composite(m,(gx-m.width//2,gy-m.height))
    cell.alpha_composite(p,(gx-p.width//2+10*S,gy-p.height+2))
    cell.alpha_composite(over,(gx-over.width//2,gy-LIFT*S-over.height))
for r,icon in enumerate(icons):
    y0=36+r*(cellh+22)
    d.text((10,y0),labels[icon],fill=(34,31,40),font=font)
    for c,(gname,col) in enumerate(grounds):
        cell=Image.new('RGBA',(cellw-8,cellh),col+(255,))
        figure(cell,(cellw-8)//2,cellh-8,bubble(icon,S,angles.get(icon,0)))
        sheet.alpha_composite(cell,(10+c*cellw,y0+18))
    b4=bubble(icon,4,angles.get(icon,0))
    sheet.alpha_composite(b4,(20+cellw*len(grounds),y0+18+(cellh-b4.height)//2))
y0=36+len(icons)*(cellh+22)
d.text((10,y0),"Native size (1 world px = 1 px), on the sidewalk: the frame alone, the arrow, each bubble, and the exclamation mark beside them",fill=(34,31,40),font=small)
strip=Image.new('RGBA',(W-20,110),grounds[0][1]+(255,))
x=8
for icon in [None]+icons:
    b=bubble(icon,1,angles.get(icon,0) if icon else 0)
    strip.alpha_composite(b,(x,30)); x+=b.width+8
a=img('hint_arrow',1); strip.alpha_composite(a,(x,46)); x+=a.width+12
al=img('alert',1); strip.alpha_composite(al,(x,40)); x+=al.width+12
sheet.alpha_composite(strip,(10,y0+18))
sheet.save(out)
