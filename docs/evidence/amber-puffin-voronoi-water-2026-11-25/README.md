# The south water as drifting Voronoi lines, drawn outside the game

Evidence for [amber-puffin](../../todo/2026-10-11-amber-puffin/README.md), the south water is a blue
base with drifting Voronoi lines: its standalone experiment. The scene that drew and measured
everything here is `tests/probes/voronoi_water.tscn` (script `voronoi_water.gd`, shader
`voronoi_water.gdshader`, all three beside each other); nothing in the game loads it.

## The claim and its limits

- **The look** is the probe's shader as committed, at the desktop window's scale (two screen pixels
  a world pixel, the game's 640x360 view filling 1280x720). Each GIF is the middle 640x360 of that
  frame, so a quarter of the view at full size, 6 s at 12 fps; the full-view stills show the whole
  frame at the clock's zero. Today's water is not repeated here; its approved motion is
  [waterfront.gif](../m159-scenery-animation-2026-09-26/waterfront.gif).
- **The cost** is the wall time of a frame drawn on demand into a viewport of the canvas's size,
  with the GPU's queue drained by a read-back at the end of each batch, on an Apple M2 under the
  Compatibility renderer (OpenGL 4.1 over Metal). It is the desktop's GPU, not a phone's: the
  ratios between the ways of drawing travel better than the milliseconds, and no phone was
  measured.
- **Other agents' Godot test runs were running** through both captures and the measurement (the
  load average read about 4 before and after), and a wait of eight minutes for them to end did not
  see them end. The earlier run below, from a working tree that differed only in its trial count
  and an unused timer field, gives the spread between two runs.

## What is kept

| file | what it is |
|---|---|
| `curved.gif` | the look as asked, the intensity taken off the distance, so the outlines are curves |
| `straight.gif` | the same centroids with the intensity taken off the squared distance, so the outlines stay straight |
| `curved-full-view.png` | the curved look's whole 1280x720 frame at the clock's zero |
| `tile-repeated-full-view.png` | one seamless tile of eight cells, drawn at a texel a world pixel and repeated across the view, as a prerendered tile would be |
| `results.json` | the measurement: every batch of every trial, and the summary |

The raw PNG frames (180 a look, 30 fps), the MP4s made from them and the capture of today's water
stay in scratch space: the GIFs and stills are made from those frames by the commands below.

## The figures

Milliseconds a frame on the M2, from `results.json`'s summary: the median over five trials of a
frame with the water drawn once and eight times over the whole canvas, one pass being the
difference over the seven extra copies. `fixed` is what the single copy costs beyond the empty
frame and one pass: for the live tile, drawing the tile itself.

| way of drawing | 1920x1080 pass | 1280x720 pass |
|---|---:|---:|
| a flat fill, no shader | 0.120 | 0.044 |
| today's water: the 32px tile under the game's shader, one quad a tile | 0.157 | 0.073 |
| Voronoi lines, curved | 3.137 | 1.312 |
| Voronoi lines, straight | 3.231 | 1.352 |
| a prerendered tile, repeated | 0.127 | 0.053 |
| a live tile, drawn every frame and repeated | 0.122, fixed 0.208 | 0.052, fixed 0.185 |

The empty frame itself (the clear and the read-back's share) took 0.415 and 0.392.

**The earlier run** (three trials, from the probe before its trial count went to five and an unused
GPU-timer field went, which reads 0 under this renderer) measured at 1920x1080: flat 0.105, today's
water 0.245, curved 2.593, straight 2.671, the live tile 0.101 with 0.128 fixed. The curved lines'
pass moved by about a fifth between the two runs, today's water by more, since a pass that small
is near the noise.

## Reproduce

Run from a fresh clone, one engine at a time, with a display (a headless run says so and exits):

```sh
git fetch origin refs/pull/<PR>/head   # the pull request that added this folder
git checkout 50e3e4ab500f6da62351bbaea45ae9f6ff2265b6
GODOT=/path/to/Godot ./tools/check.sh  # imports the project once
out="$(mktemp -d)"
"$GODOT" --path . --disable-vsync res://tests/probes/voronoi_water.tscn -- --capture "$out/capture"
"$GODOT" --path . --disable-vsync res://tests/probes/voronoi_water.tscn -- --measure "$out/results.json"
for look in curved straight; do
  ffmpeg -framerate 30 -i "$out/capture/$look/frame-%04d.png" -vf \
    "crop=640:360:320:180,fps=12,split[a][b];[a]palettegen=max_colors=32[p];[b][p]paletteuse=dither=none" \
    "$out/$look.gif"
done
```

Both jobs refuse an output that exists. The capture writes four looks, `curved`, `straight`,
`tile_live` and `current` (today's water), 180 frames each; the measurement takes about a minute.
Timings vary between launches.

## Source

- The probe's revision: `50e3e4ab500f6da62351bbaea45ae9f6ff2265b6`, a clean tree at capture time.
- Godot 4.7.2.stable.official.ed1daf0bf, Compatibility renderer, OpenGL 4.1 Metal, Apple M2.
- The shader's settings are its defaults: a cell of 48 world pixels, a jitter of 0.8 of a cell, an
  intensity of up to 0.25 of a cell, periods between 3 and 7 s, outlines 1.25 world pixels wide,
  the base `#215979` (the average of today's water tile) and white at 85%.
- Footprint: five files and this README, about 2.7 MB, most of it the two GIFs.
