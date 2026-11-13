# polite-tapir — The dawn is an ordered list of phases, each a class handed the DawnContext · 2026-11-13

**The ask.** The event scheduler is broken up (`scheduler-breakup.md`, the design review's breakup the player approved:
"agree on all design review points. let's do it", inbox #1268 in olive-ferret): the dawn's passes become one class per
phase, each handed the day's `DawnContext`, the location judge gets a file of its own, and `build_day(context)` is an
ordered list of phases.

**Who did what.** A Fable agent wrote the detailed design and handed the coding off (inbox #1432 in minty-rabbit); Sonnet
built it in three pull requests, each reviewed by Fable but the third, whose Fable review the player left to the next
session.

## What was built

- **#1448, the two judges**: `RuledLocationGround` (`src/events/ruled_location_ground.gd`) and `RuledRoadblockGround`
  (`src/events/dawn_phases/ruled_roadblock_ground.gd`) are classes of their own; `RowGround` answers the weights it was
  made with (`weights()`, `is_a_wall_by_cost()`), so the location judge asks the walk's ground and no balance number
  gains a second reader; `RuledRoadblockGround.close_by()` is the one measure the judge and the count wrote twice.
- **#1449, the opening phases**: `DawnPhase` and `DawnAmbient`, `DawnScars`, `DawnMasts`, `DawnWallBodies`,
  `DawnCalmKeptClean`, `DawnRoadblocks`; `DawnContext` gains `hold_fixed_part()` and `keeps_the_routes()`.
- **This pull request, the other phases**: `DawnScripted`, `DawnOneShots`, `DawnSpoilers`, `DawnMoments`, `DawnDraw`,
  `DawnLesson`, `DawnRoadblockCount`; `build_day()` runs the thirteen phases in today's order and nothing else.
- **Nothing a day places changed**: the placement fingerprints (`FP`, `DP`, `TA`, `ESCAPE_SPACING`) and
  `placement_rows.gd` were identical before and after each of the three, against the designer's baseline on `549d5fc8b`.

## Where the design did not hold

- **The phases' run-log lines** go through `context.note(`, which `tests/test_texts_catalogue.gd` read as player-facing
  sentences once they left the scheduler, a file on its allow-list; `res://src/events/dawn_phases/` joined the list.
- **A rename wrapped across a line** (a name broken after `EventScheduler.`) was missed by the builders' scripted pass
  twice; each review found it.
- **The divider "the day's locations, from the bags"** stays in the scheduler over `LOCATIONS_SALT`, `view_weight()`
  and the bags' tables, which placement's step 3 replaces in place.

## Choices open to overturn

The designer's, where the item is silent, each with what it was chosen over:

- **Thirteen phases where the item names eight**: the fixed parts are three classes, since the scars stand between the
  ambient rows and the masts in the plan's order; the calm area kept clean, the dawn draw and the roadblock count are
  phases the approved review's list does not name, so that `build_day()` is the list alone. Over: one fixed-parts class
  with the scars inside it, and the three left as static functions beside the list.
- **The dawn draw moves, though placement's step 2 deletes it**, as the small file step 2 edits. Over: leaving it in the
  scheduler.
- **Phases are objects behind a base class** (`DawnPhase`, `run(context)`), made fresh each dawn and holding nothing
  (inbox #1392 in dappled-wombat). Over: thirteen classes with a static `run()`.
- **Names are `Dawn` and what the phase plans**, since `RoadblockPhase` and `ScriptedPhase` already name the algorithms.
  Over: a `...DawnPhase` suffix.
- **`RuledRoadblockGround` under `dawn_phases/`**, beside its glue. Over: an inner class of the roadblocks' phase, or a
  file beside the location judge.
- **The location judge is handed the walk's ground.** Over: reading the scheduler's two weights, which would send them
  to `Tuning`.
- **`DawnContext` gains two questions and `route_ground()` goes private.** Over: each phase writing the hold loop, and a
  public `keeps_the_routes()` on the scheduler.
- **One measure of close by** with `TASK_ROW_CLOSE_BY` in the judge's file, the constant going from two reader files to
  three. Over: both staying in the scheduler.
- **The fitted tables' readers stay with the tables** (`DawnMoments` reads `EventScheduler.MOMENTS_PER_DAY`, the judge
  calls `ground_weight()`), since placement deletes the tables in place. Over: moving the numbers with their readers.
- **The literal salts get names** (`DawnScripted.SALT`, `DawnSpoilers.SALT`, `DawnMoments.SALT`).
- **No new suite**: the existing suites and the fingerprints hold the phases, as `PlanBuilder` and `DawnContext` were
  left (records fluffy-ferret and rosy-yak). Over: a suite per phase handed a fake context, which minty-quail's
  `tests-one-module.md` may add.
- **Three pull requests** where the item says one, since one would run past what a builder holds well.

## Left open, on the board

- **Whether the files now holding balance numbers come under the balance rules** (board question balance-reach):
  `TASK_ROW_CLOSE_BY` and the location judge's two weights, `DawnMasts.CURFEW_ANNOUNCE_DAY`, and the park spoilers'
  three numbers in `dawn_spoilers.gd` sit in files only the events row of the rules covers.
- **When `WalkSiting` (about 580 lines) gets a file of its own** (board question walksiting-lift): the designer proposed
  placement's step 4, which rewrites it; the scheduler stays about 1,500 lines until placement's steps delete their
  blocks.
- **No listed layer break moved**: the scheduler's four stand in `WalkSiting.could_be_in_her_view()`.

The probe `tests/probes/m128_park_beats.gd` exits on two shared-state leaks (a `City` left in the runner, a signal left
connected) on `main` as on this branch: older than this work, and not built here.
