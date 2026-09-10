"""Prepare diagonal SVG inputs and register saved PNG output at native dimensions."""
import argparse
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import subprocess

from PIL import Image, ImageDraw

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
PREVIOUS = ROOT / 'docs/evidence/style-transfer-2026-09-10'
NAMES = ['mother_front_diagonal_a', 'mother_front_diagonal_b', 'pram_front_diagonal',
         'mother_back_diagonal_a', 'mother_back_diagonal_b', 'pram_back_diagonal']
CELL = (384, 512)


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def prepare(root):
    sheet = Image.new('RGBA', (1152, 1024))
    manifest = []
    for index, name in enumerate(NAMES):
        svg = root / 'assets/rig' / f'{name}.svg'
        manifest.append(dict(svg=f'assets/rig/{name}.svg',
                             png=f'assets/illustrated/svg-transfer/rig/{name}.png',
                             svg_sha256=hashlib.sha256(svg.read_bytes()).hexdigest()))
        for scale in (1, 8):
            destination = SOURCE / f'{name}-svg{ "-8x" if scale == 8 else ""}.png'
            assert not destination.exists(), destination
            subprocess.run([os.environ.get('GODOT', '/Applications/Godot.app/Contents/MacOS/Godot'),
                            '--headless', '--path', str(root), '--script',
                            str(PREVIOUS / 'rasterize-svg.gd'), '--',
                            str(root / 'assets/rig' / f'{name}.svg'), str(destination), str(scale)],
                           check=True, timeout=30)
        raster = Image.open(destination).convert('RGBA')
        sheet.alpha_composite(raster, ((index % 3) * CELL[0] + (CELL[0] - raster.width) // 2,
                                      (index // 3) * CELL[1] + 448 - raster.height))
    destination = SOURCE / 'diagonal-sheet-svg.png'
    assert not destination.exists(), destination
    sheet.save(destination)
    manifest_path = SOURCE / 'source-manifest.json'
    assert not manifest_path.exists(), manifest_path
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')


def register(output):
    assert not output.exists(), output
    output.mkdir(parents=True)
    checker = module('checker', ROOT / 'tools/remove-checkerboard.py')
    previous = module('register_previous', PREVIOUS / 'register-transfer.py')
    checker.extract(SOURCE / 'diagonal-sheet-generated.png', output / 'diagonal-sheet-extracted.png')
    atlas = Image.open(output / 'diagonal-sheet-extracted.png').convert('RGBA')
    atlas = atlas.resize((1152, 1024), Image.Resampling.LANCZOS)
    (output / 'rig').mkdir()
    measurements = []
    comparison = Image.new('RGB', (960, 600), '#68767c')
    draw = ImageDraw.Draw(comparison)
    for index, name in enumerate(NAMES):
        native = Image.open(SOURCE / f'{name}-svg.png').convert('RGBA')
        template = Image.open(SOURCE / f'{name}-svg-8x.png').convert('RGBA')
        x, y = (index % 3) * CELL[0], (index // 3) * CELL[1]
        cell = atlas.crop((x, y, x + CELL[0], y + CELL[1]))
        bounds = cell.getchannel('A').point(lambda a: 255 if a > 192 else 0).getbbox()
        target = template.getchannel('A').getbbox()
        assert bounds and target
        filled = previous.extend_colors(cell.crop(bounds))
        fitted = Image.new('RGB', template.size)
        fitted.paste(filled.resize((target[2] - target[0], target[3] - target[1]),
                                  Image.Resampling.LANCZOS), target[:2])
        fitted.putalpha(template.getchannel('A'))
        final = previous.extend_colors(fitted).resize(native.size, Image.Resampling.LANCZOS)
        final.putalpha(native.getchannel('A'))
        final.save(output / 'rig' / f'{name}.png')
        assert final.getchannel('A').tobytes() == native.getchannel('A').tobytes()
        measurements.append(dict(name=name, size=native.size, generated_cell_bounds=bounds,
                                 svg_8x_bounds=target, alpha_identical_to_native_svg=True))
        cx, cy = (index % 3) * 320, (index // 3) * 300
        draw.text((cx + 8, cy + 8), name, fill='white')
        for column, raster in enumerate((native, final)):
            big = raster.resize((raster.width * 4, raster.height * 4), Image.Resampling.NEAREST)
            comparison.paste(big, (cx + column * 160 + (160 - big.width) // 2,
                                   cy + 240 - big.height), big)
    (output / 'registration.json').write_text(json.dumps(measurements, indent=2) + '\n')
    comparison.save(output / 'diagonal-comparison.png')


def directions(output):
    """A labelled source comparison, assembled at the runtime's 34px/0.7 ground offsets."""
    assert not output.exists(), output
    sheet = Image.new('RGB', (1280, 1280), '#68767c')
    draw = ImageDraw.Draw(sheet)
    views = [('N', 'back', False, -90), ('NE', 'back_diagonal', False, -45),
             ('E', 'side', False, 0), ('SE', 'front_diagonal', False, 45),
             ('S', 'front', False, 90), ('SW', 'front_diagonal', True, 135),
             ('W', 'side', True, 180), ('NW', 'back_diagonal', True, 225)]
    for index, (label, view, mirror, degrees) in enumerate(views):
        cx, cy = (index % 2) * 640, (index // 2) * 320
        draw.text((cx + 12, cy + 10), f'{label} - SVG left / PNG right - 3x', fill='white')
        angle = math.radians(degrees)
        dx, dy = math.cos(angle) * 34, math.sin(angle) * 34 * 0.7
        for column in range(2):
            parts = []
            for kind, offset in [('mother', (0, 0)), ('pram', (dx, dy))]:
                name = f'{kind}_{view}' + ('_a' if kind == 'mother' else '')
                if column:
                    path = ROOT / 'assets/illustrated/svg-transfer/rig' / f'{name}.png'
                else:
                    source = SOURCE if 'diagonal' in view else PREVIOUS
                    path = source / f'{name}-svg.png'
                raster = Image.open(path).convert('RGBA')
                if mirror:
                    raster = raster.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                parts.append((raster, offset))
            if dy < 0:
                parts.reverse()
            for raster, (x, y) in parts:
                big = raster.resize((raster.width * 3, raster.height * 3), Image.Resampling.NEAREST)
                sheet.paste(big, (round(cx + column * 320 + 160 + x * 3 - big.width / 2),
                                 round(cy + 200 + y * 3 - big.height)), big)
    sheet.save(output)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('prepare', 'register', 'directions'))
    parser.add_argument('path', type=Path, help='SVG checkout, new registration folder, or new directions PNG')
    args = parser.parse_args()
    {'prepare': prepare, 'register': register, 'directions': directions}[args.mode](args.path.resolve())
