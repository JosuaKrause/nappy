"""Compare authored three-pose SVG geometry and render a fixed-scale source sheet.

Usage: uv run python source-review.py
Run the preserved parent render-svgs.gd first with this folder's sources.txt.
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
NAMES = ('dog','dog_front_diagonal','dog_back_diagonal','dog_front','dog_back')
PAPER = (238,235,228,255)


def main() -> None:
    if len(sys.argv) != 1:
        raise SystemExit(__doc__)
    mapping = json.loads((HERE/'pose-paths.json').read_text())
    records = []
    for name in NAMES:
        a = (ROOT/'art/events'/f'{name}.svg').read_text()
        c = (ROOT/'art/events'/f'{name}_c.svg').read_text()
        expected = a[a.index('<svg'):]
        for limb in mapping[name]['legs']:
            old,new = limb['a_path'],limb['c_path']
            assert expected.count(f'd="{old}"') == 2
            assert old.split(' L')[0] == new.split(' L')[0], 'root moved'
            expected = expected.replace(f'd="{old}"',f'd="{new}"')
        assert expected == c[c.index('<svg'):], f'non-leg geometry differs: {name}'
        for suffix in ('','_b','_c'):
            p = ROOT/'art/events'/f'{name}{suffix}.svg'
            records.append({'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
    # Same 6x native scale in every panel; no individual pose fitting.
    sheet = Image.new('RGBA',(5*250,3*210+30),PAPER)
    draw = ImageDraw.Draw(sheet)
    for col,name in enumerate(NAMES):
        draw.text((col*250+8,5),name,fill='black')
        phases = ('','_c','_b') if name in ('dog_front','dog_back') else ('','_b','_c')
        for row,(phase,label) in enumerate(zip(phases,('step 1','rest','step 2'))):
            if row == 1 and name in ('dog_front_diagonal','dog_back_diagonal'):
                label = 'existing B reference'
            base = HERE if phase == '_c' else BASE
            p = base/'source-renders/art/events'/f'{name}{phase}@6.png'
            im = Image.open(p).convert('RGBA')
            x,y = col*250+(250-im.width)//2,30+row*210
            sheet.alpha_composite(im,(x,y+195-im.height))
            draw.text((col*250+8,y+5),f'{label}: {name}{phase}',fill='black')
            records.append({'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
    sheet.convert('RGB').save(HERE/'three-pose-sources.png')
    (HERE/'source-manifest.json').write_text(json.dumps({'inputs':records},indent=2)+'\n')
    print('Five C sources preserve all body paths, materials, canvases and leg roots.')


if __name__ == '__main__':
    main()
