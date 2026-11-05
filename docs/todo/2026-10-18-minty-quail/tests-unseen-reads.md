# Tests drive public seams: what the count cannot see

`tests-public-seams.md`'s two count commands print nothing outside its two exempt files, and they
cannot see a private member reached another way, a game collection a test edits by hand, or a
public member that only tests call. This item is the read-only scoping of those, by owner, with the
seam each moves to and the builds they split into. Its rule for a seam is `tests-public-seams.md`'s
Build paragraph: a member made public, or added, has a caller among the game's own classes or is a
dependency the game's own code hands in, and where the game has no reader the test goes through
what the game exposes. File and line references are to `main` when the item was filed; a builder
re-reads them.

**Readings of the rule.** The first two, open to the player's overturn, rest on the Build
paragraph's wording and leave the two weaker tiers below unscheduled; the third is a question on
the Nappy board (members-no-reader), and builds 6, 7 and 10 wait for its answer; the fourth
follows from the Build paragraph alone:

- **A caller under `src/dev` counts as a game caller.** The rigs and the scene-recipe runtime are
  the composition root in `tools/layer_map.py`'s layering (**orchestrating**, "Code is designed by
  layer"), and `tests-public-seams.md` already accepts `Crowd.add_recipe_actor()` (only the recipe
  runtime calls it) as a seam. About 55 names stand on this reading.
- **A caller in the member's own class counts.** It rests on the Build paragraph's wording, "a
  caller among the game's own classes", which the defining class meets; minty-quail-47's "each used
  by the game or by its own owner" is about a hand-in a field's owner writes, and minty-quail-44's
  `Building` queries had callers in other classes too (`City`, the posters), so neither record
  decides it. About 250 names stand on this reading.
- **Whether a member with no reader at all stays is the player's to answer** (board question
  members-no-reader). Records minty-quail-busy-swan (`mast_in_play()` and the `arrow_*` queries)
  and minty-quail-downy-marten (`door_position()`, `door_axis()`, `trap()`) added queries that only
  tests read, and `tests-public-seams.md`'s resistance sentence lists `ResistanceDirector`'s `arrow_*`, `door_*`, `trap()`,
  `mast_in_play()`, `mark_tiles()`, `reaches_from_home()` and `fell_back()` among the seams the
  resistance suites drive; none has a caller under `src/` (section 3). The Build paragraph says a
  public member only a test reads is not a seam, which those records' queries are. *Proposed, not
  asked for:* the Build paragraph wins, so each is tested through what the game exposes (the drawn
  arrow, the plans, the world) and then removed or made private, superseding those two records'
  choice; the same would hold for the atlas library's accounting (`is_acquired()`,
  `reference_count()`) and `EventsAhead.walk_siting()`.
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

