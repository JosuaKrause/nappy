"""Assemble the preserved pre-final father-carrying review into the pushing review format."""

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path

from PIL import Image, ImageOps
from PIL import __version__ as pillow_version

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
HISTORICAL_RIG = ROOT / "docs/evidence/male-player-2026-09-19/registered/rig"
P2_RECIPE = ROOT / "docs/evidence/comic-pushing-strides-2026-09-12/convert.py"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
LOOP = ("a", "c", "b", "c")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rgba(path):
    return Image.open(path).convert("RGBA")


def p2_recipe():
    spec = importlib.util.spec_from_file_location("p2_recipe", P2_RECIPE)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def source(view, pose, mirror=False):
    picture = rgba(HISTORICAL_RIG / f"father_carrying_{view}_{pose}.png")
    return ImageOps.mirror(picture) if mirror else picture


def input_record():
    paths = [Path(__file__), P2_RECIPE]
    paths += [
        HISTORICAL_RIG / f"father_carrying_{view}_{pose}.png"
        for view in VIEWS
        for pose in ("a", "c", "b")
    ]
    return {
        "pillow": pillow_version,
        "files": {str(path.relative_to(ROOT)): digest(path) for path in paths},
    }


def sheets(output, p2):
    sheet = Image.new("RGBA", (54 * 8, 61 * 4), p2.BACKGROUND)
    for row, pose in enumerate(LOOP):
        for column, (_label, view, mirror, _angle) in enumerate(p2.DIRECTIONS):
            p2._place(sheet, source(view, pose, mirror), column * 54 + 27, row * 61 + 59)
    sheet.save(output / "carrying-spritesheet-native.png")
    sheet.resize((sheet.width * 6, sheet.height * 6), Image.Resampling.NEAREST).save(
        output / "carrying-spritesheet-6x.png"
    )

    for factor, name in ((1, "native"), (6, "6x")):
        frames = []
        for pose in LOOP:
            frame = Image.new("RGBA", (54 * 4 * factor, 62 * 2 * factor), p2.BACKGROUND)
            for index, (_label, view, mirror, _angle) in enumerate(p2.DIRECTIONS):
                picture = source(view, pose, mirror)
                picture = picture.resize(
                    (picture.width * factor, picture.height * factor),
                    Image.Resampling.NEAREST,
                )
                p2._place(
                    frame,
                    picture,
                    (index % 4 * 54 + 27) * factor,
                    (index // 4 * 62 + 60) * factor,
                )
            frames.append(frame)
        frames[0].save(
            output / f"carrying-{name}.gif",
            save_all=True,
            append_images=frames[1:],
            duration=[190, 190, 190, 190],
            loop=0,
            disposal=2,
        )
        p2._verify_animation(output / f"carrying-{name}.gif")


def verify(output, p2, frozen):
    assert frozen == input_record(), "a preserved carrying input or recipe changed"
    for view in VIEWS:
        for pose in ("a", "c", "b"):
            path = HISTORICAL_RIG / f"father_carrying_{view}_{pose}.png"
            picture = rgba(path)
            expected = (24, 46) if view in ("front", "back") else (26, 46)
            assert picture.size == expected
            assert picture.mode == "RGBA"
            assert digest(path) == frozen["files"][str(path.relative_to(ROOT))]
    native = rgba(output / "carrying-spritesheet-native.png")
    enlarged = rgba(output / "carrying-spritesheet-6x.png")
    assert enlarged.tobytes() == native.resize(
        (native.width * 6, native.height * 6), Image.Resampling.NEAREST
    ).tobytes()
    for name in ("native", "6x"):
        p2._verify_animation(output / f"carrying-{name}.gif")


def assemble(output):
    if output.exists():
        raise FileExistsError(f"output must be fresh: {output}")
    frozen = json.loads((HERE / "carrying-inputs.json").read_text())
    p2 = p2_recipe()
    output.mkdir(parents=True)
    sheets(output, p2)
    verify(output, p2, frozen)
    record = {
        "status": "review of preserved pre-final father carrying PNGs; no art changes",
        "directions": p2.DIRECTIONS,
        "loop": LOOP,
        "frame_ms": [190] * 4,
        "input_manifest_sha256": digest(HERE / "carrying-inputs.json"),
        "outputs": {
            path.name: digest(path)
            for path in sorted(output.iterdir())
            if path.is_file()
        },
    }
    (output / "manifest.json").write_text(json.dumps(record, indent=2) + "\n")
    print("Verified preserved carrying inputs, eight directions, static sheets, and 190ms GIFs.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--freeze-inputs", action="store_true")
    args = parser.parse_args()
    if args.freeze_inputs:
        if (HERE / "carrying-inputs.json").exists():
            parser.error("carrying input manifest already exists")
        (HERE / "carrying-inputs.json").write_text(json.dumps(input_record(), indent=2) + "\n")
        return
    if args.output_dir is None:
        parser.error("--output-dir is required")
    assemble(args.output_dir)


if __name__ == "__main__":
    main()
