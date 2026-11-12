# minty-quail — The route rig's planner and the scene recipe's readers are typed · 2026-11-12

**The ask.** Every receiver gets a class the field-read check can tell ("it should be made working",
inbox #1268 in olive-ferret), and code is typed where it can be ("we type when we can", inbox #1280 in
olive-ferret): `field-reads.md` with `typed-everywhere.md`, one pass per module. This pass is the route rig's planner
(`src/dev/route_rig_planner.gd`) and the scene recipe's readers: the recipe's schema check (`src/dev/scene_recipe.gd`)
and the authored-scene builder (`src/city/recipe_city_builder.gd`). Its search is none: it types and deletes lines and
converts no read.

## What was built

- **Three files parse without their file-level opt-out line**: `src/dev/route_rig_planner.gd`
  (`untyped_declaration`), `src/dev/scene_recipe.gd` (`untyped_declaration`, `unsafe_method_access`) and
  `src/city/recipe_city_builder.gd` (`unsafe_method_access`); none after. No other file changes.
- **The planner** loops over its line-of-sight points and its unstick directions as `Vector2`.
- **A recipe's keys are read by subscript.** The schema check and the builder read a recipe's parsed JSON, and read
  many of its keys as properties (`pin.blocks`, `data.extent.scope`, `spec.world`, `setup.day`, `move.from`,
  `result.map`, `result.manifest.checks` and the like), receivers the field-read check could not tell. Each value
  already checked to be a dictionary is read through a typed `Dictionary` local, the loop variable renamed `entry`
  where the local takes its old name, and each such key is a subscript, which is no field read. A missing key errors
  as a subscript as it did as a property, so no read became a `get()` with a default, and every existing `get()` keeps
  its default; the builder runs `SceneRecipe.validate()` first and returns on any error. The builder's anchor forms
  (a world position, a tile, a junction) sit under an `else:` over one typed local, in the same order; the manifest's
  checks are appended through a typed `Array` local holding the same array; and two sizes are read `as Array` behind
  their `is Array` guards.
- **Left, no read converted**: `CityMap`'s recipe fields and the closure, segment and planted-tree fields the builder
  writes, for the scene recipes' map capture-and-restore design in `field-reads.md`; the planner's reads, for the
  placement rewrite and the third hand-ins pull request.

## Fields read and written, by class

`tools/field_answers.py` on the three files, as it prints them at b063af422, each named method read in its class.

Fields of classes under `src/` that `src/dev/route_rig_planner.gd`, `src/dev/scene_recipe.gd`, `src/city/recipe_city_builder.gd` read or write through a receiver of that class, each with the method of the class that answers it (`tools/field_answers.py`). `(N calls)` counts a method's calls under `src/` outside its own file, `+N own` those in its own file, `+N untold` the calls of that name whose receiver's class cannot be told.