| # | file:line | expression | what it does | replacement |
|---|---|---|---|---|
| 1a | `tests/crowd_rig.gd:1522` | `Crowd._LINE_BUCKET` | reads the private 128px bucket width (`const _LINE_BUCKET := 128.0`, `crowd.gd:962`) to place a hut/gate across a bucket edge. The count regex needs a lowercase letter after `._`, so an upper-case constant slips by | GAP. Nothing but `Crowd` reads the width. Test through behaviour: place the gate by the corridor geometry the test already knows (a gate 4 tiles = 4*TILE_SIZE from the line, a tile either side of every multiple) and assert the car stops; drop the `bucket ==` equality check, which only pins a private. |
| 1b | `tests/test_atlas_leaf_consumers.gd:164-166` | `[ModeButton._RESTART_ICON, ModeButton._CONTINUE_ICON, ModeButton._JOYSTICK_ICON, ModeButton._TAP_ICON, TouchControls._PAUSE_ICON, SaveIndicator._ICON]` | private region-name constants read to ask the atlas whether the ui page bakes them | GAP/decision. Each is drawn by its node via `atlas.region(_ICON)`; a test can ask what the node draws (a recording drawer, or the texture the node's `draw` used) rather than the constant. Alternative: ask `AtlasTable.baked().region_names()` for every `ui/` region and check the page-wide sweep (`test_atlas_events.gd` already does the whole-page walk for events). |
| 1c | `tests/test_atlas_loading.gd:94` | `AtlasTable.baked().group_of(SaveIndicator._ICON)` | same private constant | same as 1b: drop it and rely on the sweep (`group_of("ui/save")` as a literal is a name the player never sees; the node's draw is the contract). |
| 1d | `tests/test_scene_recipe_activity.gd:111,113,115` | `Building._Furniture.DUCT_RUN` and `Building._Furniture[kind]` (`kind` = upper-cased string from the recipe JSON, `.to_upper()`) | private enum (`building.gd:248`) indexed by a name built at run time, to compare against `building.recipe_roof_furniture` | GAP. `Building.roof_layout()` (public, drawn from; `test_recipe_roofs.gd` already reads it) and a recording `roof_drawer` give the units and textures the roof draws; compare those to the recipe's fixtures instead of the enum. |
| 1e | `tests/test_touch.gd:813` | `TouchControls._FOCUS_KNOB_OFFSET`, `_FOCUS_KNOB_RADIUS` | already named in `tests-public-seams.md` (no reader but the drawing) | GAP: read the knob from what `TouchControls` draws (recording `draw`), or leave as a named exception. |
| 1f | `tests/test_event_redraw.gd:610-615` (`_copy_of`, used `:293`) | `for property in def.get_property_list(): if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE: copy.set(property.name, def.get(property.name))` | copies **every script variable of `EventDef`, privates included** (`_default_parts` at `event_def.gd:351`, `_cost_cache` at `:1731`) by name held in a variable | SEAM-ish: build the second def the way the catalogue does, e.g. a catalogue constructor / `EventCatalogue.by_id()` then a public field edit on a fresh `EventDef.new()`, or add a game-used `EventDef.duplicate_for_row()` only if something in `src/` would call it (nothing does: GAP -> test would write the public fields it needs onto `EventDef.new()`). |
| 1g | `tests/test_resistance_placement_kinds.gd:410-412` | same loop over `ResistanceSteps.by_index(8).get_property_list()` copying into a `ResistanceSteps.Step.new()` | copies every script variable of `Step` (`resistance_steps.gd:52`; no private variables found, so currently only the by-name copy is hidden) | SEAM: `ResistanceDirector.use_steps()` is the game-used hand-in; build the timed step with `Step.new()` and set the public fields it needs (`deadline_fraction`), or add the field to `ResistanceSteps` as a catalogue row. |
| 1h | `tests/test_main.gd:701` | `_one(main, "ResistanceDirector").has_method("_process")` | asserts a private engine virtual is absent (the director has no frame hook so its clock cannot run on a drawn frame) | GAP / decision. This is a structural assertion, not a seam. Behavioural replacement: boot, raise `Engine.time_scale`/`Engine.max_fps` variation, assert the director's clock advances only per physics tick (the item's frame-length claim), or accept as an exception. |
| 1i | `tests/test_atlas_loading.gd:247-253`, `:373-376`; `tests/test_main.gd:122-125` | `"atlas" in node`, `node.get("atlas")`, `node.get_script().get_global_name()` | tree walks that find nodes by class name / property name string. `atlas` is a public field, so not private; flagged only because they are variable-name reads | no change needed (public member, found by class name). |
| 1j | `tests/test_events_catalogue.gd:115` | `row.get(field)` over `stands_along_its_street`, `lies_across_its_street`, `trails_a_lead`, `hides_in_its_hold`, `may_be_a_pelican` | reads public `@export` fields of `EventDef` by name | no change (public; could be written as direct `row.field` via a match, cosmetic). |
| 1k | `tests/test_atlas_events.gd:55` | `load("res://src/events/views/event_pictures.gd").get_script_constant_map()` | walks every constant of `event_pictures.gd`, including any `_PRIVATE` ones | acceptable by design (its comment: the sweep exists to catch a picture named anywhere in the table); only a decision if a private constant in that file should be excluded. |

Everything else in `get/set/call/callv/has_method/Callable/obj[name]/"_" + ...` scans was either a `Callable` the test
itself holds, a dictionary `.get`, the test's own `_test_*` names (`crowd_rig.gd:41-85`, `finale_rig.gd:36-43`,
`Callable(self, case_name)` at `crowd_rig.gd:95`), or JSON data (`snapshot["_dawn_brief"]` at `test_save.gd:688` is a
legacy save key, not a member). No `get_indexed`, `callv`, `set_deferred`, `"_" +` string concatenation or `get/set("_x")` exists.

---

## 2. Hand-edited game collections and state, by owner

