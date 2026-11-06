# Tests drive public seams: what the count cannot see

`tests-public-seams.md`'s two count commands print nothing outside its two exempt files, and they
cannot see a private member reached another way, a game collection a test edits by hand, or a
public member that only tests call. This item is the read-only scoping of those, by owner, with the
seam each moves to and the builds they split into. Its rule for a seam is `tests-public-seams.md`'s
Build paragraph: a member made public, or added, has a caller among the game's own classes or is a
dependency the game's own code hands in, and where the game has no reader the test goes through
what the game exposes. File and line references are to `main` when the item was filed; a builder
re-reads them.

**Readings of the rule.** The first, open to the player's overturn, rests on the Build
paragraph's wording and leaves the DEV-only tier below unscheduled; the second and third are the
player's; the fourth follows from the Build paragraph alone:

- **A caller under `src/dev` counts as a game caller.** The rigs and the scene-recipe runtime are
  the composition root in `tools/layer_map.py`'s layering (**orchestrating**, "Code is designed by
  layer"), and `tests-public-seams.md` already accepts `Crowd.add_recipe_actor()` (only the recipe
  runtime calls it) as a seam. About 55 names stand on this reading.
- **A caller in the member's own class is no caller.** Told that about 250 public members are
  called only by their own class and the tests, the player asked "so basically they're not part of
  the API but tests use them to probe the state? so they're kind of a loophole", then answered "we
  should add the underscore", and of the pick that each becomes internal, its tests checking what
  the class does from outside, one staying public only where nothing outside can confirm the
  behavior, with its reason written down, "yes, that's cleaner" (curly-rabbit #1098). That pass is
  `tests-own-class-members.md`. This overturns the reading that the defining class counts as "a
  caller among the game's own classes".
- **A member with no reader at all goes.** Records minty-quail-busy-swan (`mast_in_play()` and the
  `arrow_*` queries) and minty-quail-downy-marten (`door_position()`, `door_axis()`, `trap()`) added
  queries that only tests read, and `tests-public-seams.md`'s resistance sentence lists
  `ResistanceDirector`'s `arrow_*`, `door_*`, `trap()`, `mast_in_play()`, `mark_tiles()`,
  `reaches_from_home()` and `fell_back()` among the seams the resistance suites drive; none has a
  caller under `src/` (section 3). Asked whether such members go, the player: "delete them if
  possible. most cases should allow similar things via mocking the affected object. if it is
  absolutely not possible to get this information otherwise *and* this information is necessary for
  the test to make sense / confirm the desired behavior we can keep it. although those cases might
  be hints that the design of that module is suboptimal" (curly-rabbit #1095). **Read as:** each is
  tested through a fake handed in or through what the game exposes (the drawn arrow, the plans, the
  world) and then removed, superseding those two records' choice, and the same for the atlas
  library's accounting (`is_acquired()`, `reference_count()`) and `EventsAhead.walk_siting()`; one
  stays only where both conditions hold, and its builder writes down why and what about the module
  makes it so.
- **A hand-built checkpoint's facing and gate state go through a plan** (`Planned` with `facing`
  and `gate_state`, handed to `EventStreaming.add()`), not a new `spawn_extra()` parameter that only
  tests would pass.


Method: greps over `tests/*.gd` (`shared_state.gd` and `test_prediction_reuse.gd` skipped) plus a
script that lists every public `func`/`var` defined under `src/` whose name a test reads as `.name` and
that has **no other word occurrence anywhere under `src/`** outside comments and its own definition
(the "zero-reader list", section 3). Two weaker tiers are given as counts only.

Verdict key for the seam column: SEAM = a game caller exists / the game hands it in, so converting is mechanical;
GAP = the game has no reader, so the test goes through what the game exposes (drawing, a signal, input and frames)
or the member is removed/needs a design decision.

---

## 1. Private members reached by a route the count misses

No test reads a private member by a route the count misses, apart from one kept read:
`tests/test_touch.gd` reads `TouchControls._FOCUS_KNOB_OFFSET` and `_FOCUS_KNOB_RADIUS`, since the
knob is a `draw_circle()` straight onto the control with no drawer to record it and a headless run
draws no pixels; the comment beside the read says so. Reads of a public member by a name held in a
variable (`node.get("atlas")`, `row.get(field)` over the catalogue's flags, the picture table's
constant sweep in `test_atlas_events.gd`) need no change.

