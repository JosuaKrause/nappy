# minty-quail — The scene recipe runtime asks events, rows and plans through methods (event interface row 3c) · 2026-11-18

**What it is.** The scene recipes' part of row 3c of minty-quail's `event-interface.md`, the row's
last: the scene recipe runtime (`src/dev/scene_recipe_runtime.gd`, which stages events for an
authored scene) asks rows, plans, live events, the event manager, contact points, the happenings and
the zoom-out camera through methods. An Opus builder built it to the design. Nothing changes in play,
in a staged scene or in the logs. With it, row 3c's reads of the events are all built.

**What was built.** The runtime commands events, so it is the caller the design hands the live event
to: `EventManager.event_of(plan)` is added for it (inbox #1278 in olive-ferret: the manager hands out
the live event only to a caller that commands it; #1541 had removed it while nothing commanded). New
methods, additions only: on the row `pursues()` and `parks_where_it_arrives()`; on the plan
`telegraphs_for()` (the escape stages the walk bag's variant row, not the catalogue row the recipe
names) and `stand_as_a_mast(id)`; on the live event `forget_her_run()` (with `EventPursuit`'s),
`walks_straight_away()` (the three departure tests) and `hold_by_hand()`; on the happenings
`column_trucks()`; on the zoom-out camera `use_simulation_clock()`, its field now private.
`tools/field_reads.txt` lost 31 lines and gained none; `tools/test_only_members.txt` gained six kept
lines, four for fields only tests read now and two the check matched by name through the runtime's
untyped reads.

**Where the design was silent or departed from.** `arrive_aged()` also sets the age a repeating
plan restarts at; no row a recipe places repeats, so the answer is the same. The names
`forget_her_run()`, `hold_by_hand()` and `walks_straight_away()` are the builder's, since 2.8 names
nothing for those commands. `src/dev/zoom_out_camera.gd` and one write in `tests/test_trailer_flags.gd`
were changed for the camera's hand-in, past the brief's literal fence, since the brief named
`simulation_clock`.

**Left in the runtime:** the row's `id` (4b); the city's, the city map's and the world map's fields
(the scene recipes' own pass with `AuthoredScene`); the calls to the private
`EventDirector._crossing_ahead_of()` (3b) and `ResistanceHappenings._bring_the_column()`.

**Proposed, not asked for, open to the player:** the departures above; the method names.
