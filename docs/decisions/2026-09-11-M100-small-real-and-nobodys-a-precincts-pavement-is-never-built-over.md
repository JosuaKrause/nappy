## M100 — Small, real, and nobody's · a precinct's pavement is never built over, 2026-09-11

The defect as queued: on seed 24757 two tiles inside a precinct span were not walkable because a
footprint had been placed across the corridor the span runs down, and `CityGenerator.
_place_hard_blockers` never read `precinct_spans`. One agent commit on `feature/precinct-pavement`,
reviewed here. **The gap was wider than the entry said**: by the time it was built the two tiles
were eighteen, and the larger share was not a big building at all but an apartment complex —
`_zone_fits`, the one gate open calm zones and complexes share, had no precinct clause, and a
complex absorbs its inner streets solid the way a big building's mass does. The fix is the
constraint the entry asked for, at candidate time on both gates: `_the_pair_is_free` (big
buildings) and `_zone_fits` (zones and complexes) refuse any footprint overlapping a precinct
span's own tile rect, the "core" band the existing precinct test already measures rather than the
widened crossroads tail, before the candidate is accepted — never a repair afterwards. **Left
alone on purpose**: dead ends, whose existing check on the removed segment's street kind already
excludes a precinct corridor (a straight segment's tile rect cannot overlap a precinct on the
crossing axis, since a block interior's tile range excludes every corridor column), and
single-block calm, which structurally cannot touch precinct ground. Measured over a hundred seeds
the constraint costs no generation retries — the average stays one attempt per city. The older
precinct test lost the carve-out that had excused a hard blocker on the band, so both precinct
tests now assert every tile walkable with nothing excused, and the new one pins seed 24757.
**Merging main after M101 and the seals-nothing fix broke `tests/test_events.gd`'s held-ground
test on the merge result and nowhere else**: it asserted the sampled days' closure, boundary,
checkpoint and seal totals against four remembered numbers, and a footprint refused on precinct
ground is a different city on the same seed, so three of the four moved (456 → 453 boundary
segments, 396 → 377 checkpoint bodies, 5320 → 5242 seals). Re-measuring would have made the test
fail on every later generator change while saying nothing about holds, so it now asserts by
comparison — the seals planned twice on the same seeded stream, with and without the `held`
out-param, must be the same size, and the other planners only have to have placed something —
which is the claim the test was always making.
