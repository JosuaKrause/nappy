## M145 — The route's curbs, tinted faint yellow · built 2026-09-14, an experiment

*(2026-09-14, [PLAYTEST-75](../playtests/PLAYTEST-75.md): "can we tint the curbstones that belong
to a path slightly yellow? to give a faint hint on an optimal path. I just want to try it out
… it should be faint as to more subconciously guide as well" — "I don't really want it to be
how we show paths but I want to assess whether it can be done without being too obvious and on
the nose".)* One agent commit on `feature/m145-route-kerb-tint`, reviewed on the PR; the two
stills are `evidence/m145-route-kerb-tint-2026-09-14/`.

**What it is, and that it is a trial.** `docs/CITY.md`'s rule that there is no cue of any
kind toward calm and that the city never suggests a route stands, with one qualification
written beside it: the route's own curbstones — the stone strip along the pavement's edge, not
the paving beside it — carry a faint yellow cast, on trial, and the trial's question is whether
a hint on the ground can stay below being noticed as one. Alpha zero is the off switch, and the
answer is what gets kept, not the tint. No second layer: `GroundLayers.build_tile_set()` gives
each of the eight kerb sources (`GroundTiles.SIDEWALK_KERB_N/S/E/W`,
`SIDEWALK_KERB_MAIN_N/S/E/W`) a tinted twin, at the id `GroundTiles.route_twin_of` gives its
source — 58 through 65, the first ids free of everything else `build_tile_set` assigns (57 is
the last damage source, `ALLEY_CRACKED_BROKEN_B`). In PNG mode the twin is the same `sidewalk`
base and the same rotated `curbstone` component `_composed_texture` would use, with the
component's own opaque pixels blended toward `Palette.ROUTE_KERB_TINT` by
`Tuning.ROUTE_KERB_TINT_ALPHA` before `GroundLayers.compose_image` lays it onto the base, so the
paving, and on a main-road kerb the red clearway line (`main_edge_red`), are untouched. In SVG
mode, where nothing is composed, the twin is the authored kerb raster
(`assets/tiles/sidewalk_kerb*.svg`) with every pixel matching the stone's own fill, `#a49b8c`
(`GroundLayers.SVG_KERB_STONE_COLOR`), blended the same way — detected by colour rather than by
a rect per source, since all eight files already share that one fill and a main kerb's clearway
line does not. After the day's tree is grown in `City._close_streets()`,
`City._tint_the_route_kerbs()` re-sets on `_ground` itself every cell whose source is one of the
eight and whose `Corridor` depth is zero to its twin, same atlas coordinates — both pavements of
every street on the tree, since a street tile answers at the grain of its street, and never a
junction, which has no kerb. `start_finale()` grows no tree, so nothing there ever carries a
twin. `Tuning.ROUTE_KERB_TINT_ALPHA` is 0.45: the strip is two pixels wide in the SVG art and
three in the illustrated `curbstone.png`, so the 0.18 that read as nothing spread over a whole
tile has to run higher to register within its own width. The test builds a real city, computes
the expected set independently from `GroundTiles.source_for` and `Corridor.of`, and asserts
`_ground`'s own cells carrying a twin source equal it exactly with the atlas coordinates the
plain source would have had, and none after the finale; a second test composes one twin in each
mode and asserts a curbstone pixel moved toward the tint while a paving pixel stayed
bit-identical to the plain source's.

**What the stills say.** At 0.45 the cast is visible on inspection, though not at a glance
across the whole debug-cluttered frame. `tint.png`'s own debug readout gives the player's tile
(`80, 89`) at capture time, which fixes where on the map the picture is looking: the street
right outside her door sits at `Corridor` depth 1 (a doorway is not a route — the tree starts at
the home street rather than counting it), so its kerbs stay plain, and sampled at that street
they read `(185-192, 163-169, 133-138)`, the isolated `curbstone.png`'s own untinted tone
(`(178, 161, 140)` on average) under the scene's daylight. One block over, the corridor's own
street — the one the purple route line in `tint-with-route-lines.png` runs along, on both
pavements — samples `(200-216, 178-192, 116-127)` at the same spot in the same frame: plainly
warmer and yellower than the doorstep's kerb, and a close crop shows a pale yellow band running
the length of both sidewalks exactly where the route line does, against a plain grey-tan kerb
where it does not. So the cast is real and correctly placed — on the corridor and nowhere else —
and registers on a close look without shouting from across the street, which is the trial's own
target; whether it also registers at the pace of an ordinary run is what the review still asks.

**The first build tinted the sidewalk.** The trial's first commit drew the route's kerb *tiles*
again on a second `TileMapLayer`, `RouteKerbs`, modulated by `Palette.ROUTE_KERB_TINT` — paving
and curbstone together, since a kerb tile is the whole pavement-edge tile and a `modulate` colours
everything drawn under it. The player's correction, on [PLAYTEST-75](../playtests/PLAYTEST-75.md):
*"that is not the curbstone -- it's the sidewalk"* — *"I specifically said *curbstone*"* — and the
instruction that replaced it: *"add the tint when compositing the curbstone onto the sidewalk"*.
`Tuning.ROUTE_KERB_TINT_ALPHA` carries its own history for the same reason: 0.18 was set against a
whole tile and read as nothing once the tint moved onto the two-or-three-pixel stone alone, so
this build re-dials it to 0.45 against the corrected art.

**Choices made where the entry was silent, open to overturn.** The hue; the constant's place
beside `BUILDING_SHADOW_ALPHA`; all eight kerb sources listed though a route never runs
alongside the main road, since the rule is "a kerb tile on an inside street" rather than a
list of today's kerbs; the finale clearing the layer explicitly since nothing else would;
the test in the routes suite, with the real-scene rig borrowed from the debug-layers suite
because neither the routes nor the ground-layers suite built a city.
