# minty-quail — The city's readers ask through methods (field reads: the city area) · 2026-11-08


minty-quail's `field-reads.md`, the city area: every group of `tools/field_reads.txt` whose owning class
lives under `src/city/`, less the fence the brief drew round the parallel placement work and the third
hand-ins pull request. No behaviour change: the run-log baseline (`test_observers`) is unchanged, the
suites of every file touched pass, and the six gates (`check.sh`, `check_layers.py`,
`check_field_reads.py`, `check_overrides.py`, `check_test_only_members.py`, `lint.sh`) are green.

**Built.** 188 lines of the list were in this area outside the fence; 140 are deleted, 48 stand.
Lines converted per owner class (before, left): `BlockLayout` 14 to 0, `BlockPlan` 6 to 0,
`Building` 19 to 5, `BuildingShadows` 4 to 2, `City` 6 to 5, `CityDecals` 3 to 0, `CityEdge` 2 to 0,
`CityMap` 112 to 34, `CityState` 1 to 0, `MarbleBag` 1 to 0, `PosterState` 4 to 2, `PosterWalls` 3 to 0,
`Prop` 4 to 0, `SceneryLayer` 3 to 0, `TrafficLight` 4 to 0, `TrafficSignals` 2 to 0.

**The method names, and why.** A method is named for what the caller asks or does, and where a
name would only repeat the field's (`main_road`, `network`), it says what the field is:
- `CityMap` answers `street_network()`, `main_road_corridor()`, `city_seed()`, `home_tile_rect()`,
  `home_block_coordinate()`, `building_lots()`, `calm_blocks_now()`, `fenced_park_block()`,
  `precinct_stretches()`, `alley_lots()`, `courtyard_lots()`, `playground_rects()`,
  `streets_built_over()`, `closed_tile_set()`, `power_station_blocks()`, `power_station_door_tiles()`,
  `plans_by_block()`, `has_plan_for()`, `blocks_with_plans()`, `plan_of()`, `layout_of()`,
  `blocks_with_layouts()`, the recipe's `has_recipe_exterior()`, `recipe_window()`,
  `recipe_road_closures()`, `has_recipe_dawn_ground()`, `recipe_tree_tiles()`,
  `has_tree_move_from()`, `tree_move_from()`, and the stretch's `stretch_building_on()`,
  `has_stretch_building_on()`, `stretch_building_lots()`, `stretch_prop_list()`,
  `stretch_litter_list()`, `stretch_crack_at()`. A field every caller reads stays public while a
  fenced reader (the route planners, the event scheduler, the scene recipes) still reads it, so
  the method cannot take the field's name; a later pull request that converts the last reader makes
  the field underscore-private and renames the method to the field's name if it wants it.
- What the generator fixes in a map has one method per fact, not a setter per field:
  `generated_from()`, `lay_main_road()`, `clear_precincts()`, `add_precinct()`,
  `add_building_lot()`, `add_building_lots()`, `note_diagnostic()`, `record_zone()`,
  `record_zone_member()`, `zone_anchors()`, `zone_footprint()`, `mark_street_absent()`,
  `restore_street()`, `record_built_over()`, `forget_built_over()`, `mark_dead_end()`, `plan_block()`,
  `carve_block()`, `add_square()`, `add_alley()`, `big_building_pairs()`, `add_big_building()`,
  `drop_last_big_building()`, `record_power_station()` (one call for the pair, its door street, its
  door tiles and its industrial count, which are one fact), `tiles_snapshot()` and `restore_tiles()`
  (the undo of a landmark that did not hold).
- `BlockLayout` has `open_ground()`, `playground_rect()`, `square_rect()`, `alley_rect()`,
  `passage_rect()` with `has_*()` for each and `carve_*()` for the generator; the static
  `BlockLayout.has(rect)` the readers called on a field is the method's own business now.
- `BlockPlan` has `step_count()`, `step_at()`, `steps_in_order()` (a copy: adding to it adds nothing to
  the arc), `append_step()` (raw, since a stored arc's days are already in order and `then()` would
  push them forward), `forced_open_day()`, `force_open_on()`, `is_forced_open_on()` and
  `is_swing_park()`.
- The wiring a city does to what it builds is one call per thing, in the order the old assignments
  ran: `Prop.dress()`, `CityEdge.dress()`, `TrafficLight.mount()`, `Building.equip()`,
  `Building.stand_on()`, `Building.draw_as()`, `Building.stand_on_home_block()`,
  `Building.put_roof_objects_in()`, `Building.hand_over_posters()`, `PosterWalls.equip()`,
  `CityDecals.use_atlas()` and `draw_through()`, `BuildingShadows.draw_through()` and
  `skip_drawing()`, `SceneryLayer.draw_through()` and `show_frame_b()`.
- Small reads: `PosterState.has_sheet()`, `sheet_at()`, `tears_made()`, `count_a_tear()`;
  `MarbleBag.draws_made()`; `Building.is_burnt()`, `lot_rect()`, `look_variant()`,
  `is_on_home_block()`; `TrafficSignals.is_powered()` and `restart_cycle()`; `CityState.use_trace()`;
  `City.ground_mode_in_force()`.

**Skipped, and why (48 lines stand).**
- *`RecipeCityBuilder` and `RecipeCityContext` (31 lines).* The authored-scene builder fills the
  stretch's bytes, tiles, cracks, props and litter into the map directly, and the context captures and
  restores every map field by name (`map.get(field)`, `map.set(field, ...)`, which the check cannot
  see). Converting them is a design, not a rename: the map capturing and restoring itself, or a
  builder object it takes whole. It wants a decision before a method per field is added.
- *`City.events`, `City.crowd` (5 lines: the poster walls, the frame recorder, the frame trace).* An
  accessor `City.event_manager()` or `walking_crowd()` names `EventManager` and `Crowd` in `city.gd`,
  which `check_layers.py` counts as new uses of two breaks already listed there. The reads wait for the
  parts to be handed to those readers directly, which the third hand-ins pull request does for the
  fenced ones.
- *Test-only fields (12 lines).* `Building.scenery_clock`, `door_world_x_range`, `power_station`,
  `station_door_col`, `station_yard_cols`, `BuildingShadows.streamed`, `falls_on`,
  `PosterState.pasted_through` (all in `city.gd` or `poster_walls.gd`), and `CityMap.home_rect`,
  `home_block`, `courtyard_rects` (in `city_generator.gd`): once the city stops writing or reading
  them, only a test reads them, and `check_test_only_members.py` fails a field that only tests read.
  Their direct writes stay until their tests are converted to read through a method the game also
  calls; that is `tests-read-fields`' to do, not this pull request's.
- *The fence.* Every line whose owner or reader is under `src/events/`, `src/routes/` or `src/dev/`, a
  `scene_recipe*` file, `event_director.gd`, `tuning.gd`, `day_director.gd`, `main.gd`,
  `day_planner.gd`, `run_session.gd`, the event manager and `EventWorld`, scenery residency and ground,
  the blackout, the still watch or the debug readout was left alone; 168 of the city-owned lines are
  those.

**Open to overturn:** the names above; `Building`'s three wiring methods (`equip`, `stand_on`,
`draw_as`) grouping fields that had been assigned one by one (each setter still runs in its old order);
`tests/test_generator.gd` reading `BlockLayout.passage` through `passage_rect()` and `has_passage()`,
the one test edit, since the generator and the map stopped reading the field and
`check_test_only_members.py` would otherwise fail it.
