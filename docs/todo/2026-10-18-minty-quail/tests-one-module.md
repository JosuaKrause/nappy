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
var a test reads gets a method, and suites move as a pull request touches them. The field-read check
reads `src/` only (`tools/check_field_reads.py`'s header hands tests to this item); the reads in the
tests are found by running it over a scratch copy of the tree with `tests/` moved under `src/`
(`--root` names the copy, `--list` prints every read). The reads of a class under `src/` that no
line of `tools/test_only_members.txt` holds, and no conversion has moved yet, are five:
`WalkerStrategy._yield_left` and `_door_state`, `CarTurn.travelled`, `LaneMover._speed` and
`ExcitementSource.player_expected_total_gross`. The rest the check reports each have a `[kept]`
line with its reason there: `EventManager.world`, `DaySpec.bag`, `DaySpec.wall_row_share`,
`City.scenery` and `City.scenery_ground`, `SceneryWater.cells`, `SceneryResidency.budget_usec`,
`ParkCordon.gap` and `last_gap`, `ResistanceHappenings.cordon`, `ModeButton.symbol` and
`hold_progress`. The count leaves out the reads under `tests/probes/` (about sixty, nearly all of
underscore fields) and the tests' own fakes: a probe is a measurement script run by name, and no suite
runs it, while this item's rule is about suites (a reading of inbox #1182 in gray-dolphin, open to
the player's correction). A builder reruns the check first, since the list moves.

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
