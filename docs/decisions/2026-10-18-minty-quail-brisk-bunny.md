# minty-quail — The atlas's and the scenery's suites are typed, and the residency suite builds no city · 2026-11-11

**The ask.** Test code is typed as the code it tests is: "we type when we can" (inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin).
The atlas's and the scenery's pass of `typed-everywhere.md`'s "What is untyped in a test goes as
its suite is converted", and the atlas and scenery entry of `tests-one-module.md`, after the ground
pictures were typed (#1329) and the city's own parts were handed what they read
(minty-quail-quiet-ibis).

## What was built

- **The atlas's suites (`test_atlas_boot`, `_decoration`, `_ground`, `_leaf_consumers`,
  `_loading`, `_packer`), `test_building_shadows`, `test_ground_floor`, `test_scenery_residency`
  and the rigs `ground_floor_checks.gd`, `recording_atlas.gd` and `front_reads.gd` are typed and
  lose their opt-out line.** `test_scenery_animation` is typed too, though it is the events'
  scenery's suite, since it needed four small fixes once its line came off. No line under `src/`
  changed.
- **`test_scenery_residency` builds no city.** A helper hands `SceneryResidency` and
  `SceneryGround` their parts the way `City.build()` does: the cached map, a ground configured from
  a source, idle fakes of the building shadows and the decals, and a real `Building` on every lot.
  The suite's reads of `City.scenery_ground` and `City.scenery_ground_source` end, and the two kept
  lines for them in `tools/test_only_members.txt` are rewritten to the readers left.
- **The dawn half of the check that dawn and relocation do not replace a building's lasting
  collision moved to `test_city_buildings`**, which builds a real city: after `City.start_day()`
  the city holds the same buildings, each the same node with the same collision shape. It was seen
  to fail with a temporary `start_day()` that swapped one building's shape. The relocation half stays in the
  residency suite.
- **The suites ask the game's methods where it has one**: the shadows' drawer is handed through
  `draw_through()`, a building's posters through `hand_over_posters()`, the ground floor's home
  building through `stand_on_home_block()` and `is_on_home_block()` and its look through
  `look_variant()`, and the residency suite reads the map's `size_in_tiles()` and `city_seed()` and
  holds the roof layer it hands in rather than reading it back.
- **Typing `FrontReads.look()`** made two other suites' opt-out names stale (`test_home_block`,
  `test_resistance_placement_kinds`), and each line was shortened to what it trips.

## Left, each with its reason

- **Past the map, the residency suite's ground is plain water or grass** rather than the city's
  border bands, which `test_city_ground_water` and `test_main` hold.
- **Fields the suites still read, with no method the game calls**: `SceneryGround`'s `atlas`,
  `chunks`, `pending`, `elapsed`, `tile_set` and `mode`; `SceneryResidency`'s `view`, `budget_usec`
  and `timing`; `BuildingShadows`' `falls_on` and `streamed`; `AtlasLibrary.trace_note`; and
  `Building`'s `scenery_resident`, `day`, `condition`, `powered`, `neighbor_window_col` and
  `posters`, read once to see that a poster pasted while unloaded survives the rebuild (a building
  is handed its posters by `hand_over_posters()`, and nothing answers them). No method was added
  for a test.
- **`test_ground_floor` builds its fixture through `stand_on()`**, as `City._spawn_buildings()`
  does, for its district, footprint and height. Writes that stay: a building's `variant` in the
  sweep over every variant; `roof_extension_rows`, `roof_extension_seamless` and
  `seamless_cover_cols`, which the city writes as fields itself; and `position`,
  `covered_ground_cols`, `door_world_x_range` and `power_station`, which no method sets.
- **Reads of `Building.shape` and `district`** (`test_scenery_residency`, `ground_floor_checks.gd`)
  stay: no method answers them.
- **Other modules' fields** were not searched and stay for their passes.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `fb60c2b7d`, over the `.gd` files
under `tests/` its pull request changed, and each method read in its class and the classes it
extends: each read with the public method that returns exactly that field, or "no method"; each
write with every public method that assigns the field, and what it assigns.

- **`AttemptSpendState`**: `city_state`, written → no method; `scars` → no method; `scars`, written
  → `give_back()` does `scars = _dawn_scars.duplicate()`, `restore()` does `scars =
  _scars_from_data(data["…"])`.
- **`BlockLayout`**: `playground` → `playground_rect()`.
- **`BlockPlan`**: `steps` → `steps_in_order()`, which returns a copy of it (the tool prints no
  method).
