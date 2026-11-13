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

- **`dawn_phases/`**, one class per phase with `run(context)`, each handed the day's `DawnContext`
  (`src/events/dawn_context.gd`, the one object every pass takes in place of `build_day()`'s parameters): the fixed parts (ambient rows, masts,
  wall bodies holding their locations), the scars, the roadblock phase's glue (its ground judge,
  `RuledRoadblockGround`, already stands in `dawn_phases/`), the scripted rows, the one-shots, the park spoilers, the
  lessons and the moments.
- **`event_scheduler.gd`** keeps `build_day(context)` as an ordered list of phases.

Three blocks are not moved, because `placement-by-construction.md` deletes them in place: the old
siting roll, the fitted tables, and the escape's own draw loop. What building a plan at a tile does not do stays in the scheduler:
`recipe_placement()` judges an authored row by the day's locations, the row's ground (`RowGround`) and
`role_for()`, and builds through `LocationFit`, which is handed the builder; `_band_offset_of()` and its
neighbours read a row's own numbers with no tile; and `blocked_by()` and `block_a_disc()` paint a blocked set for a
flood and build no plan. `PlanBuilder` (`plan_builder.gd`), an object handed the map and the three questions it
asks other classes (inbox #1392 in dappled-wombat), builds every candidate a judge, a siting or a scene recipe
sites at a tile (its facing and its route), the scene recipes' masts and escape actors included.

**The pull requests, interleaved with placement.** Each move regenerates `tools/field_reads.txt`
with `--write`: `--base` passes code reading listed fields moved into a new file with no more uses,
and fails a read that is new; a read that only moved may add its line to the list (inbox #1350 in
grassy-trout), and review reads a moving diff for the cases the check cannot count
(minty-quail-breezy-bison).

- **The phases**, two pull requests: the dawn's opening phases (the base class, the list in `build_day()`, and the
  ambient rows, the scars, the masts, the wall's bodies, the calm area kept clean and the roadblocks), then its other
  phases (the scripted rows, the one-shots, the park spoilers, the moments, the dawn draw, the run lesson and the
  roadblock count), after which `build_day()` is the list alone. Each moves code out of `event_scheduler.gd`, each
  phase taking the `DawnContext` the dawn's passes already take.

Dawn planning's reads of live-event geometry (`standing-layer-breaks.md`) move with their code,
each listed break carried to its new file in `tools/layer_map.py`, and are settled by row 3a of minty-quail's
`event-interface.md`: the row answers for its mover and its standing place. The two a
`PlanBuilder` is handed, `EventInstance.mover_for()` and `EventFootprints.stands_at()`, are named only
where a city's builder is made: by the event manager, whose builder the day's planner hands the
`DawnContext`, and by the scene recipes' runtime (`src/dev/scene_recipe_runtime.gd`).
