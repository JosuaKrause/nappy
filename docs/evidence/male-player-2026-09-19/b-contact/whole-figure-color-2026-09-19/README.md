# Diagonal B upper restoration, hem adjustment, and material match

[PLAYTEST-100](../../../../playtests/PLAYTEST-100.md) keeps the uncrossed B legs and pose, then asks for the existing same-state diagonal body texture, a lowered new-B hem edge, and separate jacket/trouser color correction. This review artifact uses C as the exact native upper source: rows 0–26, apart from the 20 opaque moved-edge destination pixels, including the face, hair, arms, shirt, and the carrying baby and blanket, copy from C without scaling or recoloring. The new B legs remain from row 28 down.

The new B hem contour moves down two native pixels. Pushing copies source rectangle `x=7..17`, `y=24..25`; carrying copies `x=8..18`, `y=24..25`. Only opaque pixels in those two-row rectangles move, so its painted edge and outline occupy the new lower destination. The output manifest records the exact source rectangle, downward shift, and destination-pixel count. Hem alpha changes stay inside that moved contour; the restored upper uses aligned C alpha, and the legs below row 27 retain original B alpha.

The jacket mapping samples A/C lower-jacket patches and applies a five-quantile affine luminance fit only to the moved B hem texture. Trousers use a one-parameter luminance gain from the same-state A/C 90th-percentile trouser sample, constrained above 1 to meet the request to lighten them while preserving B shading ratios. Skin, hair, shirt, baby, and blanket are exact C pixels; shoes stay original B pixels. `generated/manifest.json` gives their concise original-B/reference-C sample statistics, material fit values, changed-pixel counts, and every output hash.

| State | Comparison: A, C, original B, result | Clean sheet | Animation |
|---|---|---|---|
| Pushing | [12×](generated/pushing/comparison-a-c-original-recolor-12x.png) | [native](generated/pushing/pushing-spritesheet-native.png), [6×](generated/pushing/pushing-spritesheet-6x.png) | [native](generated/pushing/pushing-animation-native.gif), [6×](generated/pushing/pushing-animation-6x.gif) |
| Carrying | [12×](generated/carrying/comparison-a-c-original-recolor-12x.png) | [native](generated/carrying/carrying-spritesheet-native.png), [6×](generated/carrying/carrying-spritesheet-6x.png) | [native](generated/carrying/carrying-animation-native.gif), [6×](generated/carrying/carrying-animation-6x.gif) |

The comparison columns are, left to right: diagonal A, diagonal C, the original approved-leg B, and the restored-upper/adjusted-hem result. Sheets use columns N, NE, E, SE, S, SW, W, NW and A/C/B/C rows; western frames mirror their eastern source. GIF phases use the same order at 190ms.

## Reproduce

`inputs/` contains the frozen 30 authored PNGs. Its manifest pins their hashes, the approved unchanged E/W B hashes, Pillow, and the shared sheet helper. The recipe fails if a frozen input or helper changes. Use a fresh destination:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/whole-figure-color-2026-09-19/assemble.py \
  --output-dir /tmp/father-whole-figure-color
diff -r docs/evidence/male-player-2026-09-19/b-contact/whole-figure-color-2026-09-19/generated \
  /tmp/father-whole-figure-color
```

The recipe asserts C-exact restored upper pixels apart from the shifted B edge, the bounded shifted-hem alpha, unchanged RGB and alpha outside the recorded B edit/color regions, all 28 protected authored PNGs byte-for-byte, native canvases, nearest-neighbor 6× sheets, and all four 190ms GIF phases. These are uninstalled review images; runtime assets and shared procedures do not change.
