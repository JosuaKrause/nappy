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

**A suite that plans one city over many days hands in its mast sites worked out once per city**,
as the game does (`EventWorld.work_out_mast_sites()` on the city as built): today about forty suites
work them out at each `EventScheduler.build_day()` call, on the day's paint, so a test can measure
masts that move between days, which the game never shows (the orchestrator's choice in placement
step 3c, open to overturn). Each module's pass hoists them as it touches the suite.

**The order** is by module, those whose suites build a city before those that boot `main`, one
pull request each, each re-checking its suites with `rg` for `RunCity.`, `.build(`, `city.tscn`,
`booted_main` and `build_day`/`start_day`/`begin_day` first:

1. telemetry: `test_frame_record_wiring` checks that `main` hands the sitting's record to every
   timed system by what each records into the record it was handed, not by reading its hand-in back
   (`city.frame_timing`, `scenery.timing`, `events.timing`, the baby's, the screen edge's and the
   halo's `timing`), since a getter only this suite read would fail
   `tools/check_test_only_members.py`. *Read as:* the sentence above that a var a test reads gets a
   method holds where a game file asks too; where none would, the test reads the public effect;
2. the player and the baby: `test_tutorial_dog`'s case asking where the scheduler places the dog
   (`EventScheduler.build_day`, still on generated maps) moves to the scheduler's suite with the
   events;
3. atlas and scenery: `test_scenery_residency` observes a whole city though `SceneryGround` and
   `SceneryResidency` are handed only what they read (minty-quail-quiet-ibis), so the suite is
   converted to hand them their parts, which ends that suite's own reads of `City.scenery_ground`
   and `City.scenery_ground_source`;
   `test_events_scenery` waits for the events;
4. scene recipes: `test_recipe_structures`, `test_scene_recipe_task`, `test_scene_recipe_stretch`
   and `test_recipe_composition` once `SceneRecipeRuntime.install()` takes a narrow interface for
   what it reads from the city (its map, streets, events and poster walls) instead of the whole
   `City`, so a stand-in can be handed in; `test_recipe_crowd`'s `Crowd.recipe_coverage` check moves
   to a crowd suite;
5. the night group: `test_heat` reads the event
   instance's vars (`age`, `is_leaving`, `is_finished`, `barrier_post`) until they have methods, and
   it and `test_dark_spine` hold the scheduler's and the crowd's answers in a day-planning case each,
   to move to those modules' suites; `test_power_station`'s yard-layer frame-record case belongs in
   `test_frame_record`; `test_masts` waits for the events;
6. the crowd: a crowd suite takes `test_recipe_crowd`'s `Crowd.recipe_coverage` check (entry 4);
   the events' answers still held in the crowd's suites move with the events (entry 7):
   `test_crowd_yields`' four checks of the event instance and manager (stands as, parked, the list
   of moves, placement) and `test_crowd_bodies_on_a_real_day`'s check that a crash's cars stand on
   recorded ground. `test_danger` (the danger vocabulary) and `test_wall_shield`
   (`CityMap.wall_between()`) are not the crowd's suites though each holds a crowd half; their
   events half (in `test_danger`, about twenty tests of events, the baby, the badge and the screen
   edge) moves with the events too;
7. the events (`event_manager*`, `events_*`, `fire_truck_body`, `police_car`, `car_front`,
   `protest`, the day 6, 7 and 13 suites) and the resistance (`resistance_*`, `spent_park`,
   `park_cordon`, `burnt_door`);
8. the routes, city and regions suites that test something other than the city itself;
9. run flow, save and pause: `test_day_loop`'s retry case (the same mark in the same alley from the
   same seed) is the resistance director's placement answer, to move to the resistance suites
   after placement by construction; `test_dev_rig`'s `--spawn` event, closure and door cases read
   event placement, closures and the checkpoint huts, to move with those modules; `test_save`'s
   fence round trip ends in the city map's repaint, to move to a map suite.
