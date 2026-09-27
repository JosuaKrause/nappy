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
SELECTED = {
    'dog': 'dog_b.png',
    'dog_front_diagonal': 'dog_front_diagonal_b-from-a.png',
    'dog_back_diagonal': 'dog_back_diagonal_b-connected.png',
}
MANIFEST_HASHES = {
    'input-manifest.json': '95e6dfdaa9924fb93d5eaa31f00b2c175b1d4c4f21e794b07e4b127476f95f70',
    'refinement-input-manifest.json': '27ba80176c6725ce431e9126aed8cf3020269c41df304579abf9bf45d4ca93e9',
}
# Visible torso landmarks, manually located in the A crop plane and the uniformly
# reduced B plane. These are approximate contour landmarks, not hidden joint proofs.
# Tail/body junction, top of haunch crease, and bottom of blue collar stay independent
# of the changing paw bounds. Translation is their mean A-minus-B displacement.
TORSO = {
    'dog': {'a': [(49,77),(108,90),(232,104)], 'b': [(50,77),(110,88),(232,104)]},
    'dog_front_diagonal': {'a': [(47,82),(85,107),(231,140)], 'b': [(47,86),(86,108),(231,139)]},
    'dog_back_diagonal': {'a': [(57,122),(81,106),(263,105)], 'b': [(58,123),(85,105),(264,104)]},
}
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
        [[(62,145),(101,183),(93,206),(115,232)], [(82,150),(46,177),(25,189),(25,202)],
         [(177,157),(179,191),(182,223),(193,236)], [(205,150),(232,183),(259,208),(278,220)]],
    ],
    'dog_back_diagonal': [
        [[(65,171),(49,202),(44,240),(55,261)], [(99,175),(111,210),(112,232),(119,240)],
         [(226,151),(243,181),(252,220),(263,230)], [(242,140),(229,179),(228,206),(234,215)]],
        [[(65,171),(105,206),(101,226),(121,253)], [(99,175),(66,201),(34,220),(38,232)],
         [(226,151),(211,191),(204,217),(218,225)], [(242,140),(267,176),(282,197),(290,198)]],
    ],
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def frozen() -> None:
    for manifest in ('input-manifest.json', 'refinement-input-manifest.json'):
        if manifest in MANIFEST_HASHES and sha(HERE / manifest) != MANIFEST_HASHES[manifest]:
            raise SystemExit(f'authoritative manifest changed: {manifest}')
        entries = json.loads((HERE / manifest).read_text())
        for entry in entries['inputs']:
            p = ROOT / entry['path']
            if not p.is_file() or sha(p) != entry['sha256']:
                raise SystemExit(f"frozen input changed or missing: {entry['path']}")
        print(f"verified {len(entries['inputs'])} frozen inputs from {manifest} before writes")


def registered(name: str) -> Image.Image:
    a = Image.open(BASE / 'crops' / 'dog' / f'{name}.png').convert('RGBA')
    b = Image.open(HERE / 'raw' / SELECTED[name]).convert('RGBA')
    # First recover A's composition plane using one uniform scale, then position by
    # visible torso landmarks. Neither operation reads the changing paw silhouette.
    factor = a.width / b.width
    b = b.resize((a.width, round(b.height * factor)), Image.Resampling.LANCZOS)
    result = Image.new('RGBA', a.size)
    result.alpha_composite(b, torso_offset(name))
    return result


def torso_offset(name: str) -> tuple[int, int]:
    marks = TORSO[name]
    return tuple(round(sum(a[i]-b[i] for a,b in zip(marks['a'],marks['b']))/len(marks['a'])) for i in (0,1))


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
    # Registration diagnostics are separate from clean reviews and anatomical traces.
    land = Image.new('RGBA',(w*2,h+30),PAPER)
    for frame,im in enumerate(images):
        land.alpha_composite(im,(frame*w,30))
        d=ImageDraw.Draw(land)
        d.text((frame*w+3,3),f'{"AB"[frame]}: torso marks (white), estimated +/-3px',fill='black')
        points=TORSO[name]['ab'[frame]]
        dx,dy=torso_offset(name) if frame else (0,0)
        for x,y in points:
            x,y=x+dx+frame*w,y+dy+30
            d.ellipse((x-4,y-4,x+4,y+4),outline='white',width=2)
            d.line((x-7,y,x+7,y),fill='#6a267e',width=1)
            d.line((x,y-7,x,y+7),fill='#6a267e',width=1)
    land.convert('RGB').resize((land.width*2,land.height*2),Image.Resampling.NEAREST).save(HERE/'review'/f'{name}-torso-marks.png')


def candidate(name: str, phase: int) -> Image.Image:
    path=(HERE/'candidates'/f'{name}_b.png') if phase and name in NAMES else BASE/'candidates'/'dog'/f'{name}{"_b" if phase else ""}.png'
    return Image.open(path).convert('RGBA')


