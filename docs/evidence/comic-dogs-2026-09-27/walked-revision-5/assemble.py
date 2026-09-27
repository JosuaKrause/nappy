"""Register C illustrations and assemble three-pose/four-beat preview evidence.

Usage: uv run python assemble.py build|verify
"""
from __future__ import annotations
import hashlib
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw

HERE=Path(__file__).resolve().parent
BASE=HERE.parent
ROOT=HERE.parents[3]
NAMES=('dog',)
MANIFESTS={'input-manifest.json':'53411251857660a9c6c6d18e93e248649042011b1ebd8b26c328b8874bccd2e7'}
PAPER=(238,235,228,255)
PHASES=(0,1,2,1)
LEG_TOP={'dog':145,'dog_front_diagonal':187,'dog_back_diagonal':207,'dog_front':222,'dog_back':195}


def sha(p:Path)->str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def frozen()->None:
    for name,digest in MANIFESTS.items():
        manifest=HERE/name
        if sha(manifest)!=digest:
            raise SystemExit('authoritative manifest changed: '+name)
        for item in json.loads(manifest.read_text())['inputs']:
            p=ROOT/item['path']
            if not p.is_file() or sha(p)!=item['sha256']:
                raise SystemExit('frozen input changed or missing: '+item['path'])


def paths(name:str,native:bool)->list[Path]:
    folder='candidates' if native else 'crops'
    a=BASE/folder/'dog'/f'{name}.png'
    c=HERE/('candidates' if native else 'registered')/f'{name}_c.png'
    if name in ('dog_front','dog_back'):
        return [a,c,BASE/folder/'dog'/f'{name}_b.png']
    b=BASE/'walked-revision-4'/('candidates' if native else 'registered')/f'{name}_b.png'
    return [a,b,c]


def clean(im:Image.Image)->Image.Image:
    p=Image.new('RGBA',im.size,PAPER);p.alpha_composite(im);return p.convert('RGB')


def review(name:str)->None:
    frames=[Image.open(p).convert('RGBA') for p in paths(name,False)]
    w,h=frames[0].size
    for tag,images in [('body',frames),('leg-silhouette',[i.crop((0,LEG_TOP[name],w,h)) for i in frames])]:
        pictures=[]
        for im in images:
            if tag=='leg-silhouette':
                mono=Image.new('RGBA',im.size,'black');mono.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0));im=mono
            pictures.append(clean(im))
        sheet=Image.new('RGB',(w*3,pictures[0].height+24),PAPER[:3]);draw=ImageDraw.Draw(sheet)
        for i,picture in enumerate(pictures):
            sheet.paste(picture,(i*w,24));draw.text((i*w+4,5),('step 1','rest','step 2')[i],fill='black')
        sheet.save(HERE/'review'/f'{name}-{tag}-three-poses.png')
        pictures[0].save(HERE/'review'/f'{name}-{tag}-four-beats.gif',save_all=True,append_images=[pictures[i] for i in PHASES[1:]],duration=450,loop=0,optimize=False)
    native=Image.open(HERE/'candidates'/f'{name}_c.png').convert('RGBA')
    source=Image.open(HERE/'source-renders/art/events'/f'{name}_c@6.png').convert('RGBA')
    scale=6; candidate=native.resize((native.width*scale,native.height*scale),Image.Resampling.NEAREST)
    panel=Image.new('RGBA',(source.width*2,source.height+24),PAPER)
    panel.alpha_composite(source,(0,24));panel.alpha_composite(candidate,(source.width,24))
    d=ImageDraw.Draw(panel);d.text((3,5),'reviewed source C',fill='black');d.text((source.width+3,5),'new illustration C',fill='black')
    panel.convert('RGB').save(HERE/'review'/f'{name}-source-c.png')


