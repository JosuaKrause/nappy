# minty-quail — Row 3b's manager starts a walk through methods and is set up once · 2026-11-20

**What was asked.** Row 3b of minty-quail's `event-interface.md` (the event manager's parts): fields are not API
(inbox #1173 in gray-dolphin; **designing-classes**). This pull request (#1586) is the row's "the manager starts a walk
through methods, and is set up once", from the Opus design of row 3b (kept in the orchestrator's design folder), built
by a Sonnet agent.

**What was built.** The day planner's plan (`DayPlanner.Plan`) keeps its placements, walk, doors and whether it belongs
to a day private, given by its constructor and asked through `placements()`, `walk()`, `doors()` and
`belongs_to_a_day()`. The day spec answers `owes_her_a_return()` and `sends_a_pursuer_for_a_torn_poster()`, and
`EventsAhead.use_the_walk_of(spec)` takes both settings from the spec, so the manager writes neither. The manager asks
the encounter watch `count_under(day)`, the visible view `use_cover()`, and the stroller `is_carrying()` and
`facing_direction()`. `setup_world()`'s seven resets and `EventsAhead.drop_director()` are deleted: a manager is set up
once, for one world, which the builder already does, and `setup()` and `setup_world()` assert it. The manager's
opt-out line goes, so it is typed. `tools/field_reads.txt` loses eleven lines. Nothing a player sees or the run log
records changes.

**Open to overturn:** fork F3 of the design (the seven resets deleted together and the set-up-once rule asserted,
rather than kept); and the builder's, where the design was silent: `VisibleView.controls` made private, and `[kept]`
lines for four day-spec fields (until row 3b's last pull request) and the stroller's `carrying` and `facing` (rather
than converting their 35 suite reads here).

**The item.** Row 3b stays open until its last pull request; its note on the seven resets is settled, and
`field-reads.md` drops the manager from the untyped files and says what of the day spec, the stroller and the visible
view is left.
