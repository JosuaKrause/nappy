"""Rebuild the player-authorized father splice trial and P2-format sprite loops."""

import argparse
import hashlib
import importlib.util
import json
import shutil
from pathlib import Path

from PIL import Image, ImageOps
from PIL import __version__ as pillow_version

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
RIG = ROOT / "assets/illustrated/svg-transfer/rig"
P2_RECIPE = ROOT / "docs/evidence/comic-pushing-strides-2026-09-12/convert.py"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
LOOP = ("a", "c", "b", "c")
CUT_Y = 28
DONOR_CROP = (60, 900, 903, 1613)
FACTOR = 12


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rgba(path):
    return Image.open(path).convert("RGBA")


def p2_recipe():
    spec = importlib.util.spec_from_file_location("p2_recipe", P2_RECIPE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def inputs():
    paths = [HERE / "father-side-leg-donor.png", P2_RECIPE, Path(__file__), HERE / "chronology.json"]
    paths += [RIG / f"father_{view}_{pose}.png" for view in VIEWS for pose in ("a", "c", "b")]
    return {str(path.relative_to(ROOT)): sha(path) for path in paths}


def mirror_cardinal(source):
    result = source.copy()
    # Both A poses' hip band spans x=7..15, centered on pixel 11. Mirror x -> 22-x,
    # not around the off-center canvas midpoint. Column 23 is transparent below the cut.
    assert source.crop((23, CUT_Y, 24, 46)).getchannel("A").getbbox() is None
    lower = source.crop((0, CUT_Y, 23, 46)).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    result.paste(lower, (0, CUT_Y))
    assert result.crop((0, 0, 24, CUT_Y)).tobytes() == source.crop((0, 0, 24, CUT_Y)).tobytes()
    return result


def splice(source, diagonal):
    donor = rgba(HERE / "father-side-leg-donor.png").crop(DONOR_CROP)
    height = (46 - CUT_Y) * FACTOR
    width = round(donor.width * height / donor.height)
    lower = donor.resize((width, height), Image.Resampling.LANCZOS)
    # Fixed placement aligns the donor's two hip roots beneath the father's existing shirt.
    # No bounding-box recentering or head/hand movement is allowed.
    x = 2 * FACTOR
    assert x + width <= 26 * FACTOR
    high = Image.new("RGBA", (26 * FACTOR, 46 * FACTOR))
    high.alpha_composite(lower, (x, CUT_Y * FACTOR))
    transform = None
    if diagonal:
        # Same father leg pair, projected onto the existing southeast contact line:
        # the left/trailing foot is three native pixels higher than the right foot.
        slope = 3 * FACTOR / (width - 1)
        right = x + width - 1
        transform = (1, 0, 0, -slope, 1, slope * right)
        high = high.transform(high.size, Image.Transform.AFFINE, transform, Image.Resampling.BICUBIC)
    result = high.resize((26, 46), Image.Resampling.LANCZOS)
    result.paste(source.crop((0, 0, 26, CUT_Y)), (0, 0))
    assert result.crop((0, 0, 26, CUT_Y)).tobytes() == source.crop((0, 0, 26, CUT_Y)).tobytes()
    return result, {
        "donor_crop": DONOR_CROP,
        "fit_at_12x": [width, height],
        "placement_at_12x": [x, CUT_Y * FACTOR],
        "inverse_affine_at_12x": transform,
        "composition": "transformed lower legs first; exact A rows 0..27 pasted last",
    }


def sprite(output, view, pose, mirror=False):
    result = rgba(output / "rig" / f"father_{view}_{pose}.png")
    return ImageOps.mirror(result) if mirror else result


def sheets(output, p2):
    # P2 frame-sheet spacing (54x61), expanded to all eight directions and all four phases.
    # The player requests clean sprites only, so its title, labels and comparison panels are omitted.
    sheet = Image.new("RGBA", (54 * 8, 61 * 4), p2.BACKGROUND)
    for row, pose in enumerate(LOOP):
        for column, (_label, view, mirror, _angle) in enumerate(p2.DIRECTIONS):
            p2._place(sheet, sprite(output, view, pose, mirror), column * 54 + 27, row * 61 + 59)
    sheet.save(output / "father-spritesheet-native.png")
    sheet.resize((sheet.width * 6, sheet.height * 6), Image.Resampling.NEAREST).save(
        output / "father-spritesheet-6x.png"
    )
    # P2 animation layout (four columns, two rows, 54x62 cells), palette background and timing.
    # No text is baked into the requested sprite-only output.
    for factor, name in ((1, "native"), (6, "6x")):
        frames = []
        for pose in LOOP:
            frame = Image.new("RGBA", (54 * 4 * factor, 62 * 2 * factor), p2.BACKGROUND)
            for index, (_label, view, mirror, _angle) in enumerate(p2.DIRECTIONS):
                picture = sprite(output, view, pose, mirror)
                picture = picture.resize((picture.width * factor, picture.height * factor), Image.Resampling.NEAREST)
                p2._place(frame, picture, (index % 4 * 54 + 27) * factor, (index // 4 * 62 + 60) * factor)
            frames.append(frame)
        frames[0].save(
            output / f"father-animation-{name}.gif",
            save_all=True,
            append_images=frames[1:],
            duration=[190, 190, 190, 190],
            loop=0,
            disposal=2,
        )
        p2._verify_animation(output / f"father-animation-{name}.gif")


def verify(output, p2):
    for view in VIEWS:
        for pose in ("a", "c", "b"):
            path = output / "rig" / f"father_{view}_{pose}.png"
            picture = rgba(path)
            assert picture.size == ((24, 46) if view in ("front", "back") else (26, 46))
            bounds = picture.getchannel("A").getbbox()
            assert bounds and bounds[3] == 46 and bounds[1] <= 1, (path, bounds)
            if pose != "b" or view == "back_diagonal":
                assert path.read_bytes() == (RIG / path.name).read_bytes(), path
            else:
                original = rgba(RIG / f"father_{view}_a.png")
                assert (
                    picture.crop((0, 0, picture.width, CUT_Y)).tobytes()
                    == original.crop((0, 0, picture.width, CUT_Y)).tobytes()
                )
    sheet = rgba(output / "father-spritesheet-native.png")
    for row, pose in enumerate(LOOP):
        for column, (_label, view, mirror, _angle) in enumerate(p2.DIRECTIONS):
            expected = sprite(output, view, pose, mirror)
            x, y = column * 54 + 27 - expected.width // 2, row * 61 + 59 - 46
            expected = Image.alpha_composite(Image.new("RGBA", expected.size, p2.BACKGROUND), expected)
            assert sheet.crop((x, y, x + expected.width, y + 46)).tobytes() == expected.tobytes()
    for name in ("native", "6x"):
        p2._verify_animation(output / f"father-animation-{name}.gif")
    assert (
        rgba(output / "father-spritesheet-6x.png").tobytes()
        == sheet.resize((sheet.width * 6, sheet.height * 6), Image.Resampling.NEAREST).tobytes()
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True, help="fresh output directory")
    parser.add_argument("--freeze-inputs", action="store_true", help="create the input hashes once")
    args = parser.parse_args()
    if args.output_dir.exists():
        parser.error("output directory must be fresh")
    manifest = HERE / "inputs.json"
    current = {"pillow": pillow_version, "files": inputs()}
    if args.freeze_inputs:
        if manifest.exists():
            parser.error("input hashes already exist")
        manifest.write_text(json.dumps(current, indent=2) + "\n")
    assert current == json.loads(manifest.read_text()), "a frozen input or recipe changed"
    p2 = p2_recipe()
    args.output_dir.mkdir(parents=True)
    (args.output_dir / "rig").mkdir()
    records = {}
    for view in VIEWS:
        for pose in ("a", "c", "b"):
            source = RIG / f"father_{view}_{pose}.png"
            destination = args.output_dir / "rig" / source.name
            if pose != "b" or view == "back_diagonal":
                shutil.copy2(source, destination)
                continue
            original = rgba(RIG / f"father_{view}_a.png")
            if view in ("front", "back"):
                picture = mirror_cardinal(original)
                record = {
                    "source": f"father_{view}_a.png",
                    "crop": [0, CUT_Y, 23, 46],
                    "transform": "horizontal mirror x -> 22-x",
                    "paste_at": [0, CUT_Y],
                    "upper_rows": "A rows 0..27 unchanged",
                }
            else:
                picture, record = splice(original, view == "front_diagonal")
            picture.save(destination)
            records[view] = record | {"canvas": picture.size, "alpha_bounds": picture.getchannel("A").getbbox()}
    sheets(args.output_dir, p2)
    verify(args.output_dir, p2)
    record = {
        "loop": LOOP,
        "frame_ms": [190] * 4,
        "directions": p2.DIRECTIONS,
        "registration": records,
        "input_manifest_sha256": sha(manifest),
        "outputs": {
            str(p.relative_to(args.output_dir)): sha(p) for p in sorted(args.output_dir.rglob("*")) if p.is_file()
        },
    }
    (args.output_dir / "manifest.json").write_text(json.dumps(record, indent=2) + "\n")
    print("Verified father-only sprite sheet, protected A/C/NE/NW pixels, native canvases, and four 190ms GIF phases.")


if __name__ == "__main__":
    main()
