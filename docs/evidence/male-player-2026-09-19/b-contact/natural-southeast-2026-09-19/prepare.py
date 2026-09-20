"""Prepare cropped identities and an explicit colored hip-to-shoe contact diagram."""
import argparse
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]

def prepare(output):
    assert not output.exists(), output
    output.mkdir(parents=True)
    sheet = Image.new('RGBA', (1600, 1300))
    for i, state in enumerate(('', 'carrying_')):
        source = Image.open(ROOT / f'docs/evidence/male-player-2026-09-19/registered/extracted/father_{state}front_diagonal_b.png').convert('RGBA')
        # Crop before pelvis: the rejected original leg pose never enters this reference.
        upper = source.crop((0, 0, source.width, 208))
        bounds = upper.getchannel('A').getbbox()
        upper = upper.crop(bounds)
        upper = upper.resize((round(upper.width * 650 / upper.height), 650), Image.Resampling.LANCZOS)
        sheet.alpha_composite(upper, (i * 800 + (800-upper.width)//2, 30))
    sheet.save(output / 'father-upper-identities.png')
    diagram = Image.new('RGB', (800, 620), 'white')
    draw = ImageDraw.Draw(diagram)
    # Diagram coordinates express the accepted SVG's chains, not final artwork.
    far = [(275,100),(400,330),(550,520)]
    near = [(460,110),(345,285),(190,445)]
    draw.line(far, fill='#202020', width=82, joint='curve')
    draw.line(far, fill='#20b9d1', width=66, joint='curve')
    draw.ellipse((516,481,625,549), fill='#20b9d1', outline='#202020', width=7)
    draw.line(near, fill='#202020', width=86, joint='curve')
    draw.line(near, fill='#dc6469', width=70, joint='curve')
    draw.ellipse((145,425,260,480), fill='#dc6469', outline='#202020', width=7)
    for label, position in [('SCREEN LEFT HIP: CYAN', (65,40)), ('SCREEN RIGHT HIP: RED', (440,40)), ('RED THIGH CROSSES IN FRONT', (370,220)), ('RED TRAILING SHOE', (40,510)), ('CYAN ADVANCING SHOE', (460,580))]:
        draw.text(position, label, fill='black', font_size=20)
    diagram.save(output / 'contact-ownership-diagram.png')
    target = sheet.copy()
    draw = ImageDraw.Draw(target)
    for offset in (0, 800):
        def shift(points):
            return [(x+offset,y) for x,y in points]
        far = shift([(315,725),(420,930),(530,1140)])
        near = shift([(445,725),(345,875),(240,1050)])
        for chain, color, width in ((far,'#20b9d1',66),(near,'#dc6469',70)):
            draw.line(chain,fill='#202020',width=width+14,joint='curve')
            draw.line(chain,fill=color,width=width,joint='curve')
            x,y=chain[-1]
            draw.ellipse((x-40,y-10,x+60,y+35),fill=color,outline='#202020',width=7)
    target.save(output / 'colored-contact-edit-target.png')

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir',type=Path,required=True)
    args=parser.parse_args()
    prepare(args.output_dir)