---

## 2. Hand-edited game collections and state, by owner

### 2.1 `EventManager.world.instances` (the live-event list)

No test writes the live-event list: events come into play through `EventManager.spawn_extra()`,
`spawn_warned()` or a `Planned` handed to `EventStreaming.add()` and streamed in, and leave through
`retire()` or `clear()`. The finale rig, the escape roadblock rig and the scheduler suites build
`Planned` lists by hand and hand them to the scheduler or a rig, which is how a day's plans reach the
manager (`EventStreaming.take(plans)`), not a bypass of the list.

### 2.2 `EventWorld` / `EventManager` fields written to skip `setup_world()` / `start_day()`

No test writes an `EventWorld` field: suites hand the manager its world through `setup_world()`,
`setup()`, `use_run()` and `use_player()`, its day through `start_day()` or `start_recipe()`, and its trace
through the manager's own `trace` setter. Two writes of the baby's `WorldContext` stay:
`test_invincible.gd` sets `noise` on its own fake world, a test double's state no game path sets, and
`test_excitement_source.gd` hands a world its excitement sources, the hand-in `main.gd` and `City` make.

### 2.3 `CityMap` tile state written by hand

The game writes a map's tile state through `close_streets()`, `seal_soft_tile()`, `clear_day_soft_seals()` and
`obstruct_tiles(owner_id, tiles)` with `release_obstruction()`, and the tests do too, apart from five fixtures on a
bare or hand-made map that no game writer can make:
- `test_turns.gd` closes a junction box's lane tiles, a two-tile plug in an arm and lane stubs four tiles apart by
  writing `closed_tiles`. `close_streets()` closes only the ground a street segment's two mouths cut off, so it makes
  none of these, and closing the segment beyond the box instead changes what each check asserts. Open: re-author the
  scenarios around a real segment closure, or a map-level hand-in for lane stubs, which only tests would call.
- `test_resistance_alley_siting.gd` appends a 16-tile alley to `alley_rects`; no generated alley is longer than 8
  tiles.
- `test_ground_floor.gd` writes `building_rects` for hand-placed buildings; the recipe path writes it only from a
  full saved scene context.
- `test_still_watch.gd` writes `main_road = 0`, which the generator never picks (it picks among the middle
  corridors) and only a recipe context can set.
- `test_scene_recipe_stretch.gd` writes `stretch_active` on a 5x5 U-shaped map made as a counterexample; the test
  is already handed the real scene's map (unused) as `_map`.

### 2.4 Run and city state written by hand
`run.attempt_spend.scars.append({...})` (`test_acts.gd:292`), `run.attempt_spend.consumed_one_shots.append(...)` (`test_day_loop.gd:807,823`),
`run.resistance.completed_steps.assign/clear` (`test_day6_yeller_met.gd:53`, `test_day7_van.gd:52`, `test_resistance_placement_kinds.gd:545`),
`_run.resistance.sabotage_done = true` (`test_blackout.gd`, the game sets it at `resistance_director.gd:3122`),
`signals.powered = x` and `signals.elapsed = f` (`test_blackout.gd:272-274,288`; the game writes `powered` only in `Blackout.go_dark()/restore()` and the dev runtime), `building.powered/day/condition` writes on hand-built `Building.new()` (`test_blackout.gd`, `test_city_decay.gd`). These are fixture state on `RunState`, whose public fields the game also writes; verdict SEAM where the game's writer is a callable (`ResistanceDirector`'s completing a step, `Blackout.go_dark()`), otherwise accepted fixture.

### 2.5 `Crowd`
Agents are placed through `add_recipe_actor()` already. Remaining: `city.crowd.clear()` (about 30 sites in `crowd_closures_rig.gd`, `crowd_rig.gd`, `test_atlas_*`, `test_crowd_*`) is the game's own call (`day_director.gd:181`), fine. No test appends to the agent list. `set_focus()` is zero-reader (section 3).

### 2.6 `ChurnEvents.list` in `test_halo.gd`, `RecordingRoofDrawer`s, `FakeClock`s: the suite's own fakes, not game collections.

