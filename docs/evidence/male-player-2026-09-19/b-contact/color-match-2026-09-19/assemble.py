"""Recolor only the generated B trousers to the father's blue-gray family."""

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
CORRECT = HERE.parent / "correct-contact-2026-09-19/generated/rig"
REFERENCE = HERE.parent / "straight-contact-2026-09-19/generated/rig"
P2 = ROOT / "docs/evidence/comic-pushing-strides-2026-09-12/convert.py"
DELIVERED = HERE.parent / "diagonal-carrying-2026-09-19/generated"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
LOOP = ("a", "c", "b", "c")
PANTS_START_Y = 28
PALETTE_SAMPLES = {
    "candidate_luma_quantiles": {"10%": 41.3, "50%": 79.8, "90%": 111.0},
    "reference_ac_luma_quantiles": {"10%": 61.5, "50%": 90.3, "90%": 118.2},
    "reference_ac_rgb_at_50%": [77, 92, 113],
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rgba(path):
    return Image.open(path).convert("RGBA")


def module(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def recorded_path(path):
    """Keep the default frozen recipe checkout-independent; retain external reuse paths verbatim."""
    try:
        return str(path.resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


def pants_pixel(red, green, blue, alpha, y):
    """Select the saturated blue trouser material below the painted coat hem."""
    return alpha and y >= PANTS_START_Y and blue >= green + 11 and blue >= red + 18


def blue_gray(red, green, blue):
    """Map generated luminance into the sampled A/C blue-gray value and channel ratios."""
    source_luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue
    reference_luma = max(0, min(255, round(0.86 * source_luma + 27)))
    return (
        min(255, round(0.86 * reference_luma)),
        min(255, round(1.02 * reference_luma)),
        min(255, round(1.25 * reference_luma)),
    )


def recolor(source):
    result = source.copy()
    mask = Image.new("L", source.size)
    changed = 0
    for y in range(source.height):
        for x in range(source.width):
            red, green, blue, alpha = source.getpixel((x, y))
            if not pants_pixel(red, green, blue, alpha, y):
                continue
            result.putpixel((x, y), (*blue_gray(red, green, blue), alpha))
            mask.putpixel((x, y), 255)
            changed += 1
    assert source.getchannel("A").tobytes() == result.getchannel("A").tobytes()
    for old, new, selected in zip(
        source.get_flattened_data(), result.get_flattened_data(), mask.get_flattened_data(), strict=True
    ):
        assert selected or old == new
    assert changed, "trouser selector matched no pixels"
    return result, mask, changed


def sheets(output, prefix, state, p2):
    def sprite(view, pose, mirror):
        picture = rgba(output / "rig" / f"{prefix}_{view}_{pose}.png")
        return ImageOps.mirror(picture) if mirror else picture

    sheet = Image.new("RGBA", (54 * 8, 61 * 4), p2.BACKGROUND)
    for row, pose in enumerate(LOOP):
        for column, (_label, view, mirror, _angle) in enumerate(p2.DIRECTIONS):
            p2._place(sheet, sprite(view, pose, mirror), column * 54 + 27, row * 61 + 59)
    sheet.save(output / f"{state}-spritesheet-native.png")
    sheet.resize((sheet.width * 6, sheet.height * 6), Image.Resampling.NEAREST).save(
        output / f"{state}-spritesheet-6x.png"
    )
    for factor, name in ((1, "native"), (6, "6x")):
        frames = []
        for pose in LOOP:
            frame = Image.new("RGBA", (54 * 4 * factor, 62 * 2 * factor), p2.BACKGROUND)
            for index, (_label, view, mirror, _angle) in enumerate(p2.DIRECTIONS):
                picture = sprite(view, pose, mirror).resize(
                    (26 * factor if view not in ("front", "back") else 24 * factor, 46 * factor),
                    Image.Resampling.NEAREST,
                )
                p2._place(frame, picture, (index % 4 * 54 + 27) * factor, (index // 4 * 62 + 60) * factor)
            frames.append(frame)
        frames[0].save(output / f"{state}-animation-{name}.gif", save_all=True,
                       append_images=frames[1:], duration=[190] * 4, loop=0, disposal=2)
        p2._verify_animation(output / f"{state}-animation-{name}.gif")


def freeze_inputs():
    destination = HERE / "inputs"
    if destination.exists():
        raise FileExistsError(f"freeze destination already exists: {destination}")
    destination.mkdir()
    for name, source in (("candidate-rig", CORRECT), ("reference-rig", REFERENCE)):
        shutil.copytree(source, destination / name)
    manifest = {
        "pillow": pillow_version,
        "candidate_source": str(CORRECT.relative_to(ROOT)),
        "reference_source": str(REFERENCE.relative_to(ROOT)),
        "files": {str(path.relative_to(ROOT)): digest(path) for path in sorted(destination.rglob("*.png"))},
    }
    (destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Froze {len(manifest['files'])} PNG inputs.")


def freeze_delivered_inputs():
    for state in ("pushing", "carrying"):
        destination = HERE / "inputs" / f"final-{state}-rig"
        source = DELIVERED / state / "rig"
        if destination.exists():
            raise FileExistsError(f"freeze destination already exists: {destination}")
        assert source.is_dir(), source
        shutil.copytree(source, destination)
    manifest = {
        "source": str(DELIVERED.relative_to(ROOT)),
        "files": {str(path.relative_to(ROOT)): digest(path)
                  for path in sorted((HERE / "inputs").glob("final-*-rig/*.png"))},
    }
    (HERE / "inputs/final-delivery-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Froze {len(manifest['files'])} delivered PNG inputs.")


def verify(output, candidate, records, prefix, state, p2):
    for view in VIEWS:
        for pose in ("a", "b", "c"):
            name = f"{prefix}_{view}_{pose}.png"
            before = rgba(candidate / name)
            after = rgba(output / "rig" / name)
            assert before.size == after.size
            assert before.getchannel("A").tobytes() == after.getchannel("A").tobytes(), name
            if pose != "b" or view not in records:
                assert before.tobytes() == after.tobytes(), name
    native = rgba(output / f"{state}-spritesheet-native.png")
    assert rgba(output / f"{state}-spritesheet-6x.png").tobytes() == native.resize(
        (native.width * 6, native.height * 6), Image.Resampling.NEAREST
    ).tobytes()
    for name in ("native", "6x"):
        p2._verify_animation(output / f"{state}-animation-{name}.gif")


def assemble(output, candidate, reference, prefix, state, recolor_views):
    if output.exists():
        raise FileExistsError(f"output must be fresh: {output}")
    assert candidate.is_dir() and reference.is_dir()
    output.mkdir(parents=True)
    (output / "rig").mkdir()
    (output / "masks").mkdir()
    records = {}
    for view in VIEWS:
        for pose in ("a", "b", "c"):
            name = f"{prefix}_{view}_{pose}.png"
            source = candidate / name
            target = output / "rig" / name
            if pose != "b" or view not in recolor_views:
                shutil.copy2(source, target)
                continue
            picture, mask, changed = recolor(rgba(source))
            picture.save(target)
            mask.save(output / "masks" / f"{source.stem}-pants-mask.png")
            records[view] = {
                "candidate": recorded_path(source),
                "reference_frames": [
                    recorded_path(reference / f"{prefix}_{view}_{phase}.png") for phase in ("a", "c")
                ],
                "sample_bounds": [0, PANTS_START_Y, picture.width, picture.height],
                "selector": "alpha > 0; y >= 28; blue >= green + 11; blue >= red + 18",
                "palette_samples": PALETTE_SAMPLES,
                "transform": "reference_luma = round(0.86 * source_luma + 27); RGB = reference_luma * (0.86, 1.02, 1.25)",
                "changed_pixels": changed,
                "alpha_preserved": True,
                "outside_mask_preserved": True,
            }
    p2 = module(P2, "p2_recipe")
    sheets(output, prefix, state, p2)
    verify(output, candidate, records, prefix, state, p2)
    manifest = {
        "status": "uninstalled deterministic B-trouser color match for player review",
        "candidate_rig": recorded_path(candidate),
        "reference_rig": recorded_path(reference),
        "pillow": pillow_version,
        "input_sha256": {recorded_path(candidate / f"{prefix}_{view}_{pose}.png"): digest(candidate / f"{prefix}_{view}_{pose}.png")
                         for view in VIEWS for pose in ("a", "b", "c")},
        "method": "native-pixel RGB matrix applied only to the material selector below the coat hem",
        "records": records,
        "outputs": {str(path.relative_to(output)): digest(path) for path in sorted(output.rglob("*")) if path.is_file()},
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("Verified alpha equality, unchanged pixels outside both trouser masks, sheets, and GIF timing.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--freeze-inputs", action="store_true", help="copy the current candidate and A/C references once")
    parser.add_argument("--freeze-delivered-inputs", action="store_true",
                        help="copy the delivered pushing and carrying rigs once")
    parser.add_argument("--output-dir", type=Path, help="fresh destination for recolored review artifacts")
    parser.add_argument("--candidate-rig", type=Path, default=HERE / "inputs/candidate-rig",
                        help="rig containing the B frames to recolor")
    parser.add_argument("--reference-rig", type=Path, default=HERE / "inputs/reference-rig",
                        help="existing A/C rig that defines the blue-gray family")
    parser.add_argument("--sprite-prefix", default="father", help="filename prefix before _view_pose.png")
    parser.add_argument("--state", default="father", help="sheet and GIF filename prefix")
    parser.add_argument("--recolor-views", nargs="+", default=("side", "front_diagonal"), choices=VIEWS,
                        help="B views whose trousers receive the color transform")
    args = parser.parse_args()
    if args.freeze_inputs or args.freeze_delivered_inputs:
        if args.output_dir is not None:
            parser.error("freeze options do not take --output-dir")
        if args.freeze_inputs and args.freeze_delivered_inputs:
            parser.error("choose one freeze option")
        if args.freeze_inputs:
            freeze_inputs()
        else:
            freeze_delivered_inputs()
        return
    if args.output_dir is None:
        parser.error("--output-dir is required unless freezing inputs")
    assemble(args.output_dir, args.candidate_rig, args.reference_rig, args.sprite_prefix,
             args.state, tuple(args.recolor_views))


if __name__ == "__main__":
    main()
