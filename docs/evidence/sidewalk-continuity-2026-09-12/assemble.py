"""Prepare, register, and review the sidewalk-continuity tile family."""

from __future__ import annotations

import argparse
import hashlib
import json
import platform
import subprocess
from pathlib import Path
from typing import Any, Final, cast

from PIL import Image, ImageDraw, ImageFont
from PIL import __version__ as pillow_version

HERE: Final = Path(__file__).resolve().parent
ROOT: Final = HERE.parents[2]
RASTERIZER: Final = ROOT / "docs/evidence/style-transfer-2026-09-10/rasterize-svg.gd"
GODOT: Final = Path("/Applications/Godot.app/Contents/MacOS/Godot")
RUNTIME_TILES: Final = ROOT / "assets/illustrated/svg-transfer/tiles"
SVG_TILES: Final = ROOT / "assets/tiles"
NATIVE: Final = 32
REVIEW_SCALE: Final = 6
BACKGROUND: Final = (46, 54, 58, 255)
TEXT: Final = (245, 241, 228, 255)

TARGETS: Final = (
    "sidewalk",
    "sidewalk_cracked_hairline_a",
    "sidewalk_cracked_hairline_b",
    "sidewalk_cracked_cracked_a",
    "sidewalk_cracked_cracked_b",
    "sidewalk_cracked_broken_a",
    "sidewalk_cracked_broken_b",
)
CONTROLS: Final = (
    "sidewalk_kerb_n",
    "sidewalk_kerb_e",
    "sidewalk_kerb_s",
    "sidewalk_kerb_w",
    "sidewalk_kerb_main_n",
    "sidewalk_kerb_main_e",
    "sidewalk_kerb_main_s",
    "sidewalk_kerb_main_w",
)
ROADS: Final = ("road", "road_main")
SOURCE_NAMES: Final = TARGETS + CONTROLS + ROADS


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _fresh_directory(path: Path) -> None:
    if path.exists():
        raise FileExistsError(f"refusing to overwrite existing evidence: {path}")
    path.mkdir(parents=True)


def _rasterize(source: Path, destination: Path, scale: int) -> None:
    subprocess.run(
        [
            str(GODOT),
            "--headless",
            "--path",
            str(ROOT),
            "--script",
            str(RASTERIZER),
            "--",
            str(source),
            str(destination),
            str(scale),
        ],
        check=True,
        timeout=30,
    )


