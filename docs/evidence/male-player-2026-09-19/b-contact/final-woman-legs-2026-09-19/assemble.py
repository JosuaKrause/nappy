"""Assemble a father B-contact preview from the final P2 mother's literal legs."""

import argparse
import hashlib
import importlib.util
import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw
from PIL import __version__ as pillow_version

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
BASELINE = HERE.parent / "straight-contact-2026-09-19/generated/rig"
LOOPS = HERE.parent / "loops-2026-09-19"
P2 = ROOT / "docs/evidence/comic-pushing-strides-2026-09-12"
P2_CONVERT = P2 / "convert.py"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
FACTOR = 12
GROUND_Y = 46 * FACTOR
PROTECTED_ROWS = 31
SOURCE = {
    "side": {
        "path": P2 / "registered/p2-acb-pass4-side-ne-extracted.png",
        "whole_figure": (748, 623, 904, 911),
        "lower_crop": (748, 798, 904, 911),
        "visible_pants_y": 192,
        "placement_x": 0,
    },
    "front_diagonal": {
        "path": P2 / "registered/p2-acb-pass2-extracted.png",
        "whole_figure": (1088, 625, 1203, 916),
        "lower_crop": (1088, 800, 1203, 916),
        "visible_pants_y": 192,
        "placement_x": 48,
    },
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


def donor(view):
    record = SOURCE[view]
    atlas = rgba(record["path"])
    crop = atlas.crop(record["lower_crop"])
    whole_top = record["whole_figure"][1]
    crop_top = record["lower_crop"][1]
    visible_y = record["visible_pants_y"] - (crop_top - whole_top)
    alpha = crop.getchannel("A")
    alpha.paste(0, (0, 0, crop.width, visible_y))
    crop.putalpha(alpha)
    target_height = (46 - 28) * FACTOR
    width = round(crop.width * target_height / crop.height)
    fitted = crop.resize((width, target_height), Image.Resampling.LANCZOS)
    high = Image.new("RGBA", (26 * FACTOR, 46 * FACTOR))
    x = record["placement_x"]
    y = GROUND_Y - target_height
    assert x >= 0 and x + width <= high.width
    high.alpha_composite(fitted, (x, y))
    return high.resize((26, 46), Image.Resampling.LANCZOS), {
        "source": str(record["path"].relative_to(ROOT)),
        "source_sha256": digest(record["path"]),
        "whole_figure_bounds": list(record["whole_figure"]),
        "lower_crop": list(record["lower_crop"]),
        "visible_pants_y_in_whole_figure": record["visible_pants_y"],
        "fit_at_12x": [width, target_height],
        "placement_at_12x": [x, y],
        "operation": "literal RGBA crop; hide pixels above visible pants; uniform Lanczos fit",
    }


def splice(view):
    father = rgba(BASELINE / f"father_{view}_b.png")
    result, record = donor(view)
    result.paste(father.crop((0, 0, 26, PROTECTED_ROWS)), (0, 0))
    assert result.crop((0, 0, 26, PROTECTED_ROWS)).tobytes() == father.crop(
        (0, 0, 26, PROTECTED_ROWS)
    ).tobytes()
    assert result.getchannel("A").getbbox()[3] == 46
    record["protected_father_rows"] = [0, PROTECTED_ROWS - 1]
    record["alpha_bounds"] = list(result.getchannel("A").getbbox())
    return result, record


def donor_sheet(output):
    sheet = Image.new("RGBA", (720, 430), (89, 105, 112, 255))
    draw = ImageDraw.Draw(sheet)
    draw.text((12, 10), "FINAL P2 mother B donors — exact high-resolution crops", fill="white")
    for index, view in enumerate(("side", "front_diagonal")):
        record = SOURCE[view]
        atlas = rgba(record["path"])
        figure = atlas.crop(record["whole_figure"])
        figure.thumbnail((300, 350), Image.Resampling.LANCZOS)
        x = 25 + index * 350
        sheet.alpha_composite(figure, (x + (300 - figure.width) // 2, 48))
        label = "E / W · side B" if view == "side" else "SE / SW · front-diagonal B"
        draw.text((x, 402), label, fill="white")
    sheet.save(output / "final-mother-b-donors.png")


def input_record():
    paths = [Path(__file__), P2_CONVERT, LOOPS / "assemble.py"]
    paths += sorted(BASELINE.glob("father_*.png"))
    paths += [SOURCE[view]["path"] for view in SOURCE]
    paths += [P2 / "registered/p2-selected-generation.png", P2 / "registered/registration.json"]
    return {
        "pillow": pillow_version,
        "files": {str(path.relative_to(ROOT)): digest(path) for path in paths},
    }


def verify(output, old, p2):
    for view in VIEWS:
        for pose in ("a", "c", "b"):
            name = f"father_{view}_{pose}.png"
            path = output / "rig" / name
            baseline = BASELINE / name
            assert rgba(path).size == rgba(baseline).size
            if pose != "b" or view not in SOURCE:
                assert path.read_bytes() == baseline.read_bytes(), name
            else:
                assert rgba(path).crop((0, 0, 26, PROTECTED_ROWS)).tobytes() == rgba(
                    baseline
                ).crop((0, 0, 26, PROTECTED_ROWS)).tobytes()
    native = rgba(output / "father-spritesheet-native.png")
    enlarged = rgba(output / "father-spritesheet-6x.png")
    assert enlarged.tobytes() == native.resize(
        (native.width * 6, native.height * 6), Image.Resampling.NEAREST
    ).tobytes()
    for name in ("native", "6x"):
        p2._verify_animation(output / f"father-animation-{name}.gif")


def assemble(output):
    if output.exists():
        raise FileExistsError(f"output must be fresh: {output}")
    current = input_record()
    assert json.loads((HERE / "inputs.json").read_text()) == current, "a frozen input changed"
    output.mkdir(parents=True)
    (output / "rig").mkdir()
    records = {}
    for view in VIEWS:
        for pose in ("a", "c", "b"):
            name = f"father_{view}_{pose}.png"
            destination = output / "rig" / name
            if pose == "b" and view in SOURCE:
                picture, records[view] = splice(view)
                picture.save(destination)
            else:
                shutil.copy2(BASELINE / name, destination)
    old = module(LOOPS / "assemble.py", "father_loops")
    p2 = module(P2_CONVERT, "p2_recipe")
    old.sheets(output, p2)
    donor_sheet(output)
    verify(output, old, p2)
    manifest = {
        "status": "uninstalled one-pass player-review preview; no runtime art changed",
        "directions": p2.DIRECTIONS,
        "loop": old.LOOP,
        "frame_ms": [190] * 4,
        "protected": "all frames except side/front-diagonal B byte-identical; changed B rows 0..30 exact",
        "registration": records,
        "input_manifest_sha256": digest(HERE / "inputs.json"),
        "outputs": {
            str(path.relative_to(output)): digest(path)
            for path in sorted(output.rglob("*"))
            if path.is_file()
        },
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("Verified final P2 donors, exact father uppers, protected frames, sheets, and GIF timing.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, help="fresh output directory")
    parser.add_argument("--freeze-inputs", action="store_true")
    args = parser.parse_args()
    if args.freeze_inputs:
        if (HERE / "inputs.json").exists():
            parser.error("input manifest already exists")
        (HERE / "inputs.json").write_text(json.dumps(input_record(), indent=2) + "\n")
        return
    if args.output_dir is None:
        parser.error("--output-dir is required")
    assemble(args.output_dir)


if __name__ == "__main__":
    main()
