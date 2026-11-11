# minty-quail — The events' row suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The events' six row suites are typed and lose their opt-out line**: `test_events_catalogue`,
  `test_events_costs`, `test_events_emission`, `test_events_solid`, `test_acts` and `test_shapes`.
  Only untyped loop variables tripped the warnings; each now carries its element's type (among them
  the enum `EventDef.Look`, and `EventScheduler.Planned` under its present name, over which the
  placement track's rename to `EventPlan` reruns). No line under `src/` changed and no rig was
  edited.

## Left, each with its reason

- **Search: none.** The row's, the live event's and the plan's fields are `event-interface.md` row
  4a's scripted rewrite, so this pass converts no read.
- **Other modules' fields stay for their passes.** The pull request's description lists them by
  class, inner classes included (the plan record, a region plan, a seal candidate), writes marked,
  each with the method the game calls where one exists and each method's body checked to return
  that field: among them the row's `telegraphs_for()`, `obstructs_within()`, `heard_within()`,
  `core_within()`, `peak()`, `picture()`, `ground_shape()`, `detains_for()`, `most_in_a_day()`,
  `moves()`, `counts_as_one_barrier()` and `ends_the_day()`; the live event's `is_gone()`,
  `is_on_its_way_out()`, `row()` and `source()`; the plan record's `row()`, `placed_at()` and
  `give_role()` (its role written); the map's `calm_blocks_now()`, `size_in_tiles()` and the home,
  block, network, seed and block plans' methods; a building's `lot_rect()` and `is_burnt()`; and a
  lane mover's `lane().strategy()`. Answered only in part, by a method that derives something else:
  the row's spawn mode, first day and kind (`spawn_mode_on(day)`, `available_on(day)`,
  `is_ambient()`).

## Verified

The six suites pass one at a time, `tools/typing_census.py --check` holds, and the field-read check
passes. No check was deleted or moved.
