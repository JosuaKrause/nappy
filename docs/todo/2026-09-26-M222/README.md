## M222 — The red arrow for the van ends on the van · found 2026-09-26

> "the red arrow for the van does not end on the van"

[PLAYTEST-143](../../playtests/PLAYTEST-143.md), statement 8. The task arrow points at the contact's
position (`ResistanceDirector.red_arrow_target()`). On a task performed at an event, the contact
rides the event at an offset (`_reachable_offset()`: its `obstructs_radius` plus her body plus the
contact's reach), so it stands beside day 7's delivery van, not on it. The offset keeps the touch
point where she can reach it, and that stays. The arrow is what moves.
