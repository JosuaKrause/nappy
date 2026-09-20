"""Prepare and reproduce the woman's-leg father B-contact review trial."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image, ImageOps
from PIL import __version__ as pillow_version

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
BASELINE = HERE.parent / "straight-contact-2026-09-19/generated/rig"
RIG = ROOT / "assets/illustrated/svg-transfer/rig"
RAW = HERE / "woman-leg-composite-raw.png"
EDIT_TARGET = HERE / "edit-target.png"
INPUTS = HERE / "inputs.json"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
DIRECTIONS = (
    ("N", "back", False),
    ("NE", "back_diagonal", False),
    ("E", "side", False),
    ("SE", "front_diagonal", False),
    ("S", "front", False),
    ("SW", "front_diagonal", True),
    ("W", "side", True),
    ("NW", "back_diagonal", True),
)
LOOP = ("a", "c", "b", "c")
BACKGROUND = (89, 105, 112, 255)
CUT_Y = 28
DONOR_LOCK_Y = 34
TARGET_SIZE = (1024, 1024)
TARGET_SCALE = 12
TARGET_POSITIONS = {"side": (96, 236), "front_diagonal": (616, 236)}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def _blue_hem(pixel: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    red, green, blue, alpha = pixel
    if alpha and red > 110 and green < 125 and red - green > 40 and red - blue > 45:
        light = (red + green + blue) // 3
        if light < 78:
            return (52, 83, 110, alpha)
        if light < 103:
            return (60, 97, 126, alpha)
        return (70, 111, 140, alpha)
    return pixel


def direct_composite(view: str) -> Image.Image:
    """Keep the mother's accepted B lower figure and the father's exact upper 28 rows."""
    donor = rgba(RIG / f"mother_{view}_b.png")
    father = rgba(BASELINE / f"father_{view}_b.png")
    assert donor.size == father.size == (26, 46)
    pixels = donor.load()
    for y in range(CUT_Y, donor.height):
        for x in range(donor.width):
            pixels[x, y] = _blue_hem(pixels[x, y])
    donor.paste(father.crop((0, 0, 26, CUT_Y)), (0, 0))
    assert donor.crop((0, 0, 26, CUT_Y)).tobytes() == father.crop((0, 0, 26, CUT_Y)).tobytes()
    return donor


def prepare(path: Path) -> None:
    if path.exists():
        raise FileExistsError(f"output must be fresh: {path}")
    target = Image.new("RGBA", TARGET_SIZE)
    for view, position in TARGET_POSITIONS.items():
        picture = direct_composite(view).resize(
            (26 * TARGET_SCALE, 46 * TARGET_SCALE), Image.Resampling.NEAREST
        )
        target.alpha_composite(picture, position)
    target.save(path)
    assert target.size == TARGET_SIZE and target.getchannel("A").getbbox()


def _registered_raw_halves() -> tuple[dict[str, Image.Image], dict[str, object]]:
    source = rgba(RAW)
    if source.getchannel("A").getextrema()[0] != 0:
        raise AssertionError("generated edit has no transparent background")
    registered: dict[str, Image.Image] = {}
    records: dict[str, object] = {}
    for index, view in enumerate(("side", "front_diagonal")):
        left = round(index * source.width / 2)
        right = round((index + 1) * source.width / 2)
        half = source.crop((left, 0, right, source.height))
        # Ignore the generator's nearly transparent full-canvas fringe while retaining the
        # original alpha bytes inside the actual figure crop.
        bounds = half.getchannel("A").point(lambda value: 255 if value >= 8 else 0).getbbox()
        assert bounds, view
        crop = half.crop(bounds)
        target_height = 45
        target_width = max(1, round(crop.width * target_height / crop.height))
        assert target_width <= 26, (view, crop.size, target_width)
        fitted = crop.resize((target_width, target_height), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (26, 46))
        x = 13 - target_width // 2
        canvas.alpha_composite(fitted, (x, 1))
        registered[view] = canvas
        records[view] = {
            "raw_half": [left, 0, right, source.height],
            "alpha_crop_within_half": list(bounds),
            "fit": [target_width, target_height],
            "placement": [x, 1],
        }
    return registered, records


def final_frame(view: str, generated: Image.Image) -> Image.Image:
    father = rgba(BASELINE / f"father_{view}_b.png")
    mother = rgba(RIG / f"mother_{view}_b.png")
    direct = direct_composite(view)
    result = direct.copy()
    # The one generated edit owns only the narrow join. The accepted mother donor owns the
    # lower legs and shoes; the accepted father owns every pixel above the join.
    result.paste(generated.crop((0, CUT_Y, 26, DONOR_LOCK_Y)), (0, CUT_Y))
    result.paste(mother.crop((0, DONOR_LOCK_Y, 26, 46)), (0, DONOR_LOCK_Y))
    result.paste(father.crop((0, 0, 26, CUT_Y)), (0, 0))
    assert result.crop((0, 0, 26, CUT_Y)).tobytes() == father.crop((0, 0, 26, CUT_Y)).tobytes()
    assert result.crop((0, DONOR_LOCK_Y, 26, 46)).tobytes() == mother.crop(
        (0, DONOR_LOCK_Y, 26, 46)
    ).tobytes()
    return result


def sprite(output: Path, view: str, pose: str, mirror: bool = False) -> Image.Image:
    picture = rgba(output / "rig" / f"father_{view}_{pose}.png")
    return ImageOps.mirror(picture) if mirror else picture


def place(canvas: Image.Image, picture: Image.Image, center_x: int, bottom_y: int) -> None:
    canvas.alpha_composite(picture, (center_x - picture.width // 2, bottom_y - picture.height))


def verify_animation(path: Path) -> None:
    animation = Image.open(path)
    assert animation.n_frames == 4
    decoded: list[bytes] = []
    durations: list[int] = []
    for frame in range(4):
        animation.seek(frame)
        durations.append(int(animation.info["duration"]))
        decoded.append(animation.convert("RGBA").tobytes())
    assert durations == [190, 190, 190, 190]
    assert decoded[0] != decoded[1] and decoded[1] != decoded[2] and decoded[0] != decoded[2]
    assert decoded[1] == decoded[3]


def sheets(output: Path) -> None:
    sheet = Image.new("RGBA", (54 * 8, 61 * 4), BACKGROUND)
    for row, pose in enumerate(LOOP):
        for column, (_label, view, mirror) in enumerate(DIRECTIONS):
            place(sheet, sprite(output, view, pose, mirror), column * 54 + 27, row * 61 + 59)
    sheet.save(output / "father-spritesheet-native.png")
    sheet.resize((sheet.width * 6, sheet.height * 6), Image.Resampling.NEAREST).save(
        output / "father-spritesheet-6x.png"
    )
    for factor, name in ((1, "native"), (6, "6x")):
        frames: list[Image.Image] = []
        for pose in LOOP:
            frame = Image.new("RGBA", (54 * 4 * factor, 62 * 2 * factor), BACKGROUND)
            for index, (_label, view, mirror) in enumerate(DIRECTIONS):
                picture = sprite(output, view, pose, mirror).resize(
                    (sprite(output, view, pose, mirror).width * factor, 46 * factor),
                    Image.Resampling.NEAREST,
                )
                place(
                    frame,
                    picture,
                    (index % 4 * 54 + 27) * factor,
                    (index // 4 * 62 + 60) * factor,
                )
            frames.append(frame)
        frames[0].save(
            output / f"father-animation-{name}.gif",
            save_all=True,
            append_images=frames[1:],
            duration=[190] * 4,
            loop=0,
            disposal=2,
        )
        verify_animation(output / f"father-animation-{name}.gif")


def input_record() -> dict[str, object]:
    paths = [Path(__file__), HERE / "prompt.txt", EDIT_TARGET, RAW]
    paths.extend(sorted(BASELINE.glob("father_*.png")))
    for view in ("side", "front_diagonal"):
        for pose in ("a", "b", "c"):
            paths.append(RIG / f"mother_{view}_{pose}.png")
        paths.append(ROOT / f"docs/graphics-creation/player/mother_{view}_b.svg")
        paths.append(HERE.parent / f"inputs/father_{view}_b.svg")
    paths.extend(
        [
            ROOT / "docs/evidence/graphics-reference-urban-01.jpeg",
            ROOT / "docs/evidence/graphics-reference-cardinal.jpeg",
        ]
    )
    assert all(path.is_file() for path in paths)
    return {
        "pillow": pillow_version,
        "files": {str(path.relative_to(ROOT)): digest(path) for path in paths},
    }


def assemble(output: Path, freeze_inputs: bool) -> None:
    if output.exists():
        raise FileExistsError(f"output must be fresh: {output}")
    current = input_record()
    if freeze_inputs:
        if INPUTS.exists():
            raise FileExistsError(f"input manifest already exists: {INPUTS}")
        INPUTS.write_text(json.dumps(current, indent=2) + "\n")
    assert json.loads(INPUTS.read_text()) == current, "a frozen input changed"
    generated, registration = _registered_raw_halves()
    output.mkdir(parents=True)
    (output / "rig").mkdir()
    for view in VIEWS:
        for pose in ("a", "c", "b"):
            name = f"father_{view}_{pose}.png"
            destination = output / "rig" / name
            if pose == "b" and view in generated:
                final_frame(view, generated[view]).save(destination)
            else:
                shutil.copy2(BASELINE / name, destination)
    sheets(output)
    for view in VIEWS:
        for pose in ("a", "c", "b"):
            name = f"father_{view}_{pose}.png"
            path = output / "rig" / name
            original = BASELINE / name
            assert rgba(path).size == rgba(original).size
            if pose != "b" or view not in generated:
                assert path.read_bytes() == original.read_bytes(), name
            else:
                father = rgba(original)
                picture = rgba(path)
                assert picture.crop((0, 0, 26, CUT_Y)).tobytes() == father.crop(
                    (0, 0, 26, CUT_Y)
                ).tobytes()
                mother = rgba(RIG / f"mother_{view}_b.png")
                assert picture.crop((0, DONOR_LOCK_Y, 26, 46)).tobytes() == mother.crop(
                    (0, DONOR_LOCK_Y, 26, 46)
                ).tobytes()
                assert picture.getchannel("A").getbbox()[3] == 46
    sheet = rgba(output / "father-spritesheet-native.png")
    assert rgba(output / "father-spritesheet-6x.png").tobytes() == sheet.resize(
        (sheet.width * 6, sheet.height * 6), Image.Resampling.NEAREST
    ).tobytes()
    record = {
        "status": "uninstalled one-pass player-review trial; no runtime art changed",
        "directions": DIRECTIONS,
        "loop": LOOP,
        "frame_ms": [190] * 4,
        "protected": "all A/C and N/S/NE/NW B byte-identical; changed B rows 0..27 exact",
        "donor_lock": "mother B rows 34..45 byte-identical to the accepted native PNG",
        "generated_join_rows": [CUT_Y, DONOR_LOCK_Y - 1],
        "registration": registration,
        "input_manifest_sha256": digest(INPUTS),
        "outputs": {
            str(path.relative_to(output)): digest(path)
            for path in sorted(output.rglob("*"))
            if path.is_file()
        },
    }
    (output / "manifest.json").write_text(json.dumps(record, indent=2) + "\n")
    print("Verified protected frames, exact upper rows, direct mother legs, clean sheet, and GIF timing.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    prepare_parser = commands.add_parser("prepare", help="create the one-pass image edit target")
    prepare_parser.add_argument("--output", type=Path, default=EDIT_TARGET)
    assemble_parser = commands.add_parser("assemble", help="build the review artifacts")
    assemble_parser.add_argument("--output-dir", type=Path, required=True)
    assemble_parser.add_argument("--freeze-inputs", action="store_true")
    args = parser.parse_args()
    if args.command == "prepare":
        prepare(args.output)
    else:
        assemble(args.output_dir, args.freeze_inputs)


if __name__ == "__main__":
    main()
