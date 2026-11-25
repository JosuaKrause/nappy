# minty-quail — The city scene's suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin):
`typed-everywhere.md`, one pass per module. This pass is the city scene; its search covers `Building`
(with `Building.RoofObject`), `PosterState`, `PosterWalls`, `PosterArt`, `Prop`, `GroundLayers` and
`GroundTiles`.

## What was built

- **Eleven suites parse without their file-level opt-out line**, which each loses: `tests/test_city_buildings.gd`,
  `test_city_decay.gd`, `test_power_station.gd`, `test_routes_kerb_tint.gd`, `test_bollards.gd` and
  `test_precinct_posts.gd` (`untyped_declaration`, `unsafe_method_access`), and `test_city_world.gd`,
  `test_home_block.gd`, `test_roof_entities.gd`, `test_posters.gd` and `test_ground_layers.gd`
  (`untyped_declaration`).
- **Typing**: loops take their narrowest type (`PosterArt.Kind`, `Prop.Kind`, `GameEnums.BlockPurpose`
  among them); the decay suite's fronts are `FrontReads`, read in `test_city_buildings` through a typed
  `_front_of()`; `test_routes_kerb_tint` returns a typed inner class `VisitedCells` in place of a
  dictionary read by property; `test_roof_entities`' fixture takes a `GameEnums.BlockPurpose`.
- **Reads and writes converted to methods the game calls**: `Building.lot` → `lot_rect()`,
  `is_home_building` → `is_on_home_block()`, `variant` read → `look_variant()`; `district`, `footprint`
  and `height` written together → `stand_on()`, as `City._spawn_buildings` calls it, its `lot` and
  `variant` the defaults the suite already had; `roof_object_parent` written → `put_roof_objects_in()`;
  `PosterState.cells[tile]` → `sheet_at()`, `tears` read → `tears_made()`, `tears = 3` → three
  `count_a_tear()` calls; `Prop.kind` written → `dress(null, kind)`, as `City` dresses every prop.
- No check deleted or moved; nothing under `src/`, the rigs or `tools/test_only_members.txt` changed.

## Fields read and written, by class

