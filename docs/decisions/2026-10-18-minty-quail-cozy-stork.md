# minty-quail — Row 3a's readers ask where a plan stands and what it places · 2026-11-20

**What was asked.** Row 3a of minty-quail's `event-interface.md` (the dawn and the walk's ground ask rows and plans):
fields are not API (inbox #1173 in gray-dolphin; **designing-classes**). This pull request (#1590) is the row's "where a
plan stands and what it places", from the Opus design of row 3a (kept in the orchestrator's design folder), built by a
Sonnet agent.

**What was built.** Every reader under `src/` of a plan's `def`, `position`, `path`, `facing`, `gate_state` and `spent`
asks a method. The plan gains `came_at(at)` (streaming's record of where a plan that comes where she stands last came),
`stand_as_the_boom_of(gate)` (the region planner's door boom), and four questions its row answers, `spawn_mode_on(day)`,
`is_sent_ahead()`, `is_a_one_shot()` and `calls_in()`; the row's `calls_in()` asks a new `Aftermath.calls_in()`. The six
fields stay public for the suites and probes, each a `[kept]` line until row 4a. `tools/field_reads.txt` loses
twenty-six lines. The excitement fingerprint and the tick sweep's chain hashes are the same on main and the branch;
nothing a player sees or the run log records changes. Streaming's step measured about 70 µs a tick slower in one run
each side, a noisy reading kept for the end remeasure.

**Open to overturn:** fork F3 of the design (the suites' reads of the six fields wait for row 4a); and the builder's,
where the design was silent: the row asks its aftermath through `Aftermath.calls_in()` rather than reading its field.

**The item.** Row 3a stays open until its last pull request; section 4's rows for the plan's fields and the row's
aftermath say what is built.
