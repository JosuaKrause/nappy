"""Register the experiment atlas to SVG canvases; keep source alpha authoritative."""
from collections import deque
from pathlib import Path
import argparse
import importlib.util
import json
from PIL import Image

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
NAMES = ['mother_front_a', 'mother_front_b', 'pram_front',
         'mother_back_a', 'mother_back_b', 'pram_back',
         'mother_side_a', 'mother_side_b', 'pram_side']

def extend_colors(image):
    """Extend retained colors into transparent pixels without borrowing checker colors."""
    width, height = image.size
    pixels = list(image.get_flattened_data())
    seen = bytearray(int(p[3] != 0) for p in pixels)
    pending = deque(i for i, valid in enumerate(seen) if valid)
    assert pending, 'empty sprite'
    while pending:
        index = pending.popleft()
        x, y = index % width, index // width
        for nx, ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0 <= nx < width and 0 <= ny < height:
                other = ny * width + nx
                if not seen[other]:
                    seen[other] = 1
                    pixels[other] = pixels[index]
                    pending.append(other)
    rgb = Image.new('RGB', image.size)
    rgb.putdata([pixel[:3] for pixel in pixels])
    return rgb

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path, help='New directory for extracted and registered images')
    output = parser.parse_args().output
    assert not output.exists(), 'Choose a new output directory to preserve existing results'
    output.mkdir(parents=True)
    spec = importlib.util.spec_from_file_location('checker', ROOT / 'tools/remove-checkerboard.py')
    checker = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(checker)
    raw = SOURCE / 'rig-sheet-generated.png'
    extracted = output / 'rig-sheet-extracted.png'
    checker.extract(raw, extracted)
    atlas = Image.open(extracted).convert('RGBA').resize((1152,1536), Image.Resampling.LANCZOS)
    (output / 'rig').mkdir()
    measurements = []
    for index, name in enumerate(NAMES):
        native_path = SOURCE / (name + '-svg.png')
        native = Image.open(native_path).convert('RGBA')
        template = Image.open(SOURCE / (name + '-svg-8x.png')).convert('RGBA')
        cell = atlas.crop(((index%3)*384,(index//3)*512,(index%3+1)*384,(index//3+1)*512))
        # Discard antialiased extraction dust when measuring, while retaining painted edge color.
        bounds = cell.getchannel('A').point(lambda a: 255 if a > 192 else 0).getbbox()
        target = template.getchannel('A').getbbox()
        assert bounds is not None and target is not None
        subject = cell.crop(bounds)
        filled = extend_colors(subject)
        registered = Image.new('RGB', template.size)
        registered.paste(filled.resize((target[2]-target[0],target[3]-target[1]),Image.Resampling.LANCZOS),target[:2])
        # Extend edge colors before final downsampling to avoid dark fringes in antialiased pixels.
        registered.putalpha(template.getchannel('A'))
        registered = extend_colors(registered).resize(native.size,Image.Resampling.LANCZOS)
        registered.putalpha(native.getchannel('A'))
        destination = output / 'rig' / (name + '.png')
        assert not destination.exists(), destination
        registered.save(destination)
        assert registered.size == native.size
        assert registered.getchannel('A').tobytes() == native.getchannel('A').tobytes()
        measurements.append({'name':name,'size':native.size,'generated_cell_bounds':bounds,
                             'svg_8x_bounds':target,'alpha_identical_to_native_svg':True})
    (output/'registration.json').write_text(json.dumps(measurements,indent=2)+'\n')

if __name__ == '__main__':
    main()