`tools/field_answers.py --counts` on the eleven files, as it prints them at the merge of main
ea5946e88 (a method's call count moves as main adds or drops calls), each named method read in its
class. Of these, the pass converts the `Building`, `PosterState` and `Prop` fields named above; the
searched classes' other fields are left because no method answers them, or because the method that
does sets several fields together and would change what a suite varies (`stand_on()` and `draw_as()`
for `footprint`, `variant` and `height` written one at a time; `equip()` for `atlas`, `roof_drawer` and
`front_drawer`, at the three sites that set one of them; the fourth, `scenery_resident` on a fresh
station, is `equip(null, null, null)`); every other class's fields are left for their own modules' passes.

- `BlockPlan`: `steps` read (`tests/test_power_station.gd` on 1 line): no method
- `Building`: `atlas` read (`tests/test_roof_entities.gd` on 2 lines): no method; `atlas` written (`tests/test_roof_entities.gd` on 1 line): `equip()` does `atlas = library` (1 call); `condition` written (`tests/test_city_decay.gd` on 4 lines): no method; `covered_ground_cols` read (`tests/test_city_buildings.gd` on 13 lines): no method; `day` written (`tests/test_city_decay.gd` on 5 lines, `tests/test_power_station.gd` on 2 lines): no method; `district` read (`tests/test_city_buildings.gd` on 7 lines, `tests/test_city_decay.gd` on 2 lines, `tests/test_home_block.gd` on 1 line): no method; `door_world_x_range` read (`tests/test_city_buildings.gd` on 1 line): no method; `footprint` written (`tests/test_roof_entities.gd` on 3 lines): `stand_on()` does `footprint = size` (1 call); `front_drawer` written (`tests/test_city_decay.gd` on 1 line, `tests/test_power_station.gd` on 1 line): `equip()` does `front_drawer = fronts` (1 call); `height` read (`tests/test_home_block.gd` on 4 lines): no method; `height` written (`tests/test_city_decay.gd` on 2 lines): `stand_on()` does `height = wall_height` (1 call), `draw_as()` does `height = wall_height` (1 call); `neighbor_taken` read (`tests/test_posters.gd` on 4 lines): no method; `poster_art` read (`tests/test_posters.gd` on 4 lines): no method; `power_station` read (`tests/test_city_buildings.gd` on 5 lines, `tests/test_home_block.gd` on 3 lines, `tests/test_posters.gd` on 1 line, `tests/test_power_station.gd` on 1 line): no method; `power_station` written (`tests/test_power_station.gd` on 2 lines): no method; `powered` written (`tests/test_power_station.gd` on 3 lines): no method; `roof_drawer` written (`tests/test_roof_entities.gd` on 1 line): `equip()` does `roof_drawer = roofs` (1 call); `roof_extension_rows` read (`tests/test_city_buildings.gd` on 1 line): no method; `roof_extension_rows` written (`tests/test_roof_entities.gd` on 1 line): no method; `scenery_clock` written (`tests/test_roof_entities.gd` on 1 line): no method; `scenery_resident` read (`tests/test_home_block.gd` on 1 line): no method; `station_door_col` written (`tests/test_power_station.gd` on 1 line): no method; `station_yard_cols` written (`tests/test_power_station.gd` on 1 line): no method; `tint_variant` read (`tests/test_city_buildings.gd` on 2 lines): no method; `variant` written (`tests/test_roof_entities.gd` on 10 lines): `stand_on()` does `variant = with_variant` (1 call), `draw_as()` does `variant = with_variant` (1 call)
- `Building.RoofObject`: `duct_links` read (`tests/test_roof_entities.gd` on 1 line): no method; `rotor` read (`tests/test_roof_entities.gd` on 3 lines): no method; `texture_key` read (`tests/test_home_block.gd` on 1 line, `tests/test_roof_entities.gd` on 1 line): no method
- `City`: `atlas` written (`tests/test_posters.gd` on 1 line): `build()` does `atlas = AtlasLibrary.new()` (2 calls); `events` read (`tests/test_city_world.gd` on 2 lines, `tests/test_posters.gd` on 10 lines): no method; `map` read (`tests/test_city_world.gd` on 1 line, `tests/test_home_block.gd` on 1 line, `tests/test_power_station.gd` on 2 lines, `tests/test_routes_kerb_tint.gd` on 11 lines): no method; `poster_art` written (`tests/test_posters.gd` on 1 line): no method; `run` read (`tests/test_city_buildings.gd` on 1 line, `tests/test_posters.gd` on 3 lines): no method; `scenery` read (`tests/test_routes_kerb_tint.gd` on 1 line): no method; `scenery_ground` read (`tests/test_routes_kerb_tint.gd` on 6 lines): no method; `skip_crowd_drawing` written (`tests/test_city_world.gd` on 1 line): no method; `skip_event_drawing` written (`tests/test_city_world.gd` on 1 line): no method
- `CityMap`: `big_buildings` read (`tests/test_power_station.gd` on 3 lines): `big_building_pairs()` (1 call); `block_layouts` read (`tests/test_city_buildings.gd` on 1 line): no method; `block_plans` read (`tests/test_city_buildings.gd` on 1 line, `tests/test_posters.gd` on 1 line, `tests/test_power_station.gd` on 6 lines, `tests/test_routes_kerb_tint.gd` on 1 line): `plans_by_block()` (9 calls, +1 own); `boundary_wall_at_a` read (`tests/test_power_station.gd` on 1 line): no method; `building_rects` read (`tests/test_home_block.gd` on 2 lines): `building_lots()` (8 calls); `closed_tiles` read (`tests/test_power_station.gd` on 1 line): `closed_tile_set()` (1 call); `home_block` read (`tests/test_home_block.gd` on 2 lines, `tests/test_power_station.gd` on 1 line): `home_block_coordinate()` (6 calls); `home_rect` read (`tests/test_power_station.gd` on 2 lines): `home_tile_rect()` (7 calls); `main_road` read (`tests/test_routes_kerb_tint.gd` on 1 line): `main_road_corridor()` (18 calls); `network` read (`tests/test_routes_kerb_tint.gd` on 1 line): `street_network()` (19 calls); `power_station` read (`tests/test_power_station.gd` on 5 lines): `power_station_blocks()` (5 calls); `power_station_door` read (`tests/test_power_station.gd` on 2 lines): `power_station_door_tiles()` (3 calls); `power_station_door_key` read (`tests/test_power_station.gd` on 1 line): no method; `power_station_industrial_blocks` read (`tests/test_power_station.gd` on 1 line): no method; `precinct_spans` read (`tests/test_precinct_posts.gd` on 1 line): `precinct_stretches()` (5 calls); `seed_used` read (`tests/test_city_buildings.gd` on 24 lines, `tests/test_power_station.gd` on 24 lines, `tests/test_routes_kerb_tint.gd` on 1 line): `city_seed()` (14 calls)
- `EventDef`: `id` read (`tests/test_city_decay.gd` on 1 line): no method
- `EventInstance`: `def` read (`tests/test_posters.gd` on 1 line): `row()` (2 calls); `excitement` read (`tests/test_city_world.gd` on 1 line): `source()` (16 calls)
- `EventManager`: `world` read (`tests/test_city_world.gd` on 2 lines, `tests/test_posters.gd` on 1 line): no method; `world.instances` read (`tests/test_city_world.gd` on 2 lines): `instances()` (21 calls)
- `EventPlan`: `def` read (`tests/test_city_decay.gd` on 1 line, `tests/test_power_station.gd` on 2 lines): `row()` (27 calls); `def.id` read (`tests/test_city_decay.gd` on 1 line): `row_id()` (6 calls); `def.obstructs_radius` read (`tests/test_power_station.gd` on 2 lines): `obstructs_within()` (1 call); `position` read (`tests/test_city_decay.gd` on 1 line, `tests/test_power_station.gd` on 2 lines): `placed_at()` (28 calls); of it alone, `is_placed()` returns `position != Vector2.INF` (31 calls, +4 own)
- `EventWorld`: `day` read (`tests/test_posters.gd` on 1 line): no method
- `FrameLedger`: `keep` written (`tests/test_power_station.gd` on 1 line): `keep_this_frame()` does `keep = on` (2 calls)
- `GarbageSacks.Placed`: `position` read (`tests/test_city_decay.gd` on 2 lines): no method
- `GroundShape`: `radius` read (`tests/test_bollards.gd` on 2 lines, `tests/test_precinct_posts.gd` on 1 line): `rounding_radius()` (6 calls)
- `Litter.Placed`: `position` read (`tests/test_city_decay.gd` on 1 line): no method
- `PosterState`: `cells` read (`tests/test_posters.gd` on 6 lines): no method; `pasted_through` read (`tests/test_posters.gd` on 2 lines): no method; `pasted_through` written (`tests/test_posters.gd` on 4 lines): `reset()` does `pasted_through = 0` (3 calls, +1 own)
- `PosterWalls`: `art` read (`tests/test_posters.gd` on 1 line): no method
- `RegionPlanner.RegionPlan`: `alley_doors` read (`tests/test_power_station.gd` on 3 lines): no method; `alley_walls` read (`tests/test_power_station.gd` on 1 line): no method; `doors` read (`tests/test_power_station.gd` on 3 lines): no method; `wall_bodies` read (`tests/test_power_station.gd` on 1 line): no method; `walls` read (`tests/test_power_station.gd` on 1 line): no method
- `ResistanceRunState`: `completed_steps` written (`tests/test_posters.gd` on 5 lines): `give_back()` does `completed_steps = _dawn_completed_steps.duplicate()` (1 call), `restore()` does `completed_steps = _to_int_array(data["…"])` (3 calls)
- `ResistanceSteps.Step`: `index` read (`tests/test_posters.gd` on 2 lines): no method
- `RunHeader`: `day` written (`tests/test_posters.gd` on 2 lines): `reset()` does `day = 1` (3 calls), `restore()` does `day = int(data["…"])` (3 calls)
- `RunState`: `calendar` read (`tests/test_city_buildings.gd` on 1 line, `tests/test_posters.gd` on 2 lines): no method; `header` read (`tests/test_posters.gd` on 2 lines): no method; `posters` read (`tests/test_posters.gd` on 55 lines): no method; `resistance` read (`tests/test_posters.gd` on 5 lines): no method
- `SceneryGround`: `chunks` read (`tests/test_routes_kerb_tint.gd` on 2 lines): no method; `elapsed` written (`tests/test_roof_entities.gd` on 2 lines): no method; `tile_set` read (`tests/test_routes_kerb_tint.gd` on 1 line): no method
- `SceneryLayer`: `frame_b` read (`tests/test_roof_entities.gd` on 1 line): no method
- `ScreenCover`: `left` read (`tests/test_posters.gd` on 1 line): `left_corner()` (2 calls)
- `Sitting`: `frame_timing` written (`tests/test_power_station.gd` on 1 line): `use_frame_timing()` does `frame_timing = timing` (1 call)
- `StreetNetwork.Segment`: `a` read (`tests/test_power_station.gd` on 1 line): no method; `b` read (`tests/test_power_station.gd` on 1 line): no method; `horizontal` read (`tests/test_power_station.gd` on 1 line): no method
- `Stroller`: `facing` written (`tests/test_posters.gd` on 1 line): `reset_at()` does `facing = look.normalized()` (3 calls)
- `WorldMap`: `size` read through `CityMap` (`tests/test_city_buildings.gd` on 1 line, `tests/test_city_decay.gd` on 2 lines, `tests/test_city_world.gd` on 2 lines, `tests/test_routes_kerb_tint.gd` on 4 lines): `size_in_tiles()` (66 calls)
- Receiver's class not told: `tests/test_posters.gd:209` `paper.a`
- Receiver's class not told: `tests/test_posters.gd:210` `over.a`
- Receiver's class not told: `tests/test_posters.gd:211` `paper.a`
- Receiver's class not told: `tests/test_posters.gd:213` `got.a`
- Receiver's class not told: `tests/test_posters.gd:215` `over.a`
- Receiver's class not told: `tests/test_posters.gd:217` `got.a`
- Receiver's class not told: `tests/test_posters.gd:221` `over.a`
- Receiver's class not told: `tests/test_posters.gd:222` `got.a`

The eight lines whose receiver's class is not told are `Color.a` reads on pixel colors in
`test_posters`, an engine type.

## Verified

At test parity: the eleven suites pass; the typing census, `./tools/check.sh`, the field-read and the
test-only-member checks and the lint pass.
