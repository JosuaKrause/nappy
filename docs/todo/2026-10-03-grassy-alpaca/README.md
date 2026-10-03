priority: now

# grassy-alpaca — A car is lethal only in front of it while it drives · filed 2026-10-03

> "cars should only be lethal in front of them while they're driving. if they're standing still they
> are good. except for noise" · "when I walk behind a standing car right now and it starts moving I die
> -- that is not correct the car is driving away from me"

[minty-hedgehog](../../playtests/2026-10-03-minty-hedgehog.md), statement 4 (note #433, and the player's answer when asked what "in front" covers). **A car
kills only what is ahead of it while it drives.** A standing car is already harmless with its noise
kept: `Crowd._strike()` and `CrowdAgent.will_be_lethal()` return false below
`CAR_STRIKE_MIN_SPEED` (20 px/s), and its noise field does not depend on speed. What is wrong is the
strike box, symmetric about the car's centre (|along| ≤ `CAR_STRIKE_HALF_LENGTH` 26, |across| ≤
`CAR_STRIKE_HALF_WIDTH` 14): the rear half kills, so she dies behind a car that pulls away from
her. `docs/MECHANICS.md` ("A car is lethal") already says "in front of a moving car", which the code
does not match; the horn already sounds only ahead.

**Proposed, not asked for:** the box keeps its width and covers only from the car's centre forward,
the sides of the front half included; crowd cars only, since the event vehicles each have their own
row (the reversing lorry's danger is behind it); a test where a car starts away from her standing
behind it.
