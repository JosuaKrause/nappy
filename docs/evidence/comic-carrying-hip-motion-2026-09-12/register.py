#!/usr/bin/env python3
"""Extract and register the F hip-motion carrying frames from frozen raw inputs."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import io
import json
import re
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont, ImageSequence, UnidentifiedImageError
from PIL import __version__ as PILLOW_VERSION

VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
PHASES = ("a", "c", "b")
ANIMATION_PHASES = ("a", "c", "b", "c")
NAMES = tuple(f"mother_carrying_{view}_{phase}" for view in VIEWS for phase in PHASES)
NATIVE = {view: (24, 46) if view in ("front", "back") else (26, 46) for view in VIEWS}
DIRECTIONS = ("north", "northeast", "east", "southeast", "south", "southwest", "west", "northwest")
DIRECTION_LABELS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
VIEW_BY_DIRECTION = (
    "back",
    "back_diagonal",
    "side",
    "front_diagonal",
    "front",
    "front_diagonal",
    "side",
    "back_diagonal",
)
BACKGROUND = (104, 118, 124, 255)
SHEET_LEFT = 14
SHEET_COLUMN_WIDTH = 32
SHEET_TITLE_HEIGHT = 10
SHEET_DIRECTION_HEIGHT = 10
SHEET_ROW_HEIGHT = 50
SHEET_FOOTER_HEIGHT = 10
HEX_SHA256 = re.compile(r"[0-9a-f]{64}")
SVG_LENGTH = re.compile(r"([0-9]+(?:\.[0-9]+)?)(?:px)?")


@dataclass
class Prepared:
    config: dict[str, Any]
    config_sha256: str
    cells: dict[str, Image.Image]
    registered: dict[str, Image.Image]
    extraction: dict[str, str]
    measurements: dict[str, dict[str, Any]]
    raw_inputs: dict[str, dict[str, Any]]
    dependency: dict[str, str]


def sha256(path: Path) -> str:
    if not path.is_file():
        raise ValueError(f"input does not exist: {path}")
    return hashlib.sha256(path.read_bytes()).hexdigest()


def content_sha256(image: Image.Image) -> str:
    rgba = image.convert("RGBA")
    digest = hashlib.sha256()
    digest.update(f"{rgba.width}x{rgba.height}:RGBA\n".encode())
    digest.update(rgba.tobytes())
    return digest.hexdigest()


def load_json(path: Path, description: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"invalid {description}: {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ValueError(f"{description} must be a JSON object")
    return value


def resolve(config_path: Path, value: str) -> Path:
    path = Path(value)
    return (config_path.parent / path).resolve() if not path.is_absolute() else path.resolve()


def require_keys(record: dict[str, Any], allowed: set[str], description: str) -> None:
    unknown = set(record) - allowed
    if unknown:
        raise ValueError(f"unknown {description} keys: {', '.join(sorted(unknown))}")


def require_sha(value: Any, description: str) -> str:
    if not isinstance(value, str) or HEX_SHA256.fullmatch(value) is None:
        raise ValueError(f"{description} must be 64 lowercase hexadecimal characters")
    return value


def require_dimensions(value: Any, description: str) -> list[int]:
    if (
        not isinstance(value, list)
        or len(value) != 2
        or any(not isinstance(item, int) or isinstance(item, bool) or item <= 0 for item in value)
    ):
        raise ValueError(f"{description} must be [positive_width, positive_height]")
    return value


def require_offset(value: Any, description: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        raise ValueError(f"{description} must be an integer")
    return value


def checker_module(path: Path) -> Any:
    spec = importlib.util.spec_from_file_location("f_neutral_checker", path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load checkerboard remover: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    if not callable(getattr(module, "neutral_background_mask", None)):
        raise ValueError(f"checkerboard remover has no neutral_background_mask(): {path}")
    return module


def svg_dimensions(path: Path) -> list[int]:
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as exc:
        raise ValueError(f"invalid SVG XML: {path}: {exc}") from exc
    result: list[int] = []
    for attribute in ("width", "height"):
        raw = root.get(attribute, "")
        match = SVG_LENGTH.fullmatch(raw)
        if match is None:
            raise ValueError(f"SVG {attribute} must be an integer pixel length: {path}: {raw!r}")
        number = float(match.group(1))
        if not number.is_integer() or number <= 0:
            raise ValueError(f"SVG {attribute} must be a positive integer: {path}: {raw!r}")
        result.append(int(number))
    return result


def parse_config(config_path: Path) -> tuple[dict[str, Any], dict[str, dict[str, Any]], Path]:
    config = load_json(config_path, "config")
    require_keys(
        config,
        {"timing_ms", "pillow_version", "horizontal_offset", "checkerboard_remover", "raw_batches", "svg_pairs"},
        "config",
    )
    if config.get("timing_ms") != 190:
        raise ValueError("timing_ms is required and fixed at 190")
    if config.get("pillow_version") != PILLOW_VERSION:
        raise ValueError(
            f"Pillow version mismatch: expected {config.get('pillow_version')!r}, running {PILLOW_VERSION!r}"
        )
    global_offset = require_offset(config.get("horizontal_offset", 0), "horizontal_offset")

    dependency = config.get("checkerboard_remover")
    if not isinstance(dependency, dict):
        raise ValueError("checkerboard_remover must contain path and sha256")
    require_keys(dependency, {"path", "sha256"}, "checkerboard_remover")
    if not isinstance(dependency.get("path"), str):
        raise ValueError("checkerboard_remover.path must be a string")
    dependency_path = resolve(config_path, dependency["path"])
    expected_dependency_hash = require_sha(dependency.get("sha256"), "checkerboard_remover.sha256")
    if sha256(dependency_path) != expected_dependency_hash:
        raise ValueError(f"checkerboard remover hash mismatch: {dependency_path}")

    pairs = config.get("svg_pairs")
    if not isinstance(pairs, list):
        raise ValueError("svg_pairs must be an array")
    pair_map: dict[str, dict[str, Any]] = {}
    for pair in pairs:
        if not isinstance(pair, dict):
            raise ValueError("each svg_pairs entry must be an object")
        require_keys(pair, {"name", "svg", "svg_sha256", "dimensions"}, "SVG pair")
        name = pair.get("name")
        if name not in NAMES or name in pair_map:
            raise ValueError(f"invalid or duplicate SVG frame name: {name!r}")
        if not isinstance(pair.get("svg"), str):
            raise ValueError(f"SVG path must be a string: {name}")
        view = str(name).removeprefix("mother_carrying_").rsplit("_", 1)[0]
        expected_dimensions = list(NATIVE[view])
        dimensions = require_dimensions(pair.get("dimensions"), f"SVG dimensions for {name}")
        if dimensions != expected_dimensions:
            raise ValueError(
                f"configured SVG dimensions mismatch for {name}: {dimensions} versus {expected_dimensions}"
            )
        svg_path = resolve(config_path, pair["svg"])
        expected_svg_hash = require_sha(pair.get("svg_sha256"), f"svg_sha256 for {name}")
        if sha256(svg_path) != expected_svg_hash:
            raise ValueError(f"SVG hash mismatch: {svg_path}")
        actual_dimensions = svg_dimensions(svg_path)
        if actual_dimensions != dimensions:
            raise ValueError(f"actual SVG dimensions mismatch for {name}: {actual_dimensions} versus {dimensions}")
        pair_map[str(name)] = pair
    if set(pair_map) != set(NAMES):
        raise ValueError("svg_pairs must contain exactly all 15 canonical frame names")

    batches = config.get("raw_batches")
    if not isinstance(batches, list):
        raise ValueError("raw_batches must be an array")
    frame_map: dict[str, dict[str, Any]] = {}
    raw_paths: set[Path] = set()
    for batch in batches:
        if not isinstance(batch, dict):
            raise ValueError("each raw_batches entry must be an object")
        require_keys(batch, {"path", "sha256", "dimensions", "frames"}, "raw batch")
        if not isinstance(batch.get("path"), str):
            raise ValueError("raw batch path must be a string")
        raw_path = resolve(config_path, batch["path"])
        if raw_path in raw_paths:
            raise ValueError(f"duplicate raw batch path: {batch['path']}")
        raw_paths.add(raw_path)
        expected_raw_hash = require_sha(batch.get("sha256"), f"raw SHA-256 for {batch['path']}")
        if sha256(raw_path) != expected_raw_hash:
            raise ValueError(f"raw input hash mismatch: {raw_path}")
        dimensions = require_dimensions(batch.get("dimensions"), f"raw dimensions for {batch['path']}")
        try:
            with Image.open(raw_path) as opened:
                opened.load()
                if list(opened.size) != dimensions:
                    raise ValueError(f"raw dimensions mismatch: {raw_path}: {opened.size} versus {dimensions}")
        except UnidentifiedImageError as exc:
            raise ValueError(f"raw input is not a readable image: {raw_path}") from exc
        frames = batch.get("frames")
        if not isinstance(frames, list):
            raise ValueError(f"raw frames must be an array: {batch['path']}")
        for frame in frames:
            if not isinstance(frame, dict):
                raise ValueError("each raw frame must be an object")
            require_keys(frame, {"name", "bounds", "horizontal_offset"}, "raw frame")
            name = frame.get("name")
            if name not in NAMES or name in frame_map:
                raise ValueError(f"invalid or duplicate raw frame name: {name!r}")
            bounds = frame.get("bounds")
            if (
                not isinstance(bounds, list)
                or len(bounds) != 4
                or any(not isinstance(item, int) or isinstance(item, bool) for item in bounds)
            ):
                raise ValueError(f"bounds for {name} must be four integers")
            left, top, right, bottom = bounds
            if left < 0 or top < 0 or right <= left or bottom <= top or right > dimensions[0] or bottom > dimensions[1]:
                raise ValueError(f"bounds for {name} exceed raw image {dimensions}: {bounds}")
            offset = require_offset(frame.get("horizontal_offset", global_offset), f"horizontal_offset for {name}")
            frame_map[str(name)] = {
                "batch": batch,
                "raw_path": raw_path,
                "bounds": bounds,
                "horizontal_offset": offset,
            }
    if set(frame_map) != set(NAMES):
        raise ValueError("raw_batches must contain exactly all 15 canonical frame names")
    return config, {name: {"raw": frame_map[name], "svg": pair_map[name]} for name in NAMES}, dependency_path


def extract_cell(image: Image.Image, bounds: list[int], checker: Any) -> tuple[Image.Image, str]:
    cell = image.crop(tuple(bounds)).convert("RGBA")
    alpha = cell.getchannel("A")
    if alpha.getextrema() == (255, 255):
        mask = checker.neutral_background_mask(cell)
        if any(mask):
            original = alpha.tobytes()
            alpha.putdata([0 if mask[index] else original[index] for index in range(len(mask))])
            cell.putalpha(alpha)
            return cell, "neutral-connected-region"
    return cell, "source-alpha"


def register_one(cell: Image.Image, view: str, offset: int) -> tuple[Image.Image, dict[str, Any]]:
    bounds = cell.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError("raw cell has no visible pixels")
    figure = cell.crop(bounds)
    fitted_width = round(figure.width * 45 / figure.height)
    target_width, target_height = NATIVE[view]
    if fitted_width > target_width:
        raise ValueError(f"{view} pose is too wide at {fitted_width}px for {target_width}px canvas; redraw it")
    fitted = figure.resize((fitted_width, 45), Image.Resampling.LANCZOS)
    x = round((target_width - fitted_width) / 2) + offset
    if x < 0 or x + fitted_width > target_width:
        raise ValueError(f"horizontal offset places {view} outside its canvas: {offset}")
    output = Image.new("RGBA", (target_width, target_height))
    output.alpha_composite(fitted, (x, 1))
    return output, {
        "cell_visible_bounds": list(bounds),
        "visible_height": 45,
        "fitted_width": fitted_width,
        "horizontal_offset": offset,
    }


def prepare(config_path: Path) -> Prepared:
    config, rows, dependency_path = parse_config(config_path)
    checker = checker_module(dependency_path)
    cells: dict[str, Image.Image] = {}
    registered: dict[str, Image.Image] = {}
    extraction: dict[str, str] = {}
    measurements: dict[str, dict[str, Any]] = {}
    raw_inputs: dict[str, dict[str, Any]] = {}
    opened: dict[Path, Image.Image] = {}
    try:
        for name in NAMES:
            raw = rows[name]["raw"]
            batch = raw["batch"]
            raw_path = raw["raw_path"]
            if raw_path not in opened:
                with Image.open(raw_path) as source:
                    opened[raw_path] = source.convert("RGBA")
                    opened[raw_path].load()
                raw_inputs[batch["path"]] = {
                    "sha256": batch["sha256"],
                    "dimensions": batch["dimensions"],
                }
            cell, method = extract_cell(opened[raw_path], raw["bounds"], checker)
            view = name.removeprefix("mother_carrying_").rsplit("_", 1)[0]
            image, measurement = register_one(cell, view, raw["horizontal_offset"])
            cells[name] = cell
            registered[name] = image
            extraction[name] = method
            pair = rows[name]["svg"]
            measurements[name] = measurement | {
                "raw_path": batch["path"],
                "raw_bounds": raw["bounds"],
                "svg": pair["svg"],
                "svg_sha256": pair["svg_sha256"],
                "dimensions": list(image.size),
                "png": f"rig/{name}.png",
            }
    finally:
        for image in opened.values():
            image.close()
    dependency = config["checkerboard_remover"]
    return Prepared(
        config=config,
        config_sha256=sha256(config_path),
        cells=cells,
        registered=registered,
        extraction=extraction,
        measurements=measurements,
        raw_inputs=raw_inputs,
        dependency={"path": dependency["path"], "sha256": dependency["sha256"]},
    )


def draw_centered(draw: ImageDraw.ImageDraw, center_x: int, y: int, text: str, font: ImageFont.ImageFont) -> None:
    left, _, right, _ = draw.textbbox((0, 0), text, font=font)
    draw.text((center_x - (right - left) // 2, y), text, fill="white", font=font)


def direction_figure(images: dict[str, Image.Image], column: int, phase: str) -> Image.Image:
    view = VIEW_BY_DIRECTION[column]
    image = images[f"mother_carrying_{view}_{phase}"]
    return image.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if column >= 5 else image


def compose_direction_grid(images: dict[str, Image.Image], phases: tuple[str, ...], title: str) -> Image.Image:
    width = SHEET_LEFT + len(DIRECTIONS) * SHEET_COLUMN_WIDTH
    height = SHEET_TITLE_HEIGHT + SHEET_DIRECTION_HEIGHT + len(phases) * SHEET_ROW_HEIGHT + SHEET_FOOTER_HEIGHT
    sheet = Image.new("RGBA", (width, height), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    label_font = ImageFont.load_default()
    draw.text((2, 1), title, fill="white", font=label_font)
    row_top = SHEET_TITLE_HEIGHT + SHEET_DIRECTION_HEIGHT
    for column, label in enumerate(DIRECTION_LABELS):
        center_x = SHEET_LEFT + column * SHEET_COLUMN_WIDTH + SHEET_COLUMN_WIDTH // 2
        draw_centered(draw, center_x, SHEET_TITLE_HEIGHT, label, label_font)
        for row, phase in enumerate(phases):
            figure = direction_figure(images, column, phase)
            x = center_x - figure.width // 2
            y = row_top + row * SHEET_ROW_HEIGHT + SHEET_ROW_HEIGHT - 2 - figure.height
            sheet.alpha_composite(figure, (x, y))
    for row, phase in enumerate(phases):
        draw.text((2, row_top + row * SHEET_ROW_HEIGHT + 20), phase.upper(), fill="white", font=label_font)
    draw.text((2, height - SHEET_FOOTER_HEIGHT), "native pixels | west mirrors east", fill="white", font=label_font)
    return sheet


def compose_source_preview(cells: dict[str, Image.Image]) -> Image.Image:
    column_width, row_height = 300, 400
    title_height, footer_height = 28, 28
    sheet = Image.new(
        "RGBA", (column_width * len(VIEWS), title_height + row_height * len(PHASES) + footer_height), BACKGROUND
    )
    draw = ImageDraw.Draw(sheet)
    title_font = ImageFont.load_default(size=18)
    label_font = ImageFont.load_default(size=16)
    draw.text((6, 4), "F - Hip motion | fitted source cells", fill="white", font=title_font)
    for column, view in enumerate(VIEWS):
        for row, phase in enumerate(PHASES):
            name = f"mother_carrying_{view}_{phase}"
            image = cells[name]
            available_width, available_height = column_width - 16, row_height - 34
            scale = min(1.0, available_width / image.width, available_height / image.height)
            fitted = image.resize(
                (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
                Image.Resampling.LANCZOS,
            )
            cell_x = column * column_width
            cell_y = title_height + row * row_height
            draw.text(
                (cell_x + 6, cell_y + 4), f"{view} {phase.upper()} | fitted {scale:.3f}x", fill="white", font=label_font
            )
            sheet.alpha_composite(
                fitted,
                (cell_x + (column_width - fitted.width) // 2, cell_y + 30 + (available_height - fitted.height) // 2),
            )
    draw.text(
        (6, sheet.height - footer_height + 4),
        "Original-resolution extracted cells are saved under extracted/.",
        fill="white",
        font=label_font,
    )
    return sheet


def enlarge(image: Image.Image) -> Image.Image:
    return image.resize((image.width * 6, image.height * 6), Image.Resampling.NEAREST)


def animation_frames(images: dict[str, Image.Image]) -> list[Image.Image]:
    return [
        compose_direction_grid(images, (phase,), f"F - Hip motion | pose {phase.upper()}") for phase in ANIMATION_PHASES
    ]


def gif_bytes(frames: list[Image.Image], timing: int) -> bytes:
    stream = io.BytesIO()
    frames[0].save(
        stream,
        format="GIF",
        save_all=True,
        append_images=frames[1:],
        duration=[timing] * len(frames),
        loop=0,
        disposal=2,
        optimize=False,
    )
    return stream.getvalue()


def inspect_gif(source: Path | io.BytesIO) -> tuple[list[Image.Image], list[int], tuple[int, int]]:
    with Image.open(source) as gif:
        size = gif.size
        frames: list[Image.Image] = []
        durations: list[int] = []
        for frame in ImageSequence.Iterator(gif):
            frames.append(frame.convert("RGBA"))
            durations.append(int(frame.info.get("duration", -1)))
    return frames, durations, size


def write_png(path: Path, image: Image.Image) -> str:
    image.save(path, format="PNG", optimize=False)
    return sha256(path)


def register(config_path: Path, output: Path) -> None:
    if output.exists():
        raise ValueError(f"refusing to overwrite existing output path: {output}")
    prepared = prepare(config_path)
    timing = prepared.config["timing_ms"]
    source_preview = compose_source_preview(prepared.cells)
    registered_native = compose_direction_grid(
        prepared.registered, PHASES, "F - Hip motion | registered | 8 directions"
    )
    native_animation = animation_frames(prepared.registered)
    enlarged_animation = [enlarge(frame) for frame in native_animation]

    output.mkdir(parents=True)
    (output / "rig").mkdir()
    (output / "extracted").mkdir()
    hashes: dict[str, str] = {}
    for name in NAMES:
        hashes[f"rig/{name}.png"] = write_png(output / "rig" / f"{name}.png", prepared.registered[name])
        hashes[f"extracted/{name}.png"] = write_png(output / "extracted" / f"{name}.png", prepared.cells[name])
    hashes["extracted-preview.png"] = write_png(output / "extracted-preview.png", source_preview)
    hashes["registered-native.png"] = write_png(output / "registered-native.png", registered_native)
    hashes["registered-6x.png"] = write_png(output / "registered-6x.png", enlarge(registered_native))
    (output / "animation-native.gif").write_bytes(gif_bytes(native_animation, timing))
    hashes["animation-native.gif"] = sha256(output / "animation-native.gif")
    (output / "animation-6x.gif").write_bytes(gif_bytes(enlarged_animation, timing))
    hashes["animation-6x.gif"] = sha256(output / "animation-6x.gif")

    decoded_frames, durations, gif_size = inspect_gif(output / "animation-native.gif")
    manifest = {
        "recipe": "F - Hip motion",
        "config_sha256": prepared.config_sha256,
        "frames": list(NAMES),
        "frame_order": list(ANIMATION_PHASES),
        "directions": list(DIRECTIONS),
        "direction_views": list(VIEW_BY_DIRECTION),
        "west_mirror": "runtime mirrors east-authored views",
        "timing_ms": timing,
        "pillow_version": PILLOW_VERSION,
        "font": "Pillow embedded default bitmap font; labels are composed before nearest-neighbor enlargement",
        "checkerboard_remover": prepared.dependency,
        "raw_inputs": prepared.raw_inputs,
        "extraction": prepared.extraction,
        "measurements": prepared.measurements,
        "animation": {
            "frame_count": len(decoded_frames),
            "frame_size": list(gif_size),
            "durations_ms": durations,
            "decoded_rgba_sha256": [content_sha256(frame) for frame in decoded_frames],
        },
        "output_sha256": hashes,
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def assert_same_pixels(actual_path: Path, expected: Image.Image, description: str) -> None:
    with Image.open(actual_path) as opened:
        actual = opened.convert("RGBA")
        actual.load()
    if actual.size != expected.size or actual.tobytes() != expected.convert("RGBA").tobytes():
        raise ValueError(f"{description} does not match canonical composition: {actual_path}")


def verify_gif(path: Path, expected_frames: list[Image.Image], timing: int) -> tuple[list[str], list[int], list[int]]:
    actual, durations, size = inspect_gif(path)
    expected, _, expected_size = inspect_gif(io.BytesIO(gif_bytes(expected_frames, timing)))
    if len(actual) != 4:
        raise ValueError(f"GIF must contain four frames: {path}: found {len(actual)}")
    if size != expected_size or any(frame.size != expected_size for frame in actual):
        raise ValueError(f"GIF frames do not share the canonical canvas: {path}")
    if durations != [190, 190, 190, 190]:
        raise ValueError(f"GIF frame durations must all be 190ms: {path}: {durations}")
    if any(actual[index].tobytes() != expected[index].tobytes() for index in range(4)):
        raise ValueError(f"GIF does not contain the canonical A, C, B, C direction sheets: {path}")
    content_hashes = [content_sha256(frame) for frame in actual]
    if content_hashes[1] != content_hashes[3] or len(set(content_hashes)) != 3:
        raise ValueError(f"GIF must contain three distinct states in A, C, B, C order: {path}")
    return content_hashes, durations, list(size)


def verify(config_path: Path, registered_dir: Path, compare_to: Path | None) -> None:
    if not registered_dir.is_dir():
        raise ValueError(f"registered directory does not exist: {registered_dir}")
    prepared = prepare(config_path)
    manifest = load_json(registered_dir / "manifest.json", "registration manifest")
    if manifest.get("recipe") != "F - Hip motion" or manifest.get("config_sha256") != prepared.config_sha256:
        raise ValueError("manifest recipe or frozen config hash does not match")
    if manifest.get("frames") != list(NAMES) or manifest.get("timing_ms") != 190:
        raise ValueError("manifest frame catalogue or timing does not match the recipe")
    if manifest.get("frame_order") != list(ANIMATION_PHASES):
        raise ValueError("manifest frame order is not A, C, B, C")
    if manifest.get("directions") != list(DIRECTIONS) or manifest.get("direction_views") != list(VIEW_BY_DIRECTION):
        raise ValueError("manifest direction order does not match the runtime")
    if manifest.get("pillow_version") != PILLOW_VERSION or manifest.get("checkerboard_remover") != prepared.dependency:
        raise ValueError("manifest tool versions or dependency hash do not match the config")
    if (
        manifest.get("raw_inputs") != prepared.raw_inputs
        or manifest.get("extraction") != prepared.extraction
        or manifest.get("measurements") != prepared.measurements
    ):
        raise ValueError("manifest input, extraction, or registration records do not match the frozen sources")

    for name in NAMES:
        assert_same_pixels(
            registered_dir / "rig" / f"{name}.png", prepared.registered[name], f"registered frame {name}"
        )
        assert_same_pixels(registered_dir / "extracted" / f"{name}.png", prepared.cells[name], f"extracted cell {name}")
    source_preview = compose_source_preview(prepared.cells)
    registered_native = compose_direction_grid(
        prepared.registered, PHASES, "F - Hip motion | registered | 8 directions"
    )
    assert_same_pixels(registered_dir / "extracted-preview.png", source_preview, "extracted preview")
    assert_same_pixels(registered_dir / "registered-native.png", registered_native, "native registered sheet")
    assert_same_pixels(registered_dir / "registered-6x.png", enlarge(registered_native), "enlarged registered sheet")

    native_frames = animation_frames(prepared.registered)
    native_hashes, durations, frame_size = verify_gif(
        registered_dir / "animation-native.gif", native_frames, prepared.config["timing_ms"]
    )
    verify_gif(
        registered_dir / "animation-6x.gif",
        [enlarge(frame) for frame in native_frames],
        prepared.config["timing_ms"],
    )
    expected_animation = {
        "frame_count": 4,
        "frame_size": frame_size,
        "durations_ms": durations,
        "decoded_rgba_sha256": native_hashes,
    }
    if manifest.get("animation") != expected_animation:
        raise ValueError("manifest animation record does not match the decoded native GIF")

    output_hashes = manifest.get("output_sha256")
    if not isinstance(output_hashes, dict):
        raise ValueError("manifest output_sha256 must be an object")
    expected_outputs = {
        *(f"rig/{name}.png" for name in NAMES),
        *(f"extracted/{name}.png" for name in NAMES),
        "extracted-preview.png",
        "registered-native.png",
        "registered-6x.png",
        "animation-native.gif",
        "animation-6x.gif",
    }
    if set(output_hashes) != expected_outputs:
        raise ValueError("manifest output list is incomplete or contains unexpected files")
    for relative, expected_hash in output_hashes.items():
        if require_sha(expected_hash, f"output hash for {relative}") != sha256(registered_dir / relative):
            raise ValueError(f"output hash mismatch: {relative}")
    if compare_to is not None:
        other = load_json(compare_to / "manifest.json", "comparison manifest")
        if output_hashes != other.get("output_sha256"):
            raise ValueError("registered output differs from --compare-to")
    print("verified 15 registered frames, 15 extracted cells, direction sheets, and two four-frame GIFs")


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(
        description=__doc__,
        epilog="example: register.py register --config f-config.json --output-dir /tmp/f-registration",
        allow_abbrev=False,
    )
    sub = result.add_subparsers(dest="command", required=True)
    reg = sub.add_parser("register", help="extract, register and assemble review outputs", allow_abbrev=False)
    reg.add_argument(
        "--config", required=True, type=Path, help="frozen JSON manifest; relative inputs resolve beside it"
    )
    reg.add_argument("--output-dir", required=True, type=Path, help="new directory; existing paths are refused")
    check = sub.add_parser(
        "verify", help="rebuild expectations and verify retained outputs without writing", allow_abbrev=False
    )
    check.add_argument("--config", required=True, type=Path)
    check.add_argument("--registered-dir", required=True, type=Path)
    check.add_argument("--compare-to", type=Path, help="another retained registration directory")
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        if args.command == "register":
            register(args.config.resolve(), args.output_dir.resolve())
        else:
            verify(
                args.config.resolve(),
                args.registered_dir.resolve(),
                args.compare_to.resolve() if args.compare_to else None,
            )
    except (OSError, ValueError, KeyError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
