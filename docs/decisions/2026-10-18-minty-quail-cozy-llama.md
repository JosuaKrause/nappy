# minty-quail — The scene recipes' suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin):
`typed-everywhere.md`, one pass per module. This pass is the scene recipes, the scripts the suites write out
included; its search covers `SceneRecipe`, `SceneRecipeRuntime` and `RecipeCityBuilder`.

## What was built

- **Eleven files parse without their file-level opt-out line**, which each loses: `tests/scene_recipe_lifecycle.gd`,
  `test_scene_recipe.gd`, `test_recipe_city_drawing.gd`, `test_recipe_structures.gd` and `test_recipe_roofs.gd`
  (`untyped_declaration`, `unsafe_method_access`), `test_recipe_composition.gd` (all three),
  `test_scene_recipe_activity.gd` (`untyped_declaration`) and `test_scene_recipe_runtime.gd` (`untyped_declaration`,
  `unsafe_method_access`), each one's written-out probe script losing its own line and being typed, and `test_scene_recipe_stretch.gd`,
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

`tools/field_answers.py` on the eleven files, verbatim as it prints at the pass's final head, each named method read
in its class. Of these, the pass converts the one `SceneRecipe` read above; the searched classes' other fields are
left for the reasons above, and every other class's fields for their own modules' passes.

Fields of classes under `src/` that `tests/scene_recipe_lifecycle.gd`, `tests/test_scene_recipe.gd`, `tests/test_scene_recipe_activity.gd`, `tests/test_scene_recipe_runtime.gd`, `tests/test_scene_recipe_stretch.gd`, `tests/test_scene_recipe_stretch_crowd.gd`, `tests/test_scene_recipe_task.gd`, `tests/test_recipe_city_drawing.gd`, `tests/test_recipe_composition.gd`, `tests/test_recipe_structures.gd`, `tests/test_recipe_roofs.gd` read or write through a receiver of that class, each with the method of the class that answers it (`tools/field_answers.py`). `(N calls)` counts a method's calls under `src/` outside its own file, `+N own` those in its own file, `+N untold` the calls of that name whose receiver's class cannot be told.

