#!/usr/bin/env python3
"""Convert a gameplay burst folder into a timing-accurate H.264 MP4.

The burst writer stores ``burst.json`` beside its PNGs.  This tool deliberately reads the
recorded elapsed times instead of imposing a nominal frame rate: a dropped frame or a busy
desktop remains visible at the right speed in the resulting clip.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

MAX_FRAMES = 36
SCHEMA_VERSION = 1
DEFAULT_TIMEOUT = 120


class ClipError(RuntimeError):
    """An actionable input or conversion failure."""


def error(message: str) -> ClipError:
    return ClipError(message)


def read_metadata(folder: Path, *, allow_partial: bool) -> tuple[list[tuple[Path, float]], float, float]:
    metadata_path = folder / "burst.json"
    if not metadata_path.is_file():
        raise error(f"burst metadata is missing: {metadata_path}")
    try:
        payload: Any = json.loads(metadata_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise error(f"cannot read valid JSON from {metadata_path}: {exc}") from exc
    if not isinstance(payload, dict) or payload.get("schema_version") != SCHEMA_VERSION:
        raise error(f"{metadata_path} must have schema_version {SCHEMA_VERSION}")
    status = payload.get("status")
    if status == "active":
        raise error(f"burst is still active: {folder}")
    if status not in ("complete", "completed", "cancelled", "partial"):
        raise error(f"burst status must be complete, completed, cancelled, or partial, got {status!r}")
    if status in ("cancelled", "partial") and not allow_partial:
        raise error("cancelled bursts require an explicit burst directory")
    frames = payload.get("frames")
    if not isinstance(frames, list) or not frames:
        raise error(f"{metadata_path} has no frames")
    if len(frames) > MAX_FRAMES:
        raise error(f"{metadata_path} lists {len(frames)} frames; maximum is {MAX_FRAMES}")
    try:
        duration = float(payload["duration_seconds"])
        target_fps = float(payload["target_fps"])
    except (KeyError, TypeError, ValueError) as exc:
        raise error(f"{metadata_path} needs numeric duration_seconds and target_fps") from exc
    if not math.isfinite(duration) or not math.isfinite(target_fps) or duration <= 0 or target_fps <= 0:
        raise error(f"duration_seconds and target_fps must be positive in {metadata_path}")

    result: list[tuple[Path, float]] = []
    previous = -1.0
    for index, frame in enumerate(frames, start=1):
        if not isinstance(frame, dict) or not isinstance(frame.get("file"), str):
            raise error(f"frame {index} has no filename in {metadata_path}")
        try:
            elapsed = float(frame["elapsed_seconds"])
        except (KeyError, TypeError, ValueError) as exc:
            raise error(f"frame {index} has invalid elapsed_seconds in {metadata_path}") from exc
        if not math.isfinite(elapsed) or elapsed < 0 or elapsed <= previous:
            raise error(f"frame timestamps must be strictly increasing in {metadata_path} (frame {index})")
        relative = Path(frame["file"])
        if relative.is_absolute() or ".." in relative.parts:
            raise error(f"frame {index} filename must stay inside the burst folder: {relative}")
        path = folder / relative
        if not path.is_file():
            raise error(f"frame {index} is missing: {path}")
        result.append((path, elapsed))
        previous = elapsed
    if duration <= previous:
        raise error(f"duration_seconds ({duration}) must be after the last frame ({previous})")
    return result, duration, target_fps


def concat_escape(path: Path) -> str:
    # Paths here are generated temporary basenames; staging avoids platform-specific quoting of
    # arbitrary source paths in ffconcat's single-quoted syntax.
    return str(path).replace("\\", "\\\\").replace("'", "\\'")


def make_manifest(frames: list[tuple[Path, float]], duration: float, destination: Path) -> None:
    lines = ["ffconcat version 1.0"]
    for index, (path, elapsed) in enumerate(frames):
        next_time = frames[index + 1][1] if index + 1 < len(frames) else duration
        lines.append(f"file '{concat_escape(path)}'")
        lines.append(f"duration {next_time - elapsed:.9f}")
    # concat needs the final file repeated for the final duration directive to apply.
    lines.append(f"file '{concat_escape(frames[-1][0])}'")
    destination.write_text("\n".join(lines) + "\n", encoding="utf-8")


def find_pending(root: Path) -> list[Path]:
    """Return unconverted completed or captured partial bursts in stable path order."""
    pending: list[Path] = []
    for metadata in sorted(root.rglob("burst.json"), key=lambda path: str(path)):
        folder = metadata.parent
        try:
            payload: Any = json.loads(metadata.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            print(f"clip: ignoring malformed burst metadata {metadata}: {exc}", file=sys.stderr)
            continue
        if not isinstance(payload, dict) or payload.get("schema_version") != SCHEMA_VERSION:
            print(f"clip: ignoring unsupported burst metadata {metadata}", file=sys.stderr)
            continue
        status = payload.get("status")
        if status == "active":
            continue
        if status not in ("complete", "completed", "cancelled", "partial"):
            print(f"clip: ignoring burst with unsupported status {status!r}: {metadata}", file=sys.stderr)
            continue
        frames = payload.get("frames")
        if not isinstance(frames, list) or not frames:
            print(f"clip: ignoring burst with no frames: {metadata}", file=sys.stderr)
            continue
        output = folder.parent / f"{folder.name}.mp4"
        if output.exists():
            continue
        pending.append(folder)
    return pending


def telemetry_directory() -> Path:
    script = Path(__file__).with_name("telemetry.sh")
    try:
        result = subprocess.run([str(script), "-d"], check=True, capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.SubprocessError) as exc:
        raise error(f"could not locate telemetry directory via {script}: {exc}") from exc
    path = Path(result.stdout.strip())
    if not path.is_dir():
        raise error(f"telemetry directory does not exist: {path}")
    return path


def convert(
    folder: Path, output: Path | None = None, *, explicit: bool = False, timeout: int = DEFAULT_TIMEOUT
) -> Path:
    folder = folder.expanduser().resolve()
    if not folder.is_dir():
        raise error(f"burst directory does not exist: {folder}")
    frames, duration, target_fps = read_metadata(folder, allow_partial=explicit)
    del target_fps  # retained in the schema for capture context; timestamps govern playback.
    output = (output.expanduser() if output else folder.parent / f"{folder.name}.mp4").resolve()
    if output.exists():
        raise error(f"refusing to overwrite existing output: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)
    if shutil.which("ffmpeg") is None:
        raise error("ffmpeg is not on PATH")
    # Keep the temporary output beside the destination so the final hard-link is same-filesystem
    # and can publish with exclusive creation (no overwrite race).
    with tempfile.TemporaryDirectory(prefix=".nappy-clip-", dir=output.parent) as temporary:
        manifest = Path(temporary) / "frames.ffconcat"
        # ffconcat's parser has platform-specific handling for apostrophes in quoted paths.
        # Stage symlinks with generated, plain names instead; this reads the source pixels while
        # keeping the source burst entirely untouched and makes every valid filesystem path safe.
        staged: list[tuple[Path, float]] = []
        for index, (source, elapsed) in enumerate(frames):
            link = Path(temporary) / f"frame-{index:04d}.png"
            link.symlink_to(source)
            staged.append((Path(link.name), elapsed))
        make_manifest(staged, duration, manifest)
        temporary_output = Path(temporary) / "clip.mp4"
        command = [
            "ffmpeg",
            "-hide_banner",
            "-loglevel",
            "error",
            "-nostdin",
            "-f",
            "concat",
            "-safe",
            "0",
            "-i",
            str(manifest),
            "-vsync",
            "vfr",
            "-vf",
            "pad=ceil(iw/2)*2:ceil(ih/2)*2",
            "-an",
            "-c:v",
            "libx264",
            "-pix_fmt",
            "yuv420p",
            "-movflags",
            "+faststart",
            "-y",
            str(temporary_output),
        ]
        try:
            subprocess.run(command, check=True, timeout=timeout, cwd=temporary)
        except subprocess.TimeoutExpired as exc:
            raise error(f"ffmpeg timed out after {timeout}s") from exc
        except (OSError, subprocess.CalledProcessError) as exc:
            raise error(f"ffmpeg could not encode {folder}: {exc}") from exc
        if not temporary_output.is_file() or temporary_output.stat().st_size == 0:
            raise error("ffmpeg reported success but produced no output")
        try:
            os.link(temporary_output, output)
        except FileExistsError as exc:
            raise error(f"refusing to overwrite output created during conversion: {output}") from exc
        finally:
            temporary_output.unlink(missing_ok=True)
    return output


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("burst_directory", nargs="?", type=Path)
    parser.add_argument("output", nargs="?", type=Path, help="optional output MP4 path")
    args = parser.parse_args(argv)
    try:
        if args.burst_directory is None:
            root = telemetry_directory()
            pending = find_pending(root)
            if not pending:
                print(f"clip: no pending bursts under {root}")
                return 0
            failures = 0
            for folder in pending:
                try:
                    print(convert(folder, explicit=True))
                except (ClipError, OSError) as exc:
                    failures += 1
                    print(f"clip: {folder}: {exc}", file=sys.stderr)
            return 1 if failures else 0
        output = convert(args.burst_directory, args.output, explicit=True)
    except (ClipError, OSError) as exc:
        print(f"clip: {exc}", file=sys.stderr)
        return 1
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
