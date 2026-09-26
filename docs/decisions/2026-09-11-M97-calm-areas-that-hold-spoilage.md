## M97 — Calm areas that hold · spoilage measured 2026-09-11

*(Playtest 20, 2026-09-03: "the spoilage of a clam area is not always effective I went to the
same park 4 times and only the last time had a high enough density of events to actually prevent
me from using it. the previous time I could just walk at the edge of it. and the time before that
didn't have any spoilage at all even though it was the second visit.")* The entry's first task was
a reproduction before any fix; `tests/probes/m97_spoilage.gd` is the instrument, on
`feature/measurements-m97-m99`, and it did not reproduce. Over 8 seeds, settle days 1, 4, 8 and
12, and every calm block — 243 biased visits — no visit was structurally empty: the spoil roll
alone denied a mean 95.9% of the lot's open ground, the full day 96.5%, and 234 of 243 visits were
over two thirds denied. Two visits fell under 15% denied, both the weighted roll drawing one
low-reach row for a large lot — the "walkable edge" the player described, now a 0.8% tail. The
day's ordinary fill placed more in the used park than the spoil roll did on 93.4% of visits, so the
bias is mostly backstopped by incidental placement rather than doing the denying itself. **What
this leaves open** is a played recurrence: the probe re-runs in seconds, the low-reach draw is the
suspect, and the fix it points at is a floor on the spoil roll's reach for a lot that size, not a
density change. Nothing in `src/` changed.
