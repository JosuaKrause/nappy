---
name: writing-tests
description: How a test is written — a suite tests the one module it is named for and mocks every other real object, a realistic mock is made in two steps, which suites combine modules and why, and what a test holds and what holds nothing. Load this BEFORE writing or changing a test.
---

# Writing tests

- **`test_<x>` tests only `<x>` and builds no real object it does not test: it mocks it.** An exception gives its reason in the suite's header.
- **Only collaborators that do something are mocked**; plain values and data are built as they are.
- **A realistic mock is made in two steps**: build the real state and read off what the test uses, then commit only the mock.
- **A test never asserts what a setting is**; a relationship between settings that encodes a guarantee stays.
- **A test holds nothing when** the game cannot reach its setup, it asserts back what it just set, it would pass with the code deleted, or another suite already holds the behavior.
- **A public member only tests read is deleted, or made internal when its own file uses it.** `tools/check_test_only_members.py` fails a new one; fix the member, never list it.
- **A suite, a rig, a fake and a probe are typed like the code they test**: a new suite opens with the typed runner header and carries no opt-out line.
- **A hand-drawn map for one specific interaction; a generated map for a realistic walk or a measurement.**
- **The suite exits clean**: a leak warning at shutdown is a real retain bug.

Test what a screenshot cannot see, and screenshot what a test cannot judge. How a change is
verified (the commands, CI's kinds of pull request, the dev flags, the rig traps) is **verify**'s;
how a test is written is this file's.

## A suite tests the one module it is named for

**A test builds no real object it does not test, it mocks it, and a test module `test_<x>` tests
only `<x>`: a hard rule, with an exception only for a stated good reason**
(inbox #1159 in gray-dolphin).
Break the problem into components that can be tested apart, and test each in its own suite. Confirm a
component's correctness by injecting its dependencies through the paths the game itself uses, a
fake or a mock that records what it is asked handed in where the game hands the real one. A test
that reads a private member or opens an escape hatch is a sign to look again: it is a sign of
testing too much at once, of not injecting as intended, or of testing internals where the outside
behaviour is what matters, and those are examples, not the only reasons
(inbox #1018 in brisk-ferret). Where a component has nothing to hand a fake to,
**designing-classes** says what its design owes.

- **Only mock what you do not want to test** (inbox #1159 in gray-dolphin). A check whose subject
  is another object's answers is not this suite's; it
  moves to that object's own suite, rather than keeping that object real here.
- **The real logic is checked once, in the real object's own suite** (inbox #1156 in gray-dolphin). Do not retest
  a component another suite already tests: the general drawing code is tested once, not again by
  everything that draws through it (inbox #1018 in brisk-ferret). The city is built only by a
  direct test of the city, or by a suite that gives its reason (inbox #1156 in gray-dolphin;
  inbox #1159 in gray-dolphin).
- **Mocking makes the suites faster** (inbox #1159 in gray-dolphin): a fake holding a handful of answers is built
  in no time, where generating a city and planning a day is slow setup.
- **Plain values and data are built as they are** (a position, a day's spec, a `Tuning`
  constant); only collaborators that do something are mocked (inbox #1159 in gray-dolphin).
- **Which map a test uses depends on what it checks** (inbox #1172 in gray-dolphin). A test of one specific
  interaction between her and her surroundings, an edge case, uses a hand-drawn map built to the
  case, so no seed has to be searched for. A test of a realistic walk, and any measurement, uses a
  real generated map: a realistic walk needs what only the generator guarantees (the whole street
  network the crowd's lanes run on, a home, calm ground; on a hand map smaller than the full
  11×11 blocks the crowd walks off the edge), and a measurement must come from a city the
  generator can produce. The bullet only chooses the map: a suite that builds a `City` on either
  kind and is not a direct test of the city gives its reason in its header, as the rule below
  requires.
- **A suite a pull request touches for another reason is converted only as far as the pull
  request's change reaches** (inbox #1159 in gray-dolphin).

**Responsibilities are combined only for a stated good reason** (inbox #1159 in gray-dolphin), such as a guarantee
that spans modules or the game's composition. The reason
is stated in the suite's `##` header comment, in words a reader can check, so a combined suite
without one reads as a suite to split. **Any suite that builds a real city and is not a direct test
of the city gives its reason** (inbox #1159 in gray-dolphin), in its header. The ones that do,
each for the reason its header states:

- **`tests/test_event_manager.gd` runs the event manager against a real generated `City`**,
  because the bugs it holds are wiring between the two (an instance freed but left in the list, a
  successor spawned but never tracked), invisible to a data-level test; its header says so.
- **`tests/test_full_run_a.gd`, `_b.gd` and `_c.gd`** (one seed each, the run in
  `tests/full_run_rig.gd`) play three seeds through all 14 days with time actually advancing: the
  game's composition is what they test. Keep it that way: a version that only *plans* each day
  leaves the mobile one-shots unfinished and the whole successor-and-scar chain untested while the
  test passes.

## A suite is typed, and opens with the typed runner header

**Test code is typed wherever the language can type it, as the code it tests is** (inbox #1280 in olive-ferret);
**godot**'s "Types" owns the rule and says what the engine fails and what it cannot type. **A fake
goes in through a public seam, so nothing stays untyped to make a test work** (inbox #1280 in olive-ferret): the
seam's parameter has a type, and the fake extends it, as `tests/recording_log.gd` extends
`Telemetry` and is handed to `main.use_run_log()`.

**A new suite opens with this one line**, and every function it hands the runner to takes it the
same way, `t: TestRunner`:

```gdscript
func run(t: TestRunner) -> void:
```

The runner, `tests/run_tests.gd`, is `class_name TestRunner`, so that the header is one line and
a suite preloads nothing to name it (inbox #1282). `t.check()`, `t.close_to()` and
the runner's own `Node` calls (`t.add_child()`, `t.get_tree()`) are then typed calls. A bare
`func run(t)` does not parse in a file without the opt-out line: the parameter is an untyped
declaration and `t.check()` an unsafe method access, and the suite is a `LOAD FAIL`. **A suite
that carries the opt-out line keeps it until it is typed, and a new one never has it**:
`tools/check_field_reads.py` fails a file that gains the line.

## A realistic mock is made in two steps

**First build the whole real state and read off the external information the test uses; then
replace the state with a mock holding only that** (inbox #1159 in gray-dolphin). The values a fake answers come from
what the real objects answered in the same situation, so the test keeps checking that situation and
its setup stays one the game can reach (below). **The committed test holds only the mock**: neither
the real build nor the step that read it off survives into the pull request.

## What a test holds

- **Always tested:** meter arithmetic, falloff and the fairness contract, generator guarantees
  across many seeds, scheduler determinism, day outcomes, ending selection. These are the places
  where a bug is invisible until it ruins somebody's run.
- **Not tested, checked by eye:** layout, colour, readability, whether a cue is legible from across
  a street.
- **A test never asserts what a setting is** (inbox #1159 in gray-dolphin). A test that
  reads a setting only to restate it goes, since it only doubles the work of a change
  (PLAYTEST-67): asserting `act_for_day(4) == 2` when `ACT_START_DAYS` is
  `[1, 4, 8, 12]` is the table restated, so moving an act boundary means editing the constant *and*
  editing the test, and no arrangement of those two numbers was ever going to disagree.

  **The kept relationship tests stay, since they encode a guarantee between settings**
  (inbox #1173 in gray-dolphin). A fairness floor, the difficulty ramp (a late day
  holds more events than an early one) and a derived number kept in step with its setting (the
  flash curve's shape `FINALE_DISTANT_FLASH_SHAPE_B` is solved from the mean wait
  `FINALE_DISTANT_FLASH_MEAN_SECONDS` between the building's distant window flashes, and the test
  catches the two going out of step) all stay; a test that only restates one setting's
  value goes. `CAR_HORN_TIME >= required_horn_time()` fails when somebody lowers the horn time
  below what is fair, because it encodes *why* the number has a floor rather than what the number
  is: it says **"you broke the thing the number was for"**, never **"you changed a number"**.

  Three that look prunable and are not: a **guard that a sweep was not vacuous** (`"there were cells
  to ask (%d)"`) is what stops a passing test from having checked nothing; an **ordering between two
  constants that encodes such a guarantee** survives every rebalance that respects it; and any defect **verify**'s "What each one
  cannot see" names, which has already shipped once.
- **A test that is true by luck is worse than no test**: if it would pass with the code deleted,
  or passes only on the seed it was written against, it is not holding anything.
- **A check that asserts back what the test just set holds nothing**: it sets a field, then reads
  the field; it hands a fake a value, then reads the value off the fake. It can only be true, so
  it cannot fail (inbox #1097 in curly-rabbit).
- **A test whose setup the game cannot reach holds nothing the player can meet** (inbox #1097 in curly-rabbit). The
  shape is a state only the test can create, such as a field set through a method that only that
  test calls: the check passes on a situation that never happens in play, and the method is dead
  weight kept alive by the test. The exception is input the game does not control, such as a corrupted
  save on disk or a browser's answer, which can really happen and is worth testing. The fix is to
  reach the state the way the game does, or to delete the test and the member with it.
- **A public function only tests read is deleted, and its test hands in a fake or reads what the
  game shows** (inbox #1095 in curly-rabbit). It stays only when both hold: the information cannot
  be had another way, and the test needs it to confirm the behavior; such a case may hint that its
  module's design is suboptimal. Its line goes in a kept group of `tools/test_only_members.txt` with
  the reason (the fairness helpers `Tuning.required_horn_time`, `required_horn_sight` and
  `sleepiness_gain_calm` are there, since the relationship tests above rest on them). The rule also
  reaches a var, a signal or a constant with no use anywhere under `src/`,
  a constant nothing reads being the same dead weight.
- **A public function only its own file and the tests use is internal** (inbox #1098 in curly-rabbit): it gets the
  underscore, and its tests check what the class does from outside. A function stays public only where
  nothing outside can confirm the behavior, with the reason written down on its line in a kept
  group of the list. The rule also reaches vars and signals, and not constants, since a test
  reading a constant to assert a relationship is what this policy wants; a constant is flagged only
  when nothing under `src/` uses it, its own file included.
- **A hand-in**, a `use_*` setter that hands the object what it depends on, stays public and sits in
  a kept group with that reason, since the game uses its default and a test hands in a fake
  (dependency injection, minty-lemur #794; mocking, inbox #1095 in curly-rabbit).
- **`tools/check_test_only_members.py` (CI's `gates` job) holds the two rules above**: it fails a
  test that reads a public member nothing else under `src/` reads, unless
  `tools/test_only_members.txt` lists it. Its `--help` and the header of that list say what it
  counts as a reader and what each group is. What a builder does about it:
  - **A failure is answered by fixing the member, never by listing it.** The list's `[no reader]`
    and `[own file only]` groups only shrink, and CI fails a line added to either.
  - **The pull request that fixes a member deletes its line**, which the check prints as a `REMOVE`
    line once the line is stale.
  - **A `[kept]` line carries its reason after the `#`**, and whether the reason holds (the
    player's exception, a hand-in, a line the check misreads) is the reviewer's to read. A member a
    game reader reaches only through a string (`call("name")`, `has_method`) is a false failure
    and goes there with that reason.
  - **A file move carries its lines, and a renamed member does not**: a moved file is tracked
    first (`git mv`, or `git add` it), so git reports the rename and the check pairs each line; a
    listed member that is renamed is fixed, or kept with its reason.
  - **A merge of `main` that conflicts in the list is resolved by
    `tools/merge-test-only-members.py`**, which replays the branch's own added and removed lines on
    main's file.
  - **What the check cannot see stays review's**: a member whose name is also a word in another
    file, and a test of an unreachable setup.
- **A duplicate test is deleted** (inbox #1097 in curly-rabbit): the same behavior already tested by another suite
  is a second place to edit and no second chance to catch a bug. Search `tests/` for the behavior
  before writing a test, and if a suite holds it, extend that one.
- **An identity is not the property.** Asserting a relationship that is *true* but is not the
  condition the sentence beside it claims pins nothing.
- The suite must exit clean. **Leak warnings at shutdown mean a real retain bug.**

## Proposed, not asked for

These rules above are the filer's or the orchestrator's proposals and readings, not the player's
words, and hold until the player corrects them. The citation is the player's word each one extends:

- **A check whose subject is another object's answers moves to that object's suite** ("A suite
  tests the one module it is named for"), a reading of "only mock what you do not want to test"
  (inbox #1159 in gray-dolphin).
- **The reason for a combined suite, or for a real city, is stated in the suite's `##` header
  comment** (inbox #1159 in gray-dolphin).
- **The test-only rule also reaches a var, a signal or a constant with no use anywhere under
  `src/`** (inbox #1095 in curly-rabbit).
- **The own-file rule also reaches vars and signals, and not constants** (inbox #1098 in
  curly-rabbit).
- **A hand-in stays public, in a kept group** (minty-lemur #794; inbox #1095 in curly-rabbit).
- **The runner's class name, `TestRunner`**, is the builder's choice; the player's words ask for
  a class name so that the header is one line, and name none (inbox #1282).
