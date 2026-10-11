# downy-lark — Leaving a gatehouse, she stands still · 2026-10-11

[azure-puffin](../playtests/2026-10-10-azure-puffin.md), inbox #667:

> oh and there is a bug when leaving the guard huts that the player keeps moving in the previous
> direction. let's reset the movement to 0 when leaving so the player has a choice.

**The cause.** The gatehouse's release already zeroed her velocity, but the controls still held
the old heading: a key physically down, or the heading a tap or a joystick drag had locked into the
`move_*` actions. The next physics frame read it and carried her on, in every control mode. A tap
locks a heading, not a target, so there was no tap target to drop.

**The hold's end resets her movement to zero.** `Stroller.show_after_inspection()`, which
`EventManager` already calls when a hold lets her out, zeroes her velocity and calls
`TouchControls.stand_still_after_hold()` through the `touch_controls` group, which drops the locked
heading (a finger still down re-steers by moving). The stroller also remembers the raw input still
held at the release and reads it as zero until it is released or changes. It holds for every
`redetains` hold, the street doors' gatehouses and the alley guard's, since they are one mechanism;
`docs/MECHANICS.md`'s hold paragraph says so. `tests/test_checkpoints.gd`
(`_test_she_stands_still_when_a_hold_lets_her_out`) walks her into a hut with the heading held by a
key, a tap and a joystick drag, runs the hold, and checks she has not moved a frame after the release
and that a new input moves her; without the fix all three leave her at (-92, 0) px/s.

*Proposed at filing and built, open to the player's correction:* a held input is ignored until
released or changed, in every control mode, for every `redetains` hold. *Chosen where the entry was
silent:* "changed" means the held direction differs, so letting go of one of two held keys counts as
a new choice and moves her.