---

## 3. Public members only tests call (zero-reader list)

Meaning: defined under `src/`, read by name by a test, and no other occurrence of that word anywhere in `src/` outside comments and the definition.
(Name collision across classes is possible in principle; spot-checked `trap`, `observer`, `reads`, `set_focus`, `is_acquired`, `reference_count`, `save_snapshot`, `penalise_resistance`: all hold.)
Grouped by owner. Each line: `member` (src file:line) -> tests that read it -> seam verdict.

**ResistanceDirector (`src/resistance/resistance_director.gd`)** -- item's "public seams" list claims these; none has a game caller:
`arrow_key` (3305), `arrow_lead_at` (3520), `arrow_nearest_at` (3514), `arrow_sweeping` (3529), `arrow_targets` (3381), `door_axis` (3228), `door_position` (3225),
`trap` (3218), `mast_in_play` (136), `mark_tiles` (1693), `reaches_from_home` (2633), `fell_back` (1848) -> `test_resistance_arrow.gd`, `test_day13_guard.gd`, `test_resistance_crossing.gd`,
`test_resistance_alley_siting.gd`, `test_resistance_replacement.gd`, `test_burnt_door.gd`, `test_resistance_reach_*.gd`, probes.
Verdict GAP for the arrow family: the game draws the arrow (`red_arrow_target()` is read by the UI; confirm), so test what the drawn arrow does (position of the arrow node/`DangerEdge`, or its pickup via a recording drawer) and remove the accessors, or accept as design decision (the item already allows a decision). `door_position/door_axis/trap`: the crossing suite wants what the checkpoint controller exposes (see next).
**CheckpointController (`src/events/checkpoint_controller.gd`):** `crossing_door` (140), `guard_after_her` (129) -> `test_resistance_crossing.gd`, `test_checkpoints.gd`. GAP: the guard stepping out is visible through the instance list (`manager.plans()` live instance by `def.id`) and the warning board (`WarningBoard`), which the suite already reads in part.
**Happenings (`src/resistance/happenings.gd`):** `raid_vans` (73), `raid_beat` (78), `is_closing` (401), `frontage_of`/`spine_x` (item lists) -> `test_resistance_replacement.gd`, `test_park_cordon.gd`, `test_park_return.gd`, probes. GAP: read the vans/beat as instances in the world (`EventManager.plans()`), `is_closing` as the cordon's visible officers (`cordon_in_the_world.gd` already does this).
**CordonTape (`src/resistance/cordon_tape.gd:60`):** `body_rect` -> `test_park_cordon.gd` (2 uses). GAP: the tape's blocker footprint through `map.is_obstructed(tile)` or its collision shape in the physics world.
**Events: EventsAhead (`src/events/events_ahead.gd`):** `walk_siting` (645), `sent_pursuer` (252) -> `test_resistance_arrow.gd`, `test_event_manager_fire.gd`, `test_route_bag.gd`, `test_pursuer_on_foot.gd`. `walk_siting`: GAP, as the item says. Siting seams with a game caller exist: `EventManager.queue_a_task_row()`, `WalkSiting.near_her()`. `sent_pursuer`: the poster's pursuer is a plan; read it off `plans()`.
**Events: EventInstance behaviours and look:** `its_officer` (`event_instance.gd:977`), `walk_on_by_hand` (only the dev runtime), `has_seen_her`/`has_investigated` (`event_investigation.gd`), `has_its_far_guard_posted` (`event_barrier_post.gd:57`), `plan_the_rest_again` (`event_departure.gd:120`), `take_now` (`event_abduction.gd:22`), `is_standing` (`event_car_driving.gd:95`) -> `test_patrol_vanish`, `test_event_behaviours`, `test_pursuer_on_foot`, `finale_rig`, `test_event_redraw`, `test_event_strides`, `test_car_driving`, `test_police_car`, `test_fire_truck_body`. GAP unless the behaviour calls them: each is a predicate the behaviour checks through its fields; replacement is to read the phase/position/drawn picture over real frames (`take_now`/`plan_the_rest_again` are "do it now" hooks: an abduction/departure advanced by real ticks).
**Events: RoadblockLook / EventLook / EventPictures / DrawLayer:** `RoadblockLook.attach_nodes` (201, 17 uses) and `far_guard_node` (239), `EventLook.drawn_rect_now` (476), `EventPictures.boom_arm_span` (1381), `DrawLayer.layer_of` (62) -> `test_halo_behind`, `test_event_views`, `test_barrier_stays`, `test_draw_layers`, `finale_rig`, `test_drawn_view`, `test_no_pop_in`, `test_resistance_traps`, `test_checkpoints`. `attach_nodes` is the look's setup done by hand (GAP: let the instance enter the tree, which attaches it); `drawn_rect_now`, `far_guard_node`, `layer_of`, `boom_arm_span` GAP: assert through the recording drawer / node under the instance (the barrier suite already reads `band_node()`, `band_rim_holder()`), or the instance's `z_index`.
**Crowd:** `Crowd.set_focus` (398; 64 uses), `signals_for_tests` (495; the name says it), `space_out_the_traffic` (653; SELF), `CrowdLanes.quietest_pavement` (232) and `busyness` (SELF), `TrafficIndex.entry_count` (110), `CrowdExcitement.jolt_swell` (161), `LaneMover.lane_key_parts` (658; 3 suites, `CrowdAgent.lane_key_parts`), `Crowd.recipe_coverage` (dev only) -> `crowd_rig.gd`, `crowd_closures_rig.gd`, `test_blackout.gd`, `test_car_front.gd`, `test_checkpoints.gd`, `test_turns.gd`, `test_crowd_contributions.gd`, `test_recipe_composition.gd`. `set_focus` is the one with 64 readers: the crowd's own focus is set by `Crowd.use_player()` and its ticks, so tests move a stroller (or `use_player` a body they place) instead: SEAM. `signals_for_tests` -> `crowd.signals` is the same object as `city.signals`: use `city.signals` (SEAM). `lane_key_parts`: GAP (item), read `heading()`/`lane_key()` and the lane through position; `entry_count`/`jolt_swell`: GAP, read the index through a car that stops/ a bump through `EventBus.crowd_bumped`.
**City (`src/city/city.gd`):** `close_ground` (1545; `test_scenery_residency.gd` x3), `home_door_is_sealed` (579; `test_resistance_placement_kinds.gd`), `ScenerGround.has_water` (205; `test_main`, `test_scenery_animation`, `test_scenery_residency`). GAP: `close_ground` is the edit hook for a stretch; the game's path is `set_region_plan()`/`recipe_closures` (dev) or `start_day()`; `home_door_is_sealed` is read through the door body in the physics world (the resistance suites do); `has_water` through `scenery_ground_source()` (the game reads that at `city.gd:1555`).
**RouteTree (`src/routes/route_tree.gd`):** `branch_for` (1060), `bundles` (1053), `has_a_choice` (120; also `trunk_used_the_spine` SELF) -> `test_route_tree.gd` (16 uses), `test_seals.gd`, `test_power_station.gd`. GAP: the planner is the consumer; test through the plan a day ends with (what `plan_day()` places and the walk the guarantee gives), as `test_power_station` partly does.
**StreetNetwork:** `junction_distances` (185) -> `test_routes_lattice.gd`. GAP (a route-distance check; the game reads `_adjacency` internally).
**Dev tools (zero-reader):** `DebugLayers.body_outline_count` (453), `AutoScreenshot` family, `WalkPlan.smoothed_turns` (68), `RigLock.has_a_deadline` (64), `RigLock.is_the_rigs_own_press` (95; see section 4), `RunConfig.rig_quit_seconds`; `FrameGraph.classes` (119), `FrameCost.*`. These are tools, each tested through what it does elsewhere in the same suite; low priority.
**Atlas library (`src/visuals/atlas_library.gd`):** `is_acquired` (565; 42 uses), `reference_count` (570; 44), `is_resident` (477), `last_load_moment` (452), `region_name_for` (139, 2 definitions), `illustrated_path_for` (149), `AtlasLibrary`/`PosterArt.region_names` -> the `test_atlas_*.gd` family. Verdict: GAP but design decision. They are the library's accounting (who holds a page); the game never asks it back. The tests assert load/release discipline, which is observable through page `Texture2D` identity/drawn textures... or accept as the library's own public API (it is a service class, not a game consumer); needs a player/orchestrator decision whether a service that exists to be measured counts.
**Stroller / Baby:** `Stroller.indicator_sources` (234), `Baby.set_stroller` (194; `test_resistance_placement_kinds.gd`) -> `test_stroller`, `test_atlas_loading`. GAP: `indicator_sources` is the draw table; read what the stroller draws.
**Telemetry:** `Telemetry.begin_memory_log` (`telemetry.gd`), read by `test_telemetry.gd` and about 30 other sites, stays: it is the one way a test gets a live run log with no file on disk. Its reason is the design the player's answer points at (inbox #1095 in curly-rabbit): the autoload owns the log and where it lives, and only `RunSession` is handed its log, while the observer and the gameplay classes call the autoload by name, so a test cannot hand them a fake log. Open: handing the log to those classes, which would let it go.
**Tuning:** `required_horn_time` (1019), `required_horn_sight` (1024), `sleepiness_gain_calm` (62) -> `crowd_rig`, `test_blackout`, `test_police_car`, `test_fire_truck_body`, `test_tuning_fairness`, `test_meters`, `scenes`. These are functions of the tunables used only to assert fairness contracts (public, balance skill). Decision: leave (a test reading a balance helper is the design).
**Other:** `MarbleBag.rig_spaced` (204; `test_route_bag.gd:139`, the name says it), `Crowd`/`EventScheduler.Planned` items listed in the README as having callers are SELF/DEV (below). `GroundRecipe.reads` (45; `test_ground_layers.gd`), `InteriorMapPlan.inner_floor_approaches` (351; `test_interior.gd`), `Blackout.update/distance_from_station` are called by `Blackout._physics_process` (`update` has a game caller: the blackout suite could use a stroller instead of calling `update(point)`).

