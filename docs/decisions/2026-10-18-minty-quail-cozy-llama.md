# minty-quail — The scene recipes' suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin):
`typed-everywhere.md`, one pass per module. This pass is the scene recipes, the scripts the suites write out
included; its search covers `SceneRecipe`, `SceneRecipeRuntime` and `RecipeCityBuilder`.

## What was built

- **Eleven files parse without their file-level opt-out line**, which each loses: `tests/scene_recipe_lifecycle.gd`,
  `test_scene_recipe.gd`, `test_recipe_city_drawing.gd`, `test_recipe_structures.gd` and `test_recipe_roofs.gd`
  (`untyped_declaration`, `unsafe_method_access`), `test_recipe_composition.gd` (all three),
  `test_scene_recipe_activity.gd` and `test_scene_recipe_runtime.gd` (`untyped_declaration`, and each one's
  written-out probe script loses its own line and is typed), and `test_scene_recipe_stretch.gd`,
  `test_scene_recipe_stretch_crowd.gd` and `test_scene_recipe_task.gd` (`unsafe_method_access`). The rig keeps every
  function's name, argument order and answer; the three `test_scene_recipe_lifecycle_*` suites, the only files that
  preload it, pass.
- **Typing**: a builder's or loader's answer is a `Dictionary`, read through a typed helper or local; loops take
  their narrowest element type; `test_scene_recipe_runtime`'s task scene dictionary is an inner class `TaskScene`.
- **One read converted**: `recipe.built.map` in the lifecycle rig asks `recipe.city_map()`, which `RunFlow` calls;
  `rg -P '\.built\b(?!\()' src tests tools` comes back empty. Left in the search: `SceneRecipeRuntime`'s `data`,
  `manifest`, `named` and `tick`, which no method the game calls answers (`lessons_learned()` answers one key of
  `data`; `subject_of()` answers a live node, not `named`'s membership, and no game caller outside the runtime
  calls it). No check deleted or moved; nothing under `src/` or `tools/test_only_members.txt` changed.

## Fields read and written, by class

`tools/field_answers.py --counts` on the eleven files, as it prints them at 90226edd7, each named method read in
its class. Of these, the pass converts the one `SceneRecipe` read above; the searched classes' other fields are
left for the reasons above, and every other class's fields for their own modules' passes.

