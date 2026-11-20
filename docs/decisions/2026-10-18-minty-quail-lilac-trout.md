# minty-quail — Row 3b's manager is handed what it needs through methods, not setter properties · 2026-11-20

**What was asked.** Row 3b of minty-quail's `event-interface.md` (the event manager's parts): a component is handed what
it depends on, and fields are not API (**designing-classes**; inbox #1173 in gray-dolphin). This pull request (#1579)
is the row's "the manager is handed what it needs through methods", from the Opus design of row 3b (kept in the
orchestrator's design folder), built by a Sonnet agent.

**What was built.** The event manager's setter properties become methods: `use_protest_target()` (was `points_at`,
written by the resistance director), `use_trace()`, `use_timing()`, `use_atlas()`, `draw_nothing()` (was
`skip_drawing`), `stream_within()` (was `stream_radius`), `rig_the_pelican()` (was `pelican_rig`), `use_planner()`
and `excitement_sources()` (was `sources`). Streaming answers `advance_the_broadcast()`, `use_the_spent_one_shots()`,
`stream_within()` and `stream_radius()`, and the spawner `rig_the_pelican()`, their
fields private. `SimulationBuilder`, `WorldSimulation` and `ResistanceDirector` call them; the run log's observer
loses its opt-out line, so it is typed; the suites, rigs and probes follow by script. `tools/field_reads.txt` loses the
design's twelve lines. Nothing a player sees or the run log records changes.

**Open to overturn (the builder's, where the design was silent):** no `stream_radius()` on the manager, since only a
suite would read it (the suite asks streaming's); two pelican-rig checks ask `spawner.rolls_a_pelican()`, and an ordinary
run's guard (no `--pelican`, so not every cyclist is the pelican) is held by drawing a full bag through the builder's
spawner and finding exactly one; the masts' shared clock is held by `test_masts` comparing two masts' own ages, so
streaming has no `broadcast_clock()` and no kept line; suite reads of the manager's old `trace`, `atlas`, `timing` and
`skip_drawing` go through the events' world until row 3b's pull request that converts it.

**The item.** Row 3b stays open until its last pull request; `field-reads.md` loses the run log's observer from its
untyped files, and row 3c no longer lists `EventManager.points_at` as left in the resistance.
