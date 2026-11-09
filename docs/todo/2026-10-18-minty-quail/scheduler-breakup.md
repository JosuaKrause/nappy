# The event scheduler is broken up: a plan record, a dawn context, and one class per dawn phase

**The ask.** The design review of this entry found that the event scheduler
(`src/events/event_scheduler.gd`, the file that plans a day's events at dawn) is a hub of about
3,450 lines and 66 static functions that 65 files under `src/` and 119 test files name, that a dawn
is threaded through 13 positional parameters, and that no item breaks it up. Shown that as "The
event scheduler is a 3,453-line hub that 65 source files and 119 test files name, and no item
breaks it up", the player asked "what is its suggestion on how to break it up?", and, given the
suggestion's three parts (the record of one placed event into its own file; the ground judges and
the density tables moved out; the dawn as a list of phases handed one context object): "agree on
all design review points. let's do it" (inbox #1268). The lens is the entry's own: "separation of
concerns, composability, cohesion, coupling" (inbox #785 in minty-lemur), and "things will ultimately be
independent" (inbox #845 in minty-dolphin).

**Read as:** the scheduler ends as a short ordered list of the dawn's phases, and each thing it
holds today has a file of its own that can be read, tested and changed alone.

**Build** (*the shape is the design review's, proposed and not asked for, open to the player's
correction; line counts are its estimates*). All under `src/events/`:

- **`EventPlan`** (`event_plan.gd`): today's inner class `EventScheduler.Planned`, one placed
  event's row, position, role and path, which 46 source files and most of the tests name.
- **`DawnContext`** (`dawn_context.gd`): the one object every phase is handed, in place of the 13
  parameters: the spec, the day's seed with a stream per salt, the map, the walk (route tree or
  chains) and its corridor, the calm areas and the ground to leave alone, the doors, what stands,
  heat, scars, the spent one-shots, the mast sites and the trace; and what the dawn builds: the
  day's events (`DayEvents`), the locations (`DayLocations`), the rules built once
  (`StreetInvalidation`) and the row-ground cache. It is the object that derives the day's facts
  once and is handed around (designing-classes).
- **`dawn_phases/`**, one class per phase with `run(context)`: the fixed parts (ambient rows, masts,
  wall bodies holding their locations), the scars, the roadblock phase's glue with its ground
  judge, the scripted rows, the one-shots, the park spoilers, the lessons and the moments.
- **`RowGround`** (`row_ground.gd`): which tiles a row may stand on, as an object holding its own
  per-day cache. This is the last re-derived case (`re-derived-cases.md`, the ground cache).
- **`PlanBuilder`** (`plan_builder.gd`): builds a plan at a tile: the side and band offsets, the
  along-street paths, the body's disc, an authored scene's placing. The resistance's happenings
  stop calling a private function of the scheduler.
- **`RuledLocationGround`** in a file of its own: the judge that offers a row at a location.
- **`event_scheduler.gd`** keeps `build_day(context)` as an ordered list of phases.

Three blocks are not moved, because `placement-by-construction.md` deletes them in place: the old
siting roll, the fitted tables, and the escape's own draw loop. The fallback that grows a route tree
when none is handed in goes with the one in the day planner (`city-hand-ins.md`).

**The pull requests, interleaved with placement:**

- **The rename of the plan record**, a pull request that is the scripted rename and nothing else,
  with the script in its description so a branch merging main reruns it. No forwarder is kept for
  the old name (inbox #852 in minty-dolphin).
- **`PlanBuilder` and `RowGround`**, pure moves, beside placement's route ground rule.
- **`DawnContext` and the phases**, after the route ground rule and before the unit draw, so the
  unit draw edits a small file. About forty suites call `build_day()` with 13 arguments; they
  change once, through one shared test helper that builds a `DawnContext`.

Dawn planning's reads of live-event geometry (`standing-layer-breaks.md`) are settled where their
code moves.
