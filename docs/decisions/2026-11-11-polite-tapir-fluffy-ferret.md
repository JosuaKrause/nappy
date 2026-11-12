# polite-tapir — Building a plan at a tile is PlanBuilder, an object handed what it asks · 2026-11-12


**The ask.** The event scheduler is broken up into pieces of their own (`scheduler-breakup.md`, the design
review's breakup, which the player approved, inbox #1268 in olive-ferret); its first piece builds a plan at a tile.
A planner's first design made it a class of static functions; the player saw no benefit in a static function and
asked for the object, since an object handed what it depends on is the dependency injection the code is built on
(inbox #1392 in dappled-wombat).

## What was built

- **`PlanBuilder`** (`src/events/plan_builder.gd`, the model layer): an object constructed with the map and three
  functions it is handed, what stops a moving row, where a body stands and the room a candidate has among placed
  plans; the game hands it `EventInstance.mover_for`, `EventFootprints.stands_at` and
  `StreetInvalidation.room_around`, so it names none of those three classes; the statics it keeps are the
  lattice's own arithmetic on the map it holds (`CityMap.period()`, `CityMap.corridor_offset()`), a plain
  value (`Mover.on_foot()`, `EventPlan.new()`) and constants (`Tuning.STREET_WIDTH`, the `EventDef` enums). Six functions left the scheduler for
  it: `build()` (once `build_placement()`), `place_at()`, `body_stands_at()`, `room_along()` (now public, since the
  resistance's happenings call it), `_along_street_path()` and `_cross_street_path()`.
- **Four places make one**, each with the same expression: the dawn (`EventScheduler.build_day()`), once a day,
  until `DawnContext` is handed one; the event manager, once a city, kept on its `EventWorld`; the scene recipes'
  runtime; and the suites and probes, through `tests/game_plan_builder.gd`.
- **Every caller is handed it**: `LocationFit`, `RuledRoadblockGround`, `WalkSiting`, `OneNoticeRule` and the
  scheduler's functions through their constructors or parameters, `EventsAhead` from its world, the resistance's
  director and happenings from the events in `setup()`; `StreetInvalidation`'s `one_notice` is the builder or null.
- **Nothing a day places changes**: the placement fingerprints (`FP`, `DP`, `ESCAPE_SPACING`) are identical before
  and after, and `tools/test.sh observers` passes with its fixture untouched.

## Choices open to overturn

- **The three questions are handed as functions**, not interface classes (each is one question, and two go when
  the row answers for its mover and standing place, row 3a of minty-quail's `event-interface.md`).
- **No named constructor for the game's wiring**: it would put `EventInstance` and `EventFootprints` back in the
  model's file; the cost is the one expression written at three places in the game.
- **The dawn makes its own builder** until `DawnContext` holds one, rather than an optional `build_day()`
  parameter with a fallback.
- **The director and the happenings take it from the events in `setup()`**; with no events set up over a city,
  the neighbor's walk to work answers null, as it does with no events.
- **`build()` in place of `build_placement()`**; the other names stay, and `_cross_street_path()` stays as it is
  (`tests-public-seams.md` leaves "a row or removing" open).
- **`StreetInvalidation`'s `one_notice` is the builder or null**, the form its `walk` parameter has, in place of
  a flag beside a builder, which would make all eleven construction sites carry one.
- **What stays in the scheduler**: `recipe_placement()` (it judges by the day's locations, the row's ground and
  `role_for()`), `_wants_this_side()` (its one caller, `open_ground_for()`, goes with the breakup's `RowGround`),
  `_band_offset_of()` and its neighbours (a row's own numbers, with no tile), and `blocked_by()` and
  `block_a_disc()` (they paint a flood's blocked set and build no plan).
- **One pull request**: the one possible cut, `body_stands_at()` second, would only add a constructor change at
  the three makers and the test helper.
- **No `tests/test_plan_builder.gd` in this pull request**: the functions' checks sit in other modules' suites,
  which minty-quail's `tests-one-module.md` sorts.

## Verified

The fingerprints above; every named suite, `route_bag`, `siting_judges_once` and ten neighbouring suites pass;
`./tools/check.sh`, the layer, field-read, test-only-member and telemetry-kind checks and the lint pass.
