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
them, one module at a time, once the hand-ins give each class something to hand
a fake to. Each module's pull request says each suite's time before and after.

**A test reads what it tests only through methods**: on the board's tests-read-fields, whether a
test counts as another object under "fields are not API", "yes" (inbox #1182 in gray-dolphin). A
var a test reads gets a method, and suites move as a pull request touches them. Every module has
had its pass; the reads below are what the field-read check, which reads `src/` only
(`tools/check_field_reads.py`'s header hands tests to this item), cannot count. They were found
by running the check over a scratch copy of the tree with `tests/` moved under `src/`.

**What breaks the rule today**, each read to be moved to the class's method or to what the class
does outward:

- `ContactPoint.is_done`: about twenty lines in the resistance suites (`test_resistance_crossing.gd`
  holds the most) read the field where the game asks `is_finished()`; its line in
  `tools/test_only_members.txt` defers to this item.
- `Crowd.step()`: the crowd's rigs and suites (`tests/crowd_closures_rig.gd` and the rest) drive
  it by hand; its line in `tools/test_only_members.txt` defers to this item.
- `WorldMap.blocked`: `tests/test_world_passability.gd` and `tests/test_day13_guard.gd` read the
  blocked layer's tiles and copy it.
- `ExcitementSource.player_velocity`: `tests/fixtures/prediction_reference.gd` reads it.
- `LaneMover.view`: `tests/test_drawn_view.gd` writes it on a car and a walker.

**One kept exception.** `tests/test_crowd_bodies_on_a_real_day.gd` builds a real city for a
guarantee that spans the event manager's plan, the city's start of the day and the crowd; its
header gives the wiring as its reason.

**A suite that plans one city over many days hands in its mast sites worked out once per city**,
as the game does (`EventWorld.work_out_mast_sites()` on the city as built): 37 files under
`tests/` use `GameDawn`, 15 of them hand sites in with `.masts(`, and the rest leave them to the
helper's default (`tests/game_dawn.gd`), which works them out at each planned dawn, on the day's
paint, so a test can measure masts that move between days, which the game never shows (the
orchestrator's choice in placement step 3c, open to overturn). Whether each of the 15 works them
out once per city is read by the builder. A pull request that touches such a suite hoists them.
