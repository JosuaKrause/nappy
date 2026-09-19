# Father's high-resolution crop-normalization preview

The pushing candidate is rejected because it copies the wrong anatomical contact; see
[PLAYTEST-96](../../../../playtests/PLAYTEST-96.md). These files preserve the failed donor
selection and normalization. The current carrying GIFs below remain independent review evidence.

Inspect the [clean eight-direction sheet](generated/father-spritesheet-6x.png), its
[native version](generated/father-spritesheet-native.png), and the
[native](generated/father-animation-native.gif) or
[6×](generated/father-animation-6x.gif) A/C/B/C loop. This is an uninstalled early
candidate for M167, the father's legs read as legs. Only E/W B and SE/SW B differ from
the straight-contact baseline; every other rig PNG is byte-identical.

For the separate baby-carrying review, see the current installed family's
[native](carrying-generated/carrying-native.gif) or
[6×](carrying-generated/carrying-6x.gif) A/C/B/C loop and the
[clean 6× sheet](carrying-generated/carrying-spritesheet-6x.png). Those artifacts read the
installed `father_carrying_*` PNGs directly. They do not use the normalized pushing candidate
and make no carrying-art change.

The preview removes the hard native crop, but it does not establish an accepted contact.
The generated side figure's foreground thigh appears to continue to the advancing
image-right shoe, so the required near-leg trailing ownership remains visually ambiguous or
wrong. Image generation also redraws trouser folds, shoes and the complete upper figure rather
than preserving literal donor pixels. The face, blue short jacket, cream shirt, pushing hands
and overall identity hold visually, but the B upper bodies are not byte-identical to A/C and can
pulse in the loop. Uniform registration keeps the 45px stature, but it does not keep internal
proportions equal: at native size the B hair, face, jacket and hand contours shift relative to A/C,
especially in the front diagonal, while the new trousers and shoes carry more visual weight. No
runtime or SVG file uses this result.

## Why the native crop failed

The final mother wears a coat that covers the pelvis and upper thighs. Her first exposed trouser
pixels begin at that long coat's hem, while the father's shorter jacket reveals the missing
pelvis-to-thigh transition. The rejected native splice jumped from the father's narrow hem at
row 30 directly to the already-separated donor thighs at row 31. Moving that horizontal seam
could not recover anatomy the donor coat occluded.

This attempt instead prepares the complete join at 12× before generation. The saved
[rough target](inputs/normalization-targets-review.png) makes the missing transition visible.
Its mother-leg masks follow the painted lower coat contour column by column: the script finds the
bottom red coat pixel, expands the contour across the adjacent dark outline, and retains only
artwork below it. It does not select an arbitrary common y row. The rough father layer comes from
the original generated large figure through source y=242, retaining the short jacket and a small
upper-trouser bridge for normalization.

## Frozen sources and roles

- Father identity and upper-body source, E/W B:
  `registered/extracted/father_side_b.png`, 260×388, whole source cell
  `[519,824,779,1212)`, visible bounds `[15,11,200,365)`, SHA-256
  `3fe82dc8e3e2c23578742ce35fb1dd34869081cdde3b8b5632457b84490bb7ae`.
- Father identity and upper-body source, SE/SW B:
  `registered/extracted/father_front_diagonal_b.png`, 259×388, whole source cell
  `[779,824,1038,1212)`, visible bounds `[41,11,186,368)`, SHA-256
  `3c2b3219bb71158a57078dcd782eaacb172f17f55bce09e43518e352488b323a`.
- Final mother leg source, E/W B: final P2 side B from
  `p2-acb-pass4-side-ne-extracted.png`, whole figure `[748,623,904,911)`, SHA-256
  `b67f962870ee64cf4301c2eed1c448a47b6ab51259a086b5a8d1c5ae455db4a3`.
- Final mother leg source, SE/SW B: final P2 front-diagonal B from
  `p2-acb-pass2-extracted.png`, whole figure `[1088,625,1203,916)`, SHA-256
  `f810a0b54821f7e3cb5669cce674c6c574d0f01656e9bc67bbd7fab5235b0c2d`.

The built-in image generator received, in order, the
[rough edit target](inputs/normalization-targets.png), the
[full father reference](inputs/father-high-resolution-reference.png), and the
[contour-clipped final mother legs](inputs/mother-final-leg-reference.png).
[The saved prompt](prompt.txt) names each role and the required hip-to-shoe ownership.
The single unmodified output is [raw/normalized.png](raw/normalized.png), 1376×1143 RGBA,
SHA-256 `626a7bf64aff8ac35f73b0e079f31c256d463c976b95a2e371ceafb6e97f6dc9`.
Generation is nondeterministic; the saved raw output makes registration reproducible.

## Whole-figure registration

Each generated panel is extracted through its real alpha, uniformly fitted to 45 native pixels
at 12×, placed one pixel above the ground line and reduced to the unchanged 26×46 canvas with
Lanczos. Horizontal placement matches the protected C frame's opacity-weighted upper-body
centroid over its top 57%, so the new stride does not choose the hand position. The side figure's
full-stature width requires an explicit fitting choice in this attempt: its requested
12× x was −7 and it is placed at x=0, preserving the complete silhouette instead of clipping or
shrinking it. The front diagonal is placed at its requested x=34. Registration operates on each
coherent whole figure; it does not paste protected native upper rows over generated legs.

Columns in the clean sheet are N, NE, E, SE, S, SW, W, NW; rows are A, C, B, C. W and SW mirror
the two authored generated results. GIFs use four 190ms phases.

## Reproduce

Run from the repository root with Python 3.14 and Pillow 12.3.0 from the locked environment,
using fresh destinations:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/normalized-crop-2026-09-19/prepare.py \
  --output-dir /tmp/father-normalized-inputs
diff -r \
  docs/evidence/male-player-2026-09-19/b-contact/normalized-crop-2026-09-19/inputs \
  /tmp/father-normalized-inputs

UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/normalized-crop-2026-09-19/assemble.py \
  --output-dir /tmp/father-normalized-review
diff -r \
  docs/evidence/male-player-2026-09-19/b-contact/normalized-crop-2026-09-19/generated \
  /tmp/father-normalized-review
```

The assembler verifies the frozen generator output and all preparation inputs, unchanged native
canvases, byte-identical protected frames, nearest-neighbor 6× sheet, and four-phase GIF timing.
Those checks establish provenance and deterministic assembly, not anatomical correctness,
motion quality or player acceptance.

The carrying review reproduces separately from the same folder:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/normalized-crop-2026-09-19/carry.py \
  --output-dir /tmp/father-carrying-review
diff -r \
  docs/evidence/male-player-2026-09-19/b-contact/normalized-crop-2026-09-19/carrying-generated \
  /tmp/father-carrying-review
```

`carrying-inputs.json` pins all fifteen installed carrying PNGs and the shared sheet/GIF helper.
The carrying assembler verifies their native canvases and hashes, the nearest-neighbor 6× sheet,
all eight direction assignments and the four 190ms GIF phases.