- **`BlockPlan.Step`**: `purpose` → no method.
- **`Building`**: `atlas`, written → `equip()` does `atlas = library`; `condition` → no method;
  `condition`, written → no method; `covered_ground_cols` → no method; `covered_ground_cols`,
  written → no method; `day` → no method; `day`, written → no method; `district` → no method;
  `district`, written → `stand_on()` does `district = purpose`, `draw_as()` does `district =
  purpose`; `door_world_x_range` → no method; `door_world_x_range`, written → no method; `footprint`
  → no method; `footprint`, written → `stand_on()` does `footprint = size`; `front_drawer` → no
  method; `front_drawer`, written → `equip()` does `front_drawer = fronts`; `height` → no method;
  `height`, written → `stand_on()` does `height = wall_height`, `draw_as()` does `height =
  wall_height`; `is_home_building` → `is_on_home_block()`; `lot` → `lot_rect()`;
  `neighbor_window_col` → no method; `neighbor_window_col`, written → no method; `poster_art`,
  written → no method; `posters` → no method; `power_station` → no method; `power_station`, written
  → no method; `powered` → no method; `powered`, written → no method; `roof_drawer`, written →
  `equip()` does `roof_drawer = roofs`; `roof_extension_rows` → no method; `roof_extension_rows`,
  written → no method; `roof_extension_seamless`, written → no method; `scenery_clock`, written → no
  method; `scenery_resident` → no method; `seamless_cover_cols`, written → no method; `shape` → no
  method; `tint_variant` → no method; `variant` → `look_variant()`; `variant`, written →
  `stand_on()` does `variant = with_variant`, `draw_as()` does `variant = with_variant`.
- **`Building.RoofObject`**: `rotor` → no method; `texture_key` → no method.
- **`BuildingShadows`**: `falls_on`, written → no method; `streamed`, written → no method.
- **`City`**: `atlas` → no method; `atlas`, written → `build()` does `atlas = AtlasLibrary.new()`;
  `crowd` → no method; `events` → no method; `map` → no method; `run` → no method; `run`, written →
  no method; `spawn_siting` → no method.
- **`CityEdge`**: `atlas`, written → `dress()` does `atlas = library`.
- **`CityMap`**: `block_layouts` → no method; `block_plans` → `plans_by_block()`; `building_rects` →
  `building_lots()`; `calm_blocks` → `calm_blocks_now()`; `home_block` → `home_block_coordinate()`;
  `main_road` → `main_road_corridor()`; `network` → `street_network()`; `playgrounds` →
  `playground_rects()`; `seed_used` → `city_seed()`.
- **`ClosureMarker`**: `atlas`, written through `ParkFenceMarker` → no method.
- **`ContactPoint`**: `is_done` → `is_finished()`.
- **`EventDef`**: `aftermath` → no method; `aftermath.on_finish` → `leaves_behind()`; `id` → no
  method; `mobile` → `moves()`; `pursuit` → no method; `redetains` → `detains_again()`; `shape` →
  `ground_shape()`; `speed` → no method; `telegraph_time` → `telegraphs_for()`.
- **`EventInstance`**: `atlas`, written → no method; `def` → `row()`; `def.id` → `row_id()`;
  `def.telegraph_time` → `telegraphs_for()`; `drawer`, written → no method; `excitement` →
  `source()`; `is_finished` → `is_gone()`; `is_leaving` → `is_on_its_way_out()`; `look` → no method;
  `path` → `walks()`.
- **`EventManager`**: `warnings` → no method; `world` → no method.
- **`EventScheduler.Planned`**: `def` → `row()`; `def.id` → `row_id()`; `live` → `instance()`;
  `mast_id` → no method; `mast_id`, written → no method; `position` → `placed_at()`; `silenced` → no
  method; `spent` → `is_spent()`.
- **`FrameLedger`**: `keep`, written → `keep_this_frame()` does `keep = on`.
- **`GroundShape`**: `half_length` → `spine_half_length()`; `radius` → `rounding_radius()`.
- **`InteriorScene`**: `atlas`, written → no method.
- **`ModeButton`**: `symbol`, written → no method.
- **`PendingWarning`**: `def` → `row()`; `left` → `seconds_left()`; `place` → `points_at()`; `shown`
  → no method.
- **`Prop`**: `kind`, written → `dress()` does `kind = as_kind`; `scale_factor`, written → `dress()`
  does `scale_factor = scaled`; `shape` → no method; `variant`, written → `dress()` does `variant =
  with_variant`.
