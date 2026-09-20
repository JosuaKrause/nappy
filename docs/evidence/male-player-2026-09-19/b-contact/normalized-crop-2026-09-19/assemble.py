"""Register the saved normalized pair and assemble the protected father review loops."""

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
RAW = HERE / "raw/normalized.png"
BASELINE = HERE.parent / "straight-contact-2026-09-19/generated/rig"
LOOPS = HERE.parent / "loops-2026-09-19"
P2 = ROOT / "docs/evidence/comic-pushing-strides-2026-09-12/convert.py"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
SOURCE_VIEWS = ("side", "front_diagonal")
RAW_SHA256 = "626a7bf64aff8ac35f73b0e079f31c256d463c976b95a2e371ceafb6e97f6dc9"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rgba(path):
    return Image.open(path).convert("RGBA")


def module(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def centroid(picture):
    alpha = picture.getchannel("A")
    rows = round(picture.height * 0.57)
    weighted = [
        (x + 0.5, alpha.getpixel((x, y)))
        for y in range(rows)
        for x in range(picture.width)
    ]
    return sum(x * value for x, value in weighted) / sum(value for _, value in weighted)


def input_record():
    paths = [
        Path(__file__),
        HERE / "prepare.py",
        HERE / "prompt.txt",
        RAW,
        LOOPS / "assemble.py",
        P2,
    ]
    paths += sorted((HERE / "inputs").glob("*"))
    paths += sorted(BASELINE.glob("father_*.png"))
    return {
        "pillow": pillow_version,
        "files": {
            str(path.relative_to(ROOT)): digest(path)
            for path in paths
            if path.is_file()
        },
    }


def extract_and_register(view, cell, output):
    alpha = cell.getchannel("A")
    assert alpha.getextrema()[0] == 0, "raw output lacks real transparency"
    bounds = alpha.point(lambda value: 255 if value > 1 else 0).getbbox()
    if bounds is None:
        raise ValueError(f"empty generated panel: {view}")
    figure = cell.crop(bounds)
    fitted_width = round(figure.width * (45 * 12) / figure.height)
    figure = figure.resize((fitted_width, 45 * 12), Image.Resampling.LANCZOS)
    anchor = rgba(BASELINE / f"father_{view}_c.png")
    requested_x = round(centroid(anchor) * 12 - centroid(figure))
    x = min(max(requested_x, 0), 26 * 12 - fitted_width)
    if fitted_width > 26 * 12:
        raise ValueError(f"full-stature figure is too wide: {view}: width={fitted_width}")
    high = Image.new("RGBA", (26 * 12, 46 * 12))
    high.alpha_composite(figure, (x, 12))
    native = high.resize((26, 46), Image.Resampling.LANCZOS)
    assert native.getchannel("A").getbbox()[3] == 46
    cell.save(output / f"father_{view}_b-generated-panel.png")
    high.save(output / f"father_{view}_b-12x.png")
    return native, {
        "raw_cell": list(cell.getbbox()),
        "visible_bounds_in_cell": list(bounds),
        "fit_at_12x": [fitted_width, 45 * 12],
        "x_at_12x": x,
        "requested_x_at_12x": requested_x,
        "canvas_edge_adjustment_x": x - requested_x,
        "y_at_12x": 12,
        "anchor": "top-57-percent opacity centroid of protected C frame",
        "native_alpha_bounds": list(native.getchannel("A").getbbox()),
    }


def verify(output, old, p2):
    for view in VIEWS:
        for pose in ("a", "c", "b"):
            name = f"father_{view}_{pose}.png"
            path = output / "rig" / name
            baseline = BASELINE / name
            assert rgba(path).size == rgba(baseline).size
            if pose != "b" or view not in SOURCE_VIEWS:
                assert path.read_bytes() == baseline.read_bytes(), name
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
    assert digest(RAW) == RAW_SHA256
    current = input_record()
    assert json.loads((HERE / "inputs.json").read_text()) == current, "a frozen input changed"
    output.mkdir(parents=True)
    (output / "rig").mkdir()
    raw = rgba(RAW)
    assert raw.size == (1376, 1143)
    split = raw.width // 2
    panels = {
        "side": raw.crop((0, 0, split, raw.height)),
        "front_diagonal": raw.crop((split, 0, raw.width, raw.height)),
    }
    records = {}
    replacements = {}
    for view, panel in panels.items():
        replacements[view], records[view] = extract_and_register(view, panel, output)
        records[view]["raw_cell"] = [
            0 if view == "side" else split,
            0,
            split if view == "side" else raw.width,
            raw.height,
        ]
    for view in VIEWS:
        for pose in ("a", "c", "b"):
            name = f"father_{view}_{pose}.png"
            destination = output / "rig" / name
            if pose == "b" and view in replacements:
                replacements[view].save(destination)
            else:
                shutil.copy2(BASELINE / name, destination)
    old = module(LOOPS / "assemble.py", "father_loops")
    p2 = module(P2, "p2_recipe")
    old.sheets(output, p2)
    verify(output, old, p2)
    manifest = {
        "status": "uninstalled one-pass generated normalization for player review",
        "raw_sha256": RAW_SHA256,
        "raw_dimensions": list(raw.size),
        "directions": p2.DIRECTIONS,
        "loop": old.LOOP,
        "frame_ms": [190] * 4,
        "protected": "all frames except side/front-diagonal B byte-identical to straight-contact baseline",
        "registration": records,
        "input_manifest_sha256": digest(HERE / "inputs.json"),
        "outputs": {
            str(path.relative_to(output)): digest(path)
            for path in sorted(output.rglob("*"))
            if path.is_file()
        },
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("Verified normalized full figures, protected frames, native canvases, sheets, and GIF timing.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path)
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
