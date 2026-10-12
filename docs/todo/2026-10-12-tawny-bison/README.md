priority: next
after: 2026-09-26-M219

# tawny-bison — A walker slides along a body's edge to a gap three lanes over · filed 2026-10-12


Found by the second review of #727 (M219, on a pedestrian street a blocked walker turns round), not
reported by the player, and the same on `main`. In the test helper of `tests/test_crowd_bodies.gd`
(six walkers, one per lane, walked at the shape for 20 s), a zig-zag with a way through holds
walkers in front of it: bodies in lanes 0–3, then a clear row, then lanes 2–5 hold all six for the
whole run; lanes 0–2 / clear / 3–5 hold one, and lanes 0–1 / clear / 2–5 hold two. The review's sweep
of 207 precinct blockages on generated days (seed 67 days 1–14 and eight more seeds on days 3, 6, 9
and 12) met no such shape, so no player has stood at one yet.

*The reviewer's reading, not confirmed:* `CrowdAgent._keep_out_of_a_body()` undoes the sideways part
of a step first, so a walker pressed against a body's edge cannot slide along it to a gap more than
two lanes over. That code is shared by every body on every street.

*Proposed, not asked for:* confirm the cause, then let a walker slide along a body's edge to the gap
(or, if that cannot be done without walkers clipping bodies, have M219's reachability walk call such
a shift shut so the walker turns round instead), with a test of the three shapes above. The band
`next`, and waiting on M219, whose walk it would change, are the filer's.
