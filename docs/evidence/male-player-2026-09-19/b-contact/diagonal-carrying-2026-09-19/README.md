# Pushing and carrying contact preview

[PLAYTEST-98](../../../../playtests/PLAYTEST-98.md) rejects the restored diagonal drawing:
it is the old thin artwork this PR is meant to refine. This recipe preserves the reviewed
attempt; its SE/SW output is not an approved solution. The separately color-matched E/W
result is accepted and must remain unchanged.

This uninstalled early preview provides actual carrying leg changes for
[PLAYTEST-103](../../../../playtests/PLAYTEST-103.md). Inspect the clean eight-direction
[carrying PNG](generated/carrying/carrying-spritesheet-6x.png) and
[carrying GIF](generated/carrying/carrying-animation-6x.gif), alongside the
[pushing PNG](generated/pushing/pushing-spritesheet-6x.png) and
[pushing GIF](generated/pushing/pushing-animation-6x.gif). Each state also has native-size
PNG and GIF files in its output folder. Columns are N, NE, E, SE, S, SW, W, NW;
rows and animation phases are A/C/B/C, with 190ms per phase.

This folder preserves geometry before the deterministic color pass. The
[color-match recipe](../color-match-2026-09-19/README.md) supplies the palette-matched
review. Nothing here changes runtime art, stroller art or gameplay.

## Per-view construction

| Directions | Pushing B | Carrying B |
|---|---|---|
| N/S | Accepted straight-contact baseline | Reflect A's lower body around x=11, using x=0..22 below y=28; preserve B's original upper |
| NE/NW | Accepted baseline unchanged | Original carrying B unchanged |
| E/W | Correct-contact normalized profile | Same corrected continuous profile legs under the original carrying upper |
| SE/SW | Accepted straight-contact baseline | Same provisional diagonal lower body under the original carrying upper |

All A/C images and NE/NW B are byte-identical to their respective baselines. Pushing N/S B
also remain byte-identical. Every changed carrying B preserves original pixels in rows 0..27,
including the baby, face, arms and carrying pose. Western views mirror their eastern authored
frames. The changed carrying B frames differ from the installed artwork below row 28.

The profile's near thigh trails across the far advancing thigh and continues into the left shoe.
Its normalized 312×552 source supplies rows 336..551, reduced with Lanczos to the 26×46 canvas.
The carrying upper uses its original high-resolution extracted B picture: crop its alpha bounds,
fit uniformly to 540px tall, center horizontally on the 312×552 working canvas, and place at y=12.
Save that assembled proof, reduce, then restore the original registered upper rows exactly.
The diagonal lower uses the accepted native straight-contact B, enlarged 12× with nearest-neighbor
before the same assembly and reduction. This explicitly remains a provisional projected donor.

## Visual limits

This is an early contact preview, not a finished natural-leg refinement. The southeast contact
has the accepted oblique foot separation and raised trailing foot; a naturally drawn independent
three-quarter donor remains unresolved. The profile B has wider separation and heavier trousers
and shoes than A/C. The carrying construction uses a fixed upper/lower join at y=28 without a
new whole-figure normalization, so the pelvis join and proportion change still need visual review.
Native inspection shows a connected silhouette, but that does not establish natural articulation.
Static sheets and offline loops do not prove gameplay movement or live stroller contact.

## Reproduce

Use the locked Python 3.14/Pillow environment from the repository root, with a fresh destination:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/diagonal-carrying-2026-09-19/assemble.py \
  --output-dir /tmp/father-diagonal-carrying-review
diff -r \
  docs/evidence/male-player-2026-09-19/b-contact/diagonal-carrying-2026-09-19/generated \
  /tmp/father-diagonal-carrying-review
```

`inputs.json` pins every selected source and assembly helper by SHA-256; changed inputs fail
before output creation. `generated/manifest.json` records each output hash. The assembler checks
native canvas sizes, protected source bytes, preserved carrying upper pixels, actual changed
carrying lower pixels, nearest-neighbor 6× sheets and four-phase GIF timing. Its one-time
`--freeze-inputs` option refuses an existing manifest; `-h` and `--help` show the accepted flags.
These checks establish deterministic provenance and preservation, not artistic acceptance.