- `AttemptSpendState`: `city_state` written (`tests/test_scene_recipe_runtime.gd`:493; `tests/test_scene_recipe_stretch.gd`:86; `tests/test_scene_recipe_task.gd`:111): no method
- `Baby`: `excitement` read (`tests/scene_recipe_lifecycle.gd`:155,156,158): `excitement_level()` (7 calls); `sleepiness` read (`tests/scene_recipe_lifecycle.gd`:154,158): `sleepiness_level()` (6 calls)
- `Building`: `covered_ground_cols` read (`tests/test_recipe_city_drawing.gd`:69,70): no method; `district` written (`tests/test_recipe_roofs.gd`:29): `stand_on()` does `district = purpose` (1 call), `draw_as()` does `district = purpose` (1 call); `footprint` written (`tests/test_recipe_roofs.gd`:27): `stand_on()` does `footprint = size` (1 call); `height` written (`tests/test_recipe_roofs.gd`:28): `stand_on()` does `height = wall_height` (1 call), `draw_as()` does `height = wall_height` (1 call); `lot` read (`tests/test_recipe_city_drawing.gd`:66; `tests/test_scene_recipe_stretch.gd`:347,349,385,387): `lot_rect()` (5 calls); `power_station` read (`tests/test_recipe_city_drawing.gd`:41): no method; `roof_drawer` written (`tests/test_recipe_roofs.gd`:31): `equip()` does `roof_drawer = roofs` (1 call); `roof_extension_rows` read (`tests/test_recipe_city_drawing.gd`:46; `tests/test_scene_recipe_stretch.gd`:355,357): no method; `tint_variant` read (`tests/test_scene_recipe_stretch.gd`:395,396,398): no method; `variant` read (`tests/test_scene_recipe_stretch.gd`:392,393): `look_variant()` (2 calls)
- `Building.RoofObject`: `duct_links` read (`tests/test_recipe_roofs.gd`:122,123): no method; `texture_key` read (`tests/test_recipe_roofs.gd`:94,108): no method
- `City`: `crowd` read (`tests/test_recipe_composition.gd`:42,43,44,45,48,54,81,87,88,89; `tests/test_scene_recipe_stretch_crowd.gd`:89): no method; `crowd_view` written (`tests/test_scene_recipe_stretch_crowd.gd`:78): no method; `events` read (`tests/scene_recipe_lifecycle.gd`:257; `tests/test_recipe_structures.gd`:141,175,178,181,183,184,191,192,194,195,197,198; `tests/test_scene_recipe_runtime.gd`:261,390,430,504; `tests/test_scene_recipe_task.gd`:123,128,213,290,291): no method; `map` read (`tests/test_recipe_composition.gd`:34,38,73,76,92; `tests/test_recipe_structures.gd`:29,39,40,48,56,59,60,72,86,121,122,123,124,130,131,139,151,154,174; `tests/test_scene_recipe_runtime.gd`:211,220,221,222,223,232,258,374,386; `tests/test_scene_recipe_stretch.gd`:87,91,93,94,99,100,118,483,490; `tests/test_scene_recipe_stretch_crowd.gd`:82; `tests/test_scene_recipe_task.gd`:141,180,207,237,258,283,334,337,338,341,342,344,345,380,385): no method; `run` read (`tests/test_recipe_composition.gd`:93,99,103; `tests/test_scene_recipe_runtime.gd`:504; `tests/test_scene_recipe_task.gd`:128): no method; `run` written (`tests/test_recipe_structures.gd`:25; `tests/test_scene_recipe_runtime.gd`:207,370,497; `tests/test_scene_recipe_stretch.gd`:82; `tests/test_scene_recipe_task.gd`:114): no method; `scenery` read (`tests/test_recipe_city_drawing.gd`:74): no method; `scenery_frame_locked` written (`tests/test_recipe_city_drawing.gd`:60): no method; `scenery_ground` read (`tests/test_recipe_city_drawing.gd`:75,76): no method; `spawn_siting` read (`tests/test_scene_recipe_runtime.gd`:505; `tests/test_scene_recipe_task.gd`:129): no method
- `CityMap`: `block_plans` read (`tests/test_recipe_composition.gd`:92; `tests/test_recipe_structures.gd`:29; `tests/test_scene_recipe_runtime.gd`:211,374,494; `tests/test_scene_recipe_stretch.gd`:87,287; `tests/test_scene_recipe_stretch_crowd.gd`:82; `tests/test_scene_recipe_task.gd`:112): `plans_by_block()` (9 calls, +1 own); `building_rects` read (`tests/test_scene_recipe.gd`:46,49; `tests/test_scene_recipe_stretch.gd`:306): `building_lots()` (8 calls); `main_road` read (`tests/test_recipe_composition.gd`:73,76): `main_road_corridor()` (18 calls); `network` read (`tests/test_recipe_structures.gd`:40,121; `tests/test_scene_recipe_stretch.gd`:452; `tests/test_scene_recipe_task.gd`:338,345): `street_network()` (19 calls); `recipe_bounds` read (`tests/scene_recipe_lifecycle.gd`:202,258,269,351; `tests/test_recipe_structures.gd`:59): `recipe_window()` (3 calls); `recipe_bounds` written (`tests/test_recipe_structures.gd`:60,72): no method; `stretch_active` read (`tests/test_scene_recipe_stretch.gd`:139,158): no method; `stretch_buildings` read (`tests/test_scene_recipe_stretch.gd`:552): no method; `stretch_cracks` read (`tests/test_scene_recipe_stretch.gd`:557): no method; `tiles` read (`tests/test_scene_recipe.gd`:54,75; `tests/test_scene_recipe_stretch.gd`:202,258): `walk_tiles()` (1 call)
- `ContactPoint`: `is_done` read (`tests/test_scene_recipe_task.gd`:148,159): `is_finished()` (4 calls); `step` read (`tests/test_scene_recipe_task.gd`:148): `task_step()` (4 calls)
- `CrowdField`: `centre` read (`tests/test_scene_recipe_stretch.gd`:440): `centre_point()` (4 calls); `centre` written (`tests/test_scene_recipe_stretch.gd`:439): `centre_on()` does `centre = at` (3 calls), `use_stretch()` does `centre = _looking_at` (1 call); `map` read (`tests/test_scene_recipe_stretch_crowd.gd`:167,168): no method; `uniform_walkers` read (`tests/test_recipe_composition.gd`:88): `weighs_walkers_uniformly()` (1 call)
- `DaySpec`: `length` read (`tests/test_recipe_structures.gd`:188,189): `seconds_on_the_clock()` (4 calls)
- `EventDef`: `flock_size` read (`tests/test_scene_recipe_runtime.gd`:185): no method; of it alone, `is_a_flock()` returns `flock_size > 0` (1 call); `id` read (`tests/test_scene_recipe_task.gd`:214): no method; `inner_radius` read (`tests/test_scene_recipe_task.gd`:218): `core_within()` (1 call); `offscreen_notice` read (`tests/test_scene_recipe_runtime.gd`:218): no method; `pursuit` read (`tests/test_scene_recipe_runtime.gd`:185): no method
- `EventInstance`: `def` read (`tests/test_recipe_structures.gd`:142; `tests/test_scene_recipe_task.gd`:214): `row()` (2 calls); `def.id` read (`tests/test_recipe_structures.gd`:142; `tests/test_scene_recipe_task.gd`:214): `row_id()` (11 calls); `held_by_hand` read (`tests/test_scene_recipe_runtime.gd`:247,250,255): no method; `is_finished` read (`tests/test_scene_recipe_task.gd`:214): `is_gone()` (20 calls, +1 own); `is_leaving` read (`tests/test_scene_recipe_runtime.gd`:243): `is_on_its_way_out()` (14 calls, +1 own)
- `EventManager`: `ahead` read (`tests/test_recipe_structures.gd`:178,181,191,192): no method; `warnings` read (`tests/test_recipe_structures.gd`:198): no method
- `EventPlan`: `def` read (`tests/test_recipe_structures.gd`:105; `tests/test_scene_recipe_runtime.gd`:392): `row()` (27 calls); `def.id` read (`tests/test_recipe_structures.gd`:105): `row_id()` (6 calls); `facing` read (`tests/test_recipe_structures.gd`:106): no method; `position` read (`tests/scene_recipe_lifecycle.gd`:258; `tests/test_recipe_structures.gd`:105,146; `tests/test_scene_recipe_stretch.gd`:523): `placed_at()` (28 calls); of it alone, `is_placed()` returns `position != Vector2.INF` (31 calls, +4 own)
- `EventsAhead`: `holds_the_home_streets` read (`tests/test_recipe_structures.gd`:178,191): no method; `sends_poster_pursuits` read (`tests/test_recipe_structures.gd`:181,192): no method
- `LaneMover`: `kind` read through `CrowdAgent` (`tests/test_recipe_composition.gd`:55): on its view, `lane().kind()` (8 calls)
- `MoveProposal`: `from` read (`tests/test_scene_recipe_runtime.gd`:259): `stands_at()` (8 calls); `to` read (`tests/test_scene_recipe_runtime.gd`:259): `steps_to()` (14 calls)
- `Prop`: `kind` read (`tests/test_recipe_composition.gd`:33; `tests/test_recipe_structures.gd`:213): no method
- `RegionPlanner.RegionPlan`: `door_bodies` read (`tests/test_recipe_structures.gd`:92,99,101,102,103; `tests/test_scene_recipe_stretch.gd`:519): no method; `doors` read (`tests/test_recipe_structures.gd`:87,88,91,98; `tests/test_scene_recipe_stretch.gd`:517): no method; `gates` read (`tests/test_recipe_structures.gd`:99): no method
- `ResistanceRunState`: `completed_steps` read (`tests/test_scene_recipe_task.gd`:154): no method; `sabotage_done` written (`tests/scene_recipe_lifecycle.gd`:230): `reset()` does `sabotage_done = false` (3 calls), `give_back()` does `sabotage_done = _dawn_sabotage_done` (1 call), `restore()` does `sabotage_done = bool(data["…"])` (3 calls)
- `ResistanceSteps.Step`: `index` read (`tests/test_scene_recipe_task.gd`:154): no method; `is_pickup` read (`tests/test_scene_recipe_task.gd`:148,151,160,271,288): no method; `task_event_id` read (`tests/test_scene_recipe_task.gd`:160): no method
- `RigLock`: `locked_out` read (`tests/scene_recipe_lifecycle.gd`:189): no method
- `RoadClosure`: `segment` read (`tests/test_scene_recipe.gd`:143): no method
- `RunHeader`: `day` read (`tests/scene_recipe_lifecycle.gd`:123,124,133,226,234; `tests/test_recipe_composition.gd`:103; `tests/test_recipe_structures.gd`:38,46,55,68,86,96,115,187; `tests/test_scene_recipe_runtime.gd`:374,375,385,389; `tests/test_scene_recipe_task.gd`:382,388): no method; `day` written (`tests/test_recipe_structures.gd`:15; `tests/test_scene_recipe_runtime.gd`:205,368,491; `tests/test_scene_recipe_stretch.gd`:77,488; `tests/test_scene_recipe_task.gd`:109): `reset()` does `day = 1` (3 calls), `restore()` does `day = int(data["…"])` (3 calls); `ending` read (`tests/scene_recipe_lifecycle.gd`:233): no method; `run_seed` read (`tests/scene_recipe_lifecycle.gd`:134): no method
- `RunState`: `attempt_spend` read (`tests/test_scene_recipe_runtime.gd`:493; `tests/test_scene_recipe_stretch.gd`:86; `tests/test_scene_recipe_task.gd`:111): no method; `calendar` read (`tests/test_recipe_composition.gd`:93; `tests/test_recipe_structures.gd`:30; `tests/test_scene_recipe_runtime.gd`:212,375,500; `tests/test_scene_recipe_stretch.gd`:88; `tests/test_scene_recipe_stretch_crowd.gd`:83,90; `tests/test_scene_recipe_task.gd`:117,143,182,210,242,247,264,284): no method; `header` read (`tests/scene_recipe_lifecycle.gd`:123,124,133,134,226,233,234; `tests/test_recipe_composition.gd`:103; `tests/test_recipe_structures.gd`:15,38,46,55,68,86,96,115,187; `tests/test_scene_recipe_runtime.gd`:205,368,374,375,385,389,491; `tests/test_scene_recipe_stretch.gd`:77,488; `tests/test_scene_recipe_task.gd`:109,382,388): no method; `resistance` read (`tests/scene_recipe_lifecycle.gd`:230; `tests/test_scene_recipe_task.gd`:154): no method
- `SceneRecipeRuntime`: `data` read (`tests/scene_recipe_lifecycle.gd`:121,146,148,207): no method; of it alone, `lessons_learned()` returns `bool(data.get("…", {}).get("…", false))` (1 call); `manifest` read (`tests/scene_recipe_lifecycle.gd`:104,114,116,133,134,188; `tests/test_scene_recipe_runtime.gd`:434,448,458): no method; `named` read (`tests/scene_recipe_lifecycle.gd`:131,244,246; `tests/test_scene_recipe_runtime.gd`:238,419,423,433): no method; `tick` read (`tests/scene_recipe_lifecycle.gd`:150,158,185,188; `tests/test_scene_recipe_runtime.gd`:423,433,448): no method
- `SceneryGround`: `chunks` read (`tests/test_recipe_city_drawing.gd`:75): no method; `pending` read (`tests/test_recipe_city_drawing.gd`:76): no method
- `SealPlanner.Candidate`: `id` read (`tests/test_recipe_structures.gd`:118): no method
- `SealPlanner.SitedSeal`: `bodies` read (`tests/test_recipe_structures.gd`:145): no method
- `StreetNetwork.Segment`: `a` read (`tests/test_scene_recipe_stretch.gd`:458): no method; `b` read (`tests/test_scene_recipe_stretch.gd`:458): no method; `horizontal` read (`tests/test_recipe_structures.gd`:162): no method
- `StreetTrees.Planted`: `position` read (`tests/test_recipe_structures.gd`:51): no method; `tile` read (`tests/test_recipe_composition.gd`:25; `tests/test_recipe_structures.gd`:205; `tests/test_scene_recipe_stretch.gd`:320): no method
- `WalkField`: `done` read (`tests/test_scene_recipe_stretch.gd`:257): `is_done()` (3 calls)
- `WorldMap`: `moves` read through `CityMap` (`tests/test_scene_recipe_runtime.gd`:258): no method; `size` read through `CityMap` (`tests/test_scene_recipe_stretch.gd`:171,172,205,206,218,219,236,237): `size_in_tiles()` (66 calls)
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

