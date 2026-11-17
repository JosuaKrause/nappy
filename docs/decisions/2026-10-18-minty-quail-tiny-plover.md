# minty-quail — the calm-rect wrapper is deleted, and its probe calls the function it wrapped · 2026-11-17

The dead-code sweep (`docs/todo/2026-10-18-minty-quail/dead-code-sweep.md`) named
`EventScheduler._calm_rect()` as code nothing under `src/` reaches.

**Built.** `EventScheduler._calm_rect(map, block)` is deleted with its doc comment. It was a one-line
wrapper over `ClosurePlanner.calm_area_rect(map, block)`, the function that gives a calm block's calm
ground (its open rect, falling back to the whole lot). `tests/probes/m97_spoilage.gd` now calls
`ClosurePlanner.calm_area_rect` directly, which returns the same rect, so the probe measures the same
thing. The comment above `calm_area_rect` in `src/routes/closure_planner.gd` no longer cites the
deleted wrapper; it names the probe as the other asker of the question.

**What reached it last.** Under `src/`, its last caller was a private helper that picked calm tiles
she had not used. That helper was removed by commit `432ab2a6b` (#1169, "one reader for the walk's
plans"), which took its one call out of `src/events/event_scheduler.gd`. Since then the only caller
has been the M97 spoilage probe (added in `107fd4ca2`).

**Rejected.** Deleting the probe as well. The M97 record
(`docs/decisions/2026-09-23-M97-calm-areas-that-hold-is-closed.md`) keeps
`tests/probes/m97_spoilage.gd` as the instrument for spoilage, so only its call changed.

**Still open.** The rest of the dead-code sweep item stays open, with its remaining lines.