def family_reviews() -> None:
    entries=(('dog',False,'E'),('dog_front_diagonal',False,'SE'),('dog_front',False,'S'),
             ('dog_front_diagonal',True,'SW'),('dog',True,'W'),('dog_back_diagonal',True,'NW'),
             ('dog_back',False,'N'),('dog_back_diagonal',False,'NE'))
    for scale in (1,2,6):
        frames=[]
        for phase in (0,1):
            width=sum(candidate(n,phase).width+12 for n,_,_ in entries)*scale+12
            panel=Image.new('RGBA',(width,28*scale+46),PAPER)
            d=ImageDraw.Draw(panel)
            d.text((5,3),f'{"AB"[phase]} | Walked dog - {scale}x native - synthetic comparison',fill='black')
            x=8
            for name,mirror,label in entries:
                im=candidate(name,phase)
                if mirror: im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                im=im.resize((im.width*scale,im.height*scale),Image.Resampling.NEAREST)
                d.text((x,18),label,fill='black')
                panel.alpha_composite(im,(x,panel.height-8-im.height))
                x+=im.width+12*scale
            frames.append(panel.convert('RGB'))
        frames[0].save(HERE/'review'/f'all-facings-{scale}x.gif',save_all=True,append_images=frames[1:],duration=450,loop=0,optimize=False)
        sheet=Image.new('RGB',(frames[0].width,frames[0].height*2+8),PAPER[:3])
        sheet.paste(frames[0],(0,0))
        sheet.paste(frames[1],(0,frames[0].height+8))
        sheet.save(HERE/'review'/f'all-facings-{scale}x.png')


def build() -> None:
    frozen()
    (HERE/'review').mkdir(exist_ok=True)
    (HERE/'registered').mkdir(exist_ok=True)
    (HERE/'candidates').mkdir(exist_ok=True)
    mapping=json.loads((BASE/'candidate-manifest.json').read_text())['families'][0]['cells']
    records=[]
    for name in NAMES:
        a=Image.open(BASE/'crops'/'dog'/f'{name}.png').convert('RGBA')
        b=registered(name)
        b.save(HERE/'registered'/f'{name}_b.png',optimize=True)
        diagnostic(name,[a,b])
        original=next(item for item in mapping if item['name']==name)
        native=Image.new('RGBA',tuple(original['native_size']))
        s=original['shared_pair_scale']
        size=(round(a.width*s),round(a.height*s))
        native.alpha_composite(b.resize(size,Image.Resampling.LANCZOS),tuple(original['candidate_position']))
        native.save(HERE/'candidates'/f'{name}_b.png',optimize=True)
        raw_size=Image.open(HERE/'raw'/SELECTED[name]).size
        records.append({'name':name+'_b','raw':SELECTED[name],'raw_sha256':sha(HERE/'raw'/SELECTED[name]),
                        'raw_size':list(raw_size),'raw_to_a_plane_scale':a.width/raw_size[0],
                        'a_crop_size':list(a.size),'b_torso_offset':list(torso_offset(name)),
                        'torso_landmarks':TORSO[name], 'native_size':list(native.size),
                        'a_crop_to_native_scale':s,'native_fitted_size':list(size),
                        'native_position':original['candidate_position']})
    family_reviews()
    output_paths=sorted(p for folder in ('registered','candidates','review') for p in (HERE/folder).iterdir() if p.is_file())
    manifest={'overrides':records,'outputs':{p.relative_to(HERE).as_posix():sha(p) for p in output_paths},
              'frozen_inputs':{name:sha(HERE/name) for name in ('input-manifest.json','refinement-input-manifest.json')}}
    (HERE/'revision-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')


def verify() -> None:
    frozen()
    manifest=json.loads((HERE/'revision-manifest.json').read_text())
    assert [item['name'] for item in manifest['overrides']]==[n+'_b' for n in NAMES]
    for relative,digest in manifest['outputs'].items():
        path=HERE/relative
        if not path.is_file() or sha(path)!=digest:
            raise SystemExit(f'derivative changed or missing: {relative}')
    for item in manifest['overrides']:
        im=Image.open(HERE/'candidates'/f"{item['name']}.png")
        assert list(im.size)==item['native_size']
        assert im.getchannel('A').getextrema()==(0,255)
    print('verified three native B overrides, frozen A/cardinal/pursuing inputs, and all review hashes')


def main() -> None:
    if len(sys.argv)!=2 or sys.argv[1] not in ('build','verify','--help','-h'):
        raise SystemExit(__doc__)
    if sys.argv[1] in ('--help','-h'):
        print(__doc__)
    elif sys.argv[1]=='build':
        build()
    else:
        verify()


if __name__=='__main__':
    main()
