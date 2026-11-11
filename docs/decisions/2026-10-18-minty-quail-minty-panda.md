# minty-quail — The crowd's suites are typed and read the crowd through methods · 2026-11-11

**The ask.** Test code is typed as the code it tests is: "we type when we can" (inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin).
The first of the crowd's two passes of `typed-everywhere.md`'s "What is untyped in a test goes as
its suite is converted", after the crowd's source cuts (minty-quail-minty-osprey, -jolly-marten)
and the runner typed in every suite (minty-quail-downy-kestrel). The second, the car, walker,
turns, give-way and traffic suites, is still to come.

## What was built

- **`test_crowd_closures_a`, `_b`, `_c`, `test_crowd_contributions`, `test_crowd_field`,
  `test_crowd_streets`, `test_crowd_traffic`, `test_crowd_yields`, `crowd_rig.gd` and
  `crowd_closures_rig.gd` are typed and lose their opt-out line.** `crowd_street_rig.gd`,
  `test_crowd_bodies` and `test_crowd_bodies_on_a_real_day` had none. No line under `src/` changed.
- **The suites ask the crowd through the methods the game calls**: an agent's `mood()`, its lane's
  `kind()`, `strategy()` and `shape()` and the lane's questions for a door, a gate or a pedestrian
  ahead; the lane is told `see_a_pedestrian_at()`, `see_no_pedestrian()` and
  `find_no_junction_to_hold_at()`, a hut `stands_at()`, an arc `travel_on()` and a field
  `centre_on()`, where each was written or read by field. `tools/check_field_reads.py` does not
  read tests, so the reads were found by search.

## Left, each with its reason

- `crowd.sources`: `city.gd` and `run_session.gd` read the field too, and no method answers it.
- `crowd.skip_motion`, written: the configuration seam `city.gd` writes.
- A checkpoint hut's `inside` and `queue`: no game code reads them and no method answers them.
- A field's `radius` and `centre`, read: `half_extent()` and `centre_point()` have no caller under
  `src/`, so a test asking them would read a member only tests read.
- `agent.kind`, written on a hand-built agent: its setter installs the strategy, which is how one
  is built.
- The events' `def.shape`, `piece.shape` and `plan.position`, which are the events' passes.
- `tests-one-module.md`'s crowd entry stays as written: `test_recipe_crowd`'s
  `Crowd.recipe_coverage` check is in another module's suite, and the events' answers in the crowd's
  suites move with the events.

## Verified

The crowd's suites pass, `tools/typing_census.py --check` holds, and no game file changed, so the
identity probes do not apply. No check was deleted or moved.
