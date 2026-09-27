"""Deterministic torso registration and review assembly, never artwork painting.

Usage: uv run python assemble.py build|verify
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
BASE = HERE.parent
ROOT = HERE.parents[3]
NAMES = ('dog', 'dog_front_diagonal', 'dog_back_diagonal')
PAPER = (238, 235, 228, 255)
COLORS = ('#d02d40', '#ad40b2', '#00799a', '#d07800')
LABELS = ('near hind', 'far hind', 'near fore', 'far fore')

# Joint chains are an explicitly interpretive anatomical trace, not image measurements.
# Internal roots are inferred inside the opaque torso; distal points trace visible limbs.
# Coordinates are in A's original crop plane, after the single uniform B registration.
CHAINS = {
    'dog': [
        [[(82,123),(65,155),(53,177),(61,200)], [(104,128),(107,164),(112,188),(120,198)],
         [(201,118),(229,155),(252,187),(268,199)], [(218,116),(190,153),(171,183),(175,198)]],
        [[(82,123),(110,153),(105,178),(128,200)], [(104,128),(70,151),(36,173),(32,181)],
         [(201,118),(191,158),(183,186),(190,201)], [(218,116),(246,151),(271,176),(283,172)]],
    ],
    'dog_front_diagonal': [
        [[(62,145),(44,179),(29,203),(36,224)], [(82,150),(91,184),(98,207),(108,214)],
         [(177,157),(192,195),(213,229),(223,245)], [(205,150),(202,186),(193,209),(199,220)]],
        [[(62,145),(89,174),(73,199),(101,233)], [(82,150),(46,177),(25,189),(25,202)],
         [(177,157),(195,191),(178,214),(186,220)], [(205,150),(231,188),(245,219),(256,227)]],
    ],
    'dog_back_diagonal': [
        [[(65,171),(49,202),(44,240),(55,261)], [(99,175),(111,210),(112,232),(119,240)],
         [(226,151),(243,181),(252,220),(263,230)], [(242,140),(229,179),(228,206),(234,215)]],
        [[(65,171),(108,201),(102,222),(116,251)], [(99,175),(66,201),(34,220),(38,232)],
         [(226,151),(211,191),(204,217),(218,225)], [(242,140),(267,176),(282,197),(290,198)]],
    ],
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def frozen() -> None:
    entries = json.loads((HERE / 'input-manifest.json').read_text())
    for entry in entries['inputs']:
        p = ROOT / entry['path']
        if not p.is_file() or sha(p) != entry['sha256']:
            raise SystemExit(f"frozen input changed or missing: {entry['path']}")
    print(f"verified {len(entries['inputs'])} frozen inputs before writes")


def registered(name: str) -> Image.Image:
    a = Image.open(BASE / 'crops' / 'dog' / f'{name}.png').convert('RGBA')
    b = Image.open(HERE / 'raw' / f'{name}_b.png').convert('RGBA')
    # The edit preserves the input composition. Uniform full-canvas scaling, fixed by
    # A's plane, is independent of the new paw silhouette. No B alpha-bound fitting.
    factor = a.width / b.width
    b = b.resize((a.width, round(b.height * factor)), Image.Resampling.LANCZOS)
    result = Image.new('RGBA', a.size)
    result.alpha_composite(b, (0, 0))
    return result


def diagnostic(name: str, images: list[Image.Image]) -> None:
    w, h = images[0].size
    panels = []
    for frame, im in enumerate(images):
        panel = Image.new('RGBA', (w+40, h+70), PAPER)
        panel.alpha_composite(im, (20,45))
        d = ImageDraw.Draw(panel)
        d.text((8,5), f'{name}: {"AB"[frame]} / inferred internal pivots', fill='black')
        for chain, color in zip(CHAINS[name][frame], COLORS):
            points = [(x+20,y+45) for x,y in chain]
            d.line(points, fill=color, width=2)
            for index,(x,y) in enumerate(points):
                d.ellipse((x-3,y-3,x+3,y+3), outline=color, width=2)
                if index == 0:
                    d.line((x-5,y,x+5,y),fill=color,width=1)
                    d.line((x,y-5,x,y+5),fill=color,width=1)
        for i,(label,col) in enumerate(zip(LABELS,COLORS)):
            d.text((8+(i%2)*170,20+(i//2)*12),label,fill=col)
        panels.append(panel)
    sheet = Image.new('RGBA', (2*(w+40),h+70),PAPER)
    sheet.alpha_composite(panels[0],(0,0))
    sheet.alpha_composite(panels[1],(w+40,0))
    sheet.convert('RGB').resize((sheet.width*2,sheet.height*2)).save(HERE/'review'/f'{name}-joint-trace.png')
    clean = []
    for im in images:
        p = Image.new('RGBA',im.size,PAPER)
        p.alpha_composite(im)
        clean.append(p.convert('RGB'))
    clean[0].save(HERE/'review'/f'{name}-torso-loop.gif',save_all=True,append_images=clean[1:],duration=650,loop=0,optimize=False)
    sheet = Image.new('RGBA',(w*2,h),PAPER)
    sheet.alpha_composite(images[0]);sheet.alpha_composite(images[1],(w,0))
    sheet.convert('RGB').save(HERE/'review'/f'{name}-torso-pair.png')


def build() -> None:
    frozen()
    (HERE/'review').mkdir(exist_ok=True)
    (HERE/'registered').mkdir(exist_ok=True)
    for name in NAMES:
        a=Image.open(BASE/'crops'/'dog'/f'{name}.png').convert('RGBA')
        b=registered(name)
        b.save(HERE/'registered'/f'{name}_b.png',optimize=True)
        diagnostic(name,[a,b])


def main() -> None:
    if len(sys.argv)!=2 or sys.argv[1] not in ('build','verify','--help','-h'):
        raise SystemExit(__doc__)
    if sys.argv[1] in ('--help','-h'):
        print(__doc__)
    elif sys.argv[1]=='build':
        build()
    else:
        frozen()


if __name__=='__main__':
    main()
