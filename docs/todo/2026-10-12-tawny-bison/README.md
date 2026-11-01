priority: next

# tawny-bison — A walker slides along a body's edge to a gap across one clear row · filed 2026-10-12


Found by the second review of #727 (M219, on a pedestrian street a blocked walker turns round), not
reported by the player, and the same on `main`. In the test helper of `tests/test_crowd_bodies.gd`
(six walkers, one per lane, walked at the shape for 20 s), a zig-zag with a way through holds
walkers in front of it: bodies in lanes 0–3, then a clear row, then lanes 2–5 hold all six for the
whole run; lanes 0–2 / clear / 3–5 hold one, and lanes 0–1 / clear / 2–5 hold two; lanes 0–2, two
clear rows, then lanes 3–5 hold nobody, so the stall is a shift of three or more lanes inside one
clear row (the review's words). The review's sweep
of 207 precinct blockages on generated days (seed 67 days 1–14 and eight more seeds on days 3, 6, 9
and 12) met no such shape, so no player has stood at one yet.

*The reviewer's reading, not confirmed:* `LaneMover._keep_out_of_a_body()` undoes the sideways part
of a step first, so a walker pressed against a body's edge cannot slide along it to the gap. That
code is shared by every body on every street, and the order is decided: the
[M110 every-solid-body record](../../decisions/2026-09-12-M110-the-crowd-goes-round-a-seal-every-solid-body.md)
gives up "the cross half of the refusal before the along half: refusing both at once wedges a
walker beside a body for good, since its steering target never moves and the identical step is
refused every frame after". Any change keeps that wedge from coming back. The nearest precedent is
the [tall-walrus record](../../decisions/2026-10-07-tall-walrus.md): bollards are circles, so she
slides toward a gap, and head-on she stops.

*Proposed, not asked for:* confirm the cause, then let a walker slide along a body's edge to the gap,
quoting M110 and keeping its wedge out
(or, if that cannot be done without walkers clipping bodies, have M219's reachability walk call such
a shift shut so the walker turns round instead), with a test of the three shapes above. The band
`next` is the filer's.
