# Playtest 37 — 2026-09-08

Notes given in one conversation, on the capture M53's bollards were reviewed with
(`docs/evidence/archive/session-captures/2026-09-08/rig-190124-seed4242-v0.7.0-2-g7f9cc02-dirty/bollards-precinct-mouth.png`,
seed 4242, the shore precinct's west mouth). One finding, and it is a re-report: the bollards were
built as if the complaint were *nothing marks the closure*, and the complaint was that **a
crossing is painted where no road is**.

---

## 1. The zebra at the edge of the precinct should not be there

> "the original complaint was that there is a zebra crossing at the edge of the precinct which
> shouldn't be there"

> "we can keep the bollards but it doesn't address the complaint"

**What the capture shows.** The crossroads west of the posts is a full four-way: zebras on the
north and south arms across the crossing street, a zebra on the west arm across the precinct
corridor's road where it continues west — and a zebra on the **east** arm, across a road stub that
runs one pavement's width past the junction box and stops at the bollards. Nothing drives on that
stub and nothing has to be crossed there.

**This is the 2026-09-02 instruction read back, and it was only half built.** *(2026-09-02: "there
should be no zebra cross markings or cars in a pedestrianized precinct — all roads leading up to a
precinct should be t-junctions at the edge nothing should go in.")* M53 paved the junctions
**inside** a span — a street crossing a precinct meets paving, no zebra, the box reads as a T — and
left the crossroads at each **end** of the span as an ordinary four-way, because
`CityGenerator._street_tile` asks `CityMap.street_kind_at()` and a span *"stops short of the
crossroads at either end"*. So the arm that leads into the precinct is laid as a crossing over a
carriageway that ends a tile later.

**The bollards stay.** They were asked for as the smallest thing that says *closed on purpose*, and
that is still true of them; what they do not do is remove the paint that promises a road. The
posts belong on the first tile of paving, which moves when the stub does.

**What this side reads into it.** The generator already has the repair, for a different case:
`CityGenerator._seal_stub_crossings()` is what a dead end, an absorbed corridor and a big building
each call over the ground that stopped being a street — *"the surviving junction next to `gone` is
a T now, and the quarter of it on `gone`'s side is a two-tile spur of carriageway and zebra ... it
becomes pavement and the road visibly ends at the junction."* A precinct span is ground that was
never a street for cars, and its two ends are that case exactly.