### Two weaker tiers (counts, for scope)
- **DEV-only readers** (the only `src/` caller is under `src/dev`, the scene-recipe/rig tools): about 55 names including `Crowd.add_recipe_actor` and `recipe_coverage`, `City.set_region_plan`, `ResistanceDirector.read_mark/start_recipe_task/scene_task_errors`, `EventManager.start_recipe`, `EventScheduler.place_at/recipe_placement`, `EventInstance.walk_on_by_hand/solid_part_centres/solid_part_shapes/is_solid`, `WorldMap.is_obstructed`, `VisibleView.visible_share`. The README already treats the recipe runtime as a game caller; the first reading above counts `src/dev` among the game's own classes (the item's own seams `add_recipe_actor`, `place_at`, `read_mark` depend on it).
- **SELF-only readers** (public, but the only caller is the defining file itself): about 250 names, dominated by `Building` (ground-floor and roof family used by `test_ground_floor.gd`: `ground_floor_texture`, `window_texture`, `entrance_door_col`, `extension_rows`, `portico_is_drawn`, `roof_layout`, `fire_escape_*`, 20+ members), `TouchControls` geometry (`heading_to`, `in_dead_zone`, `is_double_tap`, `run_focus_for`, `boundary_x`), `FrameRecorder`/`FrameLedger` (`ledger` alone has 34 test reads), `ParkCordon` (`stretches` 34, `officers` 11, `last_gap` 7, `closed_at`, `trapped`, `relaid`), `EventScheduler.Planned` helpers (`gap_to`, `counts_against_the_line`, `denies`, `reach_touches`, `keeps_its_field_clear`, which the item names as asked "what the scheduler asks"), `ResistanceDirector` (`guard_position`, `guard_spot`, `draw_reachable`, `place_contact`, `nearest_alley_*`), `TitleScreen.hard_mode_*`, `GameSave.has_save/fail/file_data`, `FigureLook`/`PursuerLook` `*_pictures()`, `Sprites.base_transform_of`. They are internals made public for tests, which the player ruled a loophole (the second reading above); `tests-own-class-members.md` is the pass that makes them internal.

