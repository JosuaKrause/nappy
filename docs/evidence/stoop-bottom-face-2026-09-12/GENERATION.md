# Stoop bottom step-face

This derivative addresses the requested missing brown vertical step wall at the bottom of the
32×32 stoop tile. The immutable input is the accepted paving registration bundle's registered stoop
PNG; its `registered_sha256` is checked before every build and verification. The existing `assets/tiles/stoop.svg` already carries the corresponding bottom boundary line
at `y=31`, so it remains the editable source authority and needs no geometry change.

The reproducible operation copies the complete lower full-width brown step-face band, source rows
19 through 24 (`[0,19,32,25]`, including its dark edge and brown face), to new rows 32 through 37.
It then resizes the resulting 32×38 RGBA image to 32×32 with Pillow
`Image.Resampling.NEAREST`. This keeps the operation pixel-exact and avoids introducing blended
colors. The source SHA-256, output SHA-256, script SHA-256 and Pillow version are recorded by
`rebuild.py`.

From the repository root:

```sh
uv run python docs/evidence/stoop-bottom-face-2026-09-12/rebuild.py build \
  --input-bundle docs/evidence/paving-boundary-joints-2026-09-12/bundle \
  --output-dir /tmp/stoop-bottom-face-rebuild
cmp assets/illustrated/svg-transfer/tiles/stoop.png \
  /tmp/stoop-bottom-face-rebuild/stoop.png
```

The rebuilt file must match the runtime target byte for byte. The `verify` command checks the
refined stoop against the accepted registered source and checks the other six
paving PNGs plus the sidewalk and alley layer bases against the existing immutable registration:

```sh
uv run python docs/evidence/stoop-bottom-face-2026-09-12/rebuild.py verify \
  --bundle-dir docs/evidence/paving-boundary-joints-2026-09-12/bundle \
  --target-dir assets/illustrated/svg-transfer/tiles
```

The enlarged before/after stills are generated as `stoop-before-10x.png` and `stoop-after-10x.png`
for repeated visual review. No source SVG, tile dimensions, anchors or runtime bindings change.
