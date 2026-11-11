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

- **What is untyped in a test goes as its suite is converted** to public seams and to one module
  (`tests-public-seams.md`, `tests-one-module.md`): the pull request that converts a suite types it
  and deletes its file-level ignore. A module's typing pass may come first, typing its suites and
  deleting their lines, while their reads of other modules' fields wait for those modules' passes.
- **The files under `src/` are typed in the module passes** (`field-reads.md`).
- **A probe that names a member no class has parses only behind its opt-out line** and fails when
  it runs. `tests/probes/bouncy_egret_day11_mast.gd` reads `siting.scenery_ground` off
  `EventScheduler.WalkSiting` twice, a member that is the private `_ground`; the pull request that
  next types the probe has it ask through a method.

**Done when** no file under `tests/` carries a file-level ignore of the typing warnings.
