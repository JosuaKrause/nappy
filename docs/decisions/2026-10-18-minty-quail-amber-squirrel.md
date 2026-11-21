# minty-quail — The live event is handed everything in one setup call: row 3b · 2026-11-20

**What was asked.** Row 3b of minty-quail's `event-interface.md` (the event manager's parts): the spawner hands a live
event everything in one setup call, so nothing writes a live event's members after it is made; fields are not API
(inbox #1173 in gray-dolphin; **designing-classes**). This pull request (#1593) is the row's "the live event is handed
everything in one setup call", from the Opus design of row 3b (kept in the orchestrator's design folder), built by a
Sonnet agent.

**What was built.** `EventSurroundings` (`src/events/event_surroundings.gd`, simulation) is what every live event of a
world is set up in: the map, the navigator, where she is, the world it is drawn in, the atlas and drawer, whether it
draws, the timing sink, the trace, the car's lights and where a protest points. `EventInstance.setup(row, at, route,
face, surroundings, gate)` is the one setup call, the gate (the plan's shared boom state) last. The live event's
`skip_draw`, `timing`, `atlas`, `drawer`, `trace`, `signals`, `points_at` and `gate_state` are private; `EventBody` is
handed the gate in its constructor; `EventBehaviours.compose()` hands the car the lights, and `Figure.lights()` is gone.
The events' world builds one surroundings per live event (`surroundings()`), its hand-ins private behind
`use_lights()`, `draw_nothing()`, `use_timing()`, `use_atlas()`, `use_protest_target()` and a new `use_drawer()`; the
spawner's eight member writes are gone, and streaming hands `plan.gate()` to `create()`. A script rewrote 132 setup
calls in 58 suite and rig files and moved 39 member writes into the chain or the gate argument; the rest were done by
hand and the pull request lists them. Nothing a player sees or the run log records changes.

**Also built, owed by row 3b.** The spawner's warning of the row a source calls in asks `source.calls_in()` instead of
reading `source.aftermath.on_sight`, and two lines leave `tools/field_reads.txt`.

**Open to overturn, the builder's where the design was silent:** the question is `world_drawn_in()`, since GDScript
cannot name a builder `drawn_in(world)` and a question `drawn_in()` alike; `EventWorld.use_drawer()`, a hand-in for the
suites' recording drawer, kept with its reason in `tools/test_only_members.txt`; the suites read what an event drew
through `DrawnEvent.recording()` and `drawer_of()`, which keep the drawer as node meta in the rig; the events' world's
`_where_protests_point` is private, read by suites through `surroundings()`.

**The item.** Row 3b stays open: its saving and restoring as one value, streaming's own state per plan, and the live
event's age are left. Section 4.2's rows for the live event's hand-ins and gate, row 2a's left items and row 3b say
what is built.
