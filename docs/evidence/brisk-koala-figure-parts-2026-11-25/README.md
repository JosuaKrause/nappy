# brisk-koala: figures whose idle frame moves part of them keep their still pixels still

**Claim (in progress).** The busker's strum, a café sitter's lean and a poster crew's brush redraw
only their moving spans' layers; the owner's picture, the café's slice and table and the static
spans are not drawn again for a swap. The look is unchanged within raster rounding.

- `layers.json`: the reviewed extraction record of `tools/split-scenes.py --metadata-output`.
- `parity/`: `SCENERY_COMPARISON_OUTPUT=<dir> ./tools/test.sh probes/scenery_animation_art.gd`,
  the figure stems kept: each composite of the parts against its complete source, original left,
  composite right, both frames; at most one alpha level and about two premultiplied levels apart.
- `run.sh`, `analyse.py`: the alternating frame-record harness of m159-offscreen-2026-10-11 on
  days 1 and 4, hashing the files this work changes. Results not yet retained.
- Redraw counts: `./tools/test.sh probes/brisk_koala_idle_redraws.gd`, ten seconds of each event's
  own clock. Branch `161195c1d` counts are recorded; the base run is not yet done.

Source revision of the parts and parity: `161195c1d`. Native macOS, Apple M2, Godot 4.7.2.