---

## 4. The crowd's, the events' and RouteTree's privates in the three city suites; `test_rig_press.gd`

The line numbers in the blackout and scenery residency suites are from before those suites built a city per test (record minty-quail-speckled-lynx); a builder re-reads them.

**`test_city_decay.gd`:** no crowd, RouteTree, or private-name read at all. Events: `EventScheduler.open_ground_for(mouse, map, {})` (`:174`) and `EventScheduler.build_day(DaySpec.for_day(day), rng, map)` (`:185`) -- both are the scheduler's own calls (`open_ground_for` is read by `place_*`; the suite asks what the scheduler asks). Hand-built `Building.new()` fixtures with `condition`, `day`, `district`, `footprint`, `front_drawer` set (`:179-260`, 12 of them with positions): the same pattern as blackout. Nothing further hidden; the README's "crowd, events and RouteTree privates" does not describe this file.

**`test_blackout.gd`:**
- crowd: `_city.crowd.start_day(day, rng)` (`:60,284`), `_city.crowd.set_focus(centre)` (`:288`, zero game reader), `_city.crowd.step(STEP)` (`:293`, public, the checkpoint suites do the same), `for agent in _city.crowd.agents()` (`:296`), `agent.kind`, `agent.travelling_vertically()` (`lane_mover.gd:566`; read by `crowd.gd`), `agent.speed()` (`lane_mover.gd:543`; many readers). Seam: stand a real stroller (or `Crowd.use_player(body)`) where `set_focus` points, let the crowd's physics ticks run (`PhysicsTicks.pass_ticks`), read cars by `CrowdLanes.corridor_at()` and `heading()`.
- events: `_city.events.start_day(DaySpec.for_day(day), rng, [], power_station_door_position())` (`:59`) and `_city.events.plans()` (`:82`, public). `start_day` by hand duplicates the day director's call; the stable form is `DayDirector.start_day()` or `city.start_day(state, day, rng)` + `events.start_day` as `Boot.day(main)` does.
- other privates-by-another-route: `_run.resistance.sabotage_done = true` (`:*`), `_city.signals.powered/elapsed` writes (`:272-274`), `_city.blackout.update(point)` (`:73,92,99,...`; the game calls it from `Blackout._physics_process` with her position: SEAM-by-stroller instead of calling `update(point)`), `hall.powered/day` writes on a hand-built `Building` with 13 copied fields (`:155-180`), `scene.lighting_at()` and `scene.flash_windows()` on `InteriorScene` (SELF only: GAP -> read what the scene draws).
- RouteTree: not touched.

