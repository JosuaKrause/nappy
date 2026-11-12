# The event scheduler is broken up: a plan record, a dawn context, and one class per dawn phase

**The ask.** The design review of the refactor (minty-quail) found that the event scheduler
(`src/events/event_scheduler.gd`, the file that plans a day's events at dawn) is a hub of about
3,450 lines and 66 static functions that 65 files under `src/` and 119 test files name, that a dawn
is threaded through 13 positional parameters, and that no item breaks it up. Shown that as "The
event scheduler is a 3,453-line hub that 65 source files and 119 test files name, and no item
breaks it up", the player asked "what is its suggestion on how to break it up?", and, given the
suggestion's three parts (the record of one placed event into its own file; the ground judges and
the density tables moved out; the dawn as a list of phases handed one context object): "agree on
all design review points. let's do it" (inbox #1268 in olive-ferret). The lens is minty-quail's own: "separation of
concerns, composability, cohesion, coupling" (inbox #785 in minty-lemur), and "things will ultimately be
independent" (inbox #845 in minty-dolphin).

**Read as:** the scheduler ends as a short ordered list of the dawn's phases, and each thing it
holds today has a file of its own that can be read, tested and changed alone.

**Build**, the design review's shape, which the player approved ("I saw the review and approved
it", inbox #1268 in olive-ferret); the file-by-file detail was worked out by the same review after the approval, and
the line counts are its estimates. All under `src/events/`:

- **`DawnContext`** (`dawn_context.gd`): the one object every phase is handed, in place of the 13
  parameters: the spec, the day's seed with a stream per salt, the map, the walk (route tree or
  chains) and its corridor, the calm areas and the ground to leave alone, the doors, what stands,
  heat, scars, the spent one-shots, the mast sites, the trace and the plan builder (`PlanBuilder`),
  handed in by the day's planner; and what the dawn builds: the day's events (`DayEvents`), the
  locations (`DayLocations`), the rules built once (`StreetInvalidation`) and the row-ground cache. It is the object that derives the day's facts
  once and is handed around (designing-classes).
- **`dawn_phases/`**, one class per phase with `run(context)`: the fixed parts (ambient rows, masts,
  wall bodies holding their locations), the scars, the roadblock phase's glue with its ground
  judge, the scripted rows, the one-shots, the park spoilers, the lessons and the moments.
- **`RowGround`** (`row_ground.gd`): which tiles a row may stand on, as an object holding its own
  per-day cache. This is the last re-derived case (minty-quail's `re-derived-cases.md`, the ground cache).
- **`RuledLocationGround`** in a file of its own: the judge that offers a row at a location.
- **`event_scheduler.gd`** keeps `build_day(context)` as an ordered list of phases.

Three blocks are not moved, because `placement-by-construction.md` deletes them in place: the old
siting roll, the fitted tables, and the escape's own draw loop. The fallback that grows a route tree
when none is handed in goes with `DawnContext` below, whose shared test helper hands a route to every
call under `tests/` that hands none today. What building a plan at a tile does not do stays in the scheduler:
`recipe_placement()` judges an authored row by the day's locations, the row's ground and `role_for()`, all the
scheduler's, and builds through `LocationFit`, which is handed the builder; `_wants_this_side()` is a ground
question whose one caller, `open_ground_for()`, goes with `RowGround` above; `_band_offset_of()` and its
neighbours read a row's own numbers with no tile; and `blocked_by()` and `block_a_disc()` paint a blocked set for a
flood and build no plan. `PlanBuilder` (`plan_builder.gd`), an object handed the map and the three questions it
asks other classes (inbox #1392 in dappled-wombat), builds every candidate a judge, a siting or a scene recipe
sites at a tile (its facing and its route), the scene recipes' masts and escape actors included.

**The pull requests, interleaved with placement.** Each move regenerates `tools/field_reads.txt`
with `--write`: `--base` passes code reading listed fields moved into a new file with no more uses,
and fails a read that is new; a read that only moved may add its line to the list (inbox #1350 in
grassy-trout), and review reads a moving diff for the cases the check cannot count
(minty-quail-breezy-bison).

- **`RowGround`**: it is a seam, no pure move, since the object with its own per-day
  cache replaces the `ground: Dictionary` threaded through `StreetInvalidation`,
  `RouteJunctionsRule`, `LocationFit`, both ground judges, `_weight_in()`, `_best_of()` and
  `WalkSiting`.
- **`DawnContext`**, after `RowGround`, and
  before the unit draw, so the unit draw edits a small file. The suites and probes that call
  `build_day()` with 13 arguments change once, through one shared test helper that builds a
  `DawnContext`.
- **The phases**, a pull request of their own after `DawnContext`: the context changes a signature
  and every caller, and the phases move code.

Dawn planning's reads of live-event geometry (`standing-layer-breaks.md`) move with their code,
each listed break carried to its new file in `tools/layer_map.py`, and are settled by row 3a of minty-quail's
`event-interface.md`: the row answers for its mover and its standing place. The two a
`PlanBuilder` is handed, `EventInstance.mover_for()` and `EventFootprints.stands_at()`, stay listed
against `event_scheduler.gd`, where the dawn makes its builder, until `DawnContext` is handed a
builder.
