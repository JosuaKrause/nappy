## M53 — The precinct is for walking · built 2026-09-02

*(2026-09-02: "there should be no zebra cross markings or cars in a pedestrianized precinct — all
roads leading up to a precinct should be t-junctions at the edge nothing should go in.")*

**The question that produced this should never have been asked.** The queue carried the item as
*two recorded instructions in tension, and the player decides*. Only one of them was recorded —
playtest 16's finding 2, which already named both answers. The other was
`CityGenerator._street_tile`'s own docstring defending what the code did, and a docstring is
evidence of what was **built**, never of what was **agreed**. The player's reply was *"where does
that question even come from?"*, and the answer is: from this side treating the two as equals.

**Two halves, and neither is correct without the other**, which is why they are one commit. Paving
the junction box removes the zebra; on its own it would have left a car on the crossing street
driving over unmarked pavement, which is worse than the paint and invisible. `is_driveable_at` now
asks **both** corridors that meet at a tile rather than only the one the car is following.

**The drawing needed no code at all.** The ground painter already gives any tile in a precinct band
the precinct's brick, so the repainted tiles picked it up — the shot in `docs/evidence/`
(`shot-2026-09-02-seed4242-4442e68-precinct-street-ends.png`) is the carriageway ending flush at the
paving with no zebra and no car in the band.

**M49's *junctions are four-way where an arm dead-ends* did not reproduce here, and structurally
cannot.** Once either corridor is a precinct the whole box is one flat sheet of paving with no
per-arm kerb or line art, so there is no directional drawing left to be wrong. Three candidates ruled
out, entry still open.

**The wall-share floor moved from 25% to 20%, and the first attempt at it was the wrong shape.**
`tests/test_events.gd` asserts that a real share of the gaps between adjacent route strands carry an
off-corridor wall. Measured on the same map and the same sampled days, that share fell from 26 of 89
to 21 of 89 once the box was paved: the rows that place on a carriageway — the patrol, the
checkpoint — cannot sit in a gap running through a precinct. *Rejected: taking those gaps out of the
denominator, which is what the check's meaning would want.* It cannot be determined honestly from
geometry — `EventScheduler._role_for` assigns the `WALL` role from a row's cost and lethality and
never consults where the row may be placed, and most rows place on `SIDEWALK`, which a precinct gap
still has. Answering *"could anything have walled this gap"* properly means cross-referencing every
active day's wall-eligible defs against their placement lists, machinery the rig does not have. An
exclusion built on geometry alone would have been wrong in the same direction as an unexplained
floor, with a better disguise. So the floor moved with the measurement recorded beside it — and the
direction is the design rather than a loss: fewer walls in the one stretch of city whose whole point
is that it is the safest ground in it.

**Found and not fixed**, filed in `TODO.md`: seed 24757 has two non-walkable tiles inside a precinct
span, because something with a footprint was placed across the corridor — pre-existing, and caught
by the new generation test rather than caused by it. And nothing in the game **draws a bollard**,
though six comments and two doc sentences explain a precinct by saying a driver meets a bollarded
street: the carriageway ends flush against paving, which reads as the road running out rather than
as a street closed on purpose.
