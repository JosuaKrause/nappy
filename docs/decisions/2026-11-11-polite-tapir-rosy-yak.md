# polite-tapir — A dawn is one DawnContext, handed to every pass, and the suites plan through GameDawn · 2026-11-13


**The ask.** The event scheduler is broken up into pieces of their own (`scheduler-breakup.md`, the design review's
breakup, which the player approved, inbox #1268 in olive-ferret); this piece hands a dawn one object in place of
`build_day()`'s thirteen parameters, so the dawn's phases and placement's unit draw can each take it.

**Who did what.** A Fable agent wrote the detailed design and handed the coding off, its own decision under the model
table (inbox #1432 in minty-rabbit); Sonnet built it in two pull requests, tests first, each reviewed by Fable. The
design names why tests first: changing `build_day()`'s signature with its callers in separate pull requests would need
a thirteen-parameter shim in `src/` that only tests read.

## What was built

- **#1440, the dawn's test helper**: `tests/game_dawn.gd` (`GameDawn`), a chain that says only what a test's day differs
  in, and the 80 calls of `build_day()` in 40 files under `tests/` rewritten through it by a one-off script; every
  call's effective arguments are unchanged (the review compared all 80 by script). It hands the day's tree where a
  test names no walk, which is what `build_day()`'s fallback grew.
- **This pull request, `DawnContext`** (`src/events/dawn_context.gd`, the model layer): handed the spec, the day's seed,
  the map, the walk, the calm areas, the plan builder and the ground's maker at construction, and what a walk may be
  without after it (`use_the_run()`, `use_the_doors()`, `use_what_stands()`, `use_mast_sites()`, `use_trace()`,
  `use_the_roadblock_row()`); it derives the corridor, the day's events, locations, ground and rules once, on first ask.
  `build_day(context)` returns nothing and every dawn pass takes the context; `DayPlanner` makes it with the city's own
  plan builder; `DayEvents` loses its two hand-ons (`use_locations()` and `locations()`, `use_ground()` and
  `ground()`); the route-tree and spec fallbacks go; `GameDawn` builds one.
- **Nothing a day places changed**: the placement fingerprints (`FP`, `DP`, `TA`, `ESCAPE_SPACING`) and
  `placement_rows.gd` are identical before and after.

## Choices open to overturn

The designer's where the item is silent, kept as given, each with what it was chosen over:

- **The roadblock phase's row is in the context** (`roadblock_row()`), which the item's list did not name; a second
  parameter beside it would undo the one object every phase is handed. Over: `build_day(context, row)`.
- **The ground's maker is handed in as a function**, as `PlanBuilder` is handed its three questions (fluffy-ferret),
  so the context names no scheduler. Over: the context calling `EventScheduler.row_ground()` itself (a static
  fetched, tied to the hub being broken up), or a finished `RowGround` handed in (made over a second `Corridor`).
- **The street she starts on is worked out in the context** with `ClosurePlanner.home_street()`, as `RowGround`
  asks it. Over: `RouteSource.street_it_starts_in()`, which answers differently for a walk that is not a tree.
- **The seed is an integer and the context gives the streams**; `build_day()` read only `rng.seed`, and
  `street_bag_seed()` takes the integer too.
- **Hand-ins after the constructor, in the repository's `use_*()` form**, with `use_the_run()` taking the run's three
  together. Over: fourteen constructor parameters.
- **`build_day()` returns nothing**: the plan is read off the context (`events()`), the locations and ground beside it.
- **`DayEvents` loses its locations and ground hand-ons**, which the context now holds.
- **One rules object for the scripted phase too**, where it was built with no one-notice rule; no spec the game makes
  differs, and a hand-made spec that keeps one notice at a time now asks it of its scripted rows. Over: a second
  rules object for the scripted phase.
- **The calm area kept clean is told to the context once** (`keep_clean()`, guarded by an assert). Over: the context
  deciding it lazily at the first ask, an answer that would depend on who asks first.
- **Every dawn pass takes the context in this pull request**, the small ones included, so the phases' pull request
  moves code and changes no signature; the two judges keep their narrow constructors.
- **The escape's draw loop is handed the context**, since the escape's rules are the one place a `WalkGround` is
  built; the loop is otherwise untouched, and placement deletes it.
- **`DayPlanner.plan_the_escape_city()` takes a required builder.** Over: making one, or an optional one with a
  fallback, which fluffy-ferret rejected for `build_day()`.
- **The test helper is a chain that says only what differs.** Over: a function with the old thirteen positions,
  which the next change to the context would again ripple through every call.
- **The helper's default mast sites are worked out at each planned dawn**, as about forty calls did; hoisting them
  once per city is `tests-one-module.md`'s, and `.masts(sites)` is where a suite does it.
- **Two pull requests, tests first** (above). Over: one pull request, or `src/` first behind a shim only tests read.
- **No `tests/test_dawn_context.gd`**: the context's derivations are held by the scheduler's suite, the event
  manager's (which plans through `DayPlanner`) and the placement fingerprints, as fluffy-ferret left `PlanBuilder`
  without a suite of its own. Over: a suite of its own, which `tests-one-module.md` may add.
