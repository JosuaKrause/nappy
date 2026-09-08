#!/usr/bin/env python3
"""Bring a real-world photo or video into docs/reference/, shrunk and stripped.

Run it through the wrapper, which owns the environment:

    tools/reference.sh <file-or-directory>...

Three things happen to everything that goes in, and each of them is the point:

*   **It is shrunk to fit inside 1280x720, aspect ratio kept.** That is the game's own design
    box, so a reference sits beside a screenshot at the same scale. Nothing is ever enlarged --
    a small source stays small rather than being blown up to look like more detail than it has.
*   **Every scrap of metadata is dropped.** A phone photo carries GPS coordinates, a device
    serial, a timestamp and often a name, none of which is reference material and all of which
    is published the moment the repository is. There is no flag to keep it.
*   **A video also loses its sound and most of its frames** -- 15fps, no audio track -- because
    what a video is here is a motion reference, and the audio is the half most likely to have
    recorded somebody who did not agree to be recorded.

Failure is loud on purpose: a missing input, an unreadable file, an ffmpeg that is not there, or
an output that did not appear all stop the run with a non-zero exit rather than being skipped
quietly. A pass that silently converted nothing looks exactly like a pass that worked.
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageOps

try:  # An iPhone photo is HEIC, and Pillow cannot open one without this.
    import pillow_heif

    pillow_heif.register_heif_opener()
    HEIF = True
except ImportError:  # pragma: no cover - the wrapper installs it; a bare run may not have it.
    HEIF = False

REPO = Path(__file__).resolve().parent.parent
FOLDER = REPO / "docs" / "reference"

# The game's own design box -- see src/ui/screen_orientation.gd, which authors every screen
# against 1280x720. A reference that fits the same box can be held up against a screenshot.
MAX_SIZE = (1280, 720)

# Quality for the JPEG a photo becomes. 88 is where re-encoding a downscaled photograph stops
# being visible by eye and the file is still a few hundred KB rather than a few MB, which is
# what makes committing one reasonable.
JPEG_QUALITY = 88

# A slug that is still a camera's own filename rather than a subject: `pxl-20260907-205519546`,
# `img-4821`, `dsc01234`, `dscf0007`, `p1010042`, `20260907-142233`. Matched loosely on purpose --
# a false positive costs one printed reminder, a false negative commits a timestamp.
CAMERA_STEM = re.compile(r"^(pxl|img|dsc|dscf|dji|gopr|p\d{3})[-_]?\d|^\d{6,8}[-_]\d{4,}")

STILLS = {".jpg", ".jpeg", ".png", ".webp", ".tif", ".tiff", ".bmp", ".heic", ".heif"}
VIDEOS = {".mp4", ".mov", ".m4v", ".avi", ".mkv", ".webm"}

# Constant Rate Factor for the H.264 a video becomes: lower is better and bigger, 28 is a
# visibly-fine motion reference at a fraction of a phone capture's size.
VIDEO_CRF = "28"
VIDEO_FPS = "15"


def slugify(stem: str) -> str:
    """`IMG_4821 (2).HEIC` -> `img-4821-2`. Names reach a URL and a shell eventually."""
    slug = re.sub(r"[^a-z0-9]+", "-", stem.lower()).strip("-")
    return slug or "reference"


def fitted(size: tuple[int, int]) -> tuple[int, int]:
    """`size` scaled to fit inside `MAX_SIZE`, aspect ratio kept, never enlarged."""
    width, height = size
    scale = min(MAX_SIZE[0] / width, MAX_SIZE[1] / height, 1.0)
    return max(1, round(width * scale)), max(1, round(height * scale))


def convert_still(source: Path, destination_stem: Path) -> Path:
    with Image.open(source) as image:
        image.load()
        # `getchannel` would raise; `mode` is the cheap question. Alpha survives as PNG because
        # a cut-out reference with a transparent background is a different thing from a photo.
        has_alpha = image.mode in ("RGBA", "LA") or "transparency" in image.info
        # `exif_transpose` applies the orientation tag and then it is safe to throw the tag away
        # -- otherwise stripping metadata silently rotates every phone photo.
        image = ImageOps.exif_transpose(image)
        image = image.convert("RGBA" if has_alpha else "RGB")
        target = fitted(image.size)
        if target != image.size:
            image = image.resize(target, Image.LANCZOS)
        # A fresh image object carries none of the source's `info` dict, which is where EXIF,
        # ICC, XMP and PNG text chunks all live. Copying the pixels is the strip.
        clean = Image.new(image.mode, image.size)
        clean.putdata(list(image.getdata()))
        if has_alpha:
            out = destination_stem.with_suffix(".png")
            clean.save(out, format="PNG", optimize=True)
        else:
            out = destination_stem.with_suffix(".jpg")
            clean.save(out, format="JPEG", quality=JPEG_QUALITY, optimize=True, progressive=True)
    return out


def convert_video(source: Path, destination_stem: Path) -> Path:
    if shutil.which("ffmpeg") is None:
        raise RuntimeError("ffmpeg is not on PATH, and a video reference needs it")
    out = destination_stem.with_suffix(".mp4")
    # -map_metadata -1 drops the container's metadata; -an drops the audio track outright rather
    # than muting it; the scale filter is the same fit-inside-the-box rule the stills get, with
    # -2 keeping each side even, which H.264 requires.
    command = [
        "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
        "-i", str(source),
        "-map_metadata", "-1",
        "-an",
        "-r", VIDEO_FPS,
        # Two scale passes rather than one. `min(iw,W)`/`min(ih,H)` rather than a bare W:H,
        # because `force_original_aspect_ratio=decrease` on its own still *enlarges* a source
        # smaller than the box, which is the one thing the size rule says never to do; and the
        # second pass rounds both sides down to even numbers, which H.264 requires. The
        # `force_divisible_by` option does that in one pass and is not in every ffmpeg build --
        # it is missing from the one this was written against, which failed loudly and is why
        # there are two passes.
        "-vf", f"scale='min(iw,{MAX_SIZE[0]})':'min(ih,{MAX_SIZE[1]})'"
               ":force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2",
        "-c:v", "libx264", "-preset", "slow", "-crf", VIDEO_CRF,
        "-pix_fmt", "yuv420p", "-movflags", "+faststart",
        str(out),
    ]
    subprocess.run(command, check=True)
    return out


def sources(paths: list[Path]) -> list[Path]:
    found: list[Path] = []
    for path in paths:
        if not path.exists():
            raise FileNotFoundError(f"no such file or directory: {path}")
        if path.is_dir():
            found.extend(sorted(p for p in path.rglob("*") if p.is_file()))
        else:
            found.append(path)
    keep = [p for p in found if p.suffix.lower() in STILLS | VIDEOS]
    skipped = [p for p in found if p not in keep]
    for path in skipped:
        print(f"  skipped (not a photo or a video): {path.name}")
    if not keep:
        raise RuntimeError("nothing to convert -- no photos or videos among the given paths")
    return keep


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+", type=Path,
                        help="photos, videos, or directories of them")
    parser.add_argument("--force", action="store_true",
                        help="overwrite an existing file of the same name")
    args = parser.parse_args()

    FOLDER.mkdir(parents=True, exist_ok=True)
    # Godot walks every directory under the project and would import each of these as a texture,
    # writing a .import sidecar per file and carrying them into the exported game. An empty
    # .gdignore is the engine's own "this directory is not mine".
    (FOLDER / ".gdignore").touch()

    failures = 0
    for source in sources(args.paths):
        stem = FOLDER / slugify(source.stem)
        existing = [p for p in (stem.with_suffix(s) for s in (".jpg", ".png", ".mp4")) if p.exists()]
        if existing and not args.force:
            print(f"  refused (already there, use --force): {existing[0].name}")
            failures += 1
            continue
        try:
            if source.suffix.lower() in VIDEOS:
                out = convert_video(source, stem)
            else:
                if source.suffix.lower() in (".heic", ".heif") and not HEIF:
                    raise RuntimeError("pillow-heif is not installed, so a HEIC cannot be read")
                out = convert_still(source, stem)
        except Exception as error:  # noqa: BLE001 - every failure is reported and counted
            print(f"  FAILED {source.name}: {error}")
            failures += 1
            continue
        # The verification the dedicated tools give for free: an output that is not there, or is
        # empty, is a conversion that did not happen however clean the command looked.
        if not out.exists() or out.stat().st_size == 0:
            print(f"  FAILED {source.name}: wrote nothing to {out.name}")
            failures += 1
            continue
        before = source.stat().st_size / 1e6
        after = out.stat().st_size / 1e6
        print(f"  {source.name} -> docs/reference/{out.name}  ({before:.1f}MB -> {after:.1f}MB)")

    # The one thing this script cannot do for you, said out loud rather than left in a rule
    # somebody has to remember. A camera stem is frequently the capture timestamp -- Google's
    # `PXL_YYYYMMDD_HHMMSSsss` is UTC to the millisecond -- so committing one puts back, in the
    # filename, the `DateTime` the pass above just stripped out of the EXIF.
    camera_named = sorted(p.name for p in FOLDER.iterdir()
                          if p.suffix.lower() in {".jpg", ".png", ".mp4"}
                          and CAMERA_STEM.match(p.stem))
    if camera_named:
        print(f"\n{len(camera_named)} file(s) still carry a camera stem, e.g. {camera_named[0]}")
        print("  Rename them <subject>-<detail>-NN before committing -- a stem like "
              "`pxl-20260907-205519546` is the capture time, which is the metadata this pass "
              "exists to remove. See .claude/skills/reference-photos/SKILL.md.")

    if failures:
        print(f"{failures} failed", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
