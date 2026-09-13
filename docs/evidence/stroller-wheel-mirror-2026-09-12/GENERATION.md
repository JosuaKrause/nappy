# Diagonal stroller wheel reuse

This recipe applies a localized wheel and axle replacement to the southeast stroller view. The
SE body, hood, handle, canvas, alpha outside the masks and bottom registration remain from the
current runtime PNG. The donor is the current northeast diagonal PNG, whose wheel heading is
accepted for review; its wheel and lower axle regions are copied in place because the donor
already expresses the needed projected wheel plane. The paired SW runtime mirror continues to
receive its automatic horizontal reflection. No direction assignment or draw transform changes.

The immutable inputs are retained in `frozen-inputs/`. The source SE PNG has SHA-256
`8e09e8447d9f4398d735b91542351b8e754f53903f8b4eb12a8f95800e160611`; the NE donor has SHA-256
`11f278b6c7e584d7d4250365ad808c9142e9a65f576ef68ebad7115a50ad5699`. The resulting runtime
PNG has SHA-256 `adb38bc65fd1b3850ec7e45847e0224a9bf26700b4afa899531b362378db322d`.

The native masks use half-open Pillow bounds and cover the three visible wheel/axle regions after
their matching native centers and bottom rows are aligned: `(5, 22, 13, 29)`, `(13, 23, 23, 30)`
and `(24, 21, 32, 29)`. These preserve the fixed
36×30 canvas and bottom-most occupied row. Because the original wheels merge into the chassis,
the masks include their lower attachment pixels; the review sheets are required to catch any
seam or leftover axle mismatch.

The reproducible recipe uses CPython 3.14.7 and Pillow 12.3.0 from the repository environment:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run python \
  docs/evidence/stroller-wheel-mirror-2026-09-12/mirror.py \
  --input docs/evidence/stroller-wheel-mirror-2026-09-12/frozen-inputs/pram_front_diagonal-before.png \
  --donor docs/evidence/stroller-wheel-mirror-2026-09-12/frozen-inputs/pram_back_diagonal-donor.png \
  --output-dir /tmp/stroller-wheel-mirror-rebuild
```

The default operation replaces the masked donor pixels without mirroring. RGBA replacement
includes transparent donor pixels so displaced wheel remnants are cleared. `--mirror-donor`
provides an optional handedness comparison; the runtime operation omits it.

The script rejects changed input hashes, unexpected dimensions, existing output directories and
unknown arguments. It writes the candidate PNG, native and 6× before/after sheets, and input
hash records. `review/se-sw-before-after-6x.png` shows the current runtime's automatic SW mirror
beside the SE result; it is static assignment evidence and does not establish motion.

The enlarged review shows the diagonal wheel plane and its paired SW reflection while retaining
the stroller body height. Review the small fork transitions at native size in the game as well.

Verify the installed derivative and the four unchanged stroller textures from the repository root:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run python \
  docs/evidence/stroller-wheel-mirror-2026-09-12/verify.py \
  --runtime-dir assets/illustrated/svg-transfer/rig \
  --assignment-dir docs/evidence/stroller-view-assignment-2026-09-12/bundle/registered \
  --candidate assets/illustrated/svg-transfer/rig/pram_front_diagonal.png
```
