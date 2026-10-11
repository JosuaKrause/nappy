# grassy-alpaca — A crowd car is lethal only in front of it while it drives · 2026-10-11


[minty-hedgehog](../playtests/2026-10-03-minty-hedgehog.md), statement 4, note #433:

> cars should only be lethal in front of them while they're driving. if they're standing still they are good. except for noise

and, asked what "in front" covers:

> when I walk behind a standing car right now and it starts moving I die -- that is not correct the car is driving away from me

**A standing car was already harmless; the box was the fault.** `Crowd._strike()` and
`CrowdAgent.will_be_lethal()` already returned false below `CAR_STRIKE_MIN_SPEED` (20 px/s), but the
strike box was symmetric about the car's centre (|along| ≤ `CAR_STRIKE_HALF_LENGTH` 26px, |across| ≤
`CAR_STRIKE_HALF_WIDTH` 14px), so its rear half killed her behind a car pulling away.

**The box now runs from the car's centre forward**, the same width: the front half and its sides.
`Crowd._strike()` rejects anything behind the centre, and `CrowdAgent.will_be_lethal()`, the
prediction behind the red caret, uses the same box, solved along the car's heading rather than
sampled every 0.25s, since at 185 px/s a car crosses more than the 26px front box between samples.
The debug strike-box layer draws the front half; `docs/MECHANICS.md` and the `tuning.gd` comment say
so. The horn already sounded only ahead. `car_turn.gd` uses `CAR_STRIKE_HALF_LENGTH` as the body's
half length for its tail swing, and the body is still symmetric, so it is unchanged. Crowd cars only:
the event vehicles keep their own rows, and [sunny-finch](2026-10-07-sunny-finch.md) already built
the police car the same way. `tests/test_car_front.gd` holds the rear half and its sides safe, the
front half and its sides lethal, the prediction agreeing, a car setting off away from her standing
just behind it never striking, and one driving at her still striking. The still,
[car-front-2026-10-11](../evidence/car-front-2026-10-11/), shows the debug box over the front half of a
southbound car.

*Proposed at filing and built, open to the player's correction:* the box keeps its width and covers
the front half and its sides; crowd cars only. *Chosen where the entry was silent:* a point exactly
at the car's centre counts as in front.
