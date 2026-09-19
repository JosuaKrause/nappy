"""Prepare an uncrossed two-track walking guide beneath cropped father identities."""
import argparse
from pathlib import Path
from PIL import Image, ImageDraw

HERE=Path(__file__).resolve().parent
SOURCE=HERE.parent/'natural-southeast-2026-09-19/generated/recolored-source.png'

def prepare(output):
    assert not output.exists(),output
    output.mkdir(parents=True)
    source=Image.open(SOURCE).convert('RGBA')
    assert source.size==(1391,1131)
    target=Image.new('RGBA',source.size)
    target.paste(source.crop((0,0,1391,580)),(0,0))
    draw=ImageDraw.Draw(target)
    for offset in (0,695):
        # Each chain remains on its own side of the pelvis. No X or swapped hips.
        for points,color,width in (([(366,600),(395,820),(430,1008)],'#20b9d1',72),
                                   ([(260,600),(240,775),(218,955)],'#dc6469',76)):
            chain=[(x+offset,y) for x,y in points]
            draw.line(chain,fill='#202020',width=width+12,joint='curve')
            draw.line(chain,fill=color,width=width,joint='curve')
            x,y=chain[-1]
            draw.ellipse((x-30,y-8,x+65,y+36),fill=color,outline='#202020',width=6)
    target.save(output/'uncrossed-contact-edit-target.png')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir',type=Path,required=True)
    args=parser.parse_args()
    prepare(args.output_dir)