### 2.1 `EventManager.world.instances` (the live-event list) -- the big one, 11 suites
Game paths that add/remove: `EventSpawner.spawn()` (`event_spawner.gd:112`, reached through `EventManager.spawn_extra()`,
`EventManager.spawn_warned()`), `EventStreaming.add()` + `stream_in()` (`event_streaming.gd:36,119`; `Planned` carries
`facing` and `gate_state`, so a hut/gate is a plan), `EventManager.retire()` (`:689`, `EventStreaming` erase at `:216`)
and `EventManager.clear()` (`:357`, throws all away).

| file:lines | expression | notes |
|---|---|---|
| `test_encounters.gd` 352, 422-423, 457, 467 (+ `clear()` 361, 430, 503) | append mothers, posts, hut, cyclist; `world.instances.clear()` | SEAM: `spawn_extra()` for a mover with a path (`:601,651` already do); `EventManager.clear()` for the clears. |
| `test_events_chat.gd` 94, 155, 207, 221, 245 | append `mother`/`far_lane` | SEAM: `spawn_extra()`. |
| `test_halo.gd` 313, 321, 553, 562, 940, 1020, 1054, 1422 (+ `erase` 1048, 1446) | `manager.add_child(x); manager.world.instances.append(x)`; `world.instances.erase(retired)` | SEAM: `spawn_extra()` / `retire()`. (`events.list.append(source)` at `:1148..1444` is `ChurnEvents`, the suite's own fake list: not a game collection.) |
| `test_danger.gd` 565, 574, 757, 804 (+ `erase` 816) | append `ordinary`/`lethal`/`engine` | SEAM: `spawn_extra()` / `retire()`. |
| `test_drawn_view.gd` 376 (+ `erase` 391) | append `engine` | SEAM as above. |
| `test_event_parts.gd` 181 (+ `clear` 49, in `_free_world`) | append hut; clear | SEAM: `streaming.add(Planned)`; teardown through `EventManager.clear()`. |
| `test_events_pursuit.gd` 572 | append inside the `arrive` callback handed to `manager.warn_first(def, her, where, arrive)` | SEAM: `manager.spawn_warned(def, path, pelican)` (`event_manager.gd:680`) is what the game's `arrive` does. |
| `test_day_director.gd` 78-90 | `director.events.world.instances.assign([kid, pelican])`, `.clear()` | SEAM: `spawn_extra()` of two cyclists, then read `landed_by_group()`; excitement set through `excitement.accumulate_landed()` stays. |
| `test_resistance_arrow.gd` 271 | `_city.events.world.instances.erase(near)` | SEAM: `_city.events.retire(near)`. |
| `finale_rig.gd` 792 (lured-off band), 1884 (charge test) | named in the item. 792: `EventManager.new()` with no `setup_world`, `EventInstance.new(); setup(escape_roadblock, (1000,1000)); manager.add_child(band); manager.world.instances.append(band)`. 1884: in a booted escape: `guard.atlas = city.events.world.atlas; city.add_child(guard); guard.set_process(false); city.events.world.instances.append(guard); guard.resume(...)` | 1884: SEAM `city.events.spawn_extra(EventCatalogue.by_id("masked_pursuer"), her.global_position, path)` (builds through `spawner.create()`, gives atlas/drawer/signals); `guard.set_process(false)`/`resume()` stay as the test's own stepping. 792: needs `manager.setup_world(map, run)` first (otherwise `spawn_extra` has no `world.map`); then `spawn_extra(EventCatalogue.escape_roadblock(), at)`, or best, `streaming.add(Planned.new(...))` so the band is a plan the escape would have planned (the manager's warning code at `:793` reads plans). |

