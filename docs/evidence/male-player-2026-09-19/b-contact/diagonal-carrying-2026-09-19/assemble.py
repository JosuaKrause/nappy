"""Assemble the uninstalled diagonal and carrying contact review from frozen inputs."""
import argparse
import hashlib
import importlib.util
import json
import shutil
from pathlib import Path
from PIL import Image, ImageOps

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
BASE = HERE.parent / 'straight-contact-2026-09-19/generated/rig'
CORRECT = HERE.parent / 'correct-contact-2026-09-19/generated'
RIG = ROOT / 'assets/illustrated/svg-transfer/rig'
EXTRACTED = ROOT / 'docs/evidence/male-player-2026-09-19/registered/extracted'
VIEWS = ('front', 'back', 'side', 'front_diagonal', 'back_diagonal')
LOOP = ('a', 'c', 'b', 'c')

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def rgba(path):
    return Image.open(path).convert('RGBA')

def module(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result

def inputs():
    paths = [Path(__file__)]
    paths += sorted(BASE.glob('father_*.png'))
    paths += [CORRECT/'rig/father_side_b.png', CORRECT/'father_side_b-12x.png']
    paths += [RIG/f'father_carrying_{v}_{p}.png' for v in VIEWS for p in ('a','b','c')]
    paths += [EXTRACTED/f'father_carrying_{v}_b.png' for v in ('side','front_diagonal')]
    paths += [ROOT/'docs/evidence/comic-pushing-strides-2026-09-12/convert.py']
    return {str(p.relative_to(ROOT)): digest(p) for p in paths if p.is_file()}

def sheets(output, state, p2):
    def sprite(view, pose, mirror):
        picture = rgba(output/'rig'/f'father_{"carrying_" if state == "carrying" else ""}{view}_{pose}.png')
        return ImageOps.mirror(picture) if mirror else picture
    sheet = Image.new('RGBA', (432,244), p2.BACKGROUND)
    for row, pose in enumerate(LOOP):
        for col, (_, view, mirror, _) in enumerate(p2.DIRECTIONS):
            p2._place(sheet, sprite(view,pose,mirror), col*54+27,row*61+59)
    sheet.save(output/f'{state}-spritesheet-native.png')
    sheet.resize((2592,1464),Image.Resampling.NEAREST).save(output/f'{state}-spritesheet-6x.png')
    for factor, size in ((1,'native'),(6,'6x')):
        frames=[]
        for pose in LOOP:
            frame=Image.new('RGBA',(216*factor,124*factor),p2.BACKGROUND)
            for index, (_, view, mirror, _) in enumerate(p2.DIRECTIONS):
                pic=sprite(view,pose,mirror)
                pic=pic.resize((pic.width*factor,pic.height*factor),Image.Resampling.NEAREST)
                p2._place(frame,pic,(index%4*54+27)*factor,(index//4*62+60)*factor)
            frames.append(frame)
        destination=output/f'{state}-animation-{size}.gif'
        frames[0].save(destination,save_all=True,append_images=frames[1:],duration=[190]*4,loop=0,disposal=2)
        p2._verify_animation(destination)
    assert rgba(output/f'{state}-spritesheet-6x.png').tobytes()==sheet.resize((2592,1464),Image.Resampling.NEAREST).tobytes()

def carrying_splice(view, lower, output):
    """Use high-resolution original carrying upper; preserve its registered identity exactly."""
    original=rgba(RIG/f'father_carrying_{view}_b.png')
    source=rgba(EXTRACTED/f'father_carrying_{view}_b.png')
    bounds=source.getchannel('A').getbbox()
    figure=source.crop(bounds)
    fitted=figure.resize((round(figure.width*540/figure.height),540),Image.Resampling.LANCZOS)
    high=Image.new('RGBA',(312,552))
    high.alpha_composite(fitted,((312-fitted.width)//2,12))
    # The player authorizes upper/lower construction. The untouched native upper is
    # restored after reduction so baby, face, arms and carrying pose cannot pulse.
    high.paste(lower.crop((0,336,312,552)),(0,336))
    high.save(output/f'carrying-{view}-assembly-12x.png')
    result=high.resize((26,46),Image.Resampling.LANCZOS)
    result.paste(original.crop((0,0,26,28)),(0,0))
    assert result.crop((0,0,26,28)).tobytes()==original.crop((0,0,26,28)).tobytes()
    return result

def assemble(output):
    assert not output.exists(), 'output must be fresh'
    assert json.loads((HERE/'inputs.json').read_text())==inputs(), 'a frozen input changed'
    output.mkdir(parents=True)
    p2=module(ROOT/'docs/evidence/comic-pushing-strides-2026-09-12/convert.py','p2_diagonal')
    for state in ('pushing','carrying'):
        (output/state/'rig').mkdir(parents=True)
        for view in VIEWS:
            for pose in ('a','b','c'):
                name=f'father_{"carrying_" if state == "carrying" else ""}{view}_{pose}.png'
                shutil.copy2((RIG if state=='carrying' else BASE)/name,output/state/'rig'/name)
    shutil.copy2(CORRECT/'rig/father_side_b.png',output/'pushing/rig/father_side_b.png')
    for view in ('front','back'):
        source=rgba(RIG/f'father_carrying_{view}_a.png')
        result=rgba(RIG/f'father_carrying_{view}_b.png')
        # Same centered A-lower reflection as the accepted pushing N/S contact.
        assert source.crop((23,28,24,46)).getchannel('A').getbbox() is None
        result.paste(ImageOps.mirror(source.crop((0,28,23,46))),(0,28))
        result.save(output/'carrying/rig'/f'father_carrying_{view}_b.png')
    for view in ('side','front_diagonal'):
        if view=='side':
            lower=rgba(CORRECT/'father_side_b-12x.png')
        else:
            lower=rgba(BASE/'father_front_diagonal_b.png').resize((312,552),Image.Resampling.NEAREST)
        carrying_splice(view,lower,output/'carrying').save(output/'carrying/rig'/f'father_carrying_{view}_b.png')
    for state in ('pushing','carrying'):
        for view in VIEWS:
            for pose in ('a','b','c'):
                name=f'father_{"carrying_" if state=="carrying" else ""}{view}_{pose}.png'
                path=output/state/'rig'/name
                original=(RIG if state=='carrying' else BASE)/name
                assert rgba(path).size==rgba(original).size
                protected=pose!='b' or view=='back_diagonal' or (state=='pushing' and view in ('front','back'))
                if protected:
                    assert path.read_bytes()==original.read_bytes(),name
                elif state=='carrying':
                    width=rgba(path).width
                    assert rgba(path).crop((0,0,width,28)).tobytes()==rgba(original).crop((0,0,width,28)).tobytes(),name
                    assert rgba(path).tobytes()!=rgba(original).tobytes(),name
        sheets(output/state,state,p2)
    record={'frame_order':LOOP,'frame_ms':[190]*4,'diagonal_source':'accepted straight-contact provisional baseline; natural three-quarter redraw unresolved','files':{str(p.relative_to(output)):digest(p) for p in sorted(output.rglob('*')) if p.is_file()}}
    (output/'manifest.json').write_text(json.dumps(record,indent=2)+'\n')
    print('Verified protected frames, carrying upper identity, four changed carrying B views, canvases and 190ms loops.')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir',type=Path)
    parser.add_argument('--freeze-inputs',action='store_true')
    args=parser.parse_args()
    if args.freeze_inputs:
        assert not (HERE/'inputs.json').exists(), 'input manifest already exists'
        (HERE/'inputs.json').write_text(json.dumps(inputs(),indent=2)+'\n')
    elif args.output_dir is None:
        parser.error('--output-dir is required')
    else:
        assemble(args.output_dir)

if __name__=='__main__':
    main()