- `AttemptSpendState`: `city_state` written (`tests/test_scene_recipe_runtime.gd` on 1 line, `tests/test_scene_recipe_stretch.gd` on 1 line, `tests/test_scene_recipe_task.gd` on 1 line): no method
- `Baby`: `excitement` read (`tests/scene_recipe_lifecycle.gd` on 3 lines): `excitement_level()` (7 calls); `sleepiness` read (`tests/scene_recipe_lifecycle.gd` on 2 lines): `sleepiness_level()` (6 calls)
- `Building`: `covered_ground_cols` read (`tests/test_recipe_city_drawing.gd` on 2 lines): no method; `district` written (`tests/test_recipe_roofs.gd` on 1 line): `stand_on()` does `district = purpose` (1 call), `draw_as()` does `district = purpose` (1 call); `footprint` written (`tests/test_recipe_roofs.gd` on 1 line): `stand_on()` does `footprint = size` (1 call); `height` written (`tests/test_recipe_roofs.gd` on 1 line): `stand_on()` does `height = wall_height` (1 call), `draw_as()` does `height = wall_height` (1 call); `lot` read (`tests/test_recipe_city_drawing.gd` on 1 line, `tests/test_scene_recipe_stretch.gd` on 4 lines): `lot_rect()` (5 calls); `power_station` read (`tests/test_recipe_city_drawing.gd` on 1 line): no method; `roof_drawer` written (`tests/test_recipe_roofs.gd` on 1 line): `equip()` does `roof_drawer = roofs` (1 call); `roof_extension_rows` read (`tests/test_recipe_city_drawing.gd` on 1 line, `tests/test_scene_recipe_stretch.gd` on 2 lines): no method; `tint_variant` read (`tests/test_scene_recipe_stretch.gd` on 3 lines): no method; `variant` read (`tests/test_scene_recipe_stretch.gd` on 2 lines): `look_variant()` (2 calls)
- `Building.RoofObject`: `duct_links` read (`tests/test_recipe_roofs.gd` on 2 lines): no method; `texture_key` read (`tests/test_recipe_roofs.gd` on 2 lines): no method
- `City`: `crowd` read (`tests/test_recipe_composition.gd` on 10 lines, `tests/test_scene_recipe_stretch_crowd.gd` on 1 line): no method; `crowd_view` written (`tests/test_scene_recipe_stretch_crowd.gd` on 1 line): no method; `events` read (`tests/scene_recipe_lifecycle.gd` on 1 line, `tests/test_recipe_structures.gd` on 12 lines, `tests/test_scene_recipe_runtime.gd` on 4 lines, `tests/test_scene_recipe_task.gd` on 5 lines): no method; `map` read (`tests/test_recipe_composition.gd` on 5 lines, `tests/test_recipe_structures.gd` on 19 lines, `tests/test_scene_recipe_runtime.gd` on 9 lines, `tests/test_scene_recipe_stretch.gd` on 9 lines, `tests/test_scene_recipe_stretch_crowd.gd` on 1 line, `tests/test_scene_recipe_task.gd` on 15 lines): no method; `run` read (`tests/test_recipe_composition.gd` on 3 lines, `tests/test_scene_recipe_runtime.gd` on 1 line, `tests/test_scene_recipe_task.gd` on 1 line): no method; `run` written (`tests/test_recipe_structures.gd` on 1 line, `tests/test_scene_recipe_runtime.gd` on 3 lines, `tests/test_scene_recipe_stretch.gd` on 1 line, `tests/test_scene_recipe_task.gd` on 1 line): no method; `scenery` read (`tests/test_recipe_city_drawing.gd` on 1 line): no method; `scenery_frame_locked` written (`tests/test_recipe_city_drawing.gd` on 1 line): no method; `scenery_ground` read (`tests/test_recipe_city_drawing.gd` on 2 lines): no method; `spawn_siting` read (`tests/test_scene_recipe_runtime.gd` on 1 line, `tests/test_scene_recipe_task.gd` on 1 line): no method
- `CityMap`: `block_plans` read (`tests/test_recipe_composition.gd` on 1 line, `tests/test_recipe_structures.gd` on 1 line, `tests/test_scene_recipe_runtime.gd` on 3 lines, `tests/test_scene_recipe_stretch.gd` on 2 lines, `tests/test_scene_recipe_stretch_crowd.gd` on 1 line, `tests/test_scene_recipe_task.gd` on 1 line): `plans_by_block()` (9 calls, +1 own); `building_rects` read (`tests/test_scene_recipe.gd` on 2 lines, `tests/test_scene_recipe_stretch.gd` on 1 line): `building_lots()` (8 calls); `main_road` read (`tests/test_recipe_composition.gd` on 2 lines): `main_road_corridor()` (18 calls); `network` read (`tests/test_recipe_structures.gd` on 2 lines, `tests/test_scene_recipe_stretch.gd` on 1 line, `tests/test_scene_recipe_task.gd` on 2 lines): `street_network()` (19 calls); `recipe_bounds` read (`tests/scene_recipe_lifecycle.gd` on 4 lines, `tests/test_recipe_structures.gd` on 1 line): `recipe_window()` (3 calls); `recipe_bounds` written (`tests/test_recipe_structures.gd` on 2 lines): no method; `stretch_active` read (`tests/test_scene_recipe_stretch.gd` on 2 lines): no method; `stretch_buildings` read (`tests/test_scene_recipe_stretch.gd` on 1 line): no method; `stretch_cracks` read (`tests/test_scene_recipe_stretch.gd` on 1 line): no method; `tiles` read (`tests/test_scene_recipe.gd` on 2 lines, `tests/test_scene_recipe_stretch.gd` on 2 lines): `walk_tiles()` (1 call)
- `ContactPoint`: `is_done` read (`tests/test_scene_recipe_task.gd` on 2 lines): `is_finished()` (4 calls); `step` read (`tests/test_scene_recipe_task.gd` on 1 line): `task_step()` (4 calls)
- `CrowdField`: `centre` read (`tests/test_scene_recipe_stretch.gd` on 1 line): `centre_point()` (4 calls); `centre` written (`tests/test_scene_recipe_stretch.gd` on 1 line): `centre_on()` does `centre = at` (3 calls), `use_stretch()` does `centre = _looking_at` (1 call); `map` read (`tests/test_scene_recipe_stretch_crowd.gd` on 2 lines): no method; `uniform_walkers` read (`tests/test_recipe_composition.gd` on 1 line): `weighs_walkers_uniformly()` (1 call)
- `DaySpec`: `length` read (`tests/test_recipe_structures.gd` on 2 lines): `seconds_on_the_clock()` (4 calls)
- `EventDef`: `flock_size` read (`tests/test_scene_recipe_runtime.gd` on 1 line): no method; of it alone, `is_a_flock()` returns `flock_size > 0` (1 call); `id` read (`tests/test_scene_recipe_task.gd` on 1 line): no method; `inner_radius` read (`tests/test_scene_recipe_task.gd` on 1 line): `core_within()` (1 call); `offscreen_notice` read (`tests/test_scene_recipe_runtime.gd` on 1 line): no method; `pursuit` read (`tests/test_scene_recipe_runtime.gd` on 1 line): no method
- `EventInstance`: `def` read (`tests/test_recipe_structures.gd` on 1 line, `tests/test_scene_recipe_task.gd` on 1 line): `row()` (2 calls); `def.id` read (`tests/test_recipe_structures.gd` on 1 line, `tests/test_scene_recipe_task.gd` on 1 line): `row_id()` (11 calls); `held_by_hand` read (`tests/test_scene_recipe_runtime.gd` on 3 lines): no method; `is_finished` read (`tests/test_scene_recipe_task.gd` on 1 line): `is_gone()` (20 calls, +1 own); `is_leaving` read (`tests/test_scene_recipe_runtime.gd` on 1 line): `is_on_its_way_out()` (14 calls, +1 own)
- `EventManager`: `ahead` read (`tests/test_recipe_structures.gd` on 4 lines): no method; `warnings` read (`tests/test_recipe_structures.gd` on 1 line): no method
- `EventPlan`: `def` read (`tests/test_recipe_structures.gd` on 1 line, `tests/test_scene_recipe_runtime.gd` on 1 line): `row()` (27 calls); `def.id` read (`tests/test_recipe_structures.gd` on 1 line): `row_id()` (6 calls); `facing` read (`tests/test_recipe_structures.gd` on 1 line): no method; `position` read (`tests/scene_recipe_lifecycle.gd` on 1 line, `tests/test_recipe_structures.gd` on 2 lines, `tests/test_scene_recipe_stretch.gd` on 1 line): `placed_at()` (28 calls); of it alone, `is_placed()` returns `position != Vector2.INF` (31 calls, +4 own)
- `EventsAhead`: `holds_the_home_streets` read (`tests/test_recipe_structures.gd` on 2 lines): no method; `sends_poster_pursuits` read (`tests/test_recipe_structures.gd` on 2 lines): no method
- `LaneMover`: `kind` read through `CrowdAgent` (`tests/test_recipe_composition.gd` on 1 line): on its view, `lane().kind()` (8 calls)
- `MoveProposal`: `from` read (`tests/test_scene_recipe_runtime.gd` on 1 line): `stands_at()` (8 calls); `to` read (`tests/test_scene_recipe_runtime.gd` on 1 line): `steps_to()` (14 calls)
- `Prop`: `kind` read (`tests/test_recipe_composition.gd` on 1 line, `tests/test_recipe_structures.gd` on 1 line): no method
- `RegionPlanner.RegionPlan`: `door_bodies` read (`tests/test_recipe_structures.gd` on 5 lines, `tests/test_scene_recipe_stretch.gd` on 1 line): no method; `doors` read (`tests/test_recipe_structures.gd` on 4 lines, `tests/test_scene_recipe_stretch.gd` on 1 line): no method; `gates` read (`tests/test_recipe_structures.gd` on 1 line): no method
- `ResistanceRunState`: `completed_steps` read (`tests/test_scene_recipe_task.gd` on 1 line): no method; `sabotage_done` written (`tests/scene_recipe_lifecycle.gd` on 1 line): `reset()` does `sabotage_done = false` (3 calls), `give_back()` does `sabotage_done = _dawn_sabotage_done` (1 call), `restore()` does `sabotage_done = bool(data["…"])` (3 calls)
- `ResistanceSteps.Step`: `index` read (`tests/test_scene_recipe_task.gd` on 1 line): no method; `is_pickup` read (`tests/test_scene_recipe_task.gd` on 5 lines): no method; `task_event_id` read (`tests/test_scene_recipe_task.gd` on 1 line): no method
- `RigLock`: `locked_out` read (`tests/scene_recipe_lifecycle.gd` on 1 line): no method
- `RoadClosure`: `segment` read (`tests/test_scene_recipe.gd` on 1 line): no method
- `RunHeader`: `day` read (`tests/scene_recipe_lifecycle.gd` on 5 lines, `tests/test_recipe_composition.gd` on 1 line, `tests/test_recipe_structures.gd` on 8 lines, `tests/test_scene_recipe_runtime.gd` on 4 lines, `tests/test_scene_recipe_task.gd` on 2 lines): no method; `day` written (`tests/test_recipe_structures.gd` on 1 line, `tests/test_scene_recipe_runtime.gd` on 3 lines, `tests/test_scene_recipe_stretch.gd` on 2 lines, `tests/test_scene_recipe_task.gd` on 1 line): `reset()` does `day = 1` (3 calls), `restore()` does `day = int(data["…"])` (3 calls); `ending` read (`tests/scene_recipe_lifecycle.gd` on 1 line): no method; `run_seed` read (`tests/scene_recipe_lifecycle.gd` on 1 line): no method
- `RunState`: `attempt_spend` read (`tests/test_scene_recipe_runtime.gd` on 1 line, `tests/test_scene_recipe_stretch.gd` on 1 line, `tests/test_scene_recipe_task.gd` on 1 line): no method; `calendar` read (`tests/test_recipe_composition.gd` on 1 line, `tests/test_recipe_structures.gd` on 1 line, `tests/test_scene_recipe_runtime.gd` on 3 lines, `tests/test_scene_recipe_stretch.gd` on 1 line, `tests/test_scene_recipe_stretch_crowd.gd` on 2 lines, `tests/test_scene_recipe_task.gd` on 8 lines): no method; `header` read (`tests/scene_recipe_lifecycle.gd` on 7 lines, `tests/test_recipe_composition.gd` on 1 line, `tests/test_recipe_structures.gd` on 9 lines, `tests/test_scene_recipe_runtime.gd` on 7 lines, `tests/test_scene_recipe_stretch.gd` on 2 lines, `tests/test_scene_recipe_task.gd` on 3 lines): no method; `resistance` read (`tests/scene_recipe_lifecycle.gd` on 1 line, `tests/test_scene_recipe_task.gd` on 1 line): no method
- `SceneRecipeRuntime`: `data` read (`tests/scene_recipe_lifecycle.gd` on 4 lines): no method; of it alone, `lessons_learned()` returns `bool(data.get("…", {}).get("…", false))` (1 call); `manifest` read (`tests/scene_recipe_lifecycle.gd` on 6 lines, `tests/test_scene_recipe_runtime.gd` on 3 lines): no method; `named` read (`tests/scene_recipe_lifecycle.gd` on 3 lines, `tests/test_scene_recipe_runtime.gd` on 4 lines): no method; `tick` read (`tests/scene_recipe_lifecycle.gd` on 4 lines, `tests/test_scene_recipe_runtime.gd` on 3 lines): no method
- `SceneryGround`: `chunks` read (`tests/test_recipe_city_drawing.gd` on 1 line): no method; `pending` read (`tests/test_recipe_city_drawing.gd` on 1 line): no method
- `SealPlanner.Candidate`: `id` read (`tests/test_recipe_structures.gd` on 1 line): no method
- `SealPlanner.SitedSeal`: `bodies` read (`tests/test_recipe_structures.gd` on 1 line): no method
- `StreetNetwork.Segment`: `a` read (`tests/test_scene_recipe_stretch.gd` on 1 line): no method; `b` read (`tests/test_scene_recipe_stretch.gd` on 1 line): no method; `horizontal` read (`tests/test_recipe_structures.gd` on 1 line): no method
- `StreetTrees.Planted`: `position` read (`tests/test_recipe_structures.gd` on 1 line): no method; `tile` read (`tests/test_recipe_composition.gd` on 1 line, `tests/test_recipe_structures.gd` on 1 line, `tests/test_scene_recipe_stretch.gd` on 1 line): no method
- `WalkField`: `done` read (`tests/test_scene_recipe_stretch.gd` on 1 line): `is_done()` (3 calls)
- `WorldMap`: `moves` read through `CityMap` (`tests/test_scene_recipe_runtime.gd` on 1 line): no method; `size` read through `CityMap` (`tests/test_scene_recipe_stretch.gd` on 8 lines): `size_in_tiles()` (66 calls)
- Receiver's class not told: `tests/scene_recipe_lifecycle.gd:71` `later_day.setup.day`
- Receiver's class not told: `tests/test_recipe_composition.gd:111` `invalid.city.tree_moves[0].to`
- Receiver's class not told: `tests/test_scene_recipe.gd:26` `pinned.city.dead_ends`
- Receiver's class not told: `tests/test_scene_recipe.gd:27` `pinned.city.power_station`
- Receiver's class not told: `tests/test_scene_recipe.gd:34` `layout_pin.city.layouts`
- Receiver's class not told: `tests/test_scene_recipe.gd:75` `repeated.map.tiles`
- Receiver's class not told: `tests/test_scene_recipe.gd:91` `input.city.power_station`
- Receiver's class not told: `tests/test_scene_recipe.gd:95` `accepted.map.power_station_door_key`
- Receiver's class not told: `tests/test_scene_recipe.gd:97` `input.city.power_station`
- Receiver's class not told: `tests/test_scene_recipe.gd:100` `input.city.power_station`
- Receiver's class not told: `tests/test_scene_recipe.gd:104` `accepted.map.power_station`
- Receiver's class not told: `tests/test_scene_recipe.gd:145` `input.setup.day`
- Receiver's class not told: `tests/test_scene_recipe.gd:149` `input.city.closures[0].kind`
- Receiver's class not told: `tests/test_scene_recipe.gd:163` `built.anchors.start`
- Receiver's class not told: `tests/test_scene_recipe_runtime.gd:300` `mixed.setup.actors[0].kind`
- Receiver's class not told: `tests/test_scene_recipe_runtime.gd:302` `mixed.setup.actors[0].kind`
- Receiver's class not told: `tests/test_scene_recipe_runtime.gd:303` `mixed.setup.background.uniform_walkers`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:143` `edited.stretch.tiles`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:145` `edited.stretch.tiles`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:163` `data.stretch.tiles`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:164` `data.stretch.tiles`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:265` `changed_seed.city.layouts`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:267` `independent.map.tiles`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:267` `original.map.tiles`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:270` `malformed.context.tiles`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:274` `drifted.stretch.tiles`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:309` `tree.stretch.tiles`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:321` `shown[0].tile`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:324` `twice.stretch.tiles`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:407` `walled.stretch.tiles`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:497` `drafted.stretch.tiles`
- Receiver's class not told: `tests/test_scene_recipe_stretch.gd:498` `drafted.stretch.tiles`
- Receiver's class not told: `tests/test_scene_recipe_stretch_crowd.gd:29` `data.playback.duration`
- Receiver's class not told: `tests/test_scene_recipe_stretch_crowd.gd:173` `body.agent.name`

## Verified

At test parity: the eleven files' suites and the other scene recipe and recipe suites pass, the two written-out
probe scripts parse; the typing census and the test-only-member check pass.
