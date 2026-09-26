## M191 — The horn watches as far as the contract needs · built 2026-09-24

*(Found while measuring M183's dark junctions, not asked for by a playtest.)*

**What was wrong.** The traffic fairness contract says a car on a street she may step onto sounds
its horn early enough for her to walk the whole carriageway with the doubled hard-fail margin
(`Tuning.validate_traffic()`, 1.39 s required against `CAR_HORN_TIME`'s 1.6 s). But
`Crowd._physics_process` watched her for the horn, the strike and the give-way scan through one
gate, `CAR_ZEBRA_SIGHT` (200px), so a car's warning was capped at 200px of travel whatever its
speed. Above 144px/s that is shorter than the contract, and cars run 130 to 185px/s: first horns
at 198 to 199px, 1.27 s at 157px/s and 1.10 s at 181px/s. The check passed because it read only
the tuning numbers, never the watch.

**What was built.** A second watch, `Tuning.CAR_HORN_SIGHT` (296px, exactly
`CAR_SPEED.y × CAR_HORN_TIME` for the fastest car, no padding), used only for the horn; the strike
and the give-way scan keep `CAR_ZEBRA_SIGHT`. `_horn()` still caps its own warning at the car's
`speed × CAR_HORN_TIME`, so a slower car does not honk any earlier than its speed asks.
`validate_traffic()` now also fails at boot if `CAR_HORN_SIGHT` is short of
`required_horn_sight()`. The same distance query serves both watches; the added `_horn()` calls
measured about 1.7 µs each, at most about 58 µs a frame with a day's 34 cars all in range.

**Measured.** `tests/probes/m191_horn_watch.gd` prints first-horn distance and time per speed from
the code's own formula (`min(speed × CAR_HORN_TIME, watch)`): before, every speed from 130 to
185px/s was clipped at 200px (1.54 s down to 1.08 s); after, every speed gets 1.60 s (208 to
296px). `tests/test_crowd.gd` drives the real `_physics_process` with a live car beyond 200px to
check the wiring rather than the constants alone.

**Open to overturn** (the agent's choices where the design was silent): the watch has no margin
above the fastest car's need; the give-way scan stays at 200px, since nothing asked for it to
widen; the probe's tables are the formula rather than a measured run.
