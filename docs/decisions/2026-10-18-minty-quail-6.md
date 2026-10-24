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

**Left:** the café's, the protest's and the firefight's ranks are not sliced, since the café draws
every sitter before every table and slicing it changes its look; the three wide scenes (fallen tree,
car accident, burst water main) are each one authored picture; the cordon tape is `ParkCordon`'s,
which `world-passability.md` holds.

**For the remeasuring step:** a spread running down the screen sorts slice by slice against her and
every figure, where it sorted at its middle (its shadow and far end cap go with the far slice); in
the escape's city section the halo draws over the buildings, the debug view over the tunnel's dark,
and the building's doors over the city's buildings wherever the building still shows under the
city; pictures of a vertical spread with her beside it, and of the escape city's halo.
