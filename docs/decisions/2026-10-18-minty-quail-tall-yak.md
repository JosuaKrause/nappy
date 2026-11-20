# minty-quail — Row 3b's warnings ask through methods: a pending warning's state is private and the board asks the live event · 2026-11-20

**What was asked.** Row 3b of minty-quail's `event-interface.md` (the event manager's parts): every caller asks an event
through methods and never reads its fields (inbox #1173 in gray-dolphin; **designing-classes**, "Fields are not API").
This pull request (#1578) is the row's warnings part, from the Opus design of row 3b (kept in the orchestrator's design
folder), built by a Sonnet agent.

**What was built.** A pending warning's state (`place`, `offset`, `shown`, `withdrawn`, `on_withdrawn`, `is_pelican`) is
private; callers ask `points_at()`, `shown_for()`, `was_withdrawn()`, `when_withdrawn(retry)` with `ask_again()`, and
`be_drawn_as_the_pelican()`, and the duplicate `left` property is deleted. The live event answers three new questions,
`has_lost_its_guard()`, `core_within()` and `heard_within()`, which the warning board asks with `drives()`,
`closes_on()`, `is_gone()` and `ends_the_day()` instead of reading fields; the board writes its run-log line before
`ask_again()`, so the log keeps its order. The spawner, `EventsAhead`, the suites, rigs and probes ask the methods
(a warning's offset is `points_at()` minus where she stands). `tools/field_reads.txt` loses the fifteen lines the design
names; `tools/test_only_members.txt` loses `left` and `place`, and `PendingWarning.def` stays a kept line for row 4a.
Nothing a player sees or the run log records changes.

**Open to overturn (the builder's, where the design was silent):** `when_withdrawn()` replaces any earlier retry;
the pelican suite asks `logged_name()` where it read `is_pelican`; the kept line's reason names row 4a.

**The item.** Row 3b stays open until its last pull request; section 2.5's pending-warning row names the new questions,
and section 4's list of the folder's classes with listed lines drops `PendingWarning`.
