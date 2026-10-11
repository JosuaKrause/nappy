# spotted-wombat — The guard leaves a steady barrier behind · 2026-10-11

[azure-koala](../playtests/2026-10-07-azure-koala.md), finding 4, inbox #601:

> the guard pursuer makes his barrier jump up and down and then dissappear

and, re-reported in [azure-puffin](../playtests/2026-10-10-azure-puffin.md), point 5, inbox #664:

> the guarded barriers disappear after shaking off the pursuer. that doesn't make sense.

**Both symptoms were the guard carrying the barrier with him**, against
[M168](2026-09-19-M168-the-escape-after-playtest-94.md)'s rule that the guard sets off while the band
stays "drawn and solid where it was, so the street stays shut". The jump: a chaser's stride bob lifts
the whole instance's canvas, and the barrier was drawn inside that lift, 2.5px. The disappearance: a
chase that ended called `_finish()`, and `EventManager._retire_finished()` freed the barrier's body
and picture with him.

**The barrier stands for the rest of the day.** `_roadblock_band_at()` cancels the bob, so the band is
drawn on its body every frame. When his chase ends — shaken off, given up — `_stand_as_the_barrier()`
returns the instance to waiting: solid, costing what a barrier costs, his post left empty, and
`_guard_spent` stops him noticing or chasing again. He walks away at his chase pace
(`_leaving_speed()`, since a roadblock has no departure speed of its own) rather than vanishing.
`docs/EVENTS.md` says so. `tests/test_barrier_stays.gd` holds the band still through notice, lunge
and pursuit and the barrier standing after the chase ends; against `main` 11 of its 17 checks fail.
The stills, [barrier-stays-2026-10-11](../evidence/barrier-stays-2026-10-11/), from a day-13 recipe
on seed 11 with a forcing patch, show one guard leaving the band, chasing, shaken off as she runs,
walking away, and the band still standing with his end empty; the stride bob is in the test only.

**Review (#676) changed three things.** The band and the guard posted beside it are their own
y-sorted node (`EventInstance.RoadblockBand`) so they sort at the band's line instead of re-sorting
with the man; the barrier keeps its own field on while he walks away (charged at the band, walled off from the band, with a rim of its own, and he is held to leave out of her sight) rather than going dark for the
walk; and the plan carries the spent guard (`Planned.guard_spent`, `chaser_side`), so a barrier
streamed out and in again comes back as only the barrier, not as a fresh armed roadblock.

*Proposed at filing and built, open to the player's correction:* the barrier stands for as long as the
roadblock would have stood had he never set off, which is the rest of the day since a roadblock has
no lifetime of its own, and the same holds whatever ends his chase. *Chosen where the entry was
silent:* he does not come back for her, and he walks away rather than vanishing.
**Also chosen, and open to overturn:** after the chase the guard still standing at the other post is
a drawing for the rest of the day; nothing notices or chases from the instance again. *Alternative
worth putting to the player:* the guard who chased walks back to his post and the barrier is armed
again.
