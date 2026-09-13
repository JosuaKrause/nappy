#!/usr/bin/env python3
"""Crop the retained F atlas into whole-row A and C image-generation inputs."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

from PIL import Image, UnidentifiedImageError
from PIL import __version__ as PILLOW_VERSION

HERE = Path(__file__).resolve().parent
DEFAULT_INPUT = HERE / "raw/carrying-f-selected.png"
EXPECTED_INPUT_SHA256 = "27ba7489bf0efbf9e475c72bbd7f7670841c7111a0703355641122873ad8f7fb"
EXPECTED_INPUT_SIZE = (1380, 1140)
EXPECTED_PILLOW_VERSION = "12.3.0"
ROWS = {
    "a": (0, 0, 1380, 400),
    "c": (0, 400, 1380, 755),
}


def sha256(path: Path) -> str:
    if not path.is_file():
        raise ValueError(f"input does not exist: {path}")
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare(source: Path) -> dict[str, Image.Image]:
    if PILLOW_VERSION != EXPECTED_PILLOW_VERSION:
        raise ValueError(f"Pillow version mismatch: expected {EXPECTED_PILLOW_VERSION}, running {PILLOW_VERSION}")
    actual_hash = sha256(source)
    if actual_hash != EXPECTED_INPUT_SHA256:
        raise ValueError(f"input hash mismatch: {source}: {actual_hash}")
    try:
        with Image.open(source) as opened:
            opened.load()
            if opened.size != EXPECTED_INPUT_SIZE:
                raise ValueError(f"input dimensions mismatch: {source}: {opened.size} versus {EXPECTED_INPUT_SIZE}")
            image = opened.copy()
    except UnidentifiedImageError as exc:
        raise ValueError(f"input is not a readable image: {source}") from exc
    return {name: image.crop(bounds) for name, bounds in ROWS.items()}


def write_rows(source: Path, output: Path) -> None:
    if output.exists():
        raise ValueError(f"refusing to overwrite existing output path: {output}")
    rows = prepare(source)
    output.mkdir(parents=True)
    records: dict[str, object] = {}
    for name, image in rows.items():
        relative = f"{name}-row.png"
        destination = output / relative
        image.save(destination, format="PNG", optimize=False)
        records[name] = {
            "path": relative,
            "bounds": list(ROWS[name]),
            "dimensions": list(image.size),
            "sha256": sha256(destination),
        }
    manifest = {
        "source": {
            "path": str(source),
            "sha256": EXPECTED_INPUT_SHA256,
            "dimensions": list(EXPECTED_INPUT_SIZE),
        },
        "pillow_version": PILLOW_VERSION,
        "operation": "whole-row crop only; source pixels are not edited",
        "rows": records,
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(
        description=__doc__,
        epilog="example: prepare-row-inputs.py --output-dir /tmp/carrying-f-row-inputs",
        allow_abbrev=False,
    )
    result.add_argument(
        "--input",
        type=Path,
        default=DEFAULT_INPUT,
        help="retained F atlas (default: raw/carrying-f-selected.png beside this script)",
    )
    result.add_argument(
        "--output-dir",
        required=True,
        type=Path,
        help="new directory for a-row.png, c-row.png, and manifest.json",
    )
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        write_rows(args.input.resolve(), args.output_dir.resolve())
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
