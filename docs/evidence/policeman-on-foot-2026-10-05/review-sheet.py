"""Compose the policeman review sheet from the SVG sources, rendered by Godot's own SVG parser.

usage: uv run python docs/evidence/policeman-on-foot-2026-10-05/review-sheet.py \
           --godot /Applications/Godot.app/Contents/MacOS/Godot --out sheet.png [--scratch DIR]

Every SVG is rendered by `render.gd` (beside this file) through `Image.load_svg_from_string()`,
at scale 1 and at scale 4, in a throwaway Godot project under the scratch directory. The sheet
then shows, on the game's own sidewalk and asphalt colours (`Palette.SIDEWALK`, `Palette.ASPHALT`):

- **game scale**: the scale-1 raster doubled with bilinear filtering, which is what the camera at
  zoom 2 does to the baked atlas region, for the policeman beside the robber, the checkpoint
  guard and the neighbor (the other blue figure with a dark cap), every family on one shared
  ground line and one shared world scale;
- **4x detail**: the policeman alone, rendered at scale 4, for joins and clipping.

The soft ellipse under each figure stands in for the runtime's own drop shadow
(`Palette.SHADOW`, black at 22%); its size is an approximation, not the runtime's.
A cell is empty where a family has no such picture: no family has an unsuffixed stride frame,
and the neighbor has no unsuffixed picture at all. A cell labelled "not yet drawn" names a
listed file that is missing.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]

SIDEWALK = (0x8B, 0x84, 0x78, 255)
ASPHALT = (0x46, 0x46, 0x4F, 255)
PAPER = (0xF4, 0xF1, 0xEA, 255)
INK = (0x22, 0x1F, 0x28, 255)

VIEWS = ["front", "front_diagonal", "side", "back_diagonal", "back"]
HEADINGS = {"front": "front", "front_diagonal": "front diag.", "side": "side", "back_diagonal": "back diag.",
            "back": "back", "": "unsuffixed"}

# (label, file stem template); `{v}` is a view, and "" stands for the unsuffixed picture.
FAMILIES: list[tuple[str, str, list[str]]] = [
    ("policeman waiting", "art/events/policeman_waiting{v}.svg", [*VIEWS, ""]),
    ("policeman lunging", "art/events/policeman_lunging{v}.svg", [*VIEWS, ""]),
    ("policeman lunging _b", "art/events/policeman_lunging{v}_b.svg", VIEWS),
    ("robber waiting", "art/events/robber_waiting{v}.svg", [*VIEWS, ""]),
    ("robber lunging", "art/events/robber_lunging{v}.svg", [*VIEWS, ""]),
    ("robber lunging _b", "art/events/robber_lunging{v}_b.svg", VIEWS),
    ("guard standing", "art/checkpoints/guard_standing{v}.svg", [*VIEWS, ""]),
    ("guard lunging", "art/checkpoints/guard_lunging{v}.svg", [*VIEWS, ""]),
    ("neighbor walking", "art/events/neighbor{v}.svg", VIEWS),
    ("neighbor walking _b", "art/events/neighbor{v}_b.svg", VIEWS),
]
POLICE_ROWS = 3


def source_for(template: str, view: str) -> Path:
    return REPO / template.format(v=f"_{view}" if view else "")


def render_all(godot: str, scratch: Path, sources: list[Path], scale: int) -> dict[Path, Image.Image]:
    project = scratch / "project"
    project.mkdir(parents=True, exist_ok=True)
    (project / "project.godot").write_text('config_version=5\n\n[application]\nconfig/name="svg-render-scratch"\n')
    shutil.copy(HERE / "render.gd", project / "render.gd")
    out = scratch / f"x{scale}"
    out.mkdir(exist_ok=True)
    cmd = [godot, "--headless", "--path", str(project), "--script", "render.gd", "--", str(scale), str(out)]
    result = subprocess.run([*cmd, *map(str, sources)], capture_output=True, text=True, check=False)
    if result.returncode != 0:
        sys.exit(f"render failed ({result.returncode}):\n{result.stdout}\n{result.stderr}")
    images: dict[Path, Image.Image] = {}
    for source in sources:
        png = out / f"{source.stem}@{scale}x.png"
        if not png.exists():
            sys.exit(f"render wrote nothing for {source}")
        images[source] = Image.open(png).convert("RGBA")
    return images


def shadow(width: int, height: int) -> Image.Image:
    layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse((0, 0, width - 1, height - 1), fill=(0, 0, 0, 56))
    return layer


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--godot", required=True, help="the Godot 4 executable")
    parser.add_argument("--out", required=True, type=Path, help="where to write the sheet PNG")
    parser.add_argument("--scratch", type=Path, help="scratch directory (default: a fresh temporary one)")
    args = parser.parse_args()

    scratch = args.scratch or Path(tempfile.mkdtemp(prefix="policeman-sheet-"))
    cells = [(label, view, source_for(t, view)) for label, t, views in FAMILIES for view in views]
    present = [path for _, _, path in cells if path.exists()]
    x1 = render_all(args.godot, scratch, present, 1)
    x4 = render_all(args.godot, scratch, [p for p in present if "policeman" in p.name], 4)

    font = ImageFont.load_default(size=13)
    small = ImageFont.load_default(size=11)
    columns = [*VIEWS, ""]
    label_w, cell_w, cell_h = 150, 84, 104
    detail_w, detail_h = 150, 196
    rows = len(FAMILIES)
    width = label_w + cell_w * len(columns) * 2 + 20
    height = 60 + rows * cell_h + 40 + POLICE_ROWS * detail_h + 20
    sheet = Image.new("RGBA", (width, height), PAPER)
    draw = ImageDraw.Draw(sheet)
    draw.text((10, 8), "Game scale (scale-1 raster doubled bilinearly, as the zoom-2 camera draws the atlas):", INK, font)
    draw.text((10, 26), "left half on the sidewalk colour, right half on the asphalt colour; one ground line per row,"
              " shared world scale. Shadow is an approximation.", INK, small)
    for half, ground in enumerate((SIDEWALK, ASPHALT)):
        for c, view in enumerate(columns):
            x = label_w + (half * len(columns) + c) * cell_w
            draw.text((x + 4, 44), HEADINGS[view], INK, small)
    for r, (label, template, views) in enumerate(FAMILIES):
        y = 60 + r * cell_h
        draw.text((10, y + cell_h // 2 - 8), label, INK, font)
        for half, ground in enumerate((SIDEWALK, ASPHALT)):
            for c, view in enumerate(columns):
                x = label_w + (half * len(columns) + c) * cell_w
                draw.rectangle((x, y, x + cell_w - 2, y + cell_h - 2), fill=ground)
                if view not in views:
                    continue
                path = source_for(template, view)
                if path not in x1:
                    draw.text((x + 6, y + cell_h // 2 - 6), "not yet drawn", PAPER, small)
                    continue
                img = x1[path]
                big = img.resize((img.width * 2, img.height * 2), Image.Resampling.BILINEAR)
                foot_x = x + cell_w // 2
                foot_y = y + cell_h - 10
                sh = shadow(34, 8)
                sheet.alpha_composite(sh, (foot_x - 17, foot_y - 4))
                sheet.alpha_composite(big, (foot_x - big.width // 2, foot_y - big.height))
    top = 60 + rows * cell_h + 10
    draw.text((10, top), "4x detail, the policeman only (rendered at scale 4, sidewalk colour):", INK, font)
    for r, (label, template, views) in enumerate(FAMILIES[:POLICE_ROWS]):
        y = top + 24 + r * detail_h
        draw.text((10, y + detail_h // 2 - 8), label, INK, font)
        for c, view in enumerate(columns):
            x = label_w + c * detail_w
            draw.rectangle((x, y, x + detail_w - 4, y + detail_h - 4), fill=SIDEWALK)
            draw.text((x + 4, y + 2), view or "(unsuffixed)", PAPER, small)
            if view not in views:
                continue
            path = source_for(template, view)
            if path not in x4:
                draw.text((x + 6, y + detail_h // 2), "not yet drawn", PAPER, small)
                continue
            img = x4[path]
            sheet.alpha_composite(img, (x + (detail_w - 4 - img.width) // 2, y + detail_h - 8 - img.height))
    sheet.convert("RGB").save(args.out)
    print(f"wrote {args.out} ({len(present)} sources rendered; scratch {scratch})")


if __name__ == "__main__":
    main()
