---
name: writing-tests
description: How a test is written — a suite tests the one module it is named for and mocks every other real object, a realistic mock is made in two steps, which suites combine modules and why, and what a test holds and what holds nothing. Load this BEFORE writing or changing a test.
---

# Writing tests

Test what a screenshot cannot see, and screenshot what a test cannot judge. How a change is
verified (the commands, CI's kinds of pull request, the dev flags, the rig traps) is **verify**'s;
how a test is written is this file's.

## A suite tests the one module it is named for

**A test builds no real object it does not test, it mocks it, and a test module `test_<x>` tests
only `<x>`: a hard rule, with an exception only for a good reason stated in the suite's header**
(inbox #1159). *Asked for as guidance rather than a hard rule (inbox #1018 in brisk-ferret) · made a
hard rule with exceptions only for good reasons on 2026-11-06, because as guidance it did not work
(inbox #1159).*
Break the problem into components that can be tested apart, and test each in its own suite. Confirm a
component's correctness by injecting its dependencies through the paths the game itself uses, a
fake or a mock that records what it is asked handed in where the game hands the real one. A test
that reads a private member or opens an escape hatch is a sign to look again: it is a sign of
testing too much at once, of not injecting as intended, or of testing internals where the outside
behaviour is what matters, and those are examples, not the only reasons. Where a component has
nothing to hand a fake to, **designing-classes** says what its design owes.

- **Only mock what you do not want to test** (inbox #1159). *Read as, the filer's reading and not
  the player's words:* a check whose subject is another object's answers is not this suite's; it
  moves to that object's own suite, rather than keeping that object real here.
- **The real logic is checked once, in the real object's own suite** (inbox #1156). Do not retest
  a component another suite already tests: the general drawing code is tested once, not again by
  everything that draws through it. The city is built only by a direct test of the city, or by a
  suite whose header gives its reason (inbox #1156; inbox #1159).
- **Mocking makes the suites faster** (inbox #1159): a fake holding a handful of answers is built
  in no time, where generating a city and planning a day is slow setup.
- **Plain values and data are built as they are** (a position, a day's spec, a `Tuning`
  constant); only collaborators that do something are mocked (inbox #1159).
- **A suite a pull request touches for another reason is converted only as far as the pull
  request's change reaches** (inbox #1159).

**Responsibilities are combined only for a stated good reason** (inbox #1159), such as a guarantee
that spans modules or the game's composition. *Proposed by the filer, open to overturn:* the reason
is stated in the suite's `##` header comment, in words a reader can check, so a combined suite without one reads as a suite to split.
**Any suite that builds a real city and is not a direct test of the city gives its reason there**
(inbox #1159). The ones that do, each for the reason its header states:

- **`tests/test_event_manager.gd` runs the event manager against a real generated `City`**,
  because the bugs it holds are wiring between the two (an instance freed but left in the list, a
  successor spawned but never tracked), invisible to a data-level test; its header says so.
- **`tests/test_full_run_a.gd`, `_b.gd` and `_c.gd`** (one seed each, the run in
  `tests/full_run_rig.gd`) play three seeds through all 14 days with time actually advancing: the
  game's composition is what they test. Keep it that way: a version that only *plans* each day
  leaves the mobile one-shots unfinished and the whole successor-and-scar chain untested while the
  test passes.

## A realistic mock is made in two steps

**First build the whole real state and read off the external information the test uses; then
replace the state with a mock holding only that** (inbox #1159). The values a fake answers come from
what the real objects answered in the same situation, so the test keeps checking that situation and
its setup stays one the game can reach (below). **The committed test holds only the mock**: neither
the real build nor the step that read it off survives into the pull request.

## What a test holds

- **Always tested:** meter arithmetic, falloff and the fairness contract, generator guarantees
  across many seeds, scheduler determinism, day outcomes, ending selection. These are the places
  where a bug is invisible until it ruins somebody's run.
- **Not tested, checked by eye:** layout, colour, readability, whether a cue is legible from across
  a street.
- **A test asserting a relationship beats one asserting a value.** `intensity < walking decay`
  survives rebalancing; `intensity == 3.2` does not.
- **A test never asserts what a setting is** (inbox #1159). *Asked for as a judgment call, a test
  that only doubles the work of a change deleted (PLAYTEST-67) · overturned to absolute on
  2026-11-06, because a test must never test configuration settings (inbox #1159).* A test that
  reads a setting only to restate it goes: asserting `act_for_day(4) == 2` when `ACT_START_DAYS` is
  `[1, 4, 8, 12]` is the table restated, so moving an act boundary means editing the constant *and*
  editing the test, and no arrangement of those two numbers was ever going to disagree.

  **The kept relationship tests stay, since they encode a fairness guarantee between settings**
  (inbox #1159). `CAR_HORN_TIME >= required_horn_time()` fails when somebody lowers the horn time
  below what is fair, because it encodes *why* the number has a floor rather than what the number
  is: it says **"you broke the thing the number was for"**, never **"you changed a number"**.

  Three that look prunable and are not: a **guard that a sweep was not vacuous** (`"there were cells
  to ask (%d)"`) is what stops a passing test from having checked nothing; an **ordering between two
  constants** survives every rebalance that respects it; and any defect **verify**'s "What each one
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
  `sleepiness_gain_calm` are there, since the relationship tests above rest on them).
  `tools/check_test_only_members.py` (CI's `gates` job) fails a test that reads a public member
  nothing else under `src/` reads. *Proposed by the orchestrator, not asked for, open to the player's
  correction:* the rule also reaches a var, a signal or a constant with no use anywhere under `src/`,
  a constant nothing reads being the same dead weight.
- **A public function only its own file and the tests use is internal** (inbox #1098 in curly-rabbit): it gets the
  underscore, and its tests check what the class does from outside. A function stays public only where
  nothing outside can confirm the behavior, with the reason written down on its line in a kept
  group of the list. The same check enforces it. *Proposed by the orchestrator, not asked for, open
  to the player's correction:* the rule also reaches vars and signals, and not constants, since a test
  reading a constant to assert a relationship is what this policy wants; a constant is flagged only
  when nothing under `src/` uses it, its own file included.
- *Proposed by the orchestrator, not asked for, open to the player's correction:* a **hand-in**, a
  `use_*` setter that hands the object what it depends on, stays public and sits in a kept group
  with that reason, since the game uses its default and a test hands in a fake (dependency injection,
  minty-lemur #794; mocking, inbox #1095 in curly-rabbit).
- **What the list enforces, and nothing more.** Its `[no reader]` and `[own file only]` groups only
  shrink: with `--base <the pull request's base>`, which CI passes, the check fails a line added to
  either, so a builder answers its failure by fixing the member, never by listing it. A line gone
  stale (the member gained a reader in another file, lost its test, is a constant used in its own file,
  is an engine name, is a function passed rather than called, or is gone) fails as a `REMOVE` line, so the
  pull request that fixes a member deletes its line. A file move carries its
  lines: an added line passes when a line of the same group with the same member name is removed in the
  same diff and git reports its file as renamed to the added line's file, each removed line pairing with
  one added line; before a commit git sees the move only once the moved file is tracked (`git mv`,
  or `git add` it first). A listed member that is renamed is the moment to fix it (or to put it in a kept line
  with its reason), never to carry its line. A merge of `main` that conflicts in the list is
  resolved by `tools/merge-test-only-members.py`, which replays the branch's own added and removed lines on main's file. A
  `[kept]` group takes a new line, and the check fails one with no reason after its `#`; whether the
  reason holds (the player's exception, a hand-in, a line the check misreads) is the reviewer's to
  read. The check cannot see a member whose name is also a word in another file or a test of an
  unreachable setup; those stay review's. A member a game reader reaches only through a string
  (`call("name")`, `has_method`) is a false failure that goes in a kept line with its reason.
- **A duplicate test is deleted** (inbox #1097 in curly-rabbit): the same behavior already tested by another suite
  is a second place to edit and no second chance to catch a bug. Search `tests/` for the behavior
  before writing a test, and if a suite holds it, extend that one.
- **An identity is not the property.** Asserting a relationship that is *true* but is not the
  condition the sentence beside it claims pins nothing.
- The suite must exit clean. **Leak warnings at shutdown mean a real retain bug.**
