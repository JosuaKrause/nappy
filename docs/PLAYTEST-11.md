# Playtest 11 — the city's shape, and the things that are in the way of nothing

The eleventh report, delivered as a numbered list of nine plus a design for the edge of the map.
Taken on `81f8b67` — **M38 merged, M39 still uncommitted** — which matters for two of the nine: the
pursuit rework was in a working tree the player was not running.

Two are defects in code that has never worked (the traffic at junctions, the diagonal `zzz`), three
are things that exist and accomplish nothing (events on the home block, closures beside parks, the
busker in a courtyard), one is the difficulty question every playtest since 07 has asked from a new
angle, and three are structural: where the home is, what a main road is, and what the edge of the
world is.

---

## The one sentence

**Several things in this city are placed without asking what they are in the way of.**

An event on the home block, a road closure beside a park, a busker in a courtyard she can walk
round, a car turning into a junction another car is already in — each is a thing the game put
somewhere without asking what that somewhere does to the route. `CLAUDE.md`'s first rule is *before
changing a number or adding a system, ask what it does to the route decision; if the answer is
"nothing", it is decoration.* Five of these nine are that rule failing at **placement** rather than
at design.

And underneath findings 4 and 7 and the edge design is one larger thing: **the city has no
hierarchy.** Every street is the same street. The home sits wherever the generator's two competing
rules leave it, the arterials are only busier rather than different in kind, and the map stops at an
invisible wall. The player is asking for a city with a middle, a spine, and an edge you can walk to.

---

## The findings, as reported

| # | What the player said | Kind |
|---|---|---|
| 1 | "events/hazards should not spawn on the home block" | design |
| 2 | "road blocks next to parks are pointless" | design |
| 3 | "the pursuing dog still moves backwards before charging. it should be still. and the run == back down appears to not have landed yet" | bug |
| 4 | "let's make the home be the center (with an odd number of rows/cols blocks) mandatory. I spawn too often at the edge leaving only a few ways into the rest of the city" | design |
| 5 | "the music guy is ineffective in actually preventing me from going to a place. In a courtyard I can still walk around (and over him) while the sleepiness meter goes up" | bug |
| 6 | "the pursuing dog in day 3 should have a much faster stop-pursuing cool-off when running" | design |
| 7 | "cars overlap on intersections — they should not go somewhere if they will run into another car… there should be a right-before-left rule to settle which car goes first. Also the main road with traffic lights hasn't landed yet — we need a separation between easy-to-navigate road and heavily trafficked and pedestrianised road — there should be a visual difference and traffic lights" | bug + design |
| 8 | "when my excitement is already high I seemingly die without reason even on low density / few pedestrians streets" | bug |
| 9 | "the diagonal zzz got moved up like the downward zzz. Let's move them down to the stroller again" | bug |

And the edge of the map, given as a design rather than as a finding:

> *"There should be one tunnel in the north (for the main road), one bridge at the bottom (for the
> main road), and the side-to-side main road just going towards east/west in one space. The player
> should be able to walk into those, which would be certain death once a car comes. That way it's
> not an artificial end but an emergent end. All other edge tiles should have T-intersections."*

---

## The analysis

### A. Placement never asks what it is in the way of (1, 2, 5)

Three findings, one shape. `EventScheduler` chooses a tile that satisfies a `placement` list and a
handful of spacing rules, and none of those rules is *"and this changes a route"*.

**Events on the home block (1).** Every day starts on the doorstep and the first thing the scheduler
is allowed to do is put something on it. Playtest 10's own trace has three crowd contacts on the
doorstep tile inside eight seconds and a day lost without her ever leaving; an authored event there
is the same failure with a name on it. The home is the one tile the player does not choose to be on,
so danger there is not a route decision — it is a tax. The exemption already exists in spirit:
`ClosurePlanner` never closes the street outside the home, for exactly this reason, and the rule
should be the same rule.

**Closures beside parks (2).** A closure's whole job is to change the shape of the route, and it is
checked against the route-redundancy invariant — *two distinct routes to two distinct calm areas* —
before it is accepted. What is never checked is whether it changed anything: a closure on a street
that only ever led to one park's second entrance is legal, invisible and pointless. This is the
route-redundancy check being used as a *floor* when it should also be a *filter*: a closure that
does not lengthen the best route to any calm area by some margin is not worth placing.