**`test_scenery_residency.gd`:** no crowd, events or RouteTree. Its non-seam reads are `city.scenery.view =` (`:540,545`), `budget_usec =` (`:335,365,379,457`), `scenery_ground.mode =`/`.clear()`/`.release(key)`/`.keys_in()`/`.chunks`/`.elapsed` (`:76-87,143-147,175,293-305,451`), `city.close_ground(rect)` (`:105,501,547`, zero game reader), `city.scenery.set_process(false)` (`:272,279`), `scenery_ground_source(tile)` (`:568,587`, a game reader exists at `city.gd:1555`), `has_water`, `get_cell_*`, `get_used_cells` (SELF). `chunks`, `mode`, `elapsed`, `keys_in`, `release`, `view`, `budget_usec` are public fields/methods that `SceneryResidency` itself reads/writes (`scenery_residency.gd:95,102,164`), so by the letter they pass; `close_ground`, `has_water` are the zero-reader ones.

**What the city suites touch of the crowd, the events and `RouteTree` is the above**: the only RouteTree readers in tests are `test_route_tree.gd` (`branch_for`, `bundles`, `has_a_choice`), `test_seals.gd` (`trunk_used_the_spine`) and `test_power_station.gd` (`cells()`, `lattice_grid`); the crowd items are `set_focus` and `agents()` in blackout.

**`test_rig_press.gd`:** reads no `_tap()` (grep finds only a comment in `test_touch.gd:194` naming it). It builds the rig with `AutoScreenshot.from_config(RunConfig.parse(words, "", true))`, sets `rig.simulation_clock = clock.read` (public field the rig reads) and lets real frames pass; the only other members are `RigLock.is_the_rigs_own_press()` (zero-reader, tested directly at `:38-70`: SELF-by-letter fails; it is the predicate `RigLock._input()` applies, and the real-frames tests above it already cover its behaviour, so the direct test could go) and `RigLock.locked_out =` (public field).

