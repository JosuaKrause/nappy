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
  the map, the walk, the calm areas and the plan builder at construction, and what a walk may be without after it
  (`use_the_run()`, `use_the_doors()`, `use_what_stands()`, `use_mast_sites()`, `use_trace()`,
  `use_the_roadblock_row()`); it derives the corridor, the day's events, locations, ground and rules once, on first ask.
  `build_day(context)` returns nothing and every dawn pass takes the context; `DayPlanner` makes it with the city's own
  plan builder; `DayEvents` loses its four hand-ons; the route-tree and spec fallbacks go; `GameDawn` builds one.
- **Nothing a day places changed**: the placement fingerprints (`FP`, `DP`, `TA`, `ESCAPE_SPACING`) and
  `placement_rows.gd` are identical before and after.

## Choices open to overturn

The designer's, kept as given and listed in full in the pull request's description, among them:

- **The roadblock phase's row lives in the context** (`roadblock_row()`), which the item's list did not name.
- **The ground's maker is handed in as a function**, as `PlanBuilder` is handed its three questions.
- **The seed is an integer and the context gives the streams**; `street_bag_seed()` takes the integer.
- **Hand-ins after the constructor**, in the repository's `use_*()` form, not fourteen constructor parameters.
- **One rules object for the scripted phase too**, where it was built with no one-notice rule.
- **The escape's draw loop is handed the context**, and `DayPlanner.plan_the_escape_city()` gains a required builder.
- **Every dawn pass takes the context in this pull request**, the small ones included.
