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

**A test reads its subject only through methods** too: on the board's tests-read-fields, whether a
test counts as another object under "fields are not API", "yes" (inbox #1182 in gray-dolphin). A var a test reads
gets a method, and suites move as a pull request touches them.

**A suite that plans one city over many days hands in its mast sites worked out once per city**,
as the game does (`EventWorld.work_out_mast_sites()` on the city as built): a suite that leaves
them to the shared helper's default (`tests/game_dawn.gd`) has them worked out at each planned
dawn, on the day's paint, so a test can measure masts that move between days, which the game never
shows (the orchestrator's choice in placement step 3c, open to overturn). Each module's pass
hoists them as it touches the suite.

**The order** is by module, those whose suites build a city before those that boot `main`, one
pull request each, each re-checking its suites with `rg` for `RunCity.`, `.build(`, `city.tscn`,
`booted_main` and `build_day`/`start_day`/`begin_day` first. Every entry has had its
pass (the records 2026-10-18-minty-quail-teal-toad, -tall-lynx, -spotted-owl, -quiet-swan,
-curly-hawk, -merry-goose and -dotted-pelican; the events and the resistance, done, the records
2026-10-18-minty-quail-gentle-bison, -pebbly-plover, -grassy-quail, -amber-elk, -sunny-sparrow, -mossy-panda,
-speckled-hare, -jolly-ibis, -tawny-bunny, -curly-hedgehog, -spry-moose, -frosty-tapir and
-golden-finch, -coral-elk, -frosty-hedgehog and -round-magpie), and what each lists is what is left of it:

1. the crowd: `test_crowd_bodies_on_a_real_day` keeps its check that a crash's cars stand on recorded
   ground, its header giving the wiring between the manager's record and a live event as its reason
   for a city.
