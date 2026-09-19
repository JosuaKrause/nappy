"""Register the uncrossed southeast pair and preserve every other father frame."""
import argparse
import hashlib
import importlib.util
import json
import shutil
from pathlib import Path
from PIL import Image
from PIL import __version__ as pillow_version

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
BASE=HERE.parent/'color-match-2026-09-19/final'
HELPER=HERE.parent/'natural-southeast-2026-09-19/assemble.py'
SHEETS=HERE.parent/'color-match-2026-09-19/assemble.py'
P2=ROOT/'docs/evidence/comic-pushing-strides-2026-09-12/convert.py'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def module(path,name):
    spec=importlib.util.spec_from_file_location(name,path)
    result=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result

def rgba(path):
    return Image.open(path).convert('RGBA')

def inputs():
    paths=[Path(__file__),HERE/'prepare.py',HERE/'retry-prompt.txt',HERE/'generated-colored.png',
           HELPER,SHEETS,P2,HERE.parent/'natural-southeast-2026-09-19/generated/recolored-source.png']
    paths+=sorted((HERE/'inputs').glob('*.png'))
    for state in ('pushing','carrying'):
        paths+=sorted((BASE/state/'rig').glob('*.png'))
    return {'pillow':pillow_version,'files':{str(p.relative_to(ROOT)):digest(p) for p in paths}}

def recolor(raw):
    result=raw.copy()
    mask=Image.new('L',raw.size)
    for y in range(575,raw.height):
        for x in range(raw.width):
            red,green,blue,alpha=raw.getpixel((x,y))
            if not alpha:
                continue
            local=x if x<695 else x-695
            # New ankle/cuff boundaries, traced on this uncrossed source.
            shoe=(local<300 and y>=880+.16*local) or (local>=350 and y>=1223-.46*local)
            colored=(red>1.5*green and red>1.4*blue) or (green>2*red and blue>2*red and green>.8*blue)
            if not (shoe or colored):
                continue
            luma=.2126*red+.7152*green+.0722*blue
            if shoe:
                value=round(.19*luma+32)
                rgb=(value+3,value,value-2)
            else:
                value=round(.66*luma+9)
                rgb=(round(.86*value),round(1.02*value),round(1.25*value))
            result.putpixel((x,y),(*rgb,alpha))
            mask.putpixel((x,y),255)
    assert result.getchannel('A').tobytes()==raw.getchannel('A').tobytes()
    for before,after,selected in zip(raw.get_flattened_data(),result.get_flattened_data(),mask.get_flattened_data(),strict=True):
        assert selected or before==after
    assert result.crop((0,0,raw.width,575)).tobytes()==raw.crop((0,0,raw.width,575)).tobytes()
    return result,mask

def assemble(output):
    assert not output.exists(),output
    assert json.loads((HERE/'inputs.json').read_text())==inputs(),'frozen input changed'
    output.mkdir(parents=True)
    raw=rgba(HERE/'generated-colored.png')
    assert raw.size==(1391,1131)
    recolored,mask=recolor(raw)
    recolored.save(output/'recolored-source.png')
    mask.save(output/'recolor-mask.png')
    helper=module(HELPER,'uncrossed_registration')
    sheets=module(SHEETS,'uncrossed_sheets')
    p2=module(P2,'uncrossed_p2')
    records={}
    for index,state in enumerate(('pushing','carrying')):
        prefix='father' if state=='pushing' else 'father_carrying'
        destination=output/state
        shutil.copytree(BASE/state/'rig',destination/'rig')
        cell_bounds=(index*695,0,695 if index==0 else 1391,1131)
        cell=recolored.crop(cell_bounds)
        bounds=cell.getchannel('A').point(lambda a:255 if a>1 else 0).getbbox()
        figure=cell.crop(bounds)
        width=round(figure.width*540/figure.height)
        fitted=figure.resize((width,540),Image.Resampling.LANCZOS)
        reference=rgba(BASE/state/'rig'/f'{prefix}_front_diagonal_c.png')
        x=round(helper.centroid(reference)*12-helper.centroid(fitted))
        assert 0<=x and x+width<=312,(state,x,width)
        high=Image.new('RGBA',(312,552))
        high.alpha_composite(fitted,(x,12))
        high.save(destination/'front-diagonal-b-12x.png')
        native=high.resize((26,46),Image.Resampling.LANCZOS)
        native.save(destination/'rig'/f'{prefix}_front_diagonal_b.png')
        for source in (BASE/state/'rig').glob('*.png'):
            target=destination/'rig'/source.name
            assert rgba(target).size==rgba(source).size
            if source.name!=f'{prefix}_front_diagonal_b.png':
                assert source.read_bytes()==target.read_bytes(),source.name
            else:
                assert rgba(target).tobytes()!=rgba(source).tobytes()
        sheets.sheets(destination,prefix,state,p2)
        sheet=rgba(destination/f'{state}-spritesheet-native.png')
        assert rgba(destination/f'{state}-spritesheet-6x.png').tobytes()==sheet.resize((2592,1464),Image.Resampling.NEAREST).tobytes()
        records[state]={'raw_cell':cell_bounds,'visible_bounds':bounds,'fit_12x':[width,540],
                        'placement_12x':[x,12],'whole_figure_uniform_scale':True,
                        'native_alpha_bounds':native.getchannel('A').getbbox(),'protected_files':14}
    (output/'manifest.json').write_text(json.dumps({'registration':records,'frame_order':['a','c','b','c'],
        'frame_ms':[190]*4,'input_manifest_sha256':digest(HERE/'inputs.json'),
        'files':{str(p.relative_to(output)):digest(p) for p in sorted(output.rglob('*')) if p.is_file()}},indent=2)+'\n')
    print(json.dumps(records,indent=2))

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--freeze-inputs',action='store_true')
    group.add_argument('--output-dir',type=Path)
    args=parser.parse_args()
    if args.freeze_inputs:
        assert not (HERE/'inputs.json').exists(),'manifest exists'
        (HERE/'inputs.json').write_text(json.dumps(inputs(),indent=2)+'\n')
    else:
        assemble(args.output_dir)