- `CityMap`: `block_layouts` read (`src/city/recipe_city_builder.gd`:72): no method; `block_plans` read (`src/city/recipe_city_builder.gd`:287; `src/dev/route_rig_planner.gd`:305): `plans_by_block()` (9 calls, +1 own); `building_rects` read (`src/city/recipe_city_builder.gd`:97,174,189): `building_lots()` (8 calls); `building_rects` written (`src/city/recipe_city_builder.gd`:177): no method; `calm_blocks` read (`src/dev/route_rig_planner.gd`:302): `calm_blocks_now()` (5 calls, +1 own); `closed_tiles` read (`src/dev/route_rig_planner.gd`:381): `closed_tile_set()` (1 call); `main_road` read (`src/city/recipe_city_builder.gd`:68): `main_road_corridor()` (18 calls); `network` read (`src/city/recipe_city_builder.gd`:200,302,345): `street_network()` (19 calls); `precinct_spans` read (`src/city/recipe_city_builder.gd`:67): `precinct_stretches()` (5 calls); `recipe_bounds` written (`src/city/recipe_city_builder.gd`:106): no method; `recipe_closures` read (`src/city/recipe_city_builder.gd`:100,324): `recipe_road_closures()` (1 call); `recipe_dawn_tiles` written (`src/city/recipe_city_builder.gd`:221): no method; `recipe_diagnostics` read (`src/city/recipe_city_builder.gd`:74): no method; `recipe_exterior` written (`src/city/recipe_city_builder.gd`:107): `witness_only()` does `recipe_exterior = false` (5 calls), `restore_edges()` does `recipe_exterior = was[0]` (5 calls); `recipe_tree_moves` read (`src/city/recipe_city_builder.gd`:103,104): no method; `recipe_tree_moves` written (`src/city/recipe_city_builder.gd`:367): no method; `recipe_trees` read (`src/city/recipe_city_builder.gd`:194): `recipe_tree_tiles()` (1 call); `recipe_trees` written (`src/city/recipe_city_builder.gd`:204): no method; `seed_used` read (`src/city/recipe_city_builder.gd`:292): `city_seed()` (14 calls); `soft_sealed_tiles` read (`src/dev/route_rig_planner.gd`:383): no method; `stretch` read (`src/city/recipe_city_builder.gd`:156,167): no method; of it alone, `has_stretch()` returns `not stretch.is_empty()` (20 calls); `stretch` written (`src/city/recipe_city_builder.gd`:169): no method; `stretch_active` written (`src/city/recipe_city_builder.gd`:223): `witness_only()` does `stretch_active = false` (5 calls), `restore_edges()` does `stretch_active = was[1]` (5 calls); `stretch_buildings` read (`src/city/recipe_city_builder.gd`:260): no method; `stretch_buildings` written (`src/city/recipe_city_builder.gd`:190): no method; `stretch_cracks` written (`src/city/recipe_city_builder.gd`:220): no method; `stretch_litter` read (`src/city/recipe_city_builder.gd`:215): `stretch_litter_list()` (1 call); `stretch_props` read (`src/city/recipe_city_builder.gd`:209): `stretch_prop_list()` (1 call); `tiles` read (`src/city/recipe_city_builder.gd`:221): `walk_tiles()` (1 call); `tiles` written (`src/city/recipe_city_builder.gd`:170): `restore_tiles()` does `tiles = snapshot` (1 call), `set_tile()` does `tiles[tile.y * size.x + tile.x] = type` (4 calls, +1 own), `repaint()` does `tiles = recipe_dawn_tiles.duplicate()` (3 calls)
- `DayController`: `spec` read (`src/dev/route_rig_planner.gd`:124,126): no method
- `DaySpec`: `exits` read (`src/dev/route_rig_planner.gd`:124,126): `exit_points()` (2 calls)
- `EventDef`: `detain_seconds` read (`src/dev/route_rig_planner.gd`:549): `detains_for()` (3 calls); of it alone, `detains_her()` returns `detain_seconds > 0.0` (2 calls); `mobile` read (`src/dev/route_rig_planner.gd`:426,548): `moves()` (2 calls); `obstructs_radius` read (`src/dev/route_rig_planner.gd`:548): `obstructs_within()` (7 calls); of it alone, `has_a_body()` returns `obstructs_radius > 0.0` (7 calls); `redetains` read (`src/dev/route_rig_planner.gd`:583,620,1259): `detains_again()` (2 calls); `shape` read (`src/dev/route_rig_planner.gd`:548,1204): `ground_shape()` (10 calls); `solid_when` read (`src/dev/route_rig_planner.gd`:549): `solid_from()` (2 calls); of it alone, `is_a_boom()` returns `solid_when == SolidWhen.WHILE_LOWERED` (3 calls)
- `EventDef.SolidPart`: `shape` read (`src/dev/route_rig_planner.gd`:532): `ground_shape()` (2 calls)
- `EventInstance`: `def` read (`src/dev/route_rig_planner.gd`:166,171,426,437,451,714): `row()` (2 calls); `def.hard_fail` read (`src/dev/route_rig_planner.gd`:426): `ends_the_day()` (1 call); `def.id` read (`src/dev/route_rig_planner.gd`:166,171): `row_id()` (11 calls); `is_finished` read (`src/dev/route_rig_planner.gd`:166,171,426,588,714): `is_gone()` (20 calls, +1 own)
- `EventPlan`: `def` read (`src/dev/route_rig_planner.gd`:503,529,533,539,583,592,620,623,638,667,1202,1204,1259,1263): `row()` (27 calls); `facing` read (`src/dev/route_rig_planner.gd`:533,586): no method; `gate_state` read (`src/dev/route_rig_planner.gd`:664): no method; `live` read (`src/dev/route_rig_planner.gd`:503,587,588,590,591,622,637,1201,1261): `instance()` (1 call); of it alone, `is_in_the_world()` returns `live != null` (2 calls); `path` read (`src/dev/route_rig_planner.gd`:540): `walks()` (6 calls); of it alone, `stands_still()` returns `path.size() < 2` (1 call); `position` read (`src/dev/route_rig_planner.gd`:540): `placed_at()` (28 calls); of it alone, `is_placed()` returns `position != Vector2.INF` (31 calls, +4 own); `spent` read (`src/dev/route_rig_planner.gd`:503,583,620,1201,1259): `is_spent()` (4 calls)
- `GroundShape`: `half_length` read (`src/dev/route_rig_planner.gd`:743,1216): `spine_half_length()` (2 calls); `radius` read (`src/dev/route_rig_planner.gd`:750,858,1186): `rounding_radius()` (6 calls)
- `ResistanceSteps.Step`: `is_one_place` read (`src/dev/route_rig_planner.gd`:147): no method; `is_pickup` read (`src/dev/route_rig_planner.gd`:114,145): no method; `task_event_id` read (`src/dev/route_rig_planner.gd`:153): no method
- `RoadClosure`: `segment` read (`src/city/recipe_city_builder.gd`:101): no method
- `StreetNetwork.Segment`: `horizontal` read (`src/city/recipe_city_builder.gd`:347): no method
- `StreetTrees.Planted`: `segment_key` read (`src/city/recipe_city_builder.gd`:345): no method; `tile` read (`src/city/recipe_city_builder.gd`:319,340,359,363): no method
- `WorldMap`: `obstructed_tiles` read through `CityMap` (`src/dev/route_rig_planner.gd`:385): no method; `size` read through `CityMap` (`src/dev/route_rig_planner.gd`:87,88,941,942,1009,1010,1011,1012,1018,1021): `size_in_tiles()` (66 calls)


## Verified

At parity: `tools/check.sh` boots clean before and after the merge of main; the field-read check against `origin/main`
passes with `tools/field_reads.txt` unchanged; the typing census and the layer check pass; the scene recipes', the
route rig's and the finale's suites pass; CI is green.
