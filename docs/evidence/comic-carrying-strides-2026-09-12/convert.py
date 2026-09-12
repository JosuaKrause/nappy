#!/usr/bin/env -S uv run --project tools
"""Register E's generated A/C/B carrying atlas and build exact-frame review evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
D_RECORD = ROOT / "docs/evidence/comic-carrying-redraw-2026-09-12"
RAW = HERE / "raw/carrying-acb-selected.png"
SOURCE = HERE / "source"
REGISTERED = HERE / "registered"
RUNTIME = ROOT / "assets/illustrated/svg-transfer/rig"
VIEWS = ("front", "back", "side", "front_diagonal", "back_diagonal")
FRAMES = ("a", "c", "b")
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
FRAME_LABELS = {"a": "Contact 1 (A)", "c": "Passing (C)", "b": "Contact 2 (B)"}
BG = (89, 105, 112, 255)
INK = (245, 247, 248, 255)
FONT_PATH = Path("/System/Library/Fonts/SFNS.ttf")
FONT_SHA256 = "2bfd40dc72e6759e248f82a52a40d551338979fffc9b5c070e685b4b7ad19e66"


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


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    assert FONT_PATH.is_file() and _sha256(FONT_PATH) == FONT_SHA256, FONT_PATH
    return ImageFont.truetype(FONT_PATH, size)


def prepare() -> None:
    """Freeze every input identity so later registration fails on stale sources."""
    manifest_path = SOURCE / "source-pair-manifest.json"
    assert not manifest_path.exists(), f"manifest already exists: {manifest_path}"
    assert RAW.is_file(), RAW
    rows: list[dict[str, object]] = []
    for view in VIEWS:
        for frame in FRAMES:
            svg = ROOT / f"assets/rig/mother_carrying_{view}_{frame}.svg"
            native = SOURCE / "svg-rendered" / f"{view}_{frame}-native.png"
            enlarged = SOURCE / "svg-rendered" / f"{view}_{frame}-6x.png"
            identity_frame = "a" if frame == "a" else "b"
            identity = D_RECORD / "registered/rig" / f"mother_carrying_{view}_{identity_frame}.png"
            for path in (svg, native, enlarged, identity):
                assert path.is_file(), path
            with Image.open(native) as image:
                size = list(image.size)
            rows.append(
                {
                    "name": f"mother_carrying_{view}_{frame}",
                    "frame_role": FRAME_LABELS[frame],
                    "svg": str(svg.relative_to(ROOT)),
                    "svg_sha256": _sha256(svg),
                    "native_render": str(native.relative_to(ROOT)),
                    "native_render_sha256": _sha256(native),
                    "enlarged_render": str(enlarged.relative_to(ROOT)),
                    "enlarged_render_sha256": _sha256(enlarged),
                    "identity_source": str(identity.relative_to(ROOT)),
                    "identity_source_sha256": _sha256(identity),
                    "dimensions": size,
                    "ground_anchor": [size[0] // 2, size[1]],
                }
            )
    with Image.open(RAW) as atlas:
        assert atlas.size == (1380, 1140), atlas.size
    payload = {
        "version": "E — Clear strides",
        "loop": ["a", "c", "b", "c"],
        "raw": str(RAW.relative_to(ROOT)),
        "raw_sha256": _sha256(RAW),
        "raw_dimensions": [1380, 1140],
        "identity_target": "docs/evidence/comic-carrying-redraw-2026-09-12/carrying-atlas-selected.png",
        "identity_target_sha256": _sha256(D_RECORD / "carrying-atlas-selected.png"),
        "pose_authority": str((SOURCE / "svg-acb-6x.png").relative_to(ROOT)),
        "pose_authority_sha256": _sha256(SOURCE / "svg-acb-6x.png"),
        "review_font": str(FONT_PATH),
        "review_font_sha256": FONT_SHA256,
        "generation_history": [
            {
                "output": "docs/evidence/comic-carrying-strides-2026-09-12/raw/carrying-acb-pass1.png",
                "output_sha256": _sha256(HERE / "raw/carrying-acb-pass1.png"),
                "prompt": "docs/evidence/comic-carrying-strides-2026-09-12/prompt.txt",
                "prompt_sha256": _sha256(HERE / "prompt.txt"),
                "inputs": [
                    "docs/evidence/comic-carrying-redraw-2026-09-12/carrying-atlas-selected.png",
                    "docs/evidence/comic-carrying-strides-2026-09-12/source/svg-acb-6x.png",
                ],
            },
            {
                "output": "docs/evidence/comic-carrying-strides-2026-09-12/raw/carrying-acb-pass2.png",
                "output_sha256": _sha256(HERE / "raw/carrying-acb-pass2.png"),
                "prompt": "docs/evidence/comic-carrying-strides-2026-09-12/prompt-b-row.txt",
                "prompt_sha256": _sha256(HERE / "prompt-b-row.txt"),
                "inputs": [
                    "docs/evidence/comic-carrying-strides-2026-09-12/raw/carrying-acb-pass1.png",
                    "docs/evidence/comic-carrying-strides-2026-09-12/source/svg-acb-6x.png",
                ],
            },
            {
                "output": "docs/evidence/comic-carrying-strides-2026-09-12/raw/carrying-acb-selected.png",
                "output_sha256": _sha256(RAW),
                "prompt": "docs/evidence/comic-carrying-strides-2026-09-12/prompt-side-back-diagonal.txt",
                "prompt_sha256": _sha256(HERE / "prompt-side-back-diagonal.txt"),
                "inputs": [
                    "docs/evidence/comic-carrying-strides-2026-09-12/raw/carrying-acb-pass2.png",
                    "docs/evidence/comic-carrying-strides-2026-09-12/source/svg-acb-6x.png",
                ],
            },
        ],
        "rows": rows,
    }
    manifest_path.write_text(json.dumps(payload, indent=2) + "\n")


def _manifest() -> dict[str, object]:
    path = SOURCE / "source-pair-manifest.json"
    assert path.is_file(), path
    payload = json.loads(path.read_text())
    assert payload["loop"] == ["a", "c", "b", "c"]
    assert _sha256(RAW) == payload["raw_sha256"], "generated atlas changed"
    assert _sha256(D_RECORD / "carrying-atlas-selected.png") == payload["identity_target_sha256"]
    assert _sha256(SOURCE / "svg-acb-6x.png") == payload["pose_authority_sha256"]
    assert _sha256(Path(payload["review_font"])) == payload["review_font_sha256"]
    for generation in payload["generation_history"]:
        assert _sha256(ROOT / generation["output"]) == generation["output_sha256"]
        assert _sha256(ROOT / generation["prompt"]) == generation["prompt_sha256"]
    rows = payload["rows"]
    assert isinstance(rows, list) and len(rows) == 15
    for row in rows:
        for path_key, hash_key in (
            ("svg", "svg_sha256"),
            ("native_render", "native_render_sha256"),
            ("enlarged_render", "enlarged_render_sha256"),
            ("identity_source", "identity_source_sha256"),
        ):
            assert _sha256(ROOT / row[path_key]) == row[hash_key], f"stale input: {row[path_key]}"
    return payload


def _cell(atlas: Image.Image, column: int, row: int) -> Image.Image:
    return atlas.crop(
        (
            round(column * atlas.width / 5),
            round(row * atlas.height / 3),
            round((column + 1) * atlas.width / 5),
            round((row + 1) * atlas.height / 3),
        )
    )


def _bounds(image: Image.Image) -> tuple[int, int, int, int]:
    bounds = image.getchannel("A").point(lambda value: 255 if value > 192 else 0).getbbox()
    assert bounds, "empty generated cell"
    assert bounds[2] - bounds[0] > image.width // 3, bounds
    assert bounds[3] - bounds[1] > image.height * 3 // 4, bounds
    return bounds


def _register(subject: Image.Image, view: str, frame: str, palette: Image.Image) -> tuple[Image.Image, dict[str, object]]:
    native_path = SOURCE / "svg-rendered" / f"{view}_{frame}-native.png"
    enlarged_path = SOURCE / "svg-rendered" / f"{view}_{frame}-6x.png"
    native = Image.open(native_path).convert("RGBA")
    template = Image.open(enlarged_path).convert("RGBA")
    scale = ((native.height - 1) * 6) / subject.height
    fitted_size = (round(subject.width * scale), round(subject.height * scale))
    assert fitted_size[0] <= template.width, (view, frame, fitted_size, template.size)
    fitted = subject.resize(fitted_size, Image.Resampling.LANCZOS)
    x = round((template.width - fitted.width) / 2)
    y = template.height - fitted.height
    assert x >= 0 and y >= 0
    staged = Image.new("RGBA", template.size, (0, 0, 0, 0))
    staged.alpha_composite(fitted, (x, y))
    staged = staged.resize(native.size, Image.Resampling.LANCZOS)
    generated_alpha = staged.getchannel("A")
    extender = _module(
        "color_extender",
        ROOT / "docs/evidence/style-transfer-2026-09-10/register-transfer.py",
    )
    final = extender.extend_colors(staged).quantize(
        palette=palette, dither=Image.Dither.NONE
    ).convert("RGBA")
    final.putalpha(generated_alpha)

    identity_frame = "a" if frame == "a" else "b"
    identity = Image.open(
        D_RECORD / "registered/rig" / f"mother_carrying_{view}_{identity_frame}.png"
    ).convert("RGBA")
    assert identity.size == final.size
    # D remains byte-exact above the coat hem; generated pixels supply only the legs and shoes.
    cut = 34
    final.paste(identity.crop((0, 0, identity.width, cut)), (0, 0))
    alpha = final.getchannel("A")
    alpha_bounds = alpha.getbbox()
    assert alpha_bounds and alpha_bounds[3] == native.height, (view, frame, alpha_bounds)
    assert any(value == 0 for value in alpha.get_flattened_data())
    return final, {
        "name": f"mother_carrying_{view}_{frame}",
        "size": list(native.size),
        "generated_cell_bounds": list(_bounds(subject)),
        "registered_alpha_bounds": list(alpha_bounds),
        "upper_identity_source": f"D {identity_frame.upper()}",
        "upper_rows_preserved": [0, cut - 1],
        "generated_alpha_preserved_before_upper_composite": True,
        "ground_line_preserved": True,
        "fit_scale": scale,
    }


def _place(sheet: Image.Image, sprite: Image.Image, center_x: int, ground_y: int) -> None:
    sheet.alpha_composite(sprite, (center_x - sprite.width // 2, ground_y - sprite.height))


def _sprite(output: Path, view: str, frame: str, mirror: bool) -> Image.Image:
    image = Image.open(output / "rig" / f"mother_carrying_{view}_{frame}.png").convert("RGBA")
    return image.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if mirror else image


def _review_ordered(output: Path) -> None:
    cell_w, cell_h = 54, 60
    left, title, header = 34, 24, 20
    sheet = Image.new("RGBA", (left + cell_w * 8, title + header + cell_h * 3), BG)
    draw = ImageDraw.Draw(sheet)
    draw.text((5, 5), "E — Clear strides · PNG animation source frames", font=_font(12), fill=INK)
    for column, (label, _view, _mirror) in enumerate(DIRECTIONS):
        draw.text((left + column * cell_w + 18, title + 3), label, font=_font(10), fill=INK)
    for row, frame in enumerate(FRAMES):
        draw.text((3, title + header + row * cell_h + 23), frame.upper(), font=_font(10), fill=INK)
        for column, (_label, view, mirror) in enumerate(DIRECTIONS):
            _place(
                sheet,
                _sprite(output, view, frame, mirror),
                left + column * cell_w + cell_w // 2,
                title + header + row * cell_h + 55,
            )
    sheet.save(output / "e-frames-native.png")
    sheet.resize((sheet.width * 6, sheet.height * 6), Image.Resampling.NEAREST).save(
        output / "e-frames-6x.png"
    )


def _review_raw_b(atlas: Image.Image, destination: Path) -> None:
    cell_w, cell_h = 270, 385
    title = 44
    sheet = Image.new("RGBA", (cell_w * 5, title + cell_h), BG)
    draw = ImageDraw.Draw(sheet)
    draw.text((16, 10), "E — Clear strides · selected raw Contact 2 (B), unmirrored", font=_font(22), fill=INK)
    for column, view in enumerate(VIEWS):
        cell = _cell(atlas, column, 2)
        subject = cell.crop(_bounds(cell))
        scale = min(240 / subject.width, 340 / subject.height)
        fitted = subject.resize(
            (round(subject.width * scale), round(subject.height * scale)), Image.Resampling.LANCZOS
        )
        x = column * cell_w + (cell_w - fitted.width) // 2
        y = title + cell_h - fitted.height - 10
        sheet.alpha_composite(fitted, (x, y))
        draw.text((column * cell_w + 8, title + 6), view.replace("_", " "), font=_font(16), fill=INK)
    sheet.save(destination)


def _animation_frame(output: Path, frame: str) -> Image.Image:
    cell_w, cell_h = 54, 62
    title = 28
    sheet = Image.new("RGBA", (cell_w * 4, title + cell_h * 2), BG)
    draw = ImageDraw.Draw(sheet)
    draw.text((5, 5), "E — Clear strides · PNG animation", font=_font(11), fill=INK)
    for index, (label, view, mirror) in enumerate(DIRECTIONS):
        column, row = index % 4, index // 4
        draw.text((column * cell_w + 3, title + row * cell_h + 2), label, font=_font(9), fill=INK)
        _place(
            sheet,
            _sprite(output, view, frame, mirror),
            column * cell_w + cell_w // 2,
            title + row * cell_h + 59,
        )
    return sheet


def _review_animation(output: Path) -> None:
    frames = [_animation_frame(output, frame) for frame in ("a", "c", "b", "c")]
    frames[0].save(
        output / "e-animation-native.gif",
        save_all=True,
        append_images=frames[1:],
        duration=[190, 190, 190, 190],
        loop=0,
        disposal=2,
    )
    enlarged = [frame.resize((frame.width * 6, frame.height * 6), Image.Resampling.NEAREST) for frame in frames]
    enlarged[0].save(
        output / "e-animation-6x.gif",
        save_all=True,
        append_images=enlarged[1:],
        duration=[190, 190, 190, 190],
        loop=0,
        disposal=2,
    )


def register(output: Path) -> None:
    _manifest()
    assert not output.exists(), f"registration exists: {output}"
    output.mkdir(parents=True)
    (output / "rig").mkdir()
    checker = _module("checker", ROOT / "tools/remove-checkerboard.py")
    if output == REGISTERED:
        extracted = HERE / "extracted/carrying-acb-extracted.png"
        extracted.parent.mkdir()
        raw_preview = HERE / "raw/b-row-selected-preview.png"
    else:
        extracted = output / "carrying-acb-extracted.png"
        raw_preview = output / "b-row-selected-preview.png"
    checker.extract(RAW, extracted)
    atlas = Image.open(extracted).convert("RGBA")
    _review_raw_b(atlas, raw_preview)
    palette = Image.open(D_RECORD / "registered/shared-palette.png")
    measurements: list[dict[str, object]] = []
    for row, frame in enumerate(FRAMES):
        for column, view in enumerate(VIEWS):
            cell = _cell(atlas, column, row)
            subject = cell.crop(_bounds(cell))
            final, measurement = _register(subject, view, frame, palette)
            final.save(output / "rig" / f"mother_carrying_{view}_{frame}.png")
            measurements.append(measurement)
    (output / "registration.json").write_text(json.dumps(measurements, indent=2) + "\n")
    _review_ordered(output)
    _review_animation(output)


def install() -> None:
    _manifest()
    assert REGISTERED.is_dir(), REGISTERED
    for view in VIEWS:
        for frame in FRAMES:
            source = REGISTERED / "rig" / f"mother_carrying_{view}_{frame}.png"
            destination = RUNTIME / source.name
            assert source.is_file(), source
            shutil.copy2(source, destination)


def verify(registered: Path, compare_to: Path | None = None) -> None:
    """Assert that registered and installed files still match the frozen recipe."""
    _manifest()
    for view in VIEWS:
        for frame in FRAMES:
            registered_png = registered / "rig" / f"mother_carrying_{view}_{frame}.png"
            image = Image.open(registered_png).convert("RGBA")
            expected_width = 24 if view in ("front", "back") else 26
            assert image.size == (expected_width, 46), (registered_png, image.size)
            assert image.getchannel("A").getbbox()[3] == 46, registered_png
            identity_frame = "a" if frame == "a" else "b"
            identity = Image.open(
                D_RECORD / "registered/rig" / f"mother_carrying_{view}_{identity_frame}.png"
            ).convert("RGBA")
            assert image.crop((0, 0, image.width, 34)).tobytes() == identity.crop(
                (0, 0, identity.width, 34)
            ).tobytes(), registered_png
    for gif_name in ("e-animation-native.gif", "e-animation-6x.gif"):
        animation = Image.open(registered / gif_name)
        assert animation.n_frames == 4, gif_name
        durations: list[int] = []
        for index in range(animation.n_frames):
            animation.seek(index)
            durations.append(int(animation.info["duration"]))
        assert durations == [190, 190, 190, 190], (gif_name, durations)
    if compare_to is not None:
        expected = [
            path.relative_to(compare_to)
            for path in compare_to.rglob("*")
            if path.is_file()
        ]
        for relative in expected:
            rebuilt = registered / relative
            retained = compare_to / relative
            assert _sha256(rebuilt) == _sha256(retained), relative


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("prepare")
    register_parser = commands.add_parser("register")
    register_parser.add_argument("--output-dir", type=Path, default=REGISTERED)
    commands.add_parser("install")
    verify_parser = commands.add_parser("verify")
    verify_parser.add_argument("--registered-dir", type=Path, default=REGISTERED)
    verify_parser.add_argument("--compare-to", type=Path)
    args = parser.parse_args()
    if args.command == "prepare":
        prepare()
    elif args.command == "register":
        register(args.output_dir.resolve())
    elif args.command == "install":
        install()
    else:
        compare_to = args.compare_to.resolve() if args.compare_to else None
        verify(args.registered_dir.resolve(), compare_to)


if __name__ == "__main__":
    main()
