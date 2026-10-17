"""Builds one looping GIF per view of the robber's two-frame alert walk.

Usage: uv run python make-walk-gifs.py --repo REPO_ROOT --spec walk-v1.json --godot GODOT
                                       --project SCRATCH_PROJECT --out FRESH_DIR

Each frame is a sheet from ../teal-trout-views-2026-10-17/render-sheet.gd (the engine's own SVG
parser, the sidewalk's ground colour, one block per scale stacked top to bottom); Pillow, already
in the repository's Python environment, joins each view's two sheets into a GIF that alternates
them every `frame_ms` milliseconds, forever. FRESH_DIR must not exist: a delivered GIF is never
overwritten.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    for flag in ("--repo", "--spec", "--godot", "--project", "--out"):
        parser.add_argument(flag, required=True)
    args = parser.parse_args()
    repo = Path(args.repo).resolve()
    out = Path(args.out).resolve()
    if out.exists():
        print(f"Output directory must be fresh: {out}", file=sys.stderr)
        return 2
    spec = json.loads(Path(args.spec).read_text())
    script = repo / "docs/evidence/teal-trout-views-2026-10-17/render-sheet.gd"
    out.mkdir(parents=True)
    scratch = out / "frames"
    scratch.mkdir()
    for view, frames in spec["views"].items():
        sheets = []
        for index, svg in enumerate(frames):
            frame_spec = scratch / f"{view}-{index}.json"
            frame_spec.write_text(json.dumps({"scales": spec["scales"], "rows": [[svg]]}))
            sheet = scratch / f"{view}-{index}.png"
            subprocess.run(
                [
                    args.godot,
                    "--headless",
                    "--path",
                    args.project,
                    "--script",
                    str(script),
                    "--",
                    "--repo",
                    str(repo),
                    "--spec",
                    str(frame_spec),
                    "--output",
                    str(sheet),
                ],
                check=True,
                capture_output=True,
            )
            if not sheet.exists():
                print(f"No sheet written for {svg}", file=sys.stderr)
                return 1
            sheets.append(Image.open(sheet).convert("RGB"))
        if len({image.size for image in sheets}) != 1:
            print(f"{view}: the frames' sheets differ in size, so the cycle would jump", file=sys.stderr)
            return 1
        gif = out / f"robber-walk-{view}-v1.gif"
        sheets[0].save(
            gif, save_all=True, append_images=sheets[1:], duration=spec["frame_ms"], loop=0, disposal=1, optimize=False
        )
        print(f"wrote {gif} {sheets[0].size}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
