# One draw-layer contract for the city and the building

This item is about the order pictures are drawn in, one of the world layer's services; it is not
the architecture's layering, which is the README's.

Draw order is fixed case by case with hard-coded numbers and no shared list: `city.tscn` Buildings 1
and Entities 2, `City.OVERHEAD_Z_INDEX = 3`, the halo 1 and debug layers 3 in `main.gd`, the building's
Backdrops -1, Walls 1, Doors 1, Entities 2 (`interior_scene.gd` near 128-141). The warning roadblock
guard is raised by checking his picture (`_draw_a_warning_guard_on_top()`, `event_instance.gd` near
2343, `Look.ROADBLOCK`) to an absolute 3, which ties him with the overhead and debug layers and puts
him over the stroller. A long object (a band, a spread) is one node sorted from one point ("nothing
y-sorts within it and draw order is the only depth there is", near 6837), the root of the hidden
guard; closures solve the same problem another way (`closure_marker.gd`, per-panel nodes, with a
float-snap hack in `city.gd` near 1197). Interior doors went to their own layer (inbox #789), while
the city's home door still y-sorts on tree order (`city.gd` near 217).

**Build:** one `DrawLayer` list shared by both worlds, through `add_entity(node, layer)` on the world
interface (`world-map.md`); one helper that adds a footprint longer than a tile as feet-anchored
slices, used by bands, spreads, fences and closures; no `z_index` written outside that module. The
warning guard's raise becomes a layer, not a look check.
