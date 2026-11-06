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
`building.powered/day/condition` writes on hand-built `Building.new()` (`test_blackout.gd`, `test_city_decay.gd`). These are fixture state on `RunState`, whose public fields the game also writes; verdict SEAM where the game's writer is a callable (`ResistanceDirector`'s completing a step, `Blackout.go_dark()`), otherwise accepted fixture.

### 2.5 `Crowd`
Agents are placed through `add_recipe_actor()` already. Remaining: `city.crowd.clear()` (about 30 sites in `crowd_closures_rig.gd`, `crowd_rig.gd`, `test_atlas_*`, `test_crowd_*`) is the game's own call (`day_director.gd:181`), fine. No test appends to the agent list. `set_focus()` stays with its reason (section 3).

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
**Events: EventsAhead (`src/events/events_ahead.gd`):** `walk_siting` stays, its reason written on it (record minty-quail-olive-sparrow): `test_route_bag.gd` reads the mast checks it sites, and `EventsAhead` builds that siting itself, so no test can hand it one. Its other readers are `test_resistance_arrow.gd` and the probes `m179_fire_on_her_way.gd` and `m180_crews_on_her_way.gd`.
**City (`src/city/city.gd`):** `home_door_is_sealed` (`test_resistance_placement_kinds.gd`), with no game reader: GAP, read through the door body in the physics world as the resistance suites do. `close_ground` and `has_water` are gone (record minty-quail-tawny-squirrel).
**RouteTree (`src/routes/route_tree.gd`):** `trunk_used_the_spine` is SELF, `tests-own-class-members.md`'s; the route tree suite reads branches, shared cells and route counts through members the planner uses (record minty-quail-lilac-walrus).
**Dev tools (zero-reader):** `DebugLayers.body_outline_count` (453), `AutoScreenshot` family, `WalkPlan.smoothed_turns` (68), `RigLock.has_a_deadline` (64), `RigLock.is_the_rigs_own_press` (95; see section 4), `RunConfig.rig_quit_seconds`; `FrameGraph.classes` (119), `FrameCost.*`. These are tools, each tested through what it does elsewhere in the same suite; low priority.
**Atlas library (`src/visuals/atlas_library.gd`):** the atlas suites read the library's load and release through the run log's page lines (record minty-quail-freckled-walrus). `is_acquired` and `reference_count` are still read by `test_escape_invisible_wall.gd:151-153`, `test_telemetry.gd:1556` and `test_scenery_animation.gd` (99, 354-361), each a line or two through the atlas suites' page-log helper (`tests/atlas_page_log.gd`); once they convert, both go. `region_name_for` and `illustrated_path_for` stay: the bake calls them.
**Stroller / Baby:** `Stroller.indicator_sources` (234), `Baby.set_stroller` (194; `test_resistance_placement_kinds.gd`) -> `test_stroller`, `test_atlas_loading`. GAP: `indicator_sources` is the draw table; read what the stroller draws.
**Telemetry:** `Telemetry.begin_memory_log` (`telemetry.gd`), read by `test_telemetry.gd` and about 30 other sites, stays: it is the one way a test gets a live run log with no file on disk. Its reason is the design the player's answer points at (inbox #1095 in curly-rabbit): the autoload owns the log and where it lives, and only `RunSession` is handed its log, while the observer and the gameplay classes call the autoload by name, so a test cannot hand them a fake log. Open: handing the log to those classes, which would let it go.
**Tuning:** `required_horn_time` (1019), `required_horn_sight` (1024), `sleepiness_gain_calm` (62) -> `crowd_rig`, `test_police_car`, `test_fire_truck_body`, `test_tuning_fairness`, `test_meters`, `scenes`. These are functions of the tunables used only to assert fairness contracts (public, balance skill). Decision: leave (a test reading a balance helper is the design).
**Other:** `Crowd`/`EventScheduler.Planned` items listed in the README as having callers are SELF/DEV (below). `GroundRecipe.reads` (45; `test_ground_layers.gd`), `InteriorMapPlan.inner_floor_approaches` (351; `test_interior.gd`), `Blackout.update/distance_from_station` are called by `Blackout._physics_process` (`update` has a game caller: the blackout suite could use a stroller instead of calling `update(point)`).