- **`RegionPlanner.RegionPlan`**: `door_bodies` → no method; `doors` → no method.
- **`ResistanceHappenings`**: `column` → no method.
- **`ResistanceRunState`**: `completed_steps` → no method; `failed_steps` → no method; `progress`,
  written → `reset()` does `progress = 0`, `give_back()` does `progress = _dawn_progress`,
  `restore()` does `progress = int(data["…"])`; `sabotage_done`, written → `reset()` does
  `sabotage_done = false`, `give_back()` does `sabotage_done = _dawn_sabotage_done`, `restore()`
  does `sabotage_done = bool(data["…"])`.
- **`ResistanceSteps.Step`**: `applies_package_weight` → no method; `applies_package_weight`,
  written → no method; `at_a_front_door` → no method; `at_a_front_door`, written → no method;
  `brief` → no method; `brief`, written → no method; `completes_at_inner_radius` → no method;
  `completes_at_inner_radius`, written → no method; `day` → no method; `day`, written → no method;
  `deadline_fraction` → no method; `deadline_fraction`, written → no method; `grants_progress` → no
  method; `grants_progress`, written → no method; `header` → no method; `header`, written → no
  method; `index` → no method; `index`, written → no method; `is_a_guarded_band` → no method;
  `is_a_guarded_band`, written → no method; `is_one_place` → no method; `is_one_place`, written → no
  method; `is_pickup` → no method; `is_pickup`, written → no method; `lingers_after_handover` → no
  method; `lingers_after_handover`, written → no method; `needs_goal` → no method; `needs_goal`,
  written → no method; `placement` → no method; `placement`, written → no method; `rigs_within` → no
  method; `rigs_within`, written → no method; `target_kind` → no method; `target_kind`, written → no
  method; `task_event_id` → no method; `task_event_id`, written → no method; `title` → no method;
  `title`, written → no method; `trap_noun` → no method; `trap_noun`, written → no method;
  `trap_row` → no method; `trap_row`, written → no method.
- **`RunFacts`**: `completed_resistance_alley_tiles`, written → no method; `escape_section` → no
  method; `escape_section`, written → `reset()` does `escape_section = 0`, `restore()` does
  `escape_section = int(data.get("…", 0))`.
- **`RunHeader`**: `day`, written → `reset()` does `day = 1`, `restore()` does `day =
  int(data["…"])`; `player_is_male` → no method.
- **`RunState`**: `attempt_spend` → no method; `calendar` → no method; `facts` → no method; `header`
  → no method; `resistance` → no method.
- **`SaveIndicator`**: `atlas`, written → no method.
- **`SceneryGround`**: `atlas`, written → no method; `chunks` → no method; `elapsed` → no method;
  `mode`, written → no method; `pending` → no method; `tile_set` → no method.
- **`SceneryLayer`**: `frame_b` → no method; `frame_b`, written → `show_frame_b()` does `frame_b =
  shown`.
- **`SceneryResidency`**: `budget_usec`, written → no method; `timing`, written → no method; `view`,
  written → `update()` does `view = next_view`.
- **`SceneryWater`**: `atlas` → no method; `atlas`, written → no method; `cells` → no method;
  `cells`, written → no method; `elapsed` → no method.
- **`Sitting`**: `atlas` → no method; `atlas`, written → no method; `run` → no method.
- **`Stroller`**: `carrying`, written → no method.
- **`Stroller.Pose`**: `mother_sources` → no method; `pram_source` → no method.
- **`TouchControls`**: `atlas`, written → no method.
- **`TrafficLight`**: `atlas`, written → `mount()` does `atlas = library`.
- **`WorldMap`**: `size` through `CityMap` → `size_in_tiles()`.
- Receiver's class not told: `tests/test_atlas_leaf_consumers.gd:173` `node.atlas`.
- Receiver's class not told: `tests/test_atlas_leaf_consumers.gd:177` `node.atlas`.
- Receiver's class not told: `tests/test_atlas_leaf_consumers.gd:181` `node.atlas`.
- Receiver's class not told: `tests/test_atlas_leaf_consumers.gd:284` `node.atlas`.
- Receiver's class not told: `tests/test_atlas_leaf_consumers.gd:288` `node.atlas`.
- Receiver's class not told: `tests/test_building_shadows.gd:37` `entry.canvas.name`.
- Receiver's class not told: `tests/test_home_block.gd:73` `a.position`.
- Receiver's class not told: `tests/test_home_block.gd:73` `b.position`.
- `tests/test_resistance_placement_kinds.gd` still ignores `unsafe_property_access`.

## Verified

The suites taken and those that touch the changed rigs pass, `tools/typing_census.py --check`
holds, and no game file changed, so the identity probes do not apply. The pull request gives each
suite's CI time before and after.
