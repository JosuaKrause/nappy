# Sidewalk material continuity

This record preserves seven 32×32 sidewalk PNGs and their generation recipe.
Their continuity with curb paving remains open in PLAYTEST-65 and `docs/TODO.md`.
The [actual-map layout review](../sidewalk-layout-review-2026-09-12/GENERATION.md) shows these
textures in repeated street runs and junction corners using the game's tile selector.
The curb and road SVG/PNG controls are the fixed inputs for this recipe. The sidewalk SVG
family uses the same source geometry: all seven target sources and all eight curb sources use the
same warm gray fill, darker joints, and staggered seam coordinates. The recorded mismatch is
between the independently generated PNG materials.

## Source and generation contract

[`source-manifest.json`](source-manifest.json) records SHA-256 hashes for the rasterizer, every
target SVG, all eight protected curb SVG/PNG controls, the normal and main road controls, the two
approved style references, the accepted-control material panel, and the target PNGs present before
this redraw. Godot 4.7.2 renders each SVG at native size and 6× before any generation. The source
neighbor panel places road, curb, and sidewalk in the correct north, east, south, or west order.
These short strips expose individual joins; the actual-map review covers repetition and corners.

The built-in imagegen tool performs the nondeterministic raster edits; it does not expose a model
identifier. Each file under [`prompts/`](prompts/) is the exact prompt supplied for its matching raw
output under [`generated/`](generated/). The plain tile uses the accepted north curb PNG as the edit
target and removes only its curb strip. Every damaged tile uses that saved plain raw output as its
edit target, its own Godot-rendered SVG as the damage source, the eight accepted curb interiors as
material authority, and both approved comic references as style references. The resulting family
therefore shares one paving base while hairline, cracked, and broken A/B states retain separate
damage placement.

[`registered/registration.json`](registered/registration.json) is the retained input authority. It
records each prompt hash, source and reference path/hash, raw-output hash and dimensions,
normalized full-frame cell `[0, 0, 1, 1]`, fixed pixel bounds, Pillow version, and font. The script
checks that authority before creating an output directory and checks it again after writing.
Registration takes the whole saved square output as a fixed cell, resizes it to 32×32 with Pillow's
LANCZOS resampler, and makes opaque-ground alpha explicit. It does not fit visible bounds, paste
curb planes, paint pixels, or restore an SVG mask.

## Reproduction

Run registration and control verification from a checkout of
5210f6d828cf61d22c95516fbb1c34ff7d96529d, whose live assets match this recipe's retained
authority. Other ground recipes can then change the runtime textures without changing this record.

The source and before panels describe the pinned source revision
bef0c39af93da2607b76faa868815b899d48ebc4. Keep a separate checkout at that revision and point
`--before-dir` to its illustrated tile directory, which contains the seven original PNGs whose
hashes are retained in the source manifest:

```sh
./tools/check.sh
uv run python docs/evidence/sidewalk-continuity-2026-09-12/assemble.py prepare \
  --output-dir /tmp/sidewalk-source-rebuild \
  --before-dir /path/to/bef0c39-checkout/assets/illustrated/svg-transfer/tiles
```

After the built-in imagegen outputs are saved at the paths named in the registration record, fixed
registration and byte comparison use:

```sh
uv run python docs/evidence/sidewalk-continuity-2026-09-12/assemble.py register \
  --output-dir /tmp/sidewalk-registered-rebuild
uv run python docs/evidence/sidewalk-continuity-2026-09-12/assemble.py verify \
  --registered-dir /tmp/sidewalk-registered-rebuild \
  --compare-to docs/evidence/sidewalk-continuity-2026-09-12/registered
uv run python docs/evidence/sidewalk-continuity-2026-09-12/assemble.py verify-controls
```

Both assembly commands refuse an existing output directory. `register` validates retained raw,
prompt, source, reference, dimension, Pillow, font, SVG, rasterizer, curb, and road authority before
creating its new directory. `verify` requires an identical file set and SHA-256 hash for every
registered tile, manifest, and native/6× review panel.

The retained environment is Python 3.14.7, Pillow 12.3.0, and Godot
4.7.2.stable.official.ed1daf0bf. Comparison labels use `Pillow ImageFont.load_default()`; all 6×
panels use nearest-neighbor enlargement so native pixels remain inspectable.

## Review panels

- [`source/edge-neighbors-native.png`](source/edge-neighbors-native.png) and its
  [`6× view`](source/edge-neighbors-native-6x.png) show SVG-source continuity against every curb
  direction for normal and main roads.
- [`before/edge-neighbors-native.png`](before/edge-neighbors-native.png) and its
  [`6× view`](before/edge-neighbors-native-6x.png) show the input PNG material mismatch with the
  same arrangements.
- [`registered/edge-neighbors-native.png`](registered/edge-neighbors-native.png) and its
  [`6× view`](registered/edge-neighbors-native-6x.png) show the selected plain paving against all
  eight protected controls. The east curb keeps its accepted, brighter pre-existing variation.
- [`registered/damaged-centers-native.png`](registered/damaged-centers-native.png) and its
  [`6× view`](registered/damaged-centers-native-6x.png) surround each damaged center with the plain
  family base across both axes.
- [`registered/damaged-repetition-native.png`](registered/damaged-repetition-native.png) and its
  [`6× view`](registered/damaged-repetition-native-6x.png) repeat every damaged tile in both axes,
  exposing cell outlines, phase changes, or broken edge coverage.

The runtime files at the pinned recipe revision are exact copies of `registered/tiles/*.png`.
The recipe preserves their `.import` sidecars and Godot resource identities.
