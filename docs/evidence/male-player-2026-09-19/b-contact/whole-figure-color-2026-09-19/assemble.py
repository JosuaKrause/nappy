"""Material-aware RGB correction for the approved uncrossed diagonal B frames.

This recipe preserves every source coordinate and alpha value.  It fits separate
native-pixel luminance mappings to the same-state diagonal A/C jacket and trouser
samples: jacket is darkened by a least-squares affine fit, while trousers are
lightened by a constrained gain that matches the A/C bright trouser percentile.
"""

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
SOURCE = HERE.parent / "uncrossed-southeast-2026-09-19/generated"
P2 = ROOT / "docs/evidence/comic-pushing-strides-2026-09-12/convert.py"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
PHASES = ("a", "b", "c")
LOOP = ("a", "c", "b", "c")
UPPER_LAST_ROW = 26
# (left, top, right-exclusive, bottom-exclusive, downward shift). These are
# the true two-row native hem contours. C supplies the body and gap; B supplies
# only the lower jacket edge, leaving B trouser interior untouched.
HEM_REGIONS = {
    "pushing": (7, 24, 18, 26, 2),
    "carrying": (8, 24, 19, 26, 2),
}
EXPECTED_SIDE_B = {
    "pushing": "9bcd63d4af8bc79744e3722d73832e4e19a7f2211aa95f9c881a13983c865eeb",
    "carrying": "8a8df0912f46641a6c5706ce3b4a45db04d679c2f7b5bc49416c687dad7981cd",
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader, path
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def prefix(state: str) -> str:
    return "father" if state == "pushing" else "father_carrying"


def luma(red: int, green: int, blue: int) -> float:
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue


def blue_material(red: int, green: int, blue: int, alpha: int) -> bool:
    """Keep neutral ink, skin, hair, shirt, shoes, baby, and blanket outside masks."""
    return alpha > 0 and luma(red, green, blue) >= 38 and blue >= green + 5 and green >= red + 5


def quantiles(values: list[float]) -> dict[str, float]:
    assert values, "material selector matched no opaque samples"
    ordered = sorted(values)
    return {str(percent): ordered[round((len(ordered) - 1) * percent / 100)] for percent in (10, 25, 50, 75, 90)}


def mask_samples(image: Image.Image, mask: Image.Image) -> list[float]:
    result = []
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = image.getpixel((x, y))
            if alpha >= 224 and mask.getpixel((x, y)):
                result.append(luma(red, green, blue))
    return result


def blue_mask(image: Image.Image, predicate) -> Image.Image:
    result = Image.new("L", image.size)
    for y in range(image.height):
        for x in range(image.width):
            if predicate(x, y, image.getpixel((x, y))):
                result.putpixel((x, y), 255)
    return result


def reference_mask(image: Image.Image, name: str) -> Image.Image:
    if name == "jacket":
        left, top, right, bottom, _shift = HEM_REGIONS["pushing"]
        return blue_mask(image, lambda x, y, pixel: left <= x < right and top <= y < bottom and blue_material(*pixel))
    return blue_mask(image, lambda _x, y, pixel: 28 <= y <= 42 and blue_material(*pixel))


def reference_samples(state: str, name: str) -> list[float]:
    result = []
    for phase in ("a", "c"):
        image = rgba(HERE / "inputs" / state / "rig" / f"{prefix(state)}_front_diagonal_{phase}.png")
        if name == "jacket":
            left, top, right, bottom, _shift = HEM_REGIONS[state]
            mask = blue_mask(image, lambda x, y, pixel: left <= x < right and top <= y < bottom and blue_material(*pixel))
        else:
            mask = reference_mask(image, name)
        result.extend(mask_samples(image, mask))
    return result


def geometry(source_b: Image.Image, source_c: Image.Image, state: str) -> tuple[Image.Image, Image.Image, Image.Image, Image.Image]:
    """Restore C's complete upper body, then lower only B's painted hem edge."""
    result = source_b.copy()
    upper = Image.new("L", source_b.size)
    hem = Image.new("L", source_b.size)
    hem_source = Image.new("L", source_b.size)
    for y in range(UPPER_LAST_ROW + 1):
        for x in range(source_b.width):
            result.putpixel((x, y), source_c.getpixel((x, y)))
            upper.putpixel((x, y), 255)
    left, top, right, bottom, shift = HEM_REGIONS[state]
    for y in range(top, bottom):
        for x in range(left, right):
            pixel = source_b.getpixel((x, y))
            if pixel[3] < 64:
                continue
            destination = (x, y + shift)
            result.putpixel(destination, pixel)
            hem.putpixel(destination, 255)
            upper.putpixel(destination, 0)
            hem_source.putpixel((x, y), 255)
    return result, upper, hem, hem_source


def material_masks(figure: Image.Image, hem: Image.Image) -> dict[str, Image.Image]:
    jacket = Image.new("L", figure.size)
    pants = Image.new("L", figure.size)
    for y in range(figure.height):
        for x in range(figure.width):
            pixel = figure.getpixel((x, y))
            if hem.getpixel((x, y)) and blue_material(*pixel):
                jacket.putpixel((x, y), 255)
            elif y >= 28 and blue_material(*pixel):
                pants.putpixel((x, y), 255)
    return {"jacket": jacket, "pants": pants}


def affine_fit(source: dict[str, float], target: dict[str, float]) -> tuple[float, float]:
    """Fit five paired A/C luminance quantiles with one restrained affine mapping."""
    xs = list(source.values())
    ys = list(target.values())
    mean_x = sum(xs) / len(xs)
    mean_y = sum(ys) / len(ys)
    denominator = sum((value - mean_x) ** 2 for value in xs)
    assert denominator, "source material has no luminance range"
    slope = sum((x - mean_x) * (y - mean_y) for x, y in zip(xs, ys, strict=True)) / denominator
    offset = mean_y - slope * mean_x
    return slope, offset


def fits(state: str, source: Image.Image, source_hem: Image.Image, final_masks: dict[str, Image.Image]) -> dict[str, dict[str, object]]:
    records: dict[str, dict[str, object]] = {}
    for name in ("jacket", "pants"):
        candidate_mask = blue_mask(source, lambda x, y, pixel: bool(source_hem.getpixel((x, y))) and blue_material(*pixel)) if name == "jacket" else final_masks["pants"]
        candidate = quantiles(mask_samples(source, candidate_mask))
        reference = quantiles(reference_samples(state, name))
        if name == "jacket":
            slope, offset = affine_fit(candidate, reference)
            transform = {"kind": "affine_luma", "slope": slope, "offset": offset}
        else:
            # A one-parameter gain is the smallest model that corrects the
            # candidate's missing bright trouser range without flattening its shadows.
            gain = reference["90"] / candidate["90"]
            assert gain > 1, (state, name, gain)
            transform = {"kind": "luma_gain", "gain": gain}
        records[name] = {"candidate_quantiles": candidate, "reference_ac_quantiles": reference, "transform": transform}
    return records


def corrected_rgb(red: int, green: int, blue: int, transform: dict[str, object]) -> tuple[int, int, int]:
    before = luma(red, green, blue)
    if transform["kind"] == "affine_luma":
        after = float(transform["slope"]) * before + float(transform["offset"])
    else:
        after = float(transform["gain"]) * before
    scale = max(0.0, after) / before
    return tuple(min(255, max(0, round(channel * scale))) for channel in (red, green, blue))


def material_stat(image: Image.Image, predicate) -> dict[str, object]:
    pixels = []
    for y in range(image.height):
        for x in range(image.width):
            pixel = image.getpixel((x, y))
            if pixel[3] >= 224 and predicate(x, y, pixel):
                pixels.append(pixel[:3])
    assert pixels, "diagnostic material selector matched no opaque pixels"
    luminances = [luma(*pixel) for pixel in pixels]
    return {
        "pixels": len(pixels),
        "mean_rgb": [round(sum(pixel[index] for pixel in pixels) / len(pixels), 1) for index in range(3)],
        "median_luma": round(quantiles(luminances)["50"], 1),
    }


def upper_material_stats(source_b: Image.Image, source_c: Image.Image, state: str) -> dict[str, object]:
    """A compact audit for materials restored exactly from diagonal C."""
    common = {
        "skin": lambda _x, y, p: y <= UPPER_LAST_ROW and p[0] >= p[1] + 20 and p[1] >= p[2] + 8,
        "hair": lambda _x, y, p: y <= 12 and p[0] >= p[1] + 10 and p[1] >= p[2] and luma(*p[:3]) < 130,
        "shirt": lambda _x, y, p: 12 <= y <= UPPER_LAST_ROW and max(p[:3]) - min(p[:3]) <= 25 and luma(*p[:3]) >= 115,
        "shoes": lambda _x, y, p: y >= 38 and max(p[:3]) - min(p[:3]) <= 35 and luma(*p[:3]) < 110,
    }
    if state == "carrying":
        common["baby"] = lambda x, y, p: 13 <= x <= 22 and 13 <= y <= 24 and p[0] >= p[1] + 20 and p[1] >= p[2] + 8
        common["blanket"] = lambda x, y, p: 7 <= x <= 20 and 17 <= y <= UPPER_LAST_ROW and blue_material(*p)
    return {name: {"original_b": material_stat(source_b, predicate), "reference_c": material_stat(source_c, predicate)} for name, predicate in common.items()}


def recolor(source: Image.Image, state: str, records: dict[str, dict[str, object]], masks: dict[str, Image.Image]) -> tuple[Image.Image, dict[str, int]]:
    result = source.copy()
    changed = {name: 0 for name in records}
    for y in range(source.height):
        for x in range(source.width):
            pixel = source.getpixel((x, y))
            for name, record in records.items():
                if not masks[name].getpixel((x, y)):
                    continue
                red, green, blue, alpha = pixel
                result.putpixel((x, y), (*corrected_rgb(red, green, blue, record["transform"]), alpha))
                changed[name] += 1
                break
    assert result.getchannel("A").tobytes() == source.getchannel("A").tobytes(), state
    selected_any = Image.new("L", source.size)
    for name, mask in masks.items():
        assert changed[name], (state, name)
        selected_any = Image.frombytes("L", source.size, bytes(max(left, right) for left, right in zip(selected_any.get_flattened_data(), mask.get_flattened_data(), strict=True)))
    for before, after, selected in zip(source.get_flattened_data(), result.get_flattened_data(), selected_any.get_flattened_data(), strict=True):
        assert selected or before == after, state
    return result, changed


def sheets(output: Path, state: str, p2) -> None:
    def sprite(view: str, pose: str, mirror: bool) -> Image.Image:
        picture = rgba(output / "rig" / f"{prefix(state)}_{view}_{pose}.png")
        return ImageOps.mirror(picture) if mirror else picture

    sheet = Image.new("RGBA", (54 * 8, 61 * 4), p2.BACKGROUND)
    for row, pose in enumerate(LOOP):
        for column, (_label, view, mirror, _angle) in enumerate(p2.DIRECTIONS):
            p2._place(sheet, sprite(view, pose, mirror), column * 54 + 27, row * 61 + 59)
    sheet.save(output / f"{state}-spritesheet-native.png")
    sheet.resize((sheet.width * 6, sheet.height * 6), Image.Resampling.NEAREST).save(output / f"{state}-spritesheet-6x.png")
    for factor, name in ((1, "native"), (6, "6x")):
        frames = []
        for pose in LOOP:
            frame = Image.new("RGBA", (54 * 4 * factor, 62 * 2 * factor), p2.BACKGROUND)
            for index, (_label, view, mirror, _angle) in enumerate(p2.DIRECTIONS):
                picture = sprite(view, pose, mirror).resize((26 * factor if view not in ("front", "back") else 24 * factor, 46 * factor), Image.Resampling.NEAREST)
                p2._place(frame, picture, (index % 4 * 54 + 27) * factor, (index // 4 * 62 + 60) * factor)
            frames.append(frame)
        frames[0].save(output / f"{state}-animation-{name}.gif", save_all=True, append_images=frames[1:], duration=[190] * 4, loop=0, disposal=2)
        p2._verify_animation(output / f"{state}-animation-{name}.gif")


def comparison(output: Path, state: str, source: Image.Image) -> None:
    background = (92, 108, 114, 255)
    canvas = Image.new("RGBA", (26 * 12 * 4, 46 * 12), background)
    names = ("a", "c")
    pictures = [rgba(HERE / "inputs" / state / "rig" / f"{prefix(state)}_front_diagonal_{pose}.png") for pose in names]
    pictures.extend((source, rgba(output / "rig" / f"{prefix(state)}_front_diagonal_b.png")))
    for index, picture in enumerate(pictures):
        canvas.alpha_composite(picture.resize((26 * 12, 46 * 12), Image.Resampling.NEAREST), (index * 26 * 12, 0))
    canvas.save(output / f"comparison-a-c-original-recolor-12x.png")


def verify(output: Path, state: str, source_b: Image.Image, source_c: Image.Image, upper: Image.Image, hem: Image.Image, masks: dict[str, Image.Image], p2) -> None:
    source_rig = HERE / "inputs" / state / "rig"
    output_rig = output / "rig"
    for original in sorted(source_rig.glob("*.png")):
        result = output_rig / original.name
        assert original.is_file() and result.is_file(), original.name
        before, after = rgba(original), rgba(result)
        assert before.size == after.size, original.name
        if original.name != f"{prefix(state)}_front_diagonal_b.png":
            assert before.getchannel("A").tobytes() == after.getchannel("A").tobytes(), original.name
            assert original.read_bytes() == result.read_bytes(), original.name
        else:
            assert before.tobytes() != after.tobytes(), original.name
    result_b = rgba(output_rig / f"{prefix(state)}_front_diagonal_b.png")
    for y in range(source_b.height):
        for x in range(source_b.width):
            if upper.getpixel((x, y)):
                assert result_b.getpixel((x, y))[3] == source_c.getpixel((x, y))[3], (state, x, y)
            elif hem.getpixel((x, y)):
                assert result_b.getpixel((x, y))[3] == source_b.getpixel((x, y - HEM_REGIONS[state][4]))[3], (state, x, y)
            else:
                assert result_b.getpixel((x, y))[3] == source_b.getpixel((x, y))[3], (state, x, y)
            if upper.getpixel((x, y)):
                assert result_b.getpixel((x, y)) == source_c.getpixel((x, y)), (state, x, y)
            elif not hem.getpixel((x, y)) and not masks["pants"].getpixel((x, y)):
                assert result_b.getpixel((x, y)) == source_b.getpixel((x, y)), (state, x, y)
    native = rgba(output / f"{state}-spritesheet-native.png")
    assert rgba(output / f"{state}-spritesheet-6x.png").tobytes() == native.resize((native.width * 6, native.height * 6), Image.Resampling.NEAREST).tobytes()
    for scale in ("native", "6x"):
        p2._verify_animation(output / f"{state}-animation-{scale}.gif")


def freeze_inputs() -> None:
    destination = HERE / "inputs"
    assert not destination.exists(), destination
    for state in ("pushing", "carrying"):
        source = SOURCE / state / "rig"
        assert source.is_dir(), source
        shutil.copytree(source, destination / state / "rig")
        side = rgba(destination / state / "rig" / f"{prefix(state)}_side_b.png")
        assert digest(SOURCE / state / "rig" / f"{prefix(state)}_side_b.png") == EXPECTED_SIDE_B[state]
        assert side.size == (26, 46)
    manifest = {
        "pillow": pillow_version,
        "source": str(SOURCE.relative_to(ROOT)),
        "p2_helper": str(P2.relative_to(ROOT)),
        "p2_helper_sha256": digest(P2),
        "approved_unchanged_side_b_sha256": EXPECTED_SIDE_B,
        "files": {str(path.relative_to(HERE)): digest(path) for path in sorted(destination.rglob("*.png"))},
    }
    (HERE / "inputs.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Froze {len(manifest['files'])} authored PNG inputs.")


def assemble(output_root: Path) -> None:
    assert not output_root.exists(), output_root
    manifest = json.loads((HERE / "inputs.json").read_text())
    actual = {str(path.relative_to(HERE)): digest(path) for path in sorted((HERE / "inputs").rglob("*.png"))}
    assert actual == manifest["files"], "frozen input changed"
    assert digest(P2) == manifest["p2_helper_sha256"], "sheet helper changed"
    p2 = module(P2, "whole_figure_color_p2")
    output_root.mkdir(parents=True)
    all_records: dict[str, object] = {}
    for state in ("pushing", "carrying"):
        output = output_root / state
        shutil.copytree(HERE / "inputs" / state / "rig", output / "rig")
        source_b = rgba(output / "rig" / f"{prefix(state)}_front_diagonal_b.png")
        source_c = rgba(HERE / "inputs" / state / "rig" / f"{prefix(state)}_front_diagonal_c.png")
        combined, upper, hem, hem_source = geometry(source_b, source_c, state)
        masks = material_masks(combined, hem)
        records = fits(state, source_b, hem_source, masks)
        recolored, changed = recolor(combined, state, records, masks)
        recolored.save(output / "rig" / f"{prefix(state)}_front_diagonal_b.png")
        (output / "masks").mkdir()
        for name, mask in masks.items():
            mask.save(output / "masks" / f"{name}-mask.png")
            records[name]["changed_pixels"] = changed[name]
        sheets(output, state, p2)
        comparison(output, state, source_b)
        verify(output, state, source_b, source_c, upper, hem, masks, p2)
        all_records[state] = {
            "upper_source": f"inputs/{state}/rig/{prefix(state)}_front_diagonal_c.png",
            "upper_rows": [0, UPPER_LAST_ROW],
            "hem_source_region": list(HEM_REGIONS[state]),
            "hem_destination_pixels": sum(value > 0 for value in hem.get_flattened_data()),
            "color_fits": records,
            "other_materials": upper_material_stats(source_b, source_c, state),
        }
    output_manifest = {
        "status": "uninstalled material-aware diagonal B color review",
        "method": "Native RGB-only luminance mappings selected by material masks; source alpha and coordinates are unchanged.",
        "comparison_order": ["diagonal A", "diagonal C", "original diagonal B", "recolored diagonal B"],
        "frame_order": list(LOOP),
        "frame_ms": [190] * 4,
        "fits": all_records,
        "files": {str(path.relative_to(output_root)): digest(path) for path in sorted(output_root.rglob("*")) if path.is_file()},
    }
    (output_root / "manifest.json").write_text(json.dumps(output_manifest, indent=2) + "\n")
    print("Verified C-exact upper rows, the bounded shifted hem alpha, 28 protected PNGs, native/6x sheets, and four 190ms GIF phases.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--freeze-inputs", action="store_true", help="copy the approved source rigs once")
    group.add_argument("--output-dir", type=Path, help="fresh destination for review artifacts")
    args = parser.parse_args()
    if args.freeze_inputs:
        freeze_inputs()
    else:
        assert args.output_dir is not None
        assemble(args.output_dir)


if __name__ == "__main__":
    main()
