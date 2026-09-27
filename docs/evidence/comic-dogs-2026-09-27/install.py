"""Install the accepted comic dog pictures as the game's runtime PNGs, or verify they are installed.

The player accepted both dog families on 2026-09-27 (playtest dotted-panda). This copies each
accepted native candidate, byte for byte, to the runtime path that stands in for its SVG,
`art/illustrated/svg-transfer/events/<name>.png` beside `art/events/<name>.svg`. Nothing is
resampled, repainted or re-registered: registration is the candidates' own, recorded by the
recipes that built them.

Which candidate is installed for which SVG follows the three-pose table in
`walked-revision-5/README.md`: every A picture and the cardinal B pictures from the first pass,
the side and diagonal B (rest) pictures from revision 4, every C picture from revision 5, and the
whole pursuing family from the first pass.

    uv run python docs/evidence/comic-dogs-2026-09-27/install.py install
    uv run python docs/evidence/comic-dogs-2026-09-27/install.py verify

Both refuse, naming the file, before writing anything if a candidate is missing, its size
disagrees with its SVG's canvas, or (for `verify`) an installed PNG differs from its candidate.
"""

from __future__ import annotations

import re
import shutil
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
RUNTIME = ROOT / "art/illustrated/svg-transfer/events"

FIRST_PASS_DOG = [
    "dog",
    "dog_front",
    "dog_front_b",
    "dog_back",
    "dog_back_b",
    "dog_front_diagonal",
    "dog_back_diagonal",
]
REVISION_4 = ["dog_b", "dog_front_diagonal_b", "dog_back_diagonal_b"]
REVISION_5 = ["dog_c", "dog_front_c", "dog_back_c", "dog_front_diagonal_c", "dog_back_diagonal_c"]
CHARGING = [
    f"charging_dog{view}{frame}"
    for view in ("", "_front", "_back", "_front_diagonal", "_back_diagonal")
    for frame in ("", "_b")
]

MAPPING: dict[str, Path] = {}
for name in FIRST_PASS_DOG:
    MAPPING[name] = HERE / "candidates/dog" / f"{name}.png"
for name in REVISION_4:
    MAPPING[name] = HERE / "walked-revision-4/candidates" / f"{name}.png"
for name in REVISION_5:
    MAPPING[name] = HERE / "walked-revision-5/candidates" / f"{name}.png"
for name in CHARGING:
    MAPPING[name] = HERE / "candidates/charging-dog" / f"{name}.png"

EXPECTED = 25


def svg_size(svg: Path) -> tuple[int, int]:
    head = svg.read_text()
    match = re.search(r'<svg[^>]*\swidth="(\d+)"[^>]*\sheight="(\d+)"', head)
    if match is None:
        raise SystemExit(f"no width/height on the root element of {svg}")
    return int(match.group(1)), int(match.group(2))


def preflight() -> None:
    if len(MAPPING) != EXPECTED:
        raise SystemExit(f"expected {EXPECTED} pictures, the mapping names {len(MAPPING)}")
    for name, candidate in MAPPING.items():
        svg = ROOT / "art/events" / f"{name}.svg"
        if not svg.is_file():
            raise SystemExit(f"no source SVG for {name}: {svg}")
        if not candidate.is_file():
            raise SystemExit(f"missing candidate for {name}: {candidate}")
        with Image.open(candidate) as image:
            if image.mode != "RGBA":
                raise SystemExit(f"{candidate} is {image.mode}, not RGBA")
            if image.size != svg_size(svg):
                raise SystemExit(f"{candidate} is {image.size}, its SVG {svg} is {svg_size(svg)}")


def install() -> None:
    preflight()
    RUNTIME.mkdir(parents=True, exist_ok=True)
    for name, candidate in MAPPING.items():
        shutil.copyfile(candidate, RUNTIME / f"{name}.png")
    verify()


def verify() -> None:
    preflight()
    for name, candidate in MAPPING.items():
        installed = RUNTIME / f"{name}.png"
        if not installed.is_file():
            raise SystemExit(f"not installed: {installed}")
        if installed.read_bytes() != candidate.read_bytes():
            raise SystemExit(f"{installed} differs from its accepted candidate {candidate}")
    stray = sorted(
        p.name
        for p in RUNTIME.glob("*dog*.png")
        if p.stem not in MAPPING
    )
    if stray:
        raise SystemExit(f"installed dog pictures with no accepted candidate: {stray}")
    print(f"{len(MAPPING)} dog pictures installed, each identical to its accepted candidate")


def main() -> None:
    commands = {"install": install, "verify": verify}
    if len(sys.argv) != 2 or sys.argv[1] not in commands:
        raise SystemExit("usage: install.py install|verify")
    commands[sys.argv[1]]()


if __name__ == "__main__":
    main()