**The two `PROBE` scripts' reads.** `tools/field_answers.py` does not read inside a string, so each probe's text was copied to a scratch `.gd` file inside the checkout (deleted after) and the tool run on both; the line numbers are lines of the probe's text, "the runtime suite's PROBE" being `tests/test_scene_recipe_runtime.gd`'s and "the activity suite's PROBE" `tests/test_scene_recipe_activity.gd`'s. What they read or write that the list above lacks, or add to it:

- `Building`: `lot` read (`the activity suite's PROBE`:59): `lot_rect()` (5 calls)
- `City`: `crowd` read (`the activity suite's PROBE`:24): no method; `events` read (`the activity suite's PROBE`:37,43,45,50,65,70): no method; `map` read (`the activity suite's PROBE`:77,98; `the runtime suite's PROBE`:107): no method; `run` written (`the runtime suite's PROBE`:103): no method
- `CityMap`: `block_plans` read (`the runtime suite's PROBE`:107): `plans_by_block()` (9 calls, +1 own)
- `EventPlan`: `def` read (`the activity suite's PROBE`:66,71,85): `row()` (27 calls); `def.id` read (`the activity suite's PROBE`:66,71,85): `row_id()` (6 calls); `facing` read (`the activity suite's PROBE`:87): no method; `position` read (`the activity suite's PROBE`:52,66,71,72,85): `placed_at()` (28 calls); of it alone, `is_placed()` returns `position != Vector2.INF` (31 calls, +4 own)
- `PosterState`: `cells` read (`the activity suite's PROBE`:78): no method
- `RegionPlanner.RegionPlan`: `door_bodies` read (`the activity suite's PROBE`:84): no method
- `RunConfig`: `active_args` read (`the activity suite's PROBE`:8): `dev_flag_words()` (1 call); `is_rig` read (`the runtime suite's PROBE`:37): no method; `recipe_path` read (`the activity suite's PROBE`:8): no method; of it alone, `warms_the_canvas_shaders()` returns `recipe_path == "…"` (1 call); `recipe_scripted` read (`the runtime suite's PROBE`:37): no method
- `RunHeader`: `day` read (`the activity suite's PROBE`:20): no method
- `RunState`: `calendar` read (`the runtime suite's PROBE`:108): no method; `header` read (`the activity suite's PROBE`:20): no method; `posters` read (`the activity suite's PROBE`:78): no method
- `SceneRecipeRuntime`: `manifest` read (`the runtime suite's PROBE`:17,20): no method; `named` read (`the runtime suite's PROBE`:72): no method
- `Sitting`: `run` read (`the activity suite's PROBE`:105): no method
- Receiver's class not told: `the activity suite's PROBE:78` `run.posters.cells[tile].kind`

Each is left: a probe runs in a child process and is typed like the suites, and these classes belong to other passes (`RunConfig`'s `active_args` is answered by `dev_flag_words()`, `RunConfig` not being in this pass's search); `SceneRecipeRuntime`'s `manifest` and `named` are left for the reasons given for the list above.

## Verified

At test parity: the eleven files' suites and the other scene recipe and recipe suites pass, the two written-out
probe scripts parse; the typing census and the test-only-member check pass.