**The busker in a courtyard (5).** *"I can still walk around (and over him) while the sleepiness
meter goes up"*, which is two complaints and both are arithmetic. **Around**: what denies calm ground
is out-emitting the decay the calm multiplier has already raised — 7.7/s at M38's 12x multiplier —
and `EventScheduler._denial_radius()` exists to do that sum. Playtest 08 did it for the busker and
sized a *crowd* of spoilers from it; playtest 10 did it for the playground and found a row that had
never once out-emitted its own ground. This is the third time, and the suspicion is that a courtyard
— the smallest calm area, one block — is being spoiled by a grid of one. **Over**: anything mobile
is exempt from *solid things are solid*, and `EventDef.paces` made the man who paces mobile. If the
busker paces, it has no body by construction. Both halves need measuring before either is moved.

### B. The dog still reverses, and the cool-off was never in the build (3, 6)

**Half of this is already answered and the player could not have seen it.** M39 was uncommitted when
this report was taken. `Tuning.PURSUIT_SHAKEN_OFF` ends a chase after 0.8s of the gap **opening** —
which is finding 6, *"a much faster stop-pursuing cool-off when running"* — and it takes the measured
price of the answer from about 35 points to **12**. Finding 3's second clause, *"the run == back
down appears to not have landed yet"*, reads as the same mechanic and is the same answer. It is on
`main` now; what it needs is a play, and if 0.8s still reads as slow it is one constant.

**The other half is a real and open decision.** The dog backs off through its telegraph because the
lunge is fired by a **clock**: it closes to its stand-off in about a third of a second and then has
two more seconds of telegraph to spend, and she is walking into it the whole time. Holding a
distance while she advances means reversing. The alternative — *stand still*, which is what the
player asked for — is the thing M35 rejected in as many words, and the rejection was right for the
build it was made in: a dog that holds its ground while she closes the last hundred pixels herself
is a dog she reaches *before* the clock lets it fire, and then it kills her from a standing start on
the first lethal frame. That is the M35 defect exactly.

So the answer is neither "back off" nor "stand still" but **fire the lunge on proximity instead of on
the clock**: it walks up, stops, and charges when she comes inside the stand-off, or when the
telegraph runs out, whichever is first. Then it never reverses and the chase always starts at the
stand-off, which is the whole content of the contract.

The number that has to be re-decided with it is `PURSUIT_MIN_NOTICE`, currently 1.5s. Sited at 184px
against a 104px stand-off, a player who walks straight in gets about **1.2s** of visible dog before
the lunge — 0.36s of it closing and 0.85s of her closing on it. That is less than the floor, and the
floor was authored rather than derived. Either it comes down, or the dog is sited further out, and
further out is capped by what is on screen: the visible world is 360px tall, so a dog telegraphing
north or south of her is off the top of the screen past about 180px.

### C. The city has no middle and no spine (4, 7, and the edges)

**Home at the centre (4).** Playtest 10 asked this as a question and the recommendation was to take
the trade by growing the city to 9×9 as its own milestone. It is now an instruction, and the
diagnosis stands: the city is *already* odd at 7×7 and `_place_home` *already* sorts candidate blocks
by distance to the centre. What pushes the home outward is the second rule,
`MIN_HOME_TO_PARK_TILES` = 30 — the centre of a 7×7 city is rarely 30 tiles from every park, so the
home is walked outward until it is. The two rules compete for the same thing, which is that the walk
out has to be long enough to matter, and at 7×7 both cannot hold.

At 9×9 they can. The cost is that a 9×9 city is **65% more blocks**, and since M28 the events are one
per block and since M27 the crowd is a field around the player — so every density number in
`docs/PLAYTEST-04.md` is re-measured, and the budget with them. That is the milestone, and it is why
it is a milestone rather than a constant.

**Main roads, and the two kinds of street (7).** This has been open by decision since M21, where
four-block calm zones shipped and *"main roads with lights"* and *"the canal"* were left. The
argument for doing it now is the player's: there is currently **one kind of street**, and the
arterials differ from it only by how many cars are on them. A city with a spine has an easy street
and a hard street, and the choice between them is a route decision — which is the only verb this
game has. It needs a visual difference that is readable at a glance, traffic lights that make a
crossing a *timing* problem rather than a gap-hunting one, and a pedestrianised counterpart that is
the opposite trade: slow, crowded, no cars.