### Two weaker tiers (counts, for scope)
- **DEV-only readers** (the only `src/` caller is under `src/dev`, the scene-recipe/rig tools): about 55 names including `Crowd.add_recipe_actor` and `recipe_coverage`, `City.set_region_plan`, `ResistanceDirector.read_mark/start_recipe_task/scene_task_errors`, `EventManager.start_recipe`, `EventScheduler.place_at/recipe_placement`, `EventInstance.walk_on_by_hand/solid_part_centres/solid_part_shapes/is_solid`, `WorldMap.is_obstructed`, `VisibleView.visible_share`. The README already treats the recipe runtime as a game caller; the first reading above counts `src/dev` among the game's own classes (the item's own seams `add_recipe_actor`, `place_at`, `read_mark` depend on it).
- **SELF-only readers** (public, but the only caller is the defining file itself): about 250 names, dominated by `Building` (ground-floor and roof family used by `test_ground_floor.gd`: `ground_floor_texture`, `window_texture`, `entrance_door_col`, `extension_rows`, `portico_is_drawn`, `roof_layout`, `fire_escape_*`, 20+ members), `TouchControls` geometry (`heading_to`, `in_dead_zone`, `is_double_tap`, `run_focus_for`, `boundary_x`), `FrameRecorder`/`FrameLedger` (`ledger` alone has 34 test reads), `ParkCordon` (`stretches` 34, `officers` 11, `last_gap` 7, `closed_at`, `trapped`, `relaid`), `EventScheduler.Planned` helpers (`gap_to`, `counts_against_the_line`, `denies`, `reach_touches`, `keeps_its_field_clear`, which the item names as asked "what the scheduler asks"), `ResistanceDirector` (`guard_position`, `guard_spot`, `draw_reachable`, `place_contact`, `nearest_alley_*`), `TitleScreen.hard_mode_*`, `GameSave.has_save/fail/file_data`, `FigureLook`/`PursuerLook` `*_pictures()`, `Sprites.base_transform_of`. They are internals made public for tests, which the player ruled a loophole (the second reading above); `tests-own-class-members.md` is the pass that makes them internal.

---

## 4. The crowd's, the events' and RouteTree's privates in the three city suites; `test_rig_press.gd`

**The city suites** (`test_city_decay.gd`, `test_blackout.gd`, `test_scenery_residency.gd`) read none of the crowd's, the events' or `RouteTree`'s privates (record minty-quail-tawny-squirrel). One hand call stays open: `test_blackout.gd` starts the events' day itself (`_city.events.start_day(DaySpec.for_day(day), rng, [], power_station_door_position())`), duplicating the call the day director makes, where the stable form is `city.start_day()` followed by `events.start_day()` as `Boot.day(main)` does; its `_city.events.plans()` read is public and stays. Otherwise what is left there is members only their own class uses, `tests-own-class-members.md`'s. The only `RouteTree` readers in tests are `test_route_tree.gd` (`branches`, `branches_on()`, a branch's `routes`), `test_seals.gd` (`trunk_used_the_spine`) and `test_power_station.gd` (`cells()`, `lattice_grid`).

**`test_rig_press.gd`:** reads no `_tap()` (grep finds only a comment in `test_touch.gd:194` naming it). It builds the rig with `AutoScreenshot.from_config(RunConfig.parse(words, "", true))`, sets `rig.simulation_clock = clock.read` (public field the rig reads) and lets real frames pass; the only other members are `RigLock.is_the_rigs_own_press()` (zero-reader, tested directly at `:38-70`: SELF-by-letter fails; it is the predicate `RigLock._input()` applies, and the real-frames tests above it already cover its behaviour, so the direct test could go) and `RigLock.locked_out =` (public field).

---

## 5. Proposed split into builds (one mechanism each)

Files in a build are those in the tables above. Builds with disjoint file sets can run in parallel; a shared helper (`finale_rig.gd`, `crowd_rig.gd`, `resistance_rig.gd`, `event_manager_rig.gd`) belongs to exactly one build.

3. **Map tile state through the map's own writers** (section 2.3): the five fixtures it lists, each open as it says. Files: `test_turns.gd`, `test_resistance_alley_siting.gd`, `test_ground_floor.gd`, `test_still_watch.gd`, `test_scene_recipe_stretch.gd`.
6. **Zero-reader members: resistance and checkpoint owners** (`ResistanceDirector` arrow/door/trap/mark accessors, `CheckpointController`, `Happenings`, `CordonTape`). Files: `test_resistance_arrow.gd`, `test_resistance_crossing.gd`, `test_resistance_alley_siting.gd`, `test_resistance_replacement.gd`, `test_resistance_traps.gd`, `test_resistance_reach_*.gd` (narrow, relocated, contacts), `test_burnt_door.gd`, `test_day13_guard.gd`, `test_park_cordon.gd`, `test_park_return.gd`, `park_cordon_sweep.gd`, `resistance_rig.gd`.

**The leftover readers build** takes what the atlas build (record minty-quail-freckled-walrus) and the events and looks build (record minty-quail-olive-sparrow) left in files no other build owns. `AtlasLibrary.is_acquired()` and `reference_count()` go once their last readers move onto the atlas suites' page-log helper (`tests/atlas_page_log.gd`): `test_escape_invisible_wall.gd` (151-153), `test_telemetry.gd` (1556) and `test_scenery_animation.gd` (99, 354-361). `RoadblockLook.attach_nodes()` goes once `test_events_pursuit.gd`, `test_scenery_animation.gd` and the probes `charger_warning.gd` and `scenery_animation_runtime.gd` let the instance enter the tree instead, and `EventPictures.boom_arm_span()` once `test_checkpoints.gd` reads the boom off what is drawn. Files: `test_escape_invisible_wall.gd`, `test_telemetry.gd`, `test_scenery_animation.gd`, `test_events_pursuit.gd`, `test_checkpoints.gd`, `tests/probes/charger_warning.gd`, `tests/probes/scenery_animation_runtime.gd`.

Parallel groups: of 3's open fixtures, `test_resistance_alley_siting.gd`'s sits in a file 6 owns and goes with it or after it, and the other four are 3's alone; the DEV-only tier is not scheduled (the first reading), and the SELF-only tier is `tests-own-class-members.md`'s.
