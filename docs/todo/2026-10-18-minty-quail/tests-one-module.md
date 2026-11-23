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
leave them to the shared helper's default (`tests/game_dawn.gd`), which works them out at each planned
dawn, on the day's paint, so a test can measure
masts that move between days, which the game never shows (the orchestrator's choice in placement
step 3c, open to overturn). Each module's pass hoists them as it touches the suite.

**The order** is by module, those whose suites build a city before those that boot `main`, one
pull request each, each re-checking its suites with `rg` for `RunCity.`, `.build(`, `city.tscn`,
`booted_main` and `build_day`/`start_day`/`begin_day` first. Every entry has had its
pass (the records 2026-10-18-minty-quail-teal-toad, -tall-lynx, -spotted-owl, -quiet-swan,
-curly-hawk, -merry-goose and -dotted-pelican; for entry 5, row 5 of `event-interface.md`, the records
2026-10-18-minty-quail-gentle-bison, -pebbly-plover, -grassy-quail, -amber-elk, -sunny-sparrow, -mossy-panda,
-speckled-hare, -jolly-ibis, -tawny-bunny, -curly-hedgehog and -spry-moose), and what each lists is what is left of it:

1. the player and the baby: `test_tutorial_dog`'s case asking where the scheduler places the dog
   (`EventScheduler.build_day`, still on generated maps) moves to the scheduler's suite with the
   events;
2. scene recipes: `test_recipe_structures`, `test_scene_recipe_task`, `test_scene_recipe_stretch`
   and `test_recipe_composition` once `SceneRecipeRuntime.install()` takes a narrow interface for
   what it reads from the city (its map, streets, events and poster walls) instead of the whole
   `City`, so a stand-in can be handed in;
3. the night group: `test_dark_spine` holds the scheduler's and the crowd's answers in a day-planning case,
   to move to those modules' suites;
4. the crowd: `test_crowd_bodies_on_a_real_day` keeps its check that a crash's cars stand on recorded
   ground, its header giving the wiring between the manager's record and a live event as its reason
   for a city; `test_wall_shield`'s fields layer cases keep a real street musician for the debug view,
   to move with the debug view's own suite pass;
5. the events (`event_manager*`, `events_*`, `fire_truck_body`, `police_car`, `car_front`,
   `protest`, the day 6, 7 and 13 suites):
   - two suites call `EventInstance.transition()` to put a live event in a phase that sets a check up
     (`test_resistance_replacement` and `test_resistance_placement_kinds`): each reaches the phase the way the game does or is handed a fake event,
     as `event-interface.md`'s section 4.2 says under `phase`;
6. run flow, save and pause: `test_dev_rig`'s `--spawn` event, closure and door cases read
   event placement, closures and the checkpoint huts, to move with those modules; `test_save`'s
   fence round trip ends in the city map's repaint, to move to a map suite.
