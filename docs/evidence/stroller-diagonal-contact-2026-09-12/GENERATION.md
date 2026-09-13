# Stroller north-diagonal contact review

This static assembly uses the current registered PNGs after the accepted travel-direction
assignment. It compares the grounded 7/6 stroller placement before and after a north-diagonal
screen-Y correction across P2's contact A, together C and contact B poses. NE uses the authored
east diagonal; NW uses the runtime's horizontal mirror. N is included as the unchanged north
cardinal reference.

The runtime placement stays 24px horizontal, 17px north, 9px south, `0.7` oblique Y and zero fixed
lift. The new term is `4 * facing.x² * facing.y² * 2px` while `facing.y < 0`; it reaches exactly
2px at NE/NW, and is zero at N, E, W and every south-facing direction. The term is continuous
through turns and does not read the eight-direction selector.

The native sheet is `comparison-native.png`; `comparison-native-6x.png` is nearest-neighbor enlargement.
The left three columns are before and the right three are after, with each row in N, NE, NW order
and each group in A, C, B order. The review measures a static hand-to-handle registration change;
it does not establish live turning or animation timing.

Inputs are frozen copies of the current runtime PNGs in `inputs/`. `SHA256SUMS` guards all eight
inputs before assembly. Regenerate from the repository root with the existing locked Pillow
environment (a fresh output directory is required because the script refuses overwrites):

```sh
UV_CACHE_DIR=/tmp/nappy-stroller-diagonal-uv-cache uv run --frozen python \
  docs/evidence/stroller-diagonal-contact-2026-09-12/assemble.py \
  /tmp/stroller-diagonal-contact/comparison-native.png
cmp docs/evidence/stroller-diagonal-contact-2026-09-12/comparison-native.png \
  /tmp/stroller-diagonal-contact/comparison-native.png
cmp docs/evidence/stroller-diagonal-contact-2026-09-12/comparison-native-6x.png \
  /tmp/stroller-diagonal-contact/comparison-native-6x.png
```

The preserved source files are PNG derivatives of the corresponding authored SVG family; this
change does not edit or reassign any texture.
