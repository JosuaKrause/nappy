# Playtest 37 — 2026-09-08

Notes given in one conversation, on the capture M53's bollards were reviewed with
(`docs/evidence/archive/session-captures/2026-09-08/rig-190124-seed4242-v0.7.0-2-g7f9cc02-dirty/bollards-precinct-mouth.png`,
seed 4242, the shore precinct's west mouth). Three findings, and every one is a re-report: the
bollards were built as if the complaint were *nothing marks the closure*, and the complaint was
that **a crossing is painted where no road is** — at a precinct's edge, at the city's border, and
on the main road's side arms.

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

## 2. The border of the city grid is T-junctions too, except at the tunnel and the bridge

> "while the agent is at it -- the border of the city grid also should have t-junctions (except
> for tunnel and bridge)"

**A re-report of M49's *"Junctions are four-way where an arm dead-ends — reproduced, with a
picture"*** (`docs/TODO.md`, with the seed and the three captures), which already says *"the
map's own border is the one place an arm genuinely dead-ends"* and *"it is every side, not the
north one"*. What the player adds is the exception, stated: **the tunnel and the bridge** — the two
ends of the spine, where `CityEdge` draws the road leaving the map and a car genuinely goes on —
keep their arm. Every other junction on a boundary street has three arms, and the zebra painted
on the fourth, running to the border, goes.

## 3. The main road's crossings are the thin-line style on all four arms

> "and the zebra crossings at the main street should be the thin line style in all four directions
> (since all have traffic lights) not only the north south ones"

**A re-report of M49's *"A main road's junction is four dotted crossings, not two"***, which
already carries the reasoning: `GroundTiles._crossing_variant` draws the dotted pair only for a
crossing across the main road's own carriageway, and the property belongs to the **junction**,
since one light governs all four crossings where the spine meets a side street. The side street's
two crossings are painted as a zebra — a promise to give way that the traffic there does not make.

## 4. The junctions are right now, and the bodies still walk off the map

> "it's now correctly t-junctions but the cars and people still go off the map"

Said on the branch with findings 1 and 2 built. **A re-report of M49's *"People walk out onto the
border and vanish there"***, which already names the cause: `CrowdAgent._cannot_go_on()` answers
*passable* for a tile outside the map, so the one wall that should stop a body reports as clear.
The paint now says T-junction and the rule under it still says street. The exception is the one
M49 already flags to check against — the spine's exits, where a car is meant to leave — and
playtest 16's finding 3 fixes its shape: *"only cars should be able to"*, never a walker.

## 5. The caret means lethal, and it is on things that are not

> "caret == lethal is good but is inconsistently applied at the moment"

> "a cat has a caret but it's benign"

> "a pedestrian without caret has a greater impact than a cat"

**Not a re-report; this is the vocabulary's second rule failing in its own terms.** Today the caret
is two rules wearing one shape: a doubled deep-red caret over anything `hard_fail`, and a single
amber one over any event whose `walk_through_cost()` reaches `Tuning.MARK_WORTH_A_DETOUR` (25
points) — *worth going round*, not lethal. `cat_dash` clears that line (17/s for 1.8s inside a
120px field) and gets the amber mark; a pedestrian (4.2/s at close range, every one of them, all
day) costs more over a pavement and is a `CrowdAgent` the rule never looks at. So the cue says the
cat matters more than the people, which is false, and *"if A is marked and B is not, A costs more to
walk through than B"* — the invariant `tests/test_danger.gd` holds over the catalogue — is only
true because the crowd is outside the catalogue.

> "carets shouldn't be chosen by source value but by expected impact value"

**So the amber caret stays, and what changes is what decides it.** `wants_a_mark()` asks a
row's `walk_through_cost()`, a number derived from the def's intensity, radii and speed — a
*source* value, the same for every instance of the row wherever it stands and whichever way she
is walking. The player wants it decided by **expected impact**: what this particular thing is
about to cost *her*, given where it is and where she is going. A café across the street she is
not walking past expects nothing; the same café on her pavement ahead expects its whole field. A
lone pedestrian expects a couple of points; a knot of them she is heading into expects more than
a cat. It is the halo's own quantity turned forward — the halo is what landed over the last five
seconds, the caret is what will land over the next — and it puts the crowd and the events under
one rule, which is what makes the cat-versus-pedestrian inconsistency go away rather than get
re-tuned.

> "amber one is fine as long as it represents a meaningful thing"

> "even the red lethal one is inconsistent since I can walk in a car from the side and I won't
> see a caret only if it sees me"

**And the red caret is under the same rule.** A car draws its doubled deep-red caret only while it
is sounding its horn — `CrowdAgent._draw_horn_mark()` on `_jolt > 0` — which is a fact about
whether the car noticed *her*, not about whether it is about to kill her. A car she walks into from
the side never honked and never carried a mark.

> "I don't want a caret when walking into a car from the side"

> "so red caret means honking -- not lethal, in this case"

> "and the red caret for the biker also means lethal"

**So the red caret has two meanings today, one shape**: on a car it means *it noticed you and is
sounding its horn*, on the cyclist it means *this ends your day*. And the direction of the fix is
fixed by the side-car sentence: expected impact is measured **with her held still** — what the
thing's own motion and field will do to her over the horizon if she does nothing — never along her
line into it. That is already the screen-edge badge's rule and the cues skill's sentence: *"measure
the thing, not the gap ... a rate that includes her 92px/s is a cue for walking."* Under it both red
carets mean one thing, *on its current course this kills you*: a car honking at her is a car whose
lane she is standing in and it marks; the cyclist coming at her marks; a car she steps into from
the side does not, because held still she is never in its path. The honk stops being the meaning
and becomes the symptom. It also settles the cat and the pedestrian in one breath — a thing whose
own approach lands less than the line on a standing player is not marked, whatever its row says —
and it means a stationary café never earns a caret, which is the halo's job from the moment she is
in its field. This lands after M92, because it changes the same files.
