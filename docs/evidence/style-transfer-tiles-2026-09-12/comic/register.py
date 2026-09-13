"""Register comic terrain and its functional road-paint layers to source tile coordinates."""

import argparse
import importlib.util
import json
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("tile_conversion", HERE.parent / "convert.py")
assert SPEC is not None and SPEC.loader is not None
CONVERSION = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CONVERSION)


def paint_components(image):
    """Identify separate warm paint strokes; dark asphalt and gray aggregate are excluded."""
    rgb = image.convert("RGB")
    pixels = rgb.load()
    remaining = {
        (x, y)
        for y in range(rgb.height)
        for x in range(rgb.width)
        if (lambda c: c[0] > 105 and c[1] > 95 and c[0] > c[2] * 1.17
            and c[1] > c[2] * 1.12)(pixels[x, y])
    }
    components = []
    while remaining:
        first = remaining.pop()
        pending, component = [first], [first]
        while pending:
            x, y = pending.pop()
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    pending.append(neighbor)
                    component.append(neighbor)
        xs, ys = zip(*component)
        components.append((len(component), (min(xs), min(ys), max(xs) + 1, max(ys) + 1)))
    return sorted(components, reverse=True)


def register(output):
    sheets = [HERE / "generated-01-layout.png"] + [HERE / f"generated-{i:02d}.png" for i in (2, 3, 4)]
    CONVERSION.register(output, sheets)
    cells = []
    # Atlas panel rules are presentation artifacts, not ground. Trim the measured three-pixel
    # divider allowance before resampling; keep all four cell edges filled and record the crop.
    for index, name in enumerate(CONVERSION.NAMES):
        sheet = Image.open(sheets[index // 16]).convert("RGBA")
        column, row = index % 4, index % 16 // 4
        bounds = [round(value * sheet.width / 4) for value in
                  (column, row, column + 1, row + 1)]
        bounds = (bounds[0] + 3, bounds[1] + 3, bounds[2] - 3, bounds[3] - 3)
        tile = sheet.crop(bounds).resize((32, 32), Image.Resampling.LANCZOS)
        tile.putalpha(255)
        tile.save(output / "tiles" / f"{name}.png")
        cells.append({"name": name, "sheet": sheets[index // 16].name, "crop": bounds})
    (output / "cell-registration.json").write_text(json.dumps(cells, indent=2) + "\n")
    # The atlas omits the east curb. Register the west variant's generated stone curb as
    # the same two-pixel edge strip on the east, over the illustrated plain sidewalk.
    sidewalk = Image.open(output / "tiles/sidewalk.png").convert("RGBA")
    west = Image.open(output / "tiles/sidewalk_kerb_w.png").convert("RGBA")
    sidewalk.alpha_composite(west.crop((0, 0, 6, 32)).resize((2, 32), Image.Resampling.LANCZOS), (30, 0))
    sidewalk.save(output / "tiles/sidewalk_kerb_e.png")
    atlas = Image.open(sheets[0]).convert("RGBA")
    measurements = []
    for index, name in enumerate(CONVERSION.ROAD_MARKINGS):
        source = Image.open(HERE.parent / "source" / f"{name}-svg.png").convert("RGBA")
        expected = paint_components(source)
        column, row = index % 4, index // 4
        cell_bounds = tuple(round(value * atlas.width / 4) for value in
                            (column, row, column + 1, row + 1))
        cell = atlas.crop(cell_bounds)
        found = paint_components(cell)[:len(expected)]
        assert len(found) == len(expected) and expected, (name, found, expected)
        # Sort by the axis separating multiple strokes. Register each painted stroke, not
        # the whole opaque tile: moving the whole tile moves its material boundaries too.
        axis = 0 if name.endswith(("_n", "_s")) and "crossing_main" in name else 1
        if "road_main_line" in name:
            axis = 0 if name.endswith(("_e", "_w")) else 1
        if name == "crossing_v":
            axis = 0
        expected.sort(key=lambda item: item[1][axis])
        found.sort(key=lambda item: item[1][axis])
        base_name = "road_main" if "main" in name else "road"
        tile = Image.open(output / "tiles" / f"{base_name}.png").convert("RGBA")
        strokes = []
        for (_, target), (area, bounds) in zip(expected, found, strict=True):
            assert area > 100, (name, area, bounds)
            stroke = cell.crop(bounds).resize((target[2] - target[0], target[3] - target[1]),
                                             Image.Resampling.LANCZOS)
            tile.alpha_composite(stroke, target[:2])
            strokes.append({"generated_crop": bounds, "native_destination": target})
        tile.save(output / "tiles" / f"{name}.png")
        measurements.append({"name": name, "atlas_cell": cell_bounds,
                             "background": base_name, "strokes": strokes})
    (output / "paint-registration.json").write_text(json.dumps(measurements, indent=2) + "\n")
    (output / "registration.json").write_text(json.dumps({
        "native_size": [32, 32], "opaque": True,
        "cells": cells, "road_paint": measurements,
        "east_curb": {"base": "sidewalk", "donor": "sidewalk_kerb_w",
                      "native_crop": [0, 0, 6, 32], "destination": [30, 0, 32, 32]},
    }, indent=2) + "\n")
    CONVERSION._comparisons(output, output / "tiles", HERE.parent / "source")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    arguments = parser.parse_args()
    register(arguments.output.resolve())
