# minty-quail — Row 3b's events' world answers through methods: EventWorld's eight fields go private · 2026-11-20

**What was asked.** Row 3b of minty-quail's `event-interface.md` (the event manager's parts): fields are not API
(inbox #1173 in gray-dolphin; **designing-classes**), and `EventWorld`, the context the event manager hands its own
parts, was read field by field from forty lines. This pull request (#1582) is the row's "the events' world answers
through methods", from the Opus design of row 3b (kept in the orchestrator's design folder), built by a Sonnet agent.

**What was built.** `EventWorld`'s `instances`, `map`, `city_map`, `run`, `player`, `day`, `trace` and `visible` are
private behind `instances()`, `map()`, `city_map()`, `run()`, `player()`, `day()`, `trace()` and `visible_view()`; the
writes are hand-ins (`take_in`, `let_go`, `keep_only`, `let_go_of_every_event`, `use_map(map, city)`, `use_run`,
`use_player`, `take_the_day`, `use_trace`), and `the_city_map()` is deleted with no forwarder. The writes were edited by
hand; a script (in the pull request's description, rerun after any merge of `main`) rewrote the reads in nine files of
`src/events/` and seven suites and probes. `tools/field_reads.txt` loses the forty `[EventWorld]` lines the design
named. Nothing a player sees or the run log records changes. The per-frame cost is measured beside it, base against head.

**Open to overturn (the builder's, where the design was silent):** `visible_view()` rather than `visible()`, which would
read as a yes-or-no question; `use_map()` taking both maps; the `walk_rows` probe handing open ground as the world's map,
as before.

**The item.** Row 3b stays open until its last pull request; section 4 counts `EventWorld`'s eleven remaining listed
lines, its drawing hand-ins, which row 3b's later pull requests take.
