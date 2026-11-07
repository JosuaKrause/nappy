# Each suite tests its one module, with everything else mocked

**The ask.** "no test should build a real object that it doesn't test (it should mock it) and test
modules should only test the module they are named for. only combine testing responsibilities if
there is a good reason", "this should result in test becoming much faster, too" (inbox #1159 in gray-dolphin). On the
board's test-isolation-plan, "yes" to its fourth step: convert and split the tests module by module,
with the suite times before and after (inbox #1159 in gray-dolphin). "the city should never be built for tests that
don't test the actual city" (inbox #1156 in gray-dolphin).

**Read as:** the rules are writing-tests' (a hard rule with exceptions only for a stated reason; a
realistic mock made in two steps; plain values built as they are; a check of another object's
answers moved to that object's suite). This item is the pass that brings the existing suites to
them, one module at a time, once the hand-ins (`city-hand-ins.md`) give each class something to hand
a fake to. Each module's pull request says each suite's time before and after.

**A test reads its subject only through methods** too: on the board's tests-read-fields, whether a
test counts as another object under "fields are not API", "yes" (inbox #1182 in gray-dolphin). A var a test reads
gets a method, and suites move as a pull request touches them.

**The order** is by module, those whose suites build a city before those that boot `main`, one
pull request each, each re-checking its suites with `rg` for `RunCity.`, `.build(`, `city.tscn`,
`booted_main` and `build_day`/`start_day`/`begin_day` first:

1. telemetry (`test_telemetry`, `test_frame_record`);
2. the player and the baby (`player_presentation`, `baby_world`, `move_poses`, `camera_start`,
   `pelican`, `loose_dog_arrives`, `tutorial_dog`);
3. atlas and scenery (`atlas_*`, `scenery_*`, `ground_floor`, `building_shadows`,
   `destination_drawing`, `debug_layers`);
4. scene recipes: `test_recipe_structures`, `test_scene_recipe_task`, `test_scene_recipe_stretch`
   and `test_recipe_composition` once `SceneRecipeRuntime.install()` takes a narrow interface for
   what it reads from the city (its map, streets, events and poster walls) instead of the whole
   `City`, so a stand-in can be handed in; `test_recipe_crowd`'s `Crowd.recipe_coverage` check moves
   to a crowd suite;
5. the night group (`blackout`, `power_station`, `heat`, `bollards`, and `masts` once the events
   allow);
6. the crowd (`crowd_bodies`, `crowd_contributions`, `crowd_yields`, `danger`, `wall_shield`);
7. the events (`event_manager*`, `events_*`, `fire_truck_body`, `police_car`, `car_front`,
   `protest`, the day 6, 7 and 13 suites) and the resistance (`resistance_*`, `spent_park`,
   `park_cordon`, `burnt_door`);
8. the routes, city and regions suites that test something other than the city itself;
9. run flow, save and pause (`run_flow`, `run_config`, `run_checkpoints`, `save`, `save_wiring`,
   `boot_handing`, `pause`, `observers`, `main`, `day_loop`, `dev_rig`, `park_return`), which
   boot the real run and are combined by composition, each with its reason stated.
