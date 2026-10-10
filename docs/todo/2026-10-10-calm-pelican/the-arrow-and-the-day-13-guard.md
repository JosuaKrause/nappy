# Day 13's arrow and the task's waiting guard agree

**Medium, a question for the player · from the re-review of PR #588 (plush-moose, every task has a
red arrow, on the closest target by walking distance).** [Feathery-badger](../../decisions/2026-10-04-feathery-badger.md)
keeps a guard around day 13's seeded roadblock ("Every guarded target (Recommended)"), placed in
`ResistanceDirector._begin_step()` and never moved, but the arrow chooses among every live roadblock
(`_arrow_candidates()`; 14 to 20 on day 13 by the cost probe), so it can point her at one with no
guard. How often was not measured. The comment above `_follow_her_between_look_alikes()` still says
the guard "is not moved when she picks another".

**Open, for the player:** should the guard follow the roadblock the arrow chooses? If yes, move or
re-place `_task_guard` on it; if no, record in [plush-moose](../../decisions/2026-10-04-plush-moose.md)
and that comment that the guard stays on the seeded roadblock.

**Low, same area:** no picture shows day 11 with several masts answering, since a scene recipe
cannot give an authored loudspeaker a mast id; let a recipe give one a `mast_id` and capture day 11
with the arrow moving between two masts. And reflow the `TASK_ARROW` comment in `src/palette.gd`,
which leaves one word alone on a line.
