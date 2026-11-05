# minty-quail — The day-13 guard and the park cordon are tested through what the game itself reads (tests through public seams) · 2026-11-05

minty-quail's `tests-public-seams.md`: `tests/test_day13_guard.gd`, `tests/park_cordon_sweep.gd` and
`tests/test_park_cordon.gd`. Tests only.

**Built.** The day-13 guard suite asks the guard's spot through the public `guard_position()` with
its fallback off, as the move of the task guard to her target asks it, with her standing past the
guard's detour so only the director's on-her-side test can give a spot a way past him: open, a spot
comes back; ringed in by soft seals or by bodies, none does; ring removed, the same spot returns.
The park cordon suites read the way out off the street musician once his escort has sent him
(`way_left()`, which the cordon itself reads), on a copy, since the array is his departure's own and
a walk that drops its points would freeze him in the park; her walk starts a set time after he is
sent off. The cordon's hold on the gap while somebody is still to come out is checked through what
it causes: a leaving escort with no gap stretch taped and the cordon open, and a slow street
musician leaving alone, inside the line and away from the gap stretch, for whom the gap stays
untaped and the cordon open while the tapers owe it its tape; with the hold made to answer no, that
test fails.

**Choices, open to overturn.** Testing the guard through `guard_position()` rather than deleting the
test, and reading the way out off the street musician rather than off the first escort's path
reversed, which may be routed round bodies (the orchestrator's calls). A test where only the
still-to-come-out hold keeps the gap, rather than accepting a behaviour check two other holds also
satisfy, or deleting the hold (the orchestrator's call; deleting it is a change to the game).
