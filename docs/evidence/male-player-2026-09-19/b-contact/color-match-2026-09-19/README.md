# Father B trouser color match

[PLAYTEST-98](../../../../playtests/PLAYTEST-98.md) accepts the E/W artwork in `final/` and
rejects its old SE/SW drawing as the solution to the leg refinement. Preserve the accepted
side pixels; the diagonal frames in these sheets are not an approved replacement.

This uninstalled review set applies one deterministic native-pixel color transform to the two
generated pushing B trouser areas. The pose, contour, alpha, shoes, skin, jacket, head and hands
come unchanged from the current correct-contact candidate. The selector begins at native row 28,
below the painted hem, and selects only saturated blue pixels; the saved white masks identify every
changed pixel. The accepted A/C samples set the mapping: their 10th, 50th and 90th-percentile
trouser luminances are 61.5, 90.3 and 118.2, versus the candidate's 41.3, 79.8 and 111.0. The
fixed transform raises source luminance through `round(0.86 * source + 27)` and emits the sampled
A/C blue-gray channel ratio `(0.86, 1.02, 1.25)`. A middle A/C sample is RGB `(77, 92, 113)`.
The manifest preserves these sample bounds and the exact formula.

Review the clean [native sheet](generated/father-spritesheet-native.png), enlarged
[6× sheet](generated/father-spritesheet-6x.png), [native GIF](generated/father-animation-native.gif),
and [6× GIF](generated/father-animation-6x.gif). The current southeast pose remains an early
candidate: this folder changes its trouser color only.

## Corrected pushing and carrying review

The frozen delivered pushing and carrying rigs receive this same transform only on their side/E B
trousers. Their southeast B frames are copied unchanged, so the accepted blue-gray diagonal cannot
be brightened by this correction. Review the clean [pushing native sheet](final/pushing/pushing-spritesheet-native.png),
[pushing 6× sheet](final/pushing/pushing-spritesheet-6x.png), [pushing native GIF](final/pushing/pushing-animation-native.gif),
[carrying native sheet](final/carrying/carrying-spritesheet-native.png), [carrying 6× sheet](final/carrying/carrying-spritesheet-6x.png),
and [carrying native GIF](final/carrying/carrying-animation-native.gif). `inputs/final-pushing-rig`
and `inputs/final-carrying-rig` freeze the exact incoming frames; each final manifest records their
hashes and the one changed material mask.

## Reproduce and reuse

The frozen input rig and A/C family references are in `inputs/`. Use the locked Python environment
and a fresh destination:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/color-match-2026-09-19/assemble.py \
  --output-dir /tmp/father-color-match
diff -r docs/evidence/male-player-2026-09-19/b-contact/color-match-2026-09-19/generated \
  /tmp/father-color-match
```

For a corrected southeast or carrying rig, pass its B-containing rig and that state's A/C family:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/color-match-2026-09-19/assemble.py \
  --candidate-rig PATH/TO/CORRECTED-RIG --reference-rig PATH/TO/STATE-REFERENCE-RIG \
  --output-dir /tmp/father-color-match-new-state
```

The final pushing and carrying assemblies use `--recolor-views side`, which protects the
delivered front-diagonal B frame byte-for-byte. To reproduce either final output, substitute its
frozen rig, filename prefix and state:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/color-match-2026-09-19/assemble.py \
  --candidate-rig docs/evidence/male-player-2026-09-19/b-contact/color-match-2026-09-19/inputs/final-carrying-rig \
  --reference-rig docs/evidence/male-player-2026-09-19/b-contact/color-match-2026-09-19/inputs/final-carrying-rig \
  --sprite-prefix father_carrying --state carrying --recolor-views side \
  --output-dir /tmp/father-final-carrying-color
diff -r docs/evidence/male-player-2026-09-19/b-contact/color-match-2026-09-19/final/carrying \
  /tmp/father-final-carrying-color
```

The command asserts alpha equality and byte equality outside each saved mask. It also verifies the
native and nearest-neighbor 6× sheets and four 190ms GIF phases. This is offline evidence only;
it does not accept the southeast anatomy or the carrying correction.
