"""Assemble the father-only straight-contact trial from frozen inputs."""
import argparse
import hashlib
import importlib.util
import json
import shutil
from pathlib import Path

from PIL import Image
from PIL import __version__ as pillow_version

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
PREVIOUS = HERE.parent / "loops-2026-09-19"
P2 = ROOT / "docs/evidence/comic-pushing-strides-2026-09-12/convert.py"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
FACTOR = 12
CUT_Y = 28
CROP = (190, 100, 1290, 1077)
PLACEMENT = (0, 336)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def module(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def rgba(path):
    return Image.open(path).convert("RGBA")


def input_record():
    paths = [Path(__file__), HERE / "side-donor-raw.png", PREVIOUS / "assemble.py", P2]
    paths += sorted((PREVIOUS / "generated/rig").glob("father_*.png"))
    paths += sorted(HERE.glob("prompt-*.txt"))
    paths += [
        HERE.parent / "inputs/father_side_b.svg",
        HERE.parent / "inputs/father_front_diagonal_b.svg",
        HERE.parent / "inputs/father_side_b-8x.png",
        HERE.parent / "inputs/father_front_diagonal_b-8x.png",
        HERE.parent / "proof/side-identity-upper.png",
        HERE.parent / "proof/front_diagonal-identity-upper.png",
        ROOT / "docs/style-references/graphics-reference-urban-01.jpeg",
        ROOT / "docs/style-references/graphics-reference-cardinal.jpeg",
    ]
    return {"pillow": pillow_version, "files": {
        str(p.relative_to(ROOT)): digest(p) for p in paths
    }}


def splice(source, diagonal):
    donor = rgba(HERE / "side-donor-raw.png").crop(CROP)
    height = (46 - CUT_Y) * FACTOR
    width = round(donor.width * height / donor.height)
    lower = donor.resize((width, height), Image.Resampling.LANCZOS)
    high = Image.new("RGBA", (26 * FACTOR, 46 * FACTOR))
    x, y = PLACEMENT
    assert x >= 0 and x + width <= high.width
    high.alpha_composite(lower, (x, y))
    transform = None
    if diagonal:
        slope = 3 * FACTOR / (width - 1)
        right = x + width - 1
        transform = (1, 0, 0, -slope, 1, slope * right)
        high = high.transform(
            high.size, Image.Transform.AFFINE, transform, Image.Resampling.BICUBIC
        )
    result = high.resize((26, 46), Image.Resampling.LANCZOS)
    result.paste(source.crop((0, 0, 26, CUT_Y)), (0, 0))
    assert result.crop((0, 0, 26, CUT_Y)).tobytes() == source.crop((0, 0, 26, CUT_Y)).tobytes()
    return result, {
        "crop": CROP, "fit_at_12x": [width, height], "placement_at_12x": PLACEMENT,
        "inverse_affine_at_12x": transform,
        "alpha_bounds": result.getchannel("A").getbbox(),
        "composition": "new lower pair first; exact accepted A rows 0..27 last",
    }


def verify(output, old, p2):
    for view in VIEWS:
        for pose in ("a", "c", "b"):
            name = f"father_{view}_{pose}.png"
            original = PREVIOUS / "generated/rig" / name
            path = output / "rig" / name
            picture = rgba(path)
            assert picture.size == rgba(original).size
            if pose != "b" or view not in ("side", "front_diagonal"):
                assert path.read_bytes() == original.read_bytes(), name
            else:
                upper = rgba(PREVIOUS / "generated/rig" / f"father_{view}_a.png")
                assert picture.crop((0, 0, 26, CUT_Y)).tobytes() == upper.crop((0, 0, 26, CUT_Y)).tobytes()
                assert picture.getchannel("A").getbbox()[3] == 46
    sheet = rgba(output / "father-spritesheet-native.png")
    for row, pose in enumerate(old.LOOP):
        for column, (_, view, mirror, _) in enumerate(p2.DIRECTIONS):
            expected = old.sprite(output, view, pose, mirror)
            x, y = column * 54 + 27 - expected.width // 2, row * 61 + 59 - 46
            expected = Image.alpha_composite(Image.new("RGBA", expected.size, p2.BACKGROUND), expected)
            assert sheet.crop((x, y, x + expected.width, y + 46)).tobytes() == expected.tobytes()
    assert rgba(output / "father-spritesheet-6x.png").tobytes() == sheet.resize(
        (sheet.width * 6, sheet.height * 6), Image.Resampling.NEAREST
    ).tobytes()
    for name in ("native", "6x"):
        p2._verify_animation(output / f"father-animation-{name}.gif")


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, epilog="Example: %(prog)s --output-dir /tmp/father-straight-review"
    )
    parser.add_argument("--output-dir", type=Path, required=True, help="fresh output directory")
    parser.add_argument("--freeze-inputs", action="store_true", help="create absent input manifest")
    args = parser.parse_args()
    if args.output_dir.exists():
        parser.error("output directory must be fresh")
    current = input_record()
    manifest = HERE / "inputs.json"
    if args.freeze_inputs:
        if manifest.exists():
            parser.error("input manifest already exists")
        manifest.write_text(json.dumps(current, indent=2) + "\n")
    assert json.loads(manifest.read_text()) == current, "frozen input changed"
    args.output_dir.mkdir(parents=True)
    (args.output_dir / "rig").mkdir()
    records = {}
    for view in VIEWS:
        for pose in ("a", "c", "b"):
            name = f"father_{view}_{pose}.png"
            target = args.output_dir / "rig" / name
            if pose != "b" or view not in ("side", "front_diagonal"):
                shutil.copy2(PREVIOUS / "generated/rig" / name, target)
            else:
                source = rgba(PREVIOUS / "generated/rig" / f"father_{view}_a.png")
                picture, records[view] = splice(source, view == "front_diagonal")
                picture.save(target)
    old = module(PREVIOUS / "assemble.py", "old_father")
    p2 = module(P2, "p2_recipe")
    old.sheets(args.output_dir, p2)
    verify(args.output_dir, old, p2)
    record = {
        "status": "uninstalled player-review trial; static poses and offline animation only",
        "directions": p2.DIRECTIONS, "loop": old.LOOP, "frame_ms": [190] * 4,
        "registration": records, "input_manifest_sha256": digest(manifest),
        "protected": "all prior A/C plus front/back/back-diagonal B byte-identical",
        "outputs": {str(p.relative_to(args.output_dir)): digest(p)
                    for p in sorted(args.output_dir.rglob("*")) if p.is_file()},
    }
    (args.output_dir / "manifest.json").write_text(json.dumps(record, indent=2) + "\n")
    print("Verified protected frames, unchanged upper pixels, canvases, sheet mirrors, four GIF phases.")


if __name__ == "__main__":
    main()
