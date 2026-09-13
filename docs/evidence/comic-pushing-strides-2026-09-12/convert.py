#!/usr/bin/env -S uv run --project tools
"""Register, review, install, and verify the P2 three-pose pushing PNG family."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import math
import platform
import shutil
from collections import deque
from pathlib import Path

import PIL
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
RIG = ROOT / "assets/illustrated/svg-transfer/rig"
P1 = HERE / "source/p1"
PASS1 = HERE / "raw/p2-acb-pass1.png"
PASS2 = HERE / "raw/p2-acb-pass2.png"
PASS4 = HERE / "raw/p2-acb-pass4-side-ne.png"
C_ROW = HERE / "raw/p2-c-row.png"
INPUT_MANIFEST = HERE / "input-manifest.json"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
FRAMES = ("a", "c", "b")
DIRECTIONS = (
    ("N", "back", False, -90),
    ("NE", "back_diagonal", False, -45),
    ("E", "side", False, 0),
    ("SE", "front_diagonal", False, 45),
    ("S", "front", False, 90),
    ("SW", "front_diagonal", True, 135),
    ("W", "side", True, 180),
    ("NW", "back_diagonal", True, 225),
)
FONT_PATH = Path("/System/Library/Fonts/SFNS.ttf")
FONT_SHA256 = "2bfd40dc72e6759e248f82a52a40d551338979fffc9b5c070e685b4b7ad19e66"
BACKGROUND = (89, 105, 112, 255)
INK = (245, 247, 248, 255)
HIGH_RES_FACTOR = 12
TARGET_FIGURE_HEIGHT = 45
UPPER_BODY_FRACTION = 0.68
RECIPE_VERSION = "p2-pushing-registration-v2"


def _dependency_paths() -> list[Path]:
    return [
        PASS1,
        PASS2,
        PASS4,
        C_ROW,
        HERE / "prompt.txt",
        HERE / "prompt-pass2.txt",
        HERE / "prompt-c-row.txt",
        HERE / "prompt-pass4-side-ne.txt",
        ROOT / "docs/evidence/comic-carrying-redraw-2026-09-12/source/pushing-atlas-edit-target.png",
        ROOT / "docs/evidence/graphics-reference-urban-01.jpeg",
        ROOT / "docs/evidence/graphics-reference-cardinal.jpeg",
        ROOT / "tools/remove-checkerboard.py",
        HERE / "convert.py",
        HERE / "make-source-review.py",
        HERE / "render-svg-sources.gd",
        HERE / "source/review/p2-source-6x.png",
        *[P1 / f"mother_{view}_{frame}.png" for frame in ("a", "b") for view in VIEWS],
        *[P1 / f"mother_{view}_{frame}.svg" for frame in ("a", "b") for view in VIEWS],
        *[ROOT / f"assets/rig/mother_{view}_{frame}.svg" for frame in FRAMES for view in VIEWS],
        *[RIG / f"pram_{view}.png" for view in VIEWS],
    ]


def _current_input_manifest() -> dict[str, object]:
    dependencies = _dependency_paths()
    for path in dependencies:
        assert path.is_file(), path
    return {
        "recipe_version": RECIPE_VERSION,
        "python_version": platform.python_version(),
        "pillow_version": PIL.__version__,
        "review_font": str(FONT_PATH),
        "review_font_sha256": _sha256(FONT_PATH),
        "files": {
            str(path.relative_to(ROOT)): _sha256(path)
            for path in dependencies
        },
    }


def freeze_inputs(output_file: Path) -> None:
    assert not output_file.exists(), f"Choose a new input manifest path: {output_file}"
    assert FONT_PATH.is_file() and _sha256(FONT_PATH) == FONT_SHA256, FONT_PATH
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(json.dumps(_current_input_manifest(), indent=2) + "\n")


def _verify_inputs() -> str:
    assert INPUT_MANIFEST.is_file(), INPUT_MANIFEST
    expected = json.loads(INPUT_MANIFEST.read_text())
    current = _current_input_manifest()
    assert expected == current, "registration inputs, recipe, Python, Pillow, or font changed"
    return _sha256(INPUT_MANIFEST)


def _module(name: str, path: Path):
    assert path.is_file(), path
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _sha256(path: Path) -> str:
    assert path.is_file(), path
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _font(size: int) -> ImageFont.FreeTypeFont:
    assert FONT_PATH.is_file() and _sha256(FONT_PATH) == FONT_SHA256, FONT_PATH
    return ImageFont.truetype(FONT_PATH, size)


def _alpha_bounds(image: Image.Image) -> tuple[int, int, int, int]:
    bounds = image.getchannel("A").point(lambda value: 255 if value > 192 else 0).getbbox()
    assert bounds, "empty generated figure"
    return bounds


def _upper_centroid_x(image: Image.Image) -> float:
    """Measure the stable head, hands, and coat while excluding gait-dependent legs."""
    alpha = image.getchannel("A")
    bounds = _alpha_bounds(image)
    cutoff = bounds[1] + round((bounds[3] - bounds[1]) * UPPER_BODY_FRACTION)
    raw = alpha.tobytes()
    weight = 0
    weighted_x = 0
    for y in range(bounds[1], cutoff):
        for x in range(image.width):
            value = raw[y * image.width + x]
            if value > 64:
                weight += value
                weighted_x += x * value
    assert weight > 0
    return weighted_x / weight


def _cell(image: Image.Image, column: int, row: int, rows: int) -> Image.Image:
    return image.crop(
        (
            round(column * image.width / 5),
            round(row * image.height / rows),
            round((column + 1) * image.width / 5),
            round((row + 1) * image.height / rows),
        )
    )


def _subject(image: Image.Image, column: int, row: int, rows: int) -> tuple[Image.Image, list[int]]:
    cell = _cell(image, column, row, rows)
    bounds = _alpha_bounds(cell)
    subject = cell.crop(bounds)
    assert subject.height >= cell.height * 0.8, (column, row, subject.size, cell.size)
    return subject, list(bounds)


def _accepted_anchor(view: str) -> tuple[float, list[dict[str, object]]]:
    records: list[dict[str, object]] = []
    anchors: list[float] = []
    for frame in ("a", "b"):
        path = P1 / f"mother_{view}_{frame}.png"
        image = Image.open(path).convert("RGBA")
        anchor = _upper_centroid_x(image)
        anchors.append(anchor)
        records.append({"path": str(path.relative_to(ROOT)), "sha256": _sha256(path), "anchor_x": anchor})
    return sum(anchors) / len(anchors), records


def _palette(subjects: list[Image.Image]) -> Image.Image:
    pixels: list[tuple[int, int, int]] = []
    references = [P1 / f"mother_{view}_{frame}.png" for frame in ("a", "b") for view in VIEWS]
    for path in references:
        assert path.is_file(), path
    for image in subjects + [Image.open(path).convert("RGBA") for path in references]:
        pixels.extend(
            (red, green, blue)
            for red, green, blue, alpha in image.get_flattened_data()
            if alpha > 64
        )
    assert pixels
    width = 1024
    pixels.extend([pixels[-1]] * (math.ceil(len(pixels) / width) * width - len(pixels)))
    samples = Image.new("RGB", (width, len(pixels) // width))
    samples.putdata(pixels)
    return samples.quantize(colors=28, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)


def _extend_colors(image: Image.Image) -> Image.Image:
    """Extend retained colors under transparent pixels before the final reduction."""
    width, height = image.size
    pixels = list(image.get_flattened_data())
    seen = bytearray(int(pixel[3] != 0) for pixel in pixels)
    pending = deque(index for index, valid in enumerate(seen) if valid)
    assert pending, "empty sprite"
    while pending:
        index = pending.popleft()
        x, y = index % width, index // width
        for neighbor_x, neighbor_y in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= neighbor_x < width and 0 <= neighbor_y < height:
                neighbor = neighbor_y * width + neighbor_x
                if not seen[neighbor]:
                    seen[neighbor] = 1
                    pixels[neighbor] = pixels[index]
                    pending.append(neighbor)
    rgb = Image.new("RGB", image.size)
    rgb.putdata([pixel[:3] for pixel in pixels])
    return rgb


def _register(
    view: str,
    frame: str,
    subject: Image.Image,
    source_bounds: list[int],
    generated_source: Path,
    palette: Image.Image,
) -> tuple[Image.Image, dict[str, object]]:
    native_size = (24, 46) if view in ("front", "back") else (26, 46)
    high_size = tuple(value * HIGH_RES_FACTOR for value in native_size)
    accepted_anchor, anchor_sources = _accepted_anchor(view)
    source_anchor = _upper_centroid_x(subject)
    scale = TARGET_FIGURE_HEIGHT * HIGH_RES_FACTOR / subject.height
    fitted_size = (round(subject.width * scale), round(subject.height * scale))
    fitted = subject.resize(fitted_size, Image.Resampling.LANCZOS)
    target_anchor = accepted_anchor * HIGH_RES_FACTOR
    requested_x = round(target_anchor - source_anchor * scale)
    x = min(max(requested_x, 0), high_size[0] - fitted.width)
    y = high_size[1] - fitted.height
    assert x >= 0 and x + fitted.width <= high_size[0], (view, frame, x, fitted_size, high_size)
    assert y >= 0
    high = Image.new("RGBA", high_size, (0, 0, 0, 0))
    high.alpha_composite(fitted, (x, y))
    reduced = high.resize(native_size, Image.Resampling.LANCZOS)
    generated_alpha = reduced.getchannel("A")
    alpha_bytes = generated_alpha.tobytes()
    final = _extend_colors(reduced).quantize(palette=palette, dither=Image.Dither.NONE).convert("RGBA")
    final.putalpha(generated_alpha)
    assert final.getchannel("A").tobytes() == alpha_bytes
    final_bounds = generated_alpha.getbbox()
    assert final_bounds and final_bounds[3] == native_size[1], (view, frame, final_bounds)
    assert final_bounds[3] - final_bounds[1] in (45, 46), (view, frame, final_bounds)
    return final, {
        "name": f"mother_{view}_{frame}",
        "canvas": list(native_size),
        "generated_source": str(generated_source.relative_to(ROOT)),
        "generated_source_sha256": _sha256(generated_source),
        "generated_cell": [VIEWS.index(view), 0 if frame == "a" else (2 if frame == "b" else 0)],
        "generated_cell_rows": 3 if frame != "c" else 1,
        "generated_cell_bounds": source_bounds,
        "whole_figure_dimensions": list(subject.size),
        "whole_figure_fit_scale": scale,
        "upper_body_fraction": UPPER_BODY_FRACTION,
        "generated_upper_body_anchor_x": source_anchor,
        "accepted_upper_body_anchor_x": accepted_anchor,
        "accepted_anchor_sources": anchor_sources,
        "requested_high_resolution_x": requested_x,
        "high_resolution_placement": [x, y],
        "canvas_edge_adjustment_x": x - requested_x,
        "registered_alpha_bounds": list(final_bounds),
        "ground_line_preserved": True,
        "generated_alpha_preserved": True,
        "aspect_ratio_preserved": True,
        "anatomical_splice_used": False,
    }


def _place(sheet: Image.Image, sprite: Image.Image, center_x: int, ground_y: int) -> None:
    sheet.alpha_composite(sprite, (center_x - sprite.width // 2, ground_y - sprite.height))


def _load_registered(output: Path, view: str, frame: str) -> Image.Image:
    path = output / "rig" / f"mother_{view}_{frame}.png"
    assert path.is_file(), path
    return Image.open(path).convert("RGBA")


def _frame_sheet(output: Path) -> None:
    cell_width, cell_height = 54, 61
    left, top = 62, 18
    sheet = Image.new("RGBA", (left + cell_width * 5, top + cell_height * 3), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    draw.text((3, 2), "P2 — Three-pose push · registered PNG", font=_font(9), fill=INK)
    for column, view in enumerate(VIEWS):
        draw.text((left + column * cell_width + 2, top), view.replace("_", " "), font=_font(7), fill=INK)
    for row, frame in enumerate(FRAMES):
        label = {"a": "Contact A", "c": "Together C", "b": "Contact B"}[frame]
        draw.text((3, top + row * cell_height + 24), label, font=_font(7), fill=INK)
        for column, view in enumerate(VIEWS):
            _place(
                sheet,
                _load_registered(output, view, frame),
                left + column * cell_width + cell_width // 2,
                top + row * cell_height + 59,
            )
    sheet.save(output / "p2-frames-native.png")
    sheet.resize((sheet.width * 6, sheet.height * 6), Image.Resampling.NEAREST).save(output / "p2-frames-6x.png")


def _direction_frame(output: Path, frame: str, factor: int) -> Image.Image:
    cell_width, cell_height = 54 * factor, 62 * factor
    top = 18 * factor
    sheet = Image.new("RGBA", (cell_width * 4, top + cell_height * 2), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    draw.text((3 * factor, 2 * factor), "P2 · A/C/B/C · all runtime directions", font=_font(8 * factor), fill=INK)
    for index, (label, view, mirror, _degrees) in enumerate(DIRECTIONS):
        column, row = index % 4, index // 4
        draw.text(
            (column * cell_width + 2 * factor, top + row * cell_height + 2 * factor),
            label,
            font=_font(7 * factor),
            fill=INK,
        )
        sprite = _load_registered(output, view, frame)
        if mirror:
            sprite = sprite.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        if factor != 1:
            sprite = sprite.resize((sprite.width * factor, sprite.height * factor), Image.Resampling.NEAREST)
        _place(sheet, sprite, column * cell_width + cell_width // 2, top + row * cell_height + 60 * factor)
    return sheet


def _animation(output: Path) -> None:
    for factor, name in ((1, "native"), (6, "6x")):
        frames = [_direction_frame(output, frame, factor) for frame in ("a", "c", "b", "c")]
        frames[0].save(
            output / f"p2-animation-{name}.gif",
            save_all=True,
            append_images=frames[1:],
            duration=[190, 190, 190, 190],
            loop=0,
            disposal=2,
        )


def _contact_sheet(output: Path, factor: int) -> Image.Image:
    cell_width, cell_height = 112 * factor, 68 * factor
    left, title, header = 22 * factor, 18 * factor, 16 * factor
    sheet = Image.new("RGBA", (left + cell_width * 3, title + header + cell_height * 8), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    draw.text((3 * factor, 2 * factor), "P2 — Three-pose push · grounded PNG contact", font=_font(8 * factor), fill=INK)
    for column, frame in enumerate(FRAMES):
        label = {"a": "Contact A", "c": "Together C", "b": "Contact B"}[frame]
        draw.text(
            (left + column * cell_width + 3 * factor, title),
            label,
            font=_font(7 * factor),
            fill=INK,
        )
    for row, (label, view, mirror, degrees) in enumerate(DIRECTIONS):
        draw.text(
            (2 * factor, title + header + row * cell_height + 24 * factor),
            label,
            font=_font(7 * factor),
            fill=INK,
        )
        angle = math.radians(degrees)
        facing_x = 0.0 if abs(math.cos(angle)) < 1e-9 else math.cos(angle)
        facing_y = 0.0 if abs(math.sin(angle)) < 1e-9 else math.sin(angle)
        vertical_distance = 9.0 if facing_y > 0.0 else 17.0
        offset = (facing_x * 24.0 * factor, facing_y * vertical_distance * 0.7 * factor)
        pram_path = RIG / f"pram_{view}.png"
        assert pram_path.is_file(), pram_path
        for column, frame in enumerate(FRAMES):
            center_x = left + column * cell_width + cell_width // 2
            ground_y = title + header + row * cell_height + 58 * factor
            draw.line(
                (
                    left + column * cell_width + 2 * factor,
                    ground_y,
                    left + (column + 1) * cell_width - 2 * factor,
                    ground_y,
                ),
                fill="#9fc2c9",
                width=factor,
            )
            mother = _load_registered(output, view, frame)
            pram = Image.open(pram_path).convert("RGBA")
            mother = mother.resize((mother.width * factor, mother.height * factor), Image.Resampling.NEAREST)
            pram = pram.resize(
                (
                    round(pram.width * 7.0 / 6.0 * factor),
                    round(pram.height * 7.0 / 6.0 * factor),
                ),
                Image.Resampling.NEAREST,
            )
            if mirror:
                mother = mother.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                pram = pram.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            parts = ((mother, (0.0, 0.0)), (pram, offset))
            if facing_y < 0.0:
                parts = tuple(reversed(parts))
            for sprite, (offset_x, offset_y) in parts:
                sheet.alpha_composite(
                    sprite,
                    (
                        round(center_x + offset_x - sprite.width / 2),
                        round(ground_y + offset_y - sprite.height),
                    ),
                )
    return sheet


def _selected_generation(
    output: Path,
    selected: dict[tuple[str, str], tuple[Image.Image, list[int], Path]],
) -> None:
    width = 338 * 5
    height = 310 * 3
    sheet = Image.new("RGBA", (width, height), "white")
    for column, view in enumerate(VIEWS):
        for row, frame in enumerate(FRAMES):
            subject, _bounds, _source = selected[(view, frame)]
            scale = 297 / subject.height
            fitted = subject.resize(
                (round(subject.width * scale), round(subject.height * scale)),
                Image.Resampling.LANCZOS,
            )
            x = column * 338 + (338 - fitted.width) // 2
            y = row * 310 + 310 - fitted.height
            sheet.alpha_composite(fitted, (x, y))
    sheet.convert("RGB").save(output / "p2-selected-generation.png")


def register(output: Path, selection: str) -> None:
    input_manifest_sha256 = _verify_inputs()
    assert not output.exists(), f"Choose a new output directory: {output}"
    assert PASS2.is_file() and PASS4.is_file() and C_ROW.is_file()
    output.mkdir(parents=True)
    (output / "rig").mkdir()
    checker = _module("checker", ROOT / "tools/remove-checkerboard.py")
    pass2_extracted = output / "p2-acb-pass2-extracted.png"
    pass4_extracted = output / "p2-acb-pass4-side-ne-extracted.png"
    c_extracted = output / "p2-c-row-extracted.png"
    checker.extract(PASS2, pass2_extracted)
    checker.extract(PASS4, pass4_extracted)
    checker.extract(C_ROW, c_extracted)
    pass2 = Image.open(pass2_extracted).convert("RGBA")
    pass4 = Image.open(pass4_extracted).convert("RGBA")
    c_row = Image.open(c_extracted).convert("RGBA")
    selected: dict[tuple[str, str], tuple[Image.Image, list[int], Path]] = {}
    for column, view in enumerate(VIEWS):
        a_subject, a_bounds = _subject(pass2, column, 0, 3)
        uses_pass4 = selection == "final" and view in ("side", "back_diagonal")
        b_atlas = pass4 if uses_pass4 else pass2
        b_source = PASS4 if uses_pass4 else PASS2
        b_subject, b_bounds = _subject(b_atlas, column, 2, 3)
        c_subject, c_bounds = _subject(c_row, column, 0, 1)
        selected[(view, "a")] = (a_subject, a_bounds, PASS2)
        selected[(view, "b")] = (b_subject, b_bounds, b_source)
        selected[(view, "c")] = (c_subject, c_bounds, C_ROW)
    palette = _palette([subject for subject, _bounds, _source in selected.values()])
    palette.save(output / "shared-palette.png")
    measurements = []
    for frame in FRAMES:
        for view in VIEWS:
            subject, bounds, generated_source = selected[(view, frame)]
            final, record = _register(
                view,
                frame,
                subject,
                bounds,
                generated_source,
                palette,
            )
            final.save(output / "rig" / f"mother_{view}_{frame}.png")
            measurements.append(record)
    (output / "registration.json").write_text(json.dumps(measurements, indent=2) + "\n")
    _selected_generation(output, selected)
    _frame_sheet(output)
    _animation(output)
    _contact_sheet(output, 1).save(output / "p2-grounded-contact-native.png")
    _contact_sheet(output, 6).save(output / "p2-grounded-contact-6x.png")
    manifest = {
        "version": "P2 — Three-pose push",
        "selection": selection,
        "recipe_version": RECIPE_VERSION,
        "input_manifest": str(INPUT_MANIFEST.relative_to(ROOT)),
        "input_manifest_sha256": input_manifest_sha256,
        "loop": ["a", "c", "b", "c"],
        "selected_whole_figures": {
            "pass2": [
                *[f"mother_{view}_a" for view in VIEWS],
                *[
                    f"mother_{view}_b"
                    for view in VIEWS
                    if selection == "pass2" or view not in ("side", "back_diagonal")
                ],
            ],
            "separate_c_row": [f"mother_{view}_c" for view in VIEWS],
            "pass4": [] if selection == "pass2" else ["mother_side_b", "mother_back_diagonal_b"],
        },
        "prompts": {str(path.relative_to(ROOT)): _sha256(path) for path in sorted(HERE.glob("prompt*.txt"))},
        "style_references": {
            str(path.relative_to(ROOT)): _sha256(path)
            for path in (
                ROOT / "docs/evidence/graphics-reference-urban-01.jpeg",
                ROOT / "docs/evidence/graphics-reference-cardinal.jpeg",
            )
        },
        "review_font": str(FONT_PATH),
        "review_font_sha256": FONT_SHA256,
        "outputs": {
            str(path.relative_to(output)): _sha256(path)
            for path in sorted(output.rglob("*"))
            if path.is_file() and path.name != "manifest.json"
        },
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def install(input_dir: Path) -> None:
    verify(input_dir, compare_runtime=False, compare_to=None)
    manifest = json.loads((input_dir / "manifest.json").read_text())
    assert manifest["selection"] == "final", "only the reviewed final selection may be installed"
    for frame in FRAMES:
        for view in VIEWS:
            source = input_dir / "rig" / f"mother_{view}_{frame}.png"
            destination = RIG / source.name
            if frame == "c":
                assert not destination.exists(), f"new C asset already exists: {destination}"
            shutil.copy2(source, destination)


def _verify_animation(path: Path) -> None:
    animation = Image.open(path)
    assert animation.n_frames == 4, path
    decoded: list[bytes] = []
    durations: list[int] = []
    for frame in range(animation.n_frames):
        animation.seek(frame)
        durations.append(int(animation.info["duration"]))
        decoded.append(animation.convert("RGBA").tobytes())
    assert durations == [190, 190, 190, 190], (path, durations)
    assert decoded[0] != decoded[1] and decoded[1] != decoded[2] and decoded[0] != decoded[2], path
    assert decoded[1] == decoded[3], path


def verify(input_dir: Path, compare_runtime: bool, compare_to: Path | None) -> None:
    input_manifest_sha256 = _verify_inputs()
    manifest_path = input_dir / "manifest.json"
    assert manifest_path.is_file(), manifest_path
    manifest = json.loads(manifest_path.read_text())
    assert manifest["version"] == "P2 — Three-pose push"
    assert manifest["selection"] in ("final", "pass2")
    assert manifest["recipe_version"] == RECIPE_VERSION
    assert manifest["input_manifest_sha256"] == input_manifest_sha256
    assert manifest["loop"] == ["a", "c", "b", "c"]
    for relative, expected in manifest["prompts"].items():
        assert _sha256(ROOT / relative) == expected, relative
    for relative, expected in manifest["style_references"].items():
        assert _sha256(ROOT / relative) == expected, relative
    for relative, expected in manifest["outputs"].items():
        assert _sha256(input_dir / relative) == expected, relative
    for frame in FRAMES:
        for view in VIEWS:
            registered = input_dir / "rig" / f"mother_{view}_{frame}.png"
            image = Image.open(registered).convert("RGBA")
            expected_size = (24, 46) if view in ("front", "back") else (26, 46)
            assert image.size == expected_size, registered
            bounds = image.getchannel("A").getbbox()
            assert bounds and bounds[3] == 46 and bounds[3] - bounds[1] in (45, 46), registered
            if compare_runtime:
                assert _sha256(RIG / registered.name) == _sha256(registered), registered.name
    _verify_animation(input_dir / "p2-animation-native.gif")
    _verify_animation(input_dir / "p2-animation-6x.gif")
    if compare_to is not None:
        assert compare_to.is_dir(), compare_to
        ours = {
            str(path.relative_to(input_dir)): _sha256(path)
            for path in input_dir.rglob("*")
            if path.is_file()
        }
        theirs = {
            str(path.relative_to(compare_to)): _sha256(path)
            for path in compare_to.rglob("*")
            if path.is_file()
        }
        assert ours == theirs, "fresh registration differs byte-for-byte"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    freeze_parser = commands.add_parser("freeze-inputs", help="freeze every recipe dependency")
    freeze_parser.add_argument("--output-file", required=True, type=Path)
    register_parser = commands.add_parser("register", help="register into a fresh output directory")
    register_parser.add_argument("--output-dir", required=True, type=Path)
    register_parser.add_argument("--selection", required=True, choices=("final", "pass2"))
    install_parser = commands.add_parser("install", help="copy a reviewed registration into runtime assets")
    install_parser.add_argument("--input-dir", required=True, type=Path)
    verify_parser = commands.add_parser("verify", help="verify evidence hashes and optional runtime copies")
    verify_parser.add_argument("--input-dir", required=True, type=Path)
    verify_parser.add_argument("--runtime", action="store_true")
    verify_parser.add_argument("--compare-to", type=Path)
    args = parser.parse_args()
    if args.command == "freeze-inputs":
        freeze_inputs(args.output_file.resolve())
    elif args.command == "register":
        register(args.output_dir.resolve(), args.selection)
    elif args.command == "install":
        install(args.input_dir.resolve())
    else:
        compare_to = args.compare_to.resolve() if args.compare_to else None
        verify(args.input_dir.resolve(), compare_runtime=args.runtime, compare_to=compare_to)


if __name__ == "__main__":
    main()