def _load(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    if image.size != (NATIVE, NATIVE):
        raise ValueError(f"tile is not {NATIVE}x{NATIVE}: {path} ({image.size})")
    if image.getchannel("A").getextrema() != (255, 255):
        raise ValueError(f"ground tile is not opaque: {path}")
    return image


def _enlarge(source: Path, destination: Path) -> None:
    image = Image.open(source).convert("RGBA")
    image.resize(
        (image.width * REVIEW_SCALE, image.height * REVIEW_SCALE),
        Image.Resampling.NEAREST,
    ).save(destination)


def _font() -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    return ImageFont.load_default()


def _draw_label(draw: ImageDraw.ImageDraw, at: tuple[int, int], label: str) -> None:
    draw.text(at, label, fill=TEXT, font=_font())


def _neighbor_strip(
    sidewalk: Image.Image,
    control: Image.Image,
    road: Image.Image,
    direction: str,
) -> Image.Image:
    if direction == "n":
        images = (road, control, sidewalk)
        strip = Image.new("RGBA", (NATIVE, NATIVE * 3))
        for index, image in enumerate(images):
            strip.alpha_composite(image, (0, index * NATIVE))
        return strip
    if direction == "s":
        images = (sidewalk, control, road)
        strip = Image.new("RGBA", (NATIVE, NATIVE * 3))
        for index, image in enumerate(images):
            strip.alpha_composite(image, (0, index * NATIVE))
        return strip
    if direction == "w":
        images = (road, control, sidewalk)
    elif direction == "e":
        images = (sidewalk, control, road)
    else:
        raise ValueError(f"unknown curb direction: {direction}")
    strip = Image.new("RGBA", (NATIVE * 3, NATIVE))
    for index, image in enumerate(images):
        strip.alpha_composite(image, (index * NATIVE, 0))
    return strip


def _edge_panel(
    sidewalk: Image.Image,
    controls: dict[str, Image.Image],
    roads: dict[str, Image.Image],
) -> Image.Image:
    cell = 128
    panel = Image.new("RGBA", (cell * 4, cell * 2), BACKGROUND)
    draw = ImageDraw.Draw(panel)
    for index, name in enumerate(CONTROLS):
        direction = name[-1]
        road_name = "road_main" if "_main_" in name else "road"
        strip = _neighbor_strip(
            sidewalk,
            controls[name],
            roads[road_name],
            direction,
        )
        cell_x, cell_y = index % 4 * cell, index // 4 * cell
        x = cell_x + (cell - strip.width) // 2
        y = cell_y + 22 + (cell - 22 - strip.height) // 2
        panel.alpha_composite(strip, (x, y))
        _draw_label(draw, (cell_x + 3, cell_y + 3), name.removeprefix("sidewalk_"))
    return panel


def _target_panel(tiles: dict[str, Image.Image]) -> Image.Image:
    cell = 96
    panel = Image.new("RGBA", (cell * 4, cell * 2), BACKGROUND)
    draw = ImageDraw.Draw(panel)
    for index, name in enumerate(TARGETS):
        x, y = index % 4 * cell, index // 4 * cell
        panel.alpha_composite(tiles[name], (x + 32, y + 30))
        _draw_label(draw, (x + 3, y + 3), name.removeprefix("sidewalk_"))
    return panel


def _control_panel(tiles: dict[str, Image.Image]) -> Image.Image:
    cell = 96
    panel = Image.new("RGBA", (cell * 4, cell * 2), BACKGROUND)
    draw = ImageDraw.Draw(panel)
    for index, name in enumerate(CONTROLS):
        x, y = index % 4 * cell, index // 4 * cell
        panel.alpha_composite(tiles[name], (x + 32, y + 30))
        _draw_label(draw, (x + 3, y + 3), name.removeprefix("sidewalk_"))
    return panel


def _damage_center_panel(tiles: dict[str, Image.Image]) -> Image.Image:
    cell = 112
    panel = Image.new("RGBA", (cell * 3, cell * 2), BACKGROUND)
    draw = ImageDraw.Draw(panel)
    plain = tiles["sidewalk"]
    for index, name in enumerate(TARGETS[1:]):
        x, y = index % 3 * cell, index // 3 * cell
        for repeat_y in range(3):
            for repeat_x in range(3):
                image = tiles[name] if (repeat_x, repeat_y) == (1, 1) else plain
                panel.alpha_composite(image, (x + 8 + repeat_x * NATIVE, y + 15 + repeat_y * NATIVE))
        _draw_label(draw, (x + 3, y + 3), name.removeprefix("sidewalk_cracked_"))
    return panel


def _repetition_panel(tiles: dict[str, Image.Image]) -> Image.Image:
    cell = 136
    panel = Image.new("RGBA", (cell * 3, cell * 2), BACKGROUND)
    draw = ImageDraw.Draw(panel)
    for index, name in enumerate(TARGETS[1:]):
        x, y = index % 3 * cell, index // 3 * cell
        for repeat_y in range(3):
            for repeat_x in range(3):
                panel.alpha_composite(tiles[name], (x + 20 + repeat_x * NATIVE, y + 20 + repeat_y * NATIVE))
        _draw_label(draw, (x + 3, y + 3), name.removeprefix("sidewalk_cracked_"))
    return panel


def _save_pair(image: Image.Image, native_path: Path) -> None:
    image.save(native_path)
    _enlarge(native_path, native_path.with_name(native_path.stem + "-6x.png"))


def _protected_paths() -> tuple[Path, ...]:
    paths: list[Path] = []
    for name in CONTROLS + ROADS:
        paths.extend((SVG_TILES / f"{name}.svg", RUNTIME_TILES / f"{name}.png"))
    return tuple(paths)


def _authority() -> dict[str, Any]:
    return cast(dict[str, Any], json.loads((HERE / "source-manifest.json").read_text()))


def _assert_hash(path: Path, expected: str, role: str) -> None:
    actual = _sha256(path)
    if actual != expected:
        raise ValueError(f"{role} changed: {path} ({expected} != {actual})")


def _verify_source_authority(before_dir: Path | None = None) -> None:
    authority = _authority()
    rasterizer = authority["rasterizer"]
    assert isinstance(rasterizer, dict)
    _assert_hash(ROOT / str(rasterizer["path"]), str(rasterizer["sha256"]), "rasterizer")
    if platform.python_version() != authority["python"]:
        raise ValueError(f"Python version changed: {authority['python']} != {platform.python_version()}")
    if pillow_version != authority["pillow_version"]:
        raise ValueError(f"Pillow version changed: {authority['pillow_version']} != {pillow_version}")
    godot_version = subprocess.run([str(GODOT), "--version"], check=True, capture_output=True, text=True).stdout.strip()
    if godot_version != authority["godot_version"]:
        raise ValueError(f"Godot version changed: {authority['godot_version']} != {godot_version}")
    for record in authority["svg_sources"].values():
        assert isinstance(record, dict)
        relative = str(record["path"])
        _assert_hash(ROOT / relative, str(record["sha256"]), "SVG source")
    for relative, expected in authority["protected_inputs"].items():
        _assert_hash(ROOT / relative, str(expected), "protected input")
    for relative, expected in authority["reference_inputs"].items():
        _assert_hash(ROOT / relative, str(expected), "generation reference")
    if before_dir is not None:
        for relative, expected in authority["before_targets"].items():
            _assert_hash(before_dir / Path(relative).name, str(expected), "before target")


def prepare(output_dir: Path, before_dir: Path) -> None:
    _verify_source_authority(before_dir)
    _fresh_directory(output_dir)
    source = output_dir / "source"
    before = output_dir / "before"
    source.mkdir()
    before.mkdir()

    source_tiles: dict[str, Image.Image] = {}
    for name in SOURCE_NAMES:
        svg = SVG_TILES / f"{name}.svg"
        native = source / f"{name}-svg.png"
        enlarged = source / f"{name}-svg-6x.png"
        _rasterize(svg, native, 1)
        _rasterize(svg, enlarged, REVIEW_SCALE)
        source_tiles[name] = _load(native)
        if Image.open(enlarged).size != (NATIVE * REVIEW_SCALE, NATIVE * REVIEW_SCALE):
            raise ValueError(f"enlarged SVG render has wrong size: {enlarged}")

    _save_pair(_target_panel({name: source_tiles[name] for name in TARGETS}), source / "targets-native.png")
    source_controls = {name: source_tiles[name] for name in CONTROLS}
    source_edge = _edge_panel(
        source_tiles["sidewalk"],
        source_controls,
        {name: source_tiles[name] for name in ROADS},
    )
    _save_pair(source_edge, source / "edge-neighbors-native.png")

    current = {name: _load(before_dir / f"{name}.png") for name in TARGETS}
    controls = {name: _load(RUNTIME_TILES / f"{name}.png") for name in CONTROLS}
    _save_pair(_control_panel(controls), source / "accepted-controls-native.png")
    _save_pair(_target_panel(current), before / "targets-native.png")
    runtime_roads = {name: _load(RUNTIME_TILES / f"{name}.png") for name in ROADS}
    _save_pair(
        _edge_panel(current["sidewalk"], controls, runtime_roads),
        before / "edge-neighbors-native.png",
    )
    _save_pair(_damage_center_panel(current), before / "damaged-centers-native.png")
    _save_pair(_repetition_panel(current), before / "damaged-repetition-native.png")

    (output_dir / "source-manifest.json").write_bytes((HERE / "source-manifest.json").read_bytes())
    _verify_source_authority(before_dir)


def _verify_protected() -> None:
    manifest = _authority()
    for relative, expected in manifest["protected_inputs"].items():
        path = ROOT / relative
        actual = _sha256(path)
        if actual != expected:
            raise ValueError(f"protected input changed: {relative} ({expected} != {actual})")


def _generation_inputs(name: str) -> list[dict[str, str]]:
    if name == "sidewalk":
        paths = (
            ("edit target and exact material authority", RUNTIME_TILES / "sidewalk_kerb_n.png"),
            ("SVG-derived functional source", HERE / "source/sidewalk-svg-6x.png"),
            ("accepted curb-family material reference", HERE / "source/accepted-controls-native-6x.png"),
            ("approved comic urban style reference", ROOT / "docs/evidence/graphics-reference-urban-01.jpeg"),
            ("approved cardinal gameplay style reference", ROOT / "docs/evidence/graphics-reference-cardinal.jpeg"),
        )
    else:
        paths = (
            ("edit target and exact family base", HERE / "generated/sidewalk.png"),
            ("SVG-derived damage source", HERE / f"source/{name}-svg-6x.png"),
            ("accepted curb-family material reference", HERE / "source/accepted-controls-native-6x.png"),
            ("approved comic urban style reference", ROOT / "docs/evidence/graphics-reference-urban-01.jpeg"),
            ("approved cardinal gameplay style reference", ROOT / "docs/evidence/graphics-reference-cardinal.jpeg"),
        )
    return [{"role": role, "path": str(path.relative_to(ROOT)), "sha256": _sha256(path)} for role, path in paths]


def _registration_authority(compare_to: Path) -> dict[str, Any]:
    authority_path = compare_to / "registration.json"
    if not authority_path.is_file():
        raise FileNotFoundError(f"registration authority is missing: {authority_path}")
    return cast(dict[str, Any], json.loads(authority_path.read_text()))


def _verify_registration_inputs(authority: dict[str, Any]) -> None:
    _verify_source_authority()
    registration = authority["registration"]
    assert isinstance(registration, dict)
    if registration["pillow_version"] != pillow_version:
        raise ValueError(f"Pillow version changed: {registration['pillow_version']} != {pillow_version}")
    if registration["font"] != "Pillow ImageFont.load_default()":
        raise ValueError(f"unexpected font authority: {registration['font']}")
    records = authority["tiles"]
    assert isinstance(records, list)
    if [record["name"] for record in records] != list(TARGETS):
        raise ValueError("registration authority has an unexpected tile list or order")
    for record in records:
        assert isinstance(record, dict)
        raw_path = ROOT / str(record["raw"])
        _assert_hash(raw_path, str(record["raw_sha256"]), "generated raw")
        with Image.open(raw_path) as raw:
            if list(raw.size) != record["raw_dimensions"]:
                raise ValueError(
                    f"generated raw dimensions changed: {raw_path} ({record['raw_dimensions']} != {list(raw.size)})"
                )
        prompt_path = ROOT / str(record["prompt"])
        _assert_hash(prompt_path, str(record["prompt_sha256"]), "prompt")
        for source in record["generation_inputs"]:
            assert isinstance(source, dict)
            _assert_hash(ROOT / str(source["path"]), str(source["sha256"]), str(source["role"]))


def register(output_dir: Path, compare_to: Path) -> None:
    authority = _registration_authority(compare_to)
    _verify_registration_inputs(authority)
    generated = HERE / "generated"
    _fresh_directory(output_dir)
    tiles_dir = output_dir / "tiles"
    tiles_dir.mkdir()
    tiles: dict[str, Image.Image] = {}
    records = []
    for name in TARGETS:
        raw_path = generated / f"{name}.png"
        raw = Image.open(raw_path).convert("RGBA")
        if raw.width != raw.height:
            raise ValueError(f"generated tile is not square: {raw_path} ({raw.size})")
        bounds = (0, 0, raw.width, raw.height)
        tile = raw.crop(bounds).resize((NATIVE, NATIVE), Image.Resampling.LANCZOS)
        tile.putalpha(255)
        destination = tiles_dir / f"{name}.png"
        tile.save(destination)
        tiles[name] = tile
        records.append(
            {
                "name": name,
                "raw": str(raw_path.relative_to(ROOT)),
                "raw_sha256": _sha256(raw_path),
                "raw_dimensions": list(raw.size),
                "normalized_cell": [0.0, 0.0, 1.0, 1.0],
                "fixed_crop": list(bounds),
                "resampling": "Pillow Image.Resampling.LANCZOS",
                "native_dimensions": [NATIVE, NATIVE],
                "opaque": tile.getchannel("A").getextrema() == (255, 255),
                "source_svg": f"assets/tiles/{name}.svg",
                "prompt": str((HERE / "prompts" / f"{name}.txt").relative_to(ROOT)),
                "prompt_sha256": _sha256(HERE / "prompts" / f"{name}.txt"),
                "generation_inputs": _generation_inputs(name),
            }
        )
    (output_dir / "registration.json").write_text(
        json.dumps(
            {
                "generation": {
                    "tool": "built-in imagegen",
                    "model_identifier": "not exposed by the built-in tool",
                    "deterministic": False,
                },
                "registration": {
                    "fixed_crop": "full saved square output",
                    "resampling": "Pillow Image.Resampling.LANCZOS",
                    "native_dimensions": [NATIVE, NATIVE],
                    "opaque": True,
                    "pillow_version": pillow_version,
                    "font": "Pillow ImageFont.load_default()",
                },
                "tiles": records,
            },
            indent=2,
        )
        + "\n"
    )
    controls = {name: _load(RUNTIME_TILES / f"{name}.png") for name in CONTROLS}
    _save_pair(_target_panel(tiles), output_dir / "targets-native.png")
    runtime_roads = {name: _load(RUNTIME_TILES / f"{name}.png") for name in ROADS}
    _save_pair(
        _edge_panel(tiles["sidewalk"], controls, runtime_roads),
        output_dir / "edge-neighbors-native.png",
    )
    _save_pair(_damage_center_panel(tiles), output_dir / "damaged-centers-native.png")
    _save_pair(_repetition_panel(tiles), output_dir / "damaged-repetition-native.png")
    _verify_registration_inputs(authority)


def verify(registered_dir: Path, compare_to: Path) -> None:
    if not registered_dir.is_dir():
        raise FileNotFoundError(f"registered directory is missing: {registered_dir}")
    if not compare_to.is_dir():
        raise FileNotFoundError(f"comparison directory is missing: {compare_to}")
    actual = {path.relative_to(registered_dir) for path in registered_dir.rglob("*") if path.is_file()}
    expected = {path.relative_to(compare_to) for path in compare_to.rglob("*") if path.is_file()}
    if actual != expected:
        raise ValueError(
            f"registered file set differs: missing={sorted(expected - actual)!r}, extra={sorted(actual - expected)!r}"
        )
    for relative in sorted(expected):
        rebuilt = registered_dir / relative
        retained = compare_to / relative
        _assert_hash(rebuilt, _sha256(retained), "registered output")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    prepare_parser = subparsers.add_parser(
        "prepare", help="render SVG sources and assemble before panels in a new directory"
    )
    prepare_parser.add_argument("--output-dir", type=Path, required=True)
    prepare_parser.add_argument("--before-dir", type=Path, required=True)
    register_parser = subparsers.add_parser(
        "register", help="register saved generated tiles and review panels in a new directory"
    )
    register_parser.add_argument("--output-dir", type=Path, required=True)
    register_parser.add_argument("--compare-to", type=Path, default=HERE / "registered")
    verify_parser = subparsers.add_parser(
        "verify", help="byte-compare a rebuilt registered directory with retained evidence"
    )
    verify_parser.add_argument("--registered-dir", type=Path, required=True)
    verify_parser.add_argument("--compare-to", type=Path, default=HERE / "registered")
    subparsers.add_parser("verify-controls", help="verify accepted curb and road inputs are unchanged")
    arguments = parser.parse_args()
    if arguments.command == "prepare":
        prepare(arguments.output_dir, arguments.before_dir)
    elif arguments.command == "register":
        register(arguments.output_dir, arguments.compare_to)
    elif arguments.command == "verify":
        verify(arguments.registered_dir, arguments.compare_to)
    else:
        _verify_protected()


if __name__ == "__main__":
    main()
