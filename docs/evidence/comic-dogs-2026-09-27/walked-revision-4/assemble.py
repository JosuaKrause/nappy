"""Register generated B artwork and draw synthetic review diagnostics.

Usage: uv run python assemble.py build|verify
"""
from __future__ import annotations

import hashlib
import importlib.util
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
BASE = HERE.parent
ROOT = HERE.parents[3]
NAMES = ('dog', 'dog_front_diagonal', 'dog_back_diagonal')
PAPER = (238, 235, 228, 255)
# Same crop-plane scale as A; registration uses fixed body features, never feet.
OFFSETS = {'dog': (0, 0), 'dog_front_diagonal': (0, 0), 'dog_back_diagonal': (0, 0)}
LEG_TOP = {'dog': 145, 'dog_front_diagonal': 187, 'dog_back_diagonal': 207}
MANIFEST_SHA = 'd3cc2c2953c8b568913a9f52ee6b3536a2ceda266034fbd8ac94ead1ee3c4a2e'


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def frozen() -> None:
    path = HERE / 'input-manifest.json'
    if MANIFEST_SHA and sha(path) != MANIFEST_SHA:
        raise SystemExit('authoritative input manifest changed')
    extra = HERE / 'diagonal-input-manifest.json'
    if sha(extra) != '99af6224c220765c109fd101a19f2c0ba5556a31490932b7ce6aa5f80b4f62d6':
        raise SystemExit('authoritative diagonal input manifest changed')
    for item in json.loads(path.read_text())['inputs'] + json.loads(extra.read_text())['inputs']:
        source = ROOT / item['path']
        if not source.is_file() or sha(source) != item['sha256']:
            raise SystemExit(f"frozen input changed or missing: {item['path']}")


def registered(name: str) -> Image.Image:
    a = Image.open(BASE / 'crops/dog' / f'{name}.png').convert('RGBA')
    raw = Image.open(HERE / 'raw' / f'{name}_b.png').convert('RGBA')
    scale = a.width / raw.width
    scaled = raw.resize((a.width, round(raw.height * scale)), Image.Resampling.LANCZOS)
    result = Image.new('RGBA', a.size)
    result.alpha_composite(scaled, OFFSETS[name])
    return result


def diagnostics(name: str, frames: list[Image.Image]) -> None:
    w, h = frames[0].size
    clean = []
    silhouettes = []
    top = LEG_TOP[name]
    for im in frames:
        p = Image.new('RGBA', im.size, PAPER)
        p.alpha_composite(im)
        clean.append(p.convert('RGB'))
        leg = im.crop((0, top, w, h))
        mono = Image.new('RGBA', leg.size, 'black')
        mono.putalpha(leg.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
        p = Image.new('RGBA', leg.size, 'white')
        p.alpha_composite(mono)
        silhouettes.append(p.convert('RGB'))
    for tag, pictures in (('body', clean), ('leg-silhouette', silhouettes)):
        height = pictures[0].height
        sheet = Image.new('RGB', (w * 2, height + 22), 'white')
        draw = ImageDraw.Draw(sheet)
        for i, picture in enumerate(pictures):
            sheet.paste(picture, (i * w, 22))
            draw.text((i * w + 5, 4), f'{name} / {"AB"[i]} / {tag}', fill='black')
        sheet.save(HERE / 'review' / f'{name}-{tag}-pair.png')
        pictures[0].save(HERE / 'review' / f'{name}-{tag}-loop.gif', save_all=True,
                         append_images=pictures[1:], duration=650, loop=0, optimize=False)
    overlay = Image.new('RGB', (w, h-top), 'white')
    # Cyan means A-only; magenta B-only; black overlap. This contains NO color data.
    a, b = [p.getchannel('A').crop((0,top,w,h)) for p in frames]
    overlay.putdata([(0,0,0) if x>=128 and y>=128 else (0,150,200) if x>=128
                     else (210,0,120) if y>=128 else (255,255,255)
                     for x,y in zip(a.get_flattened_data(),b.get_flattened_data())])
    overlay.save(HERE / 'review' / f'{name}-leg-silhouette-overlay.png')


def build() -> None:
    frozen()
    for folder in ('registered', 'candidates', 'review'):
        (HERE / folder).mkdir(exist_ok=True)
    mapping = json.loads((BASE / 'candidate-manifest.json').read_text())['families'][0]['cells']
    records = []
    for name in NAMES:
        a = Image.open(BASE / 'crops/dog' / f'{name}.png').convert('RGBA')
        b = registered(name)
        b.save(HERE / 'registered' / f'{name}_b.png', optimize=True)
        diagnostics(name, [a,b])
        original = next(item for item in mapping if item['name'] == name)
        native = Image.new('RGBA', tuple(original['native_size']))
        scale = original['shared_pair_scale']
        size = (round(a.width*scale), round(a.height*scale))
        native.alpha_composite(b.resize(size, Image.Resampling.LANCZOS), tuple(original['candidate_position']))
        native.save(HERE / 'candidates' / f'{name}_b.png', optimize=True)
        raw = HERE / 'raw' / f'{name}_b.png'
        records.append({'name':name+'_b', 'raw_sha256':sha(raw), 'raw_size':list(Image.open(raw).size),
                        'a_crop_size':list(a.size), 'offset':OFFSETS[name],
                        'inherited_a_transform':original})
    # Reuse the immutable existing all-facing layout and mirror/timing recipe.
    spec = importlib.util.spec_from_file_location('review_recipe', BASE/'walked-revision-3/assemble.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.HERE, module.NAMES = HERE, NAMES
    module.family_reviews()
    paths = sorted(p for folder in ('registered','candidates','review') for p in (HERE/folder).iterdir() if p.is_file())
    manifest = {'overrides':records, 'outputs':{p.relative_to(HERE).as_posix():sha(p) for p in paths}}
    (HERE/'revision-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')


def verify() -> None:
    frozen()
    manifest = json.loads((HERE/'revision-manifest.json').read_text())
    for relative, digest in manifest['outputs'].items():
        if sha(HERE/relative) != digest:
            raise SystemExit(f'derivative changed: {relative}')
    for item in manifest['overrides']:
        im = Image.open(HERE/'candidates'/f"{item['name']}.png")
        assert list(im.size) == item['inherited_a_transform']['native_size']
        assert im.getchannel('A').getextrema() == (0,255)
    print('Frozen inputs, native sizes, real alpha and derivative hashes verified.')


if __name__ == '__main__':
    if len(sys.argv) != 2 or sys.argv[1] not in ('build','verify','-h','--help'):
        raise SystemExit(__doc__)
    if sys.argv[1] == 'build':
        build()
    elif sys.argv[1] == 'verify':
        verify()
    else:
        print(__doc__)
