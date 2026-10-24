# minty-quail — One draw-layer list for the city and the building · 2026-10-24


minty-quail's `draw-layers.md`, the refactor's sixth PR (PR #825). Draw order was fixed case by
case with hard-coded numbers and no shared list: the city's scene, `City.OVERHEAD_Z_INDEX`, the halo
and debug layers in `main.gd` and the building's own layers each wrote their own `z_index`; the
warning roadblock guard was raised by checking his picture to an absolute 3, tying him with the
overhead and debug layers; a long object (a band, a spread) was one node sorted from one point; and
closures solved the same problem with per-panel nodes and a float-snap hack.

**Built** (`src/world/`). `DrawLayer` is the one list both worlds draw on, from the bottom
`BACKDROP, GROUND, BUILDINGS, DOORS, GROUND_MARKS, HALO, ENTITIES, WARNING, OVERHEAD, DEBUG`; a
layer's z is its place in the list, `GROUND` at 0, every layer absolute, and it is the only file
that writes a `z_index`. `WorldContext.add_entity(node, layer)` is how anything is added to a world,
over a `WorldLayers` each world fills with its own layer nodes (the city its scene's `Buildings` and
`Entities`, the building its four), so `world-map.md`'s `WorldMap` only has to name it. Every event
is handed its world (`EventInstance.world`, set by `EventManager` and `InteriorEvents`) rather than
finding it. `DrawLayer.slice_feet`, `run_of` and `add_slices`, with `Footprint.Piece.span()`, add a
footprint longer than a tile as feet-anchored slices, taken from the solid footprint #817 built:
roadworks, the stall, the barricade, scaffolding, the collapsed frontage and the roadblock's band
are drawn as one `EventInstance.Slice` per segment, and closures and park fences take their panel
feet from the same helper (`ParkClosure.rail_ends()`, which `posts()` also reads), so the float-snap
hack and the per-panel offset arithmetic are gone. The warning guard's raise is a layer: the row
field `EventDef.warns_over_the_street`, set on `roadblock`, draws him on `WARNING` while he warns
and on `ENTITIES` otherwise.

**Verified at test parity** (inbox #813): `check.sh`, `lint.sh`, `ci_telemetry_kinds.py` and 26
suites two or three per call with 0 failures, the full suite left to CI. A new
`tests/test_draw_layers.gd` fails on any `z_index` or `z_as_relative` write in `src/` or `scenes/`
outside `DrawLayer`, and checks the layer order, adding on a layer, the slice arithmetic and that a
spread stood in a world is drawn in slices. Tests changed only as far as the code moved:
`test_finale` asks `DrawLayer.layer_of()` rather than a z constant, `test_event_views` and
`test_events_catalogue` call `DrawLayer.slice_along()`, and `test_interior`'s grate check asks that
the grate's layer comes after the floor tiles.

**Choices made where the design was silent, open to overturn:** the warning guard still draws over
the stroller while he warns, since `WARNING` stands where his z of 3 already put him and a man hidden
while he warns has not warned (inbox #771 in minty-lemur); drawing him under her alone would put her
on a layer of her own and change how every figure sorts against her. The halo draws over the
buildings in both worlds. The city's home door stays on `ENTITIES`, since nobody stands north of it
and on `DOORS` the halo would draw over it. The building's walls stay a layer that is not y-sorted. A
spread row with no body falls back to 11px either side of its middle (no such row exists). Slices go
ahead of their event in the tree, so its caret stays on top of its own picture. The row field is a
plain flag, so the event data names no world type.

**Also built, after the first review (PR #825):** every long picture the item names goes through the
one helper. The protest is one slice per protester at his feet and the firefight one per gunman; the
fallen tree, the car accident and the burst water main are one slice per tile of the run, each
drawing its own band of the authored picture (a cropped draw for the tree, a clipped `EventScenery`
for the other two, through a source rect on `SceneryLayer`), the shadow going down whole with the
first; day 12's cordon tape places each stretch through the helper, its positions unchanged; and the
café is one slice per table and its sitter, so sitters and tables interleave, which the player
accepted (inbox #827). Once the escape's city is built, `InteriorScene.put_the_pictures_away()`
hides the building's floor and layer nodes, keeping its `FadeLayer` for `clear_fade()`: the
building's door pictures would otherwise draw over the city's buildings, and 15 of its walls and 11
of its doors already stood on walkable city tiles over the city's ground. The z scan also catches a
setter or the property named in a string, and a test frees one event while its world stays and
finds no slice left.

**A limit of slicing an authored picture, open to overturn:** the bands are cut by screen rows, so
an upright part standing over nearer ground (a tree's crown, the water main's fountain on an
east-west street) sorts with the farther band its rows fall in. No figure can stand where that
shows: the nearest she stands is 38px from the scene's centre line (its 24px band and her 14px
body) and all three pictures lie within about 30px of it, so only a sprite wider than its body (her
pram pushed toward the scene) reaches a few pixels in; spans authored into the picture would remove
it.

**For the remeasuring step:** end-on spreads (roadworks, the stall, the barricade, scaffolding,
the collapsed frontage, the roadblock's band on a north-south street) sort slice by slice against
her, their shadow and far end cap going with the far slice; the café's tables and sitters
interleave and sort table by table; the protest sorts protester by protester, back rank behind the
front; the wide scenes on an east-west street sort band by band, with the limit above and their
band joins to be checked by eye for seams; in the escape's city section the building is no longer
drawn at all, the halo draws over the buildings, and the debug view over the tunnel's dark and the
warning guard (debug builds only). Pictures of each.
