## M100 — A hut's hold ends the door guard's chase · built 2026-09-24

*([PLAYTEST-129](../playtests/PLAYTEST-129.md), asked whether a chased mother held at another hut can
be caught during the hold, (a) keep it or (b) let a hold end the chase: "we can try b. if she
voluntarily goes to a hut the whole pursuit has been accomplished".)*

**The moment a `redetains` row starts holding her, the door guard gives up.**
`EventManager._check_detentions()` calls `_end_the_guard_for_a_hold()` right after `start_chat()`
on a `checkpoint_hut` or `checkpoint_post`, which calls the new
`EventInstance.give_up_the_chase()`: `gave_up` set and `_be_done()`, the state `_chase()` reaches
when she outruns him, so the departure, the drawing and the run log's "gave up" line are the
ordinary shake-off's. Four checks in `tests/test_checkpoints.gd`: another hut's hold ends the
chase with no catch, his own hut's does too, the roadblock's heated hunting guard keeps chasing,
and a chase with no hold still catches her. `a` was offered and not taken: she walked into a
checkpoint while wanted, a mistake a player sees coming, at no build cost.

**Open to overturn** (choices where the answer was silent): any hut counts, the one he came out
of included, and an alley post counts as a hut; a guard still in his 1.8 s notice gives up too;
only `door_guard` is reached, so the roadblock guard and the masked pursuer (a fixed-path row
with no chase state) keep going through a hold. It is a trial ("we can try"), and its question
is in `REVIEW.md`.
