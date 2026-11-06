# minty-quail — The building's roof pieces, the scenery ground's, the atlas library's and the ground layers' members only their own class used become internal · 2026-11-06


minty-quail's `tests-own-class-members.md`, the underscore pass, for the building's window and roof
pieces, the scenery ground, the atlas library and the ground layers: a public member only its own
class and the tests use becomes internal and its tests move to what the class does outward
(curly-rabbit #1098), and one with no reader left is deleted (curly-rabbit #1095).

**Built.** The ground layers' `compose_image` and `rotate_clockwise` are internal; the rotation is
read off the four composed kerb sources, the stone on the edge each direction names. The atlas
library's `aspect_ceiling` is internal and its suite states the documented rule itself. The
scenery ground's `get_cell_source_id`, `get_cell_atlas_coords` and `get_used_cells`, which only
forwarded to the `TileMapLayer` holding the tile, are deleted, and the suites make the engine's own
calls on that layer through `tests/ground_cells.gd`; its `prepared` and `evicted` counters are
deleted, the suites reading the resident layers before and after. The building's `roof_layout`,
`roof_interior_cells` and `roof_equipment_scale` are internal, read off the recording roof drawer
by where each roof object stands (`tests/roof_reads.gd`); the ground-floor suite's exact pool check
is a sweep of 120 seeds, every unit inside the lip-free interior and every interior cell reached.
`VENT_ROTOR_SOURCE_RECT` is deleted, since nothing drew with it.

**Kept public**, each with its reason beside its line in the list: `AtlasLibrary.region_name_for`
and `illustrated_path_for`, which `tools/bake_atlases.gd` calls; `AtlasLibrary.moment_for_a_load`,
whose outside state is the one where `acquire()` raises an engine error, so the page log cannot show
it; `SceneryGround.worst_step_usec`, a wall-clock number the frame-timing probes read;
`Building.window_texture`, which `test_scenery_residency.gd` reads inside synchronous residency
updates that deliberately run without the frames a drawn read needs.

**Open to overturn.** The ground layers' 45-degree fallback check went, since it needs a doctored
recipe and makes the compositor raise an engine error; and the hand-made-image check that an empty
overlay pixel leaves the base alone went, the composed-sources check holding it on the real kerb
tile.