def family()->None:
    entries=(('dog',False,'E'),('dog_front_diagonal',False,'SE'),('dog_front',False,'S'),('dog_front_diagonal',True,'SW'),('dog',True,'W'),('dog_back_diagonal',True,'NW'),('dog_back',False,'N'),('dog_back_diagonal',False,'NE'))
    for scale in (1,2,6):
        frames=[]
        for phase,label in enumerate(('step 1','rest','step 2')):
            panel=Image.new('RGBA',(sum(Image.open(paths(n,True)[phase]).width+12 for n,_,_ in entries)*scale+12,28*scale+46),PAPER)
            d=ImageDraw.Draw(panel);d.text((5,3),f'{label} | {scale}x native | synthetic preview',fill='black');x=8
            for name,mirror,direction in entries:
                im=Image.open(paths(name,True)[phase]).convert('RGBA')
                if mirror:im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                im=im.resize((im.width*scale,im.height*scale),Image.Resampling.NEAREST)
                d.text((x,18),direction,fill='black');panel.alpha_composite(im,(x,panel.height-8-im.height));x+=im.width+12*scale
            frames.append(panel.convert('RGB'))
        frames[0].save(HERE/'review'/f'all-facings-{scale}x.gif',save_all=True,append_images=[frames[i] for i in PHASES[1:]],duration=450,loop=0,optimize=False)
        sheet=Image.new('RGB',(frames[0].width,frames[0].height*3),PAPER[:3])
        for i,frame in enumerate(frames):sheet.paste(frame,(0,i*frame.height))
        sheet.save(HERE/'review'/f'all-facings-{scale}x.png')


def build()->None:
    frozen()
    for folder in ('registered','candidates','review'):(HERE/folder).mkdir(exist_ok=True)
    mapping=json.loads((BASE/'candidate-manifest.json').read_text())['families'][0]['cells'];records=[]
    for name in NAMES:
        a=Image.open(BASE/'crops/dog'/f'{name}.png').convert('RGBA')
        raw=Image.open(HERE/'raw'/f'{name}_c.png').convert('RGBA')
        factor=a.width/raw.width;scaled=raw.resize((a.width,round(raw.height*factor)),Image.Resampling.LANCZOS)
        im=Image.new('RGBA',a.size);im.alpha_composite(scaled)
        im.save(HERE/'registered'/f'{name}_c.png',optimize=True)
        original=next(x for x in mapping if x['name']==name);s=original['shared_pair_scale']
        size=(round(a.width*s),round(a.height*s));native=Image.new('RGBA',tuple(original['native_size']))
        native.alpha_composite(im.resize(size,Image.Resampling.LANCZOS),tuple(original['candidate_position']))
        native.save(HERE/'candidates'/f'{name}_c.png',optimize=True)
        records.append({'name':name+'_c','raw_size':list(raw.size),'raw_sha256':sha(HERE/'raw'/f'{name}_c.png'),'a_crop_size':list(a.size),'raw_to_a_scale':factor,'inherited_a_transform':original})
        review(name)
    if len(NAMES)==5:family()
    outputs=sorted(p for folder in ('registered','candidates','review') for p in (HERE/folder).iterdir() if p.is_file())
    (HERE/'revision-manifest.json').write_text(json.dumps({'new_poses':records,'outputs':{p.relative_to(HERE).as_posix():sha(p) for p in outputs}},indent=2)+'\n')


def verify()->None:
    frozen();data=json.loads((HERE/'revision-manifest.json').read_text())
    for rel,digest in data['outputs'].items():
        if sha(HERE/rel)!=digest:raise SystemExit('changed derivative: '+rel)
    for item in data['new_poses']:
        im=Image.open(HERE/'candidates'/f"{item['name']}.png")
        assert list(im.size)==item['inherited_a_transform']['native_size']
        assert im.getchannel('A').getextrema()==(0,255)
    print('Frozen existing family, source/raw inputs, native alpha/canvases and derivatives verified.')


if __name__=='__main__':
    if len(sys.argv)!=2 or sys.argv[1] not in ('build','verify','-h','--help'):raise SystemExit(__doc__)
    if sys.argv[1]=='build':build()
    elif sys.argv[1]=='verify':verify()
    else:print(__doc__)
