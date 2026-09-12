# F — Hip motion registration recipe

This recipe turns retained raw generator images into the carrying family's fifteen native PNGs,
an eight-direction review sheet, and a four-frame `A, C, B, C` review GIF. It is the reproducible
extraction and registration record for M109, Convert the SVG catalogue to PNG. It does not generate
artwork or edit SVGs.

## Config

`register.py` consumes one JSON config. Relative paths resolve beside that config, so a retained
config remains portable with its evidence folder. Every input and tool dependency is frozen by an
expected SHA-256; dimensions are expected input too, rather than measurements accepted after the
fact. The complete schema is:

```json
{
  "timing_ms": 190,
  "pillow_version": "12.3.0",
  "horizontal_offset": 0,
  "checkerboard_remover": {
    "path": "../../../tools/remove-checkerboard.py",
    "sha256": "34e03aefd5aa2b3ed0025ce5801cb25bc3fa6ab9ce00669727e57c9b8fe71716"
  },
  "raw_batches": [
    {
      "path": "raw/carrying-f-selected.png",
      "sha256": "27ba7489bf0efbf9e475c72bbd7f7670841c7111a0703355641122873ad8f7fb",
      "dimensions": [1380, 1140],
      "frames": [
        {
          "name": "mother_carrying_front_a",
          "bounds": [0, 0, 276, 400],
          "horizontal_offset": 0
        }
      ]
    }
  ],
  "svg_pairs": [
    {
      "name": "mother_carrying_front_a",
      "svg": "source/svg/mother_carrying_front_a.svg",
      "svg_sha256": "ff5b3348f3c61361d34df9e0860cc8c00dc24cc4a6be91dbdcf6602eb177523a",
      "dimensions": [24, 46]
    }
  ]
}
```

The abbreviated arrays above must contain exactly the fifteen canonical frames. The retained F
sheet uses five columns in `front`, `back`, `side`, `front_diagonal`, `back_diagonal` order and three
rows in `A`, `C`, `B` order. `bounds` is the exact half-open `[left, top, right, bottom]` rectangle
for one cell. The recipe does not infer a grid. Multiple raw batches are allowed.

The top-level `horizontal_offset` defaults to zero when omitted. A frame may override it with its
own integer `horizontal_offset`; the resolved value is recorded for that frame. Use an offset only
when a stable torso center needs an explicit adjustment from bounding-box centering.

The SVG canvas is frozen twice: the config declares it and the recipe parses the actual root
`width` and `height`. Front and back frames are 24×46; side and both diagonals are 26×46. Each
visible generated figure is fitted to 45 px high and bottom-grounded with one transparent pixel
above it. A pose whose fitted width exceeds its SVG canvas is refused, preserving stature instead
of quietly shrinking it.

The extractor calls the frozen `tools/remove-checkerboard.py` neutral connected-region algorithm
only when a cell is fully opaque. Cells with real alpha retain that alpha. It does no painting,
recoloring, leg replacement, row splicing, or SVG alpha stamping. The full generated figure in each
cell is the registration source.

Before creating the destination, `register` validates the complete config, Pillow version,
checkerboard-remover hash, every raw and SVG hash, actual raw and SVG dimensions, all frame names,
bounds, and offsets. A bad input therefore leaves no partial output directory.

## Commands

Run from the repository root through the locked environment, always with a fresh destination:

```sh
UV_CACHE_DIR=/tmp/nappy-uv uv run python \
  docs/evidence/comic-carrying-hip-motion-2026-09-12/register.py \
  register --config /path/to/f-config.json --output-dir /tmp/carrying-f-registration

UV_CACHE_DIR=/tmp/nappy-uv uv run python \
  docs/evidence/comic-carrying-hip-motion-2026-09-12/register.py \
  verify --config /path/to/f-config.json \
  --registered-dir /tmp/carrying-f-registration \
  --compare-to /path/to/retained-registration
```

`register` refuses any existing output path. `verify` writes nothing. Both commands support
`--help` and `-h`, and reject missing, unknown, or stray arguments before reading inputs or writing
outputs.

The output contains:

- `rig/mother_carrying_{front,back,side,front_diagonal,back_diagonal}_{a,c,b}.png`, the fifteen
  registered native canvases;
- `extracted/` with every raw cell at its original resolution and true extracted alpha;
- `extracted-preview.png`, a clearly labeled fitted contact sheet in five view columns × three
  pose rows, with the fit scale shown per cell;
- `registered-native.png` and `registered-6x.png`, the eight runtime directions in `N`, `NE`, `E`,
  `SE`, `S`, `SW`, `W`, `NW` columns × `A`, `C`, `B` rows; and
- `animation-native.gif` and `animation-6x.gif`, each exactly four 190 ms frames in `A, C, B, C`
  order. Every GIF frame is one whole eight-direction canvas, rather than one direction at a time.

The registered sheet and animation are composed once at native scale with Pillow's embedded font.
The complete canvas, including its labels and separate header and footer bands, is then enlarged
sixfold with nearest-neighbor sampling. Thus the enlarged labels and pixels remain crisp, and no
title overlaps the bottom row. West-facing columns mirror the east-authored runtime partners; the
fifteen registered files remain the five authored views.

`manifest.json` records the config hash, Pillow version, checkerboard-remover path and hash, raw
input hashes and dimensions, extraction method, exact bounds, per-frame offsets, SVG pairs,
registration measurements, animation metadata, and output hashes. `verify` re-extracts and
re-registers from the frozen inputs, checks every output against that canonical composition, and
decodes both GIFs. It requires four equal 190 ms frames, a common canvas, three distinct visual
states, equality between frames two and four, and the canonical `A, C, B, C` content and direction
order. `--compare-to` additionally requires identical retained output hashes.

## Design boundaries

The source SVG remains authoritative for subject, direction, native canvas, and functional
placement. The generated raster supplies the illustrated interior and expressive silhouette with
its actual alpha. Runtime bindings, import sidecars, and the catalogue are handled by the parent
integration work after the source and review sheets are accepted. Pixel registration and a review
sheet do not replace visual inspection at native gameplay size.