**Cars overlap at junctions (7).** This is a defect and it is the M38 lesson one level along. M38
fixed a car *turning into an occupied lane* by making the turn look first — `TrafficIndex`, a
frame-stale index of where the cars are, plus `claim()` for two placements in the same frame. What
was never modelled is the **junction box** itself: two cars on crossing arms both have a clear lane
ahead and both enter, and the positional resolve then does the only thing it can, which is move a
body. The fix has the same shape as M38's — look before committing — plus the thing a junction needs
that a lane does not: **a priority rule.** Right-before-left is the player's suggestion, it is what
an unsignalled European junction actually uses, and it settles the symmetric case without a
negotiation. Traffic lights, where they exist, override it.

The deliberate exception is worth writing down now so it is not lost: a car that *does* enter an
occupied box is an **accident**, which is an event, and the game already has a vocabulary for one.

**The edge of the world.** The design given is better than the one in the plan, and the reason is in
the player's own sentence: *"that way it's not an artificial end but an emergent end."* A wall says
*the game stops here*. A tunnel mouth, a bridge, and a main road running off east and west say *the
city goes on and this is how you would leave it* — and they are lethal for the reason everything else
on a carriageway is lethal, which the player has already learnt. Four things follow:

- **One tunnel north, one bridge south, one main road east-west.** These are the ends of the spine
  from the finding above, so this and the main-road work are the same milestone.
- **Walkable, and fatal when a car comes.** Not a special case: it is the traffic fairness contract
  doing what it already does, on a stretch of road with no pavement beside it.
- **T-intersections everywhere else on the edge.** The lattice currently runs into the boundary and
  stops. A T-junction says the street ends and turns rather than being cut off.
- **And the guarantee that must not move**: no purpose change and no decoration may move a walkable
  tile (`tests/test_blocks.gd` asserts the walkable set is identical tile for tile across every seed
  and block arc). Three walkable exits *do* move it, deliberately, so the route guarantees are
  re-measured rather than assumed — and a route that "escapes" through a tunnel must not count as a
  route to a calm area.

### D. Dying at high excitement on a quiet street (8)

> *"When my excitement is already high I seemingly die without reason even on low density / few
> pedestrians streets."*

The strongest suspect is not the street, it is the **recovery**, and it is a rule this project took
on purpose. `EXCITEMENT_DECAY_IDLE` is **0.0** — standing still settles nothing, which was playtest
07's finding 3 and is correct — so above the calm threshold the only way down is walking somewhere
quieter, at 3.5/s, or reaching calm ground, at 7.7/s. On a quiet street with nothing nearby the meter
therefore sits where it is, and any small source is a net climb with no floor under it. A player
reads that as *nothing is happening and I am still dying*, which is exactly the report.

Three things to measure before moving anything, because the second most likely answer is the one
nobody has fixed yet:

- **What the losing line actually says.** Every `lost` entry carries its own breakdown, `crowd X,
  events Y`. Playtest 10's five runs all read `crowd 39.4, events 0.0` and that is the open
  difficulty question, deferred as its own milestone. If these lines read the same, this finding is
  that one.
- **Whether the pram says anything.** `EXCITEMENT_NEARLY_CRYING` is 80 and the pram has a cue for it.
  *"Without reason"* may be a cue that is not being read rather than a rate that is wrong.
- **Whether one contact is enough at 90.** A pedestrian contact is ~10.8 points. Above 89 a single
  bump ends the day, and one bump on an empty street is not a density problem, it is a **cliff**.

### E. The diagonal zzz (9)

M39 made `Stroller.baby_cue_lift()` conditional so that walking south the cue is lifted over the
pram instead of shoved sideways off it. The condition catches the diagonals too, and it should not:
walking diagonally the pram is already offset and there is nothing to lift over. Move them back down.
Small, and it is the third time this cue has been adjusted — `tests/test_danger.gd` should hold the
answer for all eight facings rather than for the two that were reported.

---

## What this becomes

M42 in `docs/TODO.md`, except for the parts that already have a milestone: finding 4 is the 9×9
city, and the main road and the map edges merge into one milestone about the shape of the city.
Findings 3 and 6 are re-decided against the M39 build now that it is on `main`.