---

## 5. Proposed split into builds (one mechanism each)

Files in a build are those in the tables above. Builds with disjoint file sets can run in parallel; a shared helper (`finale_rig.gd`, `crowd_rig.gd`, `resistance_rig.gd`, `event_manager_rig.gd`) belongs to exactly one build.

3. **Map tile state through the map's own writers** (section 2.3): the five fixtures it lists, each open as it says. Files: `test_turns.gd`, `test_resistance_alley_siting.gd`, `test_ground_floor.gd`, `test_still_watch.gd`, `test_scene_recipe_stretch.gd`.
4. **Escape rigs** (the finale rig's hand-built `Planned`/guard/bands, `RoadblockRig`, `escape_roadblock_rig.gd`, `seal_reach_rig.gd`, the `far_guard_node`/`layer_of`/`attach_nodes` reads): `finale_rig.gd`, `escape_roadblock_rig.gd`, `seal_reach_rig.gd`, `test_barrier_stays.gd`.
6. **Zero-reader members: resistance and checkpoint owners** (`ResistanceDirector` arrow/door/trap/mark accessors, `CheckpointController`, `Happenings`, `CordonTape`). Files: `test_resistance_arrow.gd`, `test_resistance_crossing.gd`, `test_resistance_alley_siting.gd`, `test_resistance_replacement.gd`, `test_resistance_traps.gd`, `test_resistance_reach_*.gd` (narrow, relocated, contacts), `test_burnt_door.gd`, `test_day13_guard.gd`, `test_park_cordon.gd`, `test_park_return.gd`, `park_cordon_sweep.gd`, `resistance_rig.gd`.
7. **Zero-reader members: events and look owners** (`EventsAhead.walk_siting/sent_pursuer`, behaviour predicates, `RoadblockLook`/`EventLook`/`EventPictures`/`DrawLayer`). Files: `test_event_behaviours.gd`, `test_pursuer_on_foot.gd`, `test_patrol_vanish.gd`, `test_route_bag.gd`, `test_event_manager_fire.gd`, `test_halo_behind.gd`, `test_event_views.gd`, `test_draw_layers.gd`, `test_drawn_view.gd`, `test_no_pop_in.gd`, `test_event_strides.gd`, `test_car_driving.gd`, `test_police_car.gd`, `test_fire_truck_body.gd`. Overlaps build 2 on `test_pursuer_on_foot.gd`/`test_patrol_vanish.gd`/`test_event_behaviours.gd`; sequence after it.
8. **Zero-reader members: crowd and RouteTree** (`set_focus`, `signals_for_tests`, `lane_key_parts`, `entry_count`, `jolt_swell`, `quietest_pavement`; `branch_for`, `bundles`, `has_a_choice`, `trunk_used_the_spine`, `junction_distances`). Files: `crowd_rig.gd`, `crowd_closures_rig.gd`, `test_car_front.gd`, `test_crowd_contributions.gd`, `test_turns.gd`, `test_recipe_composition.gd`, `test_recipe_crowd.gd`, `test_route_tree.gd`, `test_seals.gd`, `test_power_station.gd`, `test_routes_lattice.gd`. `set_focus` in `test_blackout.gd` goes with build 9. Overlaps build 3 on `test_turns.gd`.
9. **City/Building/scenery** (`close_ground`, `has_water`, `home_door_is_sealed`, `Building` ground-floor family, the hand-built `Building.new()` fixtures with writes to `powered/day/condition`). Files: `test_scenery_residency.gd`, `test_blackout.gd`, `test_city_decay.gd`, `test_ground_floor.gd`, `test_scenery_animation.gd`, `test_main.gd`. `test_ground_floor.gd` overlaps build 3.
10. **Atlas library accounting** (`is_acquired`, `reference_count`, `is_resident`, `last_load_moment`, `region_name_for`): files `test_atlas_*.gd`, `test_visuals.gd`, `test_interior.gd`.

Parallel groups: {2, 3, 10} are pairwise file-disjoint except as noted; 6, 7, 8 follow 2 and 3; the DEV-only tier is not scheduled (the first reading), and the SELF-only tier is `tests-own-class-members.md`'s.
