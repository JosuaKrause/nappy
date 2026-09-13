# Southern diagonal stroller wheel swap

This recipe produces the installed southeast diagonal stroller PNG from one immutable frozen SE
source. The displayed SW view is the runtime's horizontal mirror of that PNG. The final wheel
assignment is therefore explicit: final displayed SE wheel pixels equal the frozen source's
displayed SW wheel pixels, and final displayed SW wheel pixels equal the frozen source's displayed
SE wheel pixels. Re-running the recipe from the frozen source reproduces this same final
arrangement; it never reads the installed output and never toggles the swap a second time.

The body, canopy, handle, canvas, and height remain from the frozen source. The wheel assembly is
the reflection-closed union of the recorded half-open masks `(5, 22, 13, 29)`, `(13, 23, 23, 30)`,
and `(24, 21, 32, 29)`, together with their horizontal canvas-center reflections. Every target
pixel in that union receives the RGBA pixel at `(width - 1 - x, y)` from the frozen source in one
simultaneous assignment. Transparent pixels are copied as well, so displaced wheel pixels are
erased. No body pixel outside the wheel union changes.

The frozen input is `frozen-inputs/pram_front_diagonal-se-before.png`, a 36×30 RGBA PNG with
SHA-256 `adb38bc65fd1b3850ec7e45847e0224a9bf26700b4afa899531b362378db322d`. The installed and
bundled output has SHA-256 `e60f151730e0ef0e56e9f42a088f32aa5105caf8c8d340453569aa6fb256dc63`.
The native and 6× gray-opaque comparison sheets show SE and its runtime SW mirror before and after;
they are static pixel evidence and do not establish turn animation.

The reproducible command uses CPython 3.14.7 and Pillow 12.3.0 from the project environment:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run python \
  docs/evidence/stroller-southern-wheel-swap-2026-09-12/swap.py \
  --input docs/evidence/stroller-southern-wheel-swap-2026-09-12/frozen-inputs/pram_front_diagonal-se-before.png \
  --output-dir /tmp/stroller-southern-wheel-swap-rebuild
```

The generated PNG is checked against the installed asset with:

```sh
cmp /tmp/stroller-southern-wheel-swap-rebuild/pram_front_diagonal.png \
  assets/illustrated/svg-transfer/rig/pram_front_diagonal.png
```

The output directory must not already exist. The script hash, input hash, output hash, dimensions,
masks, and tool versions are recorded in `metadata.json`. `argparse` supplies `--help` and `-h`,
and rejects unknown arguments before any output directory is created.
