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

South water occupies its own surface, with no water cells or source in the static ground TileMap
or composed sheet. The approved motion distorts the existing water texture by at most 0.65px horizontally and 0.35px
vertically, using sine angular rates of 0.7 and 0.5 radians/second. A local, pausable shader
clock advances without rebuilding either water or ground draw lists. Sampling wraps within the
water region and clamps to its pixel centers, so other atlas regions cannot bleed into it.
The player approves this appearance. It is not a gameplay timing change.

## Reproduce source extraction and comparison

From the imported repository root:

```sh
uv run python tools/split-scenes.py --check
uv run python tools/split-scenes.py
./tools/check.sh
./tools/test.sh scenery_animation event_redraw atlas_leaf_consumers
./tools/test.sh probes/scenery_animation_art.gd
```

The extraction recipe uses Python's standard XML parser and Godot's SVG renderer. It preserves
source elements, attributes and painter order, writes registered component SVGs, updates atlas
membership, and generates `EventSceneryParts`. The generated SVGs and registration table say not
to edit them by hand. `--check` stages the complete result outside the repository and compares all
runtime outputs without writing. This evidence folder's `layers.json` is the retained record of
the reviewed extraction, including source SHA-256 hashes and each component's integer bounds; an
ordinary regeneration does not overwrite it. A new record is written only when an explicit
`--metadata-output <path>` is supplied. Source changes that alter the expected span structure abort
extraction instead of silently assigning a different layout.

The comparison probe performs its raster checks in memory during ordinary maintenance. To
retain a new comparison, point it at a new output directory explicitly; it never rewrites this
reviewed evidence folder by default:

```sh
SCENERY_COMPARISON_OUTPUT=/absolute/path/to/new-evidence \
  ./tools/test.sh probes/scenery_animation_art.gd
```

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
not timing benchmarks. The player approves the water ripple.

The [rendered warmup run](rendered-warmup-2026-09-26/README.md) retains ordinary and escape boot
frames from one Compatibility-renderer process. Its metadata records a rendered frame while both
the halo and water warmup nodes remain live in each boot path. It proves the real draw reaches the
renderer on both paths; it makes no frame-time or hitch claim.

The fixture's complete burst records zero building/static-roof/event-owner/event-static/water
draw callbacks during capture, two rotor callbacks, 72 pipe-motion callbacks and ten smoke-motion
callbacks across both axes. All animation clocks hold while paused and advance after resuming.
Its two rejected launches establish no visual or timing result: the first fails script parsing
on an untyped diagnostic bool before capture; the second fails a no-vent precondition and its
partial frames/log remain in `rejected-fixture-no-vent`. Full headless fixture construction passes
before the final retry. Captures use code checkpoint 224e1022 plus the fixture source; the static
water-source cleanup is not part of the waterfront launch's loaded source.

The [native comparison](native/README.md) retains three alternating profiled pairs and one
disabled-profiler pair, all accepted. Every six-second baseline window contains 180 full-building
draws; every after window contains zero. Peak atlas lookups fall from 5,357–5,388 to 171–187 per
frame. Overall median frame time is mixed across pairs and essentially unchanged in the disabled
companion; the evidence supports removal of the targeted redraw spikes, not a general FPS claim.

The focused tests exercise ownership,
phase changes, static scene keys, unchanged collisions, water/ground separation, repaint and
resource release/reentry. A headless check does not establish actual draw callback counts.

Native measurements use the same final probe schema on both revisions, five seconds of warmup
and six active seconds, alternating before/after with only one measured process at a time.
The baseline includes the latest merged main and removes only the animation implementation.
No result here establishes phone, browser or GPU performance.

The event raster comparison differs by at most one RGBA8 alpha level and three premultiplied
color levels from the original scene. These are separate-rasterization/compositing differences,
not displaced geometry or missing underlying surfaces. The event atlas grows from 642×1074 to
765×1024 pixels (375,408 additional base RGBA8 bytes), because unchanged halo/badge rendering
still consumes the complete scenes alongside the new cropped parts. The building atlas remains
332×576 and the baked ground atlas remains 172×308; no atlas-memory saving is claimed.

Final CI reconciliation removes redundant events-page references from `EventScenery` and updates
the southern-camera coverage assertion to include the actual water surface. The event manager
owns the shared page throughout its tree lifetime. Both failures reproduce before correction;
the combined camera/main/atlas-events/scenery/event-redraw/atlas-consumer focused run passes
3,093 checks after it, and import/boot passes. Artwork, draw geometry and timing are unchanged.
The [native report](native/README.md#final-ci-reconciliation) identifies the measured source and
the later ownership fix separately; no new timing results are claimed for that fix.
