# Father's final-woman-leg literal-copy preview

This is rejected crop evidence, retained with its exact recipe. The player's verdict is in
[PLAYTEST-95](../../../../playtests/PLAYTEST-95.md); the correction is open under M167,
the father's legs read as legs, in `docs/TODO.md`.

Inspect the [clean eight-direction sheet](generated/father-spritesheet-6x.png), its
[native version](generated/father-spritesheet-native.png), and the
[native](generated/father-animation-native.gif) or
[6×](generated/father-animation-6x.gif) A/C/B/C loop. The separate
[donor sheet](generated/final-mother-b-donors.png) shows only the two exact high-resolution
mother figures used here, with their direction roles; it is not a before/after comparison.

This uninstalled preview changes E/W B and SE/SW B only. Every other frame is byte-identical to
the straight-contact baseline, and rows 0 through 30 of both changed authored frames remain exact
father pixels. No runtime, SVG, stroller or shared-procedure file changes.

## Final donor selection

The [final P2 selected high-resolution sheet](../../../comic-pushing-strides-2026-09-12/registered/p2-selected-generation.png)
names two different whole figures for these directions. E/W uses
side B from `p2-acb-pass4-side-ne.png`, whose corrected leg ownership was selected specifically for
the final family. SE/SW uses front-diagonal B from `p2-acb-pass2.png`, an independently drawn
three-quarter figure. The final P2 registration records both with `anatomical_splice_used: false`.
This preview reads their retained transparent high-resolution derivatives rather than the 26×46
runtime PNGs:

- E/W: `registered/p2-acb-pass4-side-ne-extracted.png`, whole-figure crop
  `[748,623,904,911)`, SHA-256
  `b67f962870ee64cf4301c2eed1c448a47b6ab51259a086b5a8d1c5ae455db4a3`.
- SE/SW: `registered/p2-acb-pass2-extracted.png`, whole-figure crop
  `[1088,625,1203,916)`, SHA-256
  `f810a0b54821f7e3cb5669cce674c6c574d0f01656e9bc67bbd7fab5235b0c2d`.

The source PNGs retain the raw generated alpha. The E/W lower crop is `[748,798,904,911)` and the
SE/SW lower crop is `[1088,800,1203,916)`. In both whole figures, y=192 is the first row retained
as visible trousers; the earlier crop rows exist only to keep the final figure's scale and are made
transparent. Each lower crop is uniformly Lanczos-fitted to an 18-native-pixel-high 12× working
region, placed at x=0 for side and x=48 for front diagonal, and bottom-aligned to y=552. The father
rows 0 through 30 are pasted last. Thus the source drawing supplies the full visible trousers,
both legs and both shoes through the ground line, while the accepted father supplies the complete
visible upper body. The donor colors and contours are not repainted, projected or generated; final
native registration necessarily resamples those retained pixels.

W and SW mirror the two authored results. Columns are N, NE, E, SE, S, SW, W, NW; rows are A, C,
B, C. GIFs use four 190ms phases.

## Reproduce

Use the locked Python 3.14/Pillow environment from the repository root and a fresh destination.
The assembler fails if any frozen source changes and verifies the protected files, father rows,
native canvases, nearest-neighbor review enlargement and GIF timing:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/final-woman-legs-2026-09-19/assemble.py \
  --output-dir /tmp/father-final-woman-legs
diff -r \
  docs/evidence/male-player-2026-09-19/b-contact/final-woman-legs-2026-09-19/generated \
  /tmp/father-final-woman-legs
```

`inputs.json` pins the assembler, both extracted final P2 sources, the final-selection sheet and
registration record, all protected father files and the reused sheet/GIF helpers. The output
manifest records both transformations and every derivative hash. This evidence establishes source
identity and deterministic assembly, not whether the horizontal jacket/trouser join looks natural
in motion or whether the player accepts it.
