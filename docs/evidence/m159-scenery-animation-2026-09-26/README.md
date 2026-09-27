# Separate scenery drawing

Roof vents use a stationary housing and a six-pixel rotor, registered at (21, 19) in the
original 32px canvas. `Building` retains stationary furniture batches between rotor layers,
preserving painter order and the original 1.4-second timer. Complete vent SVGs are reference
sources, absent from the runtime atlas.

Pipe and crash SVGs are separated at identical/changing vector spans. Each static span contains
only unchanged elements; underlying geometry remains intact when spray or smoke uncovers it.
Moving spans are cropped to their union bounds plus one transparent texel where the original
canvas permits it. That texel preserves subpixel stroke coverage at the SVG viewport boundary.
The original complete scenes remain the halo and badge sources. Each event retains its existing
clock, per-instance phase offset, collider, shadow and lifetime.

South water occupies its own surface, with no water cells in the static ground TileMap. The
motion proposal distorts the existing water texture by at most 0.65px horizontally and 0.35px
vertically, using sine angular rates of 0.7 and 0.5 radians/second. A local, pausable shader
clock advances without rebuilding either water or ground draw lists. Sampling wraps within the
water region and clamps to its pixel centers, so other atlas regions cannot bleed into it.
This is an implementation choice for visual review, not a gameplay timing change.

## Reproduce source extraction and comparison

From the imported repository root:

```sh
python3 docs/evidence/m159-scenery-animation-2026-09-26/split-scenes.py
./tools/check.sh
./tools/test.sh scenery_animation event_redraw atlas_leaf_consumers
./tools/test.sh probes/scenery_animation_art.gd
```

The extraction recipe uses Python's standard XML parser and Godot's SVG renderer. It preserves
source elements, attributes and painter order, writes registered component SVGs, updates atlas
membership, and generates `EventSceneryParts`. `layers.json` records source SHA-256 hashes and
each component's integer bounds. Source changes that alter the expected span structure abort
extraction instead of silently assigning a different layout.

Each `*-parity.png` shows original left and composition right, phase A above B, enlarged three
times with nearest-neighbor filtering. `raster-parity.json` records the differences from
separate RGBA8 rasterization/compositing, in alpha and premultiplied color. These sheets establish
registration and source composition; runtime bursts establish animation and sorting.

## Verification status

`scenery-parts.gif` shows an enlarged synthetic fixture of production nodes, including both
event orientations. `waterfront.gif` shows the actual south shore, fixed bulkhead and bridge
(seed 4242, day 1, `--spawn edge:s --walk 0.1s7p --invincible --no-save`). Both retain 36 frames
and their real timestamps; `burst-gif.py` quantizes timestamp boundaries to GIF centiseconds.
The whole waterfront run retains its original directory name. These are visual review artifacts,
not timing benchmarks. The water ripple is a proposal for human review.

The fixture's complete burst records zero building/static-roof/event-owner/event-static/water
draw callbacks during capture, two rotor callbacks, 72 pipe-motion callbacks and ten smoke-motion
callbacks across both axes. All animation clocks hold while paused and advance after resuming.
Its two rejected launches establish no visual or timing result: the first fails script parsing
on an untyped diagnostic bool before capture; the second fails a no-vent precondition and its
partial frames/log remain in `rejected-fixture-no-vent`. Full headless fixture construction passes
before the final retry. Captures use code checkpoint 224e1022 plus the fixture source; the static
water-source cleanup is not part of the waterfront launch's loaded source.

Controlled native before/after timing is still pending. The focused tests exercise ownership,
phase changes, static scene keys, unchanged collisions, water/ground separation, repaint and
resource release/reentry. A headless check does not establish actual draw callback counts.

Native measurements use the same final probe schema on both revisions, five seconds of warmup
and six active seconds, alternating before/after with only one measured process at a time.
The baseline includes the latest merged main and removes only the animation implementation.
No result here establishes phone, browser or GPU performance.
