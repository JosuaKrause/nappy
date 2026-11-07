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

**Open on the board, not blocking:** whether a test counts as another object under "fields are not
API", so it too reads its subject only through methods (tests-read-fields; the pick, yes, runs unless
the player answers otherwise).

**The order** is the test survey's module by module; that survey's file is gone, so whoever picks
this up lists the suites again with `rg` for the ones that build a `City`, a day or `main`, and what
each reads from it.
