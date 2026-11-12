# Code is typed wherever the language can type it, the tests included

**The ask**, three messages about the typed-access step (`field-reads.md`: GDScript's warnings for an
access the engine cannot type become errors, with a file-level ignore at the top of every file not
yet converted), each quoted with what it answered (inbox #1280 in olive-ferret):

- Told that after that step a new test suite written the usual way, `func run(t)` with the runner
  handed in untyped, would no longer parse, and that the orchestrator had ruled new files fully
  typed everywhere, tests included: "wait, they weren't typed before???".
- Shown the count (of 302 script files under `src/`, 231 fully typed; of 414 under `tests/`, 49,
  with 330 suites taking the runner untyped), that GDScript makes types optional and nothing in
  the project enforced them, and the orchestrator's plan to type the runner in every suite by one
  mechanical script right after that step: "is that a limitation of the type system?".
- Told that the tests' case was habit and that the real limits are narrow (a property read on an
  untyped value is never warned, collections are typed one level deep, no interfaces or unions so
  a fake extends the class it stands in for, a callable carries no signature): "yeah, let's not
  make that a habit. we type when we can. with the public seams tests you won't have to keep
  things untyped to make it work".

**Read as:** every declaration and every receiver is typed where GDScript can type it, in the game
and in its tests alike, and a value the language cannot type is read through a typed name. A test
that hands its fake in through a public seam (`tests-public-seams.md`) has a typed place for it, so
no value stays untyped to make a test work. A new file is fully typed from its first line, a test,
a rig, a fake or a probe included; the typed-access step of `field-reads.md` is what makes the
engine hold a file to that.

**Build.**

- **The tests were typed ahead of their conversion** to public seams and to one module
  (`tests-public-seams.md`, `tests-one-module.md`): the test layer's typing passes typed every file
  under `tests/` and deleted its file-level ignore, but for the two files below, while their reads of
  other modules' fields wait for those modules' passes and the suites' conversion. *Proposed, not asked
  for:* the fields of a module whose pass has merged are converted in the other suites by one sweep
  after the last typing pass, from the reads its record lists with their methods; the plainer
  alternative is to leave them to each suite's later conversion to one module.
- *Proposed, not asked for (the orchestrator's, after the reviews of the first typing passes):*
  **a pass's list of other modules' fields is built with `tools/field_answers.py`**
  (`uv run python tools/field_answers.py --brief <the pass's brief> --counts`) once its files are
  typed, and each method the tool names as an answer, or prints apart, is read in its class, the
  classes it extends included, before the list says it answers. **The pass's record carries the
  whole list in its own text**, by class, each field with the game's method or "no method", since
  the sweep above reads the records and a pull request's description is not in the repository. The
  plainer alternative is a list matched by hand, which came back *not ready* on most of the first
  passes: inner classes, getters and an inherited getter missed, and a method credited for a value it
  only derives.
- **The files under `src/` are typed in the module passes** (`field-reads.md`).
- **Two files under `tests/` keep their opt-out line for step 4 of polite-tapir's
  `placement-by-construction.md`**, which deletes `EventScheduler._best_of()` and what only it uses, and each is
  typed or deleted by that step:
  - `tests/probes/bouncy_egret_day11_mast.gd` reads `siting.scenery_ground` off `EventScheduler.WalkSiting` twice, a
    member that is the private `_ground`, which no method answers, so it parses only behind its line and fails when
    it runs; it replays `_best_of()`'s rules through `WalkSiting`'s private members.
  - `tests/test_siting_judges_once.gd` holds the memo of `_best_of()`'s verdicts, that a placement over a walk
    siting's pool judges each candidate once (`EventScheduler.Verdicts`, the store it counts), and reads
    `WalkSiting.offers_worked_out`, a public counter only it reads, that a look works out its offer once.

**Done when** no file under `tests/` carries a file-level ignore of the typing warnings, whichever of the
three it names (`uv run python tools/check_field_reads.py --summary` counts the files by folder), and neither
does a script a suite writes out at run time (the `PROBE` strings of `tests/test_scene_recipe_activity.gd` and
`tests/test_scene_recipe_runtime.gd`, which the census does not read).