Also in the family: `finale_rig.gd:706,948,1253` and `test_checkpoints.gd:1308` build `Planned.new(...)` by hand into
local arrays handed to `RoadblockRig.build` / `EventScheduler` helpers (not the manager's list); they hand a plan in through a seam
the scheduler reads, so not a bypass of a collection (`EventStreaming.take(plans)` is how the manager receives a day's plans).

### 2.2 `EventWorld` / `EventManager` fields written to skip `setup_world()` / `start_day()`

No test writes an `EventWorld` field: suites hand the manager its world through `setup_world()`,
`setup()`, `use_run()` and `use_player()`, its day through `start_day()` or `start_recipe()`, and its trace
through the manager's own `trace` setter. Two writes of the baby's `WorldContext` stay:
`test_invincible.gd` sets `noise` on its own fake world, a test double's state no game path sets, and
`test_excitement_source.gd` hands a world its excitement sources, the hand-in `main.gd` and `City` make.

### 2.3 `CityMap` tile state written by hand (the game uses `close_streets()`, `seal_soft_tile()`, `clear_day_soft_seals()`, `obstruct_tiles(id, tiles)` and its release)
- `closed_tiles[tile] = true / erase / clear`: `finale_rig.gd:1270`, `test_scene_recipe_task.gd:367,369`, `test_world_passability.gd:74`, `test_turns.gd:180,240,265,294,348,360,378,391`, `routes_closures_rig.gd:138,163,244`. SEAM: `map.close_streets(Array[RoadClosure])` (`city_map.gd:862`, the only game writer); un-close via building a fresh map or `clear_day_holds()`.
- `soft_sealed_tiles[soft] = true` (`test_world_passability.gd:75`) / `.erase` (`test_day13_guard.gd:411`): SEAM `map.seal_soft_tile()` and `clear_day_soft_seals()`.
- `obstructed_tiles[tile] = 1 / erase`: `test_day13_guard.gd:413,418`, `test_route_rig.gd:768,775`, `test_spawn_siting.gd:252`. SEAM `obstruct_tiles(owner_id, tiles)` and its release (`park_cordon.gd:1317` calls it).
- `alley_rects.append(rect)`: `test_event_views.gd:416-417`, `test_resistance_alley_siting.gd:425`. The game writes it only in `CityGenerator` (`city_generator.gd:1050`): GAP for a standalone map; use a generated map or `CityGenerator`'s block layout, or hand in a one-block generated city.
- `map.building_rects = rects` (`test_ground_floor.gd:1052`), `map.main_road = i` (`test_still_watch.gd:268`), `map.stretch_active = true` (`test_scene_recipe_stretch.gd:195`): fixtures on a bare map; `recipe_city_builder.gd:171` writes `building_rects`, so the stretch/recipe path is the SEAM.

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
**Stroller / Baby:** `Stroller.indicator_sources` (234), `Baby.set_stroller` (194; `test_resistance_placement_kinds.gd`) -> `test_stroller`, `test_player_presentation`, `test_atlas_loading`. GAP: `indicator_sources` is the draw table; read what the stroller draws.
**Main (`src/main.gd`):** `use_reload`/`use_quit`/`use_save`/`use_sitting_home` (231/237/251/258) and `TouchControls.use_clock` (169, 4 definitions): hand-ins a test passes; the README accepts `use_clock`; the same argument applies to the four `main.use_*` (default is the real behaviour, the test hands in a fake), so they are fine under "a dependency the game's own code hands in" only if `main` itself reads the field; its only reader is `main`: SEAM-by-the-letter (the field is read by `_reload_the_scene()` etc.).
**Telemetry / save / run:** `Telemetry.begin_memory_log` (167; 30 uses -- check: `begin_run` may write it, but no word occurrence outside comments), `RunSession.observer` (58), `VisitCounter.should_send` (152), `RunState.save_snapshot` (game_state.gd:175; 15 uses, tests only; confirm the save path), `RunState.penalise_resistance` (145), `RunState.run_rng` (SELF), `RunCalendar.settled_yesterday` (66), `RunStateRegistry.unregistered_in` (84), `GameSave.waits_for` (426), `SaveIndicator.shows_struck` (324), `TitleScreen.mode_name_shown` (284) -> `test_day_loop`, `test_save`, `test_save_wiring`, `test_telemetry`, `test_visit_counter`, `test_run_state`, `test_run_checkpoints`, `test_pause`, `finale_rig`. Mixed: `save_snapshot` and `settled_yesterday` need confirmation that the game truly never calls them (a saved run must write something: if the writer uses another path, the test is asserting the wrong function); `shows_struck`/`mode_name_shown` GAP: read the label/texture drawn; `penalise_resistance` is dead code or a test hook: remove/replace with the director's own penalty call; `waits_for`, `should_send`: internals of the flush table / counter gate; `should_send` already named in `tests-public-seams.md` (platform gate).
**Tuning:** `required_horn_time` (1019), `required_horn_sight` (1024), `sleepiness_gain_calm` (62) -> `crowd_rig`, `test_blackout`, `test_police_car`, `test_fire_truck_body`, `test_tuning_fairness`, `test_meters`, `scenes`. These are functions of the tunables used only to assert fairness contracts (public, balance skill). Decision: leave (a test reading a balance helper is the design).
**Other:** `MarbleBag.rig_spaced` (204; `test_route_bag.gd:139`, the name says it), `Crowd`/`EventScheduler.Planned` items listed in the README as having callers are SELF/DEV (below). `GroundRecipe.reads` (45; `test_ground_layers.gd`), `InteriorMapPlan.inner_floor_approaches` (351; `test_interior.gd`), `Blackout.update/distance_from_station` are called by `Blackout._physics_process` (`update` has a game caller: the blackout suite could use a stroller instead of calling `update(point)`).

### Two weaker tiers (counts, for scope, not for fixing yet)
- **DEV-only readers** (the only `src/` caller is under `src/dev`, the scene-recipe/rig tools): about 55 names including `Crowd.add_recipe_actor` and `recipe_coverage`, `City.set_region_plan`, `ResistanceDirector.read_mark/start_recipe_task/scene_task_errors`, `EventManager.start_recipe`, `EventScheduler.place_at/recipe_placement`, `EventInstance.walk_on_by_hand/solid_part_centres/solid_part_shapes/is_solid`, `WorldMap.is_obstructed`, `VisibleView.visible_share`. The README already treats the recipe runtime as a game caller; the first reading above counts `src/dev` among the game's own classes (the item's own seams `add_recipe_actor`, `place_at`, `read_mark` depend on it).
- **SELF-only readers** (public, but the only caller is the defining file itself): about 250 names, dominated by `Building` (ground-floor and roof family used by `test_ground_floor.gd`: `ground_floor_texture`, `window_texture`, `entrance_door_col`, `extension_rows`, `portico_is_drawn`, `roof_layout`, `fire_escape_*`, 20+ members), `TouchControls` geometry (`heading_to`, `in_dead_zone`, `is_double_tap`, `run_focus_for`, `boundary_x`), `FrameRecorder`/`FrameLedger` (`ledger` alone has 34 test reads), `ParkCordon` (`stretches` 34, `officers` 11, `last_gap` 7, `closed_at`, `trapped`, `relaid`), `EventScheduler.Planned` helpers (`gap_to`, `counts_against_the_line`, `denies`, `reach_touches`, `keeps_its_field_clear`, which the item names as asked "what the scheduler asks"), `ResistanceDirector` (`guard_position`, `guard_spot`, `draw_reachable`, `place_contact`, `nearest_alley_*`), `TitleScreen.hard_mode_*`, `GameSave.has_save/fail/file_data`, `FigureLook`/`PursuerLook` `*_pictures()`, `Sprites.base_transform_of`. By the Build paragraph's letter a same-class caller is a game caller, so these pass; they are internals made public for tests. If the player reads the rule more strictly (a *different* game class calls it), this tier is the main remaining body of work and should be its own sizing pass.

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

1. **Instances through the manager** (`world.instances.append/erase/clear/assign` -> `spawn_extra`/`spawn_warned`/`streaming.add`+`stream_around`/`retire`/`clear`, section 2.1). Files: `test_encounters.gd`, `test_events_chat.gd`, `test_halo.gd`, `test_danger.gd`, `test_drawn_view.gd`, `test_event_parts.gd`, `test_events_pursuit.gd`, `test_day_director.gd`, `test_resistance_arrow.gd` (one line), `finale_rig.gd` (lines 792 and 1884 only; the rest of the finale rig belongs to build 4).
3. **Map tile state through the map's own writers** (section 2.3). Files: `test_turns.gd`, `test_world_passability.gd`, `test_scene_recipe_task.gd`, `test_day13_guard.gd`, `test_route_rig.gd`, `test_spawn_siting.gd`, `routes_closures_rig.gd`, `test_event_views.gd`, `test_resistance_alley_siting.gd`, `test_ground_floor.gd`, `test_still_watch.gd`, `test_scene_recipe_stretch.gd`, `finale_rig.gd` line 1270 (assign to build 4's owner). Disjoint from 1 (except `finale_rig.gd`) and from 4-6.
4. **Escape rigs** (the finale rig's hand-built `Planned`/guard/bands, `RoadblockRig`, `escape_roadblock_rig.gd`, `seal_reach_rig.gd`, the `far_guard_node`/`layer_of`/`attach_nodes` reads): `finale_rig.gd`, `escape_roadblock_rig.gd`, `seal_reach_rig.gd`, `test_barrier_stays.gd`. Takes the finale lines build 1 and 3 leave.
5. **Private-member routes the count misses** (section 1: `Crowd._LINE_BUCKET`, the `_ICON` constants, `Building._Furniture`, the by-name property copies). Files: `crowd_rig.gd` (1522), `test_atlas_leaf_consumers.gd`, `test_atlas_loading.gd`, `test_scene_recipe_activity.gd`, `test_event_redraw.gd`, `test_resistance_placement_kinds.gd`, `test_main.gd` (701), `test_touch.gd` (813). Small; disjoint from all but build 6/7 on `crowd_rig.gd`, `test_resistance_placement_kinds.gd`: run before them or fold.
6. **Zero-reader members: resistance and checkpoint owners** (`ResistanceDirector` arrow/door/trap/mark accessors, `CheckpointController`, `Happenings`, `CordonTape`). Files: `test_resistance_arrow.gd`, `test_resistance_crossing.gd`, `test_resistance_alley_siting.gd`, `test_resistance_replacement.gd`, `test_resistance_traps.gd`, `test_resistance_reach_*.gd` (narrow, relocated, contacts), `test_burnt_door.gd`, `test_day13_guard.gd`, `test_park_cordon.gd`, `test_park_return.gd`, `park_cordon_sweep.gd`, `resistance_rig.gd`. Waits for the board question members-no-reader.
7. **Zero-reader members: events and look owners** (`EventsAhead.walk_siting/sent_pursuer`, behaviour predicates, `RoadblockLook`/`EventLook`/`EventPictures`/`DrawLayer`). Files: `test_event_behaviours.gd`, `test_pursuer_on_foot.gd`, `test_patrol_vanish.gd`, `test_route_bag.gd`, `test_event_manager_fire.gd`, `test_halo_behind.gd`, `test_event_views.gd`, `test_draw_layers.gd`, `test_drawn_view.gd`, `test_no_pop_in.gd`, `test_event_strides.gd`, `test_car_driving.gd`, `test_police_car.gd`, `test_fire_truck_body.gd`. Overlaps build 1 on `test_drawn_view.gd`, build 2 on `test_pursuer_on_foot.gd`/`test_patrol_vanish.gd`/`test_event_behaviours.gd`, and build 5 on `test_event_redraw.gd`; sequence after them.
8. **Zero-reader members: crowd and RouteTree** (`set_focus`, `signals_for_tests`, `lane_key_parts`, `entry_count`, `jolt_swell`, `quietest_pavement`; `branch_for`, `bundles`, `has_a_choice`, `trunk_used_the_spine`, `junction_distances`). Files: `crowd_rig.gd`, `crowd_closures_rig.gd`, `test_car_front.gd`, `test_crowd_contributions.gd`, `test_turns.gd`, `test_recipe_composition.gd`, `test_recipe_crowd.gd`, `test_route_tree.gd`, `test_seals.gd`, `test_power_station.gd`, `test_routes_lattice.gd`. `set_focus` in `test_blackout.gd` goes with build 9. Overlap with build 3 on `test_turns.gd` and 5 on `crowd_rig.gd`.
9. **City/Building/scenery** (`close_ground`, `has_water`, `home_door_is_sealed`, `Building` ground-floor family, the hand-built `Building.new()` fixtures with writes to `powered/day/condition`). Files: `test_scenery_residency.gd`, `test_blackout.gd`, `test_city_decay.gd`, `test_ground_floor.gd`, `test_scenery_animation.gd`, `test_main.gd`. `test_ground_floor.gd` overlaps build 3.
10. **Atlas library accounting** (`is_acquired`, `reference_count`, `is_resident`, `last_load_moment`, `region_name_for`): files `test_atlas_*.gd`, `test_visuals.gd`, `test_interior.gd`. Waits for the board question members-no-reader.
11. **Save/run/telemetry/UI accessors** (`save_snapshot`, `settled_yesterday`, `penalise_resistance`, `shows_struck`, `mode_name_shown`, `waits_for`, `observer`, `should_send`; the `main.use_*` hand-ins): files `test_save.gd`, `test_save_wiring.gd`, `test_day_loop.gd`, `test_run_state.gd`, `test_run_checkpoints.gd`, `test_pause.gd`, `test_telemetry.gd`, `test_visit_counter.gd`, `test_player_presentation.gd`. Disjoint from 1-9; can run in parallel with anything but needs `save_snapshot`'s game caller confirmed first.

Parallel groups: {1+2 as one, 3, 5, 10, 11} are pairwise file-disjoint except as noted; 4 follows 1 and 3; 6, 7, 8 follow 1, 2, 3 and 5; 6, 7 and 10 wait for the board question members-no-reader; the SELF-only and DEV-only tiers are not scheduled (the first two readings).
