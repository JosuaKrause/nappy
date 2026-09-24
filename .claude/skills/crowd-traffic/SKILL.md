---
name: crowd-traffic
description: Rules for the crowd and the traffic — separation, lanes and junction boxes, traffic signals and the green wave, and the fairness contract a lethal carriageway owes. Load this BEFORE touching src/crowd/, Crowd, CrowdAgent, CrowdLanes, TrafficIndex, TrafficSignals, or anything about pedestrians, cars, zebras or lights.
---

# Crowd and traffic

## Separation between bodies is positional, never a force

A brake, a repulsion, a steering weight — all of them keep a gap that already exists and **none of
them can open one that does not**, so two bodies that start inside each other stay there.

`Crowd._bump()` resolves the player against a pedestrian by moving both;
`Crowd.space_out_the_traffic()` resolves a lane of cars from the front backwards. **If a new pair of
things must not be inside each other, move them apart; do not ask them to want to be apart.**

## A placement is not a separation

**And the separation must not be doing the placement's job.** Front-to-back resolution
**compounds**: the shortfall a car sees is its own overlap plus everything already moved ahead of
it, so a bunched queue shunts the rearmost car several lengths backwards in one frame. A car
choosing an arm of a junction has to look before it commits:

- **`TrafficIndex` is the look, and it is a frame stale on purpose.** A car covers three pixels in a
  frame and the question is about a car's length.
- **Two placements in the same frame cannot see each other**, and that is not a rare case —
  recycling is what happens to every car that leaves the box, and they all aim at the same entry
  band. `TrafficIndex.claim()` is the smallest thing that closes it.
- **A retry is not a guarantee.** Re-rolls into a busy lane still all miss now and then.
  `_join_the_back_of_the_queue()` is the fallback, because behind the last car is the one place in a
  lane that is free by construction.

**The morning's resolve runs before the first frame is drawn.** `Crowd.start_day()` ends with the
same front-to-back resolve the first physics frame would run, because a day starts from an idle
frame: the engine draws the placement before the tick that would correct it, so a correction left
to frame one is a car jumping a car's length on the street she is standing in. **And it fills
`TrafficIndex` from that resolve**, because the first frame's turns and recycles look before any
frame has rebuilt it: an empty index lets a turn book a landing a queued car is standing on, and the
shunt is paid whenever that turn lands, seconds later. **A separation that is refused rather than
made smaller is deferred, not avoided** — a nudge that meets blocked ground goes as far as the
ground allows, or the overlap is paid in one jump on a later frame nobody chooses.

**That is not spacing the crowd in `start_day`, which stays refused**: spacing places cars at
`Tuning.CAR_GAP_MIN` headway and turns a random morning into tight platoons, and the balance tests
object. The resolve chooses no position — a car that was not inside another one does not move at
all. Keep the distinction in the docstring at the call site, because the two look identical from
the outside and only one of them is allowed.

**And a retry is not a guarantee one scale out either.** When re-rolling the small decision keeps
failing, re-take the big one — a car handed a corridor whose visible stretch is all precinct
re-rolls its position and finds bollards every time, so `CrowdAgent.setup` picks another street.

## A lane is a queue; a junction is a box

`Crowd.give_way_at_junctions()` is the rule, and every clause of it is load-bearing:

- **Only crossing traffic conflicts.** Two cars meeting head-on are in different lanes and pass.
- **A car that cannot stop is counted as already in the box**, not asked to brake — the zebra's
  commit rule, because braking too late means stopping *in* the thing.
- **Nothing enters a box it cannot leave.** Without this one clause a single backed-up queue takes
  the streets either side of it with it.
- **Nearest first, then right before left.** Distance alone leaves a symmetric arrival undecided and
  right-before-left alone deadlocks four cars in a ring; in that order there is exactly one winner
  per box per frame. A light overrides the whole negotiation where there is one.
- **A car turning in a box holds the whole of it, on both axes, until it is out.** Its path crosses
  both arms and its tail is still in the way after its nose has left. It claims it from the moment
  the arc begins and not from the moment it commits: holding it for the length of an approach
  empties the crossing street for no reason.

The collision that gets through is deliberate and is **not** a catalogue row: it startles the cars
it happened to, which composes by addition like every other body. An event nobody meets in a run is
a silhouette and a fairness contract spent on decoration.

## A turn is a path, and the radius is the lattice's rather than yours

A car plans one arc — `CarTurn` — before it starts turning, and follows it. **The free parameter in
an arc tangent to two lanes is fixed by where the arc *starts*, not by a constant**: a lane centre
sits 16px from its kerb and two lanes are 32px apart, so the near-side arm comes out at 16px, the
far-side at 48 and an about-face at 16 with no choice in it at all. **If you find yourself adding a
turn-radius dial, that is the thing this entry exists to stop** — the number would have to agree
with the lane geometry to land on a lane, so it is the geometry.

The shape of it is easy to get wrong:

- **A body swings to the outside of its turn.** A car has two pixels of slack in its lane, so a few
  degrees of rotation drags its tail over the kerb. The arm that turns *away* from its own kerb
  therefore cannot begin at the carriageway's edge; it waits until the tail is inside the junction.
- **A half turn between two lanes cannot be contained by their own street.** The body's corners
  reach further from the arc's centre than the kerb is. So an about-face is taken in a junction box,
  where the crossing street's carriageway is the room it needs — and the street version, the only
  manoeuvre whose swept body crosses a kerb, is the last resort before a barrier.
- **Refusing outright is not available.** Cars that cannot turn round stop, one nose-to-wall car
  holds the junction it is standing in, and the street behind it queues. Whatever replaces a
  manoeuvre has to keep the road moving.
- **The last resort is stated over *why* an arc was refused, never over how much room is left.**
  Reversing a heading where the car stands is the one manoeuvre with no path in it, so it may only
  be reached from a state that waiting cannot mend. "Stopped with less than a nose's length of
  room" is every car that has braked to its own aim point, so that test spins cars round on the
  ordinary case. Split the refusals: **a lane occupied at the landing empties by itself; the
  ground, the geometry and the map do not.** Wait on the first, and bound the wait, because waiting
  on a car that is itself stopped is a deadlock.
- **A reversal that lands in the same state is the flicker, not the escape.** It swaps the lane a
  car belongs to without moving it, and the cross-steer then slides the body to the other lane's
  centre under every jump threshold — a car shaking its head. So a car with less than a half turn's
  road *both* ways stands still instead, and leaves the way a pocketed body leaves, once nobody can
  see it go. **Ask what the manoeuvre changes about the state that caused it**; if the answer is
  nothing, it is not a manoeuvre.

**And a car that lands from a turn has to be able to leave.** The arm probe is a single point seven
tiles out and looks straight past a two-tile plug. The exit is checked for a turnaround's worth of
road, which is the same *nothing enters a junction it cannot leave* rule read one street further on.

## A shared slot has to be given back on every way out, not on the way you were thinking of

A checkpoint hut holds **one walker at a time** (`WalkerDoorHold`), so a walker occupying one that
no longer exists shuts that door to the crowd for the rest of the day — and nothing about it looks
wrong, because the hut is a point on the map and the walker was hidden anyway.

**The way out you will write is the one you are thinking about** — the inspection ending. The ones
that cost a door are the others: a walker **recycled** at the edge of the crowd's field (every
walker eventually, since the field moves with the player and she walks faster than they do), a
walker **turned away** by a barrier while it was still queueing, and the whole crowd being
**cleared** at the end of a day. All four go through one `release`.

**Ask what else ends a body's stay somewhere, and make every answer call the same function.** A
slot handed back in only the expected case is a leak with a picture on it.

## An approach arrives late, so the guarantee is positional

**A brake and a sidestep both aim at a point and get there a frame after they should.** So *"nothing
ever stands inside a solid body"* cannot be bought by tuning either of them —
`CrowdAgent._keep_out_of_a_body()` holds the step inside the tile the agent started the frame on,
which is the same shape `nudge_back()` already has for the backward direction.

**The sideways half is given up before the forward half, and the ordering is the whole of it.**
Refusing both at once wedges a walker crossing a sidewalk beside a body for good, because its
steering target does not move and the identical step is refused on every frame after. Undoing only
the cross step leaves it walking along the street beside the body and crossing once it is past.

**And an agent already standing somewhere it may not be is left alone**, or the guard turns a bad
placement into a permanent one.

## A lane decision is stated over the lane, not over where the body happens to be

`CrowdAgent._detour` has already carried a walker off its own lane, so a scan taken from the tile it
is **standing on** finds the clear lane it just moved into, lets the detour go, and steers it
straight back into the body it was avoiding — a two-frame oscillation that reads as a walker
standing in a café.

**`_lane` is where the walker belongs and the detour is how far off it currently is.** State the
decision over the first and it is stable while the second is being acted on. Ties go to `_lane`,
which is what makes *"and it steps back afterwards"* happen at all.

**A car's lookahead is the same rule.** `_look_ahead()` walks tiles from the car's *lane centre*,
not from its body: a car still steering onto its lane straddles two rows, and the neighbouring row
is the other lane or the kerb. Asked from the body, the scan reports a wall that is not on this
car's road, and reports it *intermittently*, as the body crosses the row boundary and back. A
walker still asks from its body, because a walker acting on a detour really is on the ground it is
standing on.

**The same trap one level up: a turn has no runway.** A walker rounds a corner wherever its old
along coordinate left it, so the lane it lands on has to be **chosen at the turn**, and an arm whose
landing is taken with no room left to cross is an arm the walker does not turn into.

## A barrier is met at the distance the manoeuvre needs

**The two kinds do not get the same warning, and the reason is what each can do about one.** A car's
answer to a wall is an arc that needs a junction box to fit in, and there is no reverse gear — so it
has to decide while the last junction is still in front of it, which is what `LOOKAHEAD_TILES` is
measured to reach. A walker's answer costs a stride and can be taken anywhere, so it acts only when
the barrier is the **next tile** (`CrowdAgent._acts_on_a_barrier_within()`).

**Deciding early is not free: a street a walker gives up from a junction away is a street with
nobody on it for its whole length.** *(2026-09-19: "they should only give up if they touch an
impassable wall"; "they should still go into the section until they cannot continue".)* So a walker
picking an arm asks only whether the arm is street **at all** (`_no_street_ahead()`), never what is
standing down it; the record a walker is stopped by is the bodies themselves, while the
segment-wide hold is a car's warning and nobody else's.

**If you find yourself unifying the two, this is the entry.** The symmetric version is the one that
reads as correct and is the defect.

## A body's ground is the tiles whose middle it covers

**Every lane here is travelled down its own centre line** — a car on its lane centre, which is a
tile centre, a walker eight pixels either side of one — so a tile whose centre a body leaves clear
still has a line down it and a tile whose centre it covers has none. That is the only question
`CityMap.obstructed_tiles` is ever asked, so it is the rule `GroundShape.tiles_under()` rasterises
by.

**Counting every tile a body touches instead is not conservative, it is wrong at the kerb.** A van
pinned to the kerb overhangs its lane tile by a few pixels, which would put a whole lane of
carriageway in the record and turn every car on that street for something parked on the sidewalk.

## The heading is the datum, and it is continuous

`CrowdAgent.heading()` is a unit vector along the car's actual line of travel — cardinal in a lane,
the **tangent of its own arc** mid-turn — and `velocity()` is that times the speed it is really
doing. Everything downstream reads it: the lethal strike box and the horn, right of way at a box,
the checkpoint gate's along/across projection, the shadow, and the picture. **A turn that changes
the axis without changing this points every one of them at a car that is not there.**

`travelling_vertically()` follows the heading mid-turn for the same reason: a car that has swung
past the diagonal is across the traffic it used to be queueing with.

## A gap is a snapshot

**"Do not block the box" has to know the queue is moving.** `Crowd._can_clear_the_box` credits the
leader's speed for one `CAR_HEADWAY_TIME` — the same horizon the car-following rule already trusts
it for — but **only when the leader is already past the far side**. Crediting it unconditionally
lets a car follow its leader *into* the box.

**Ask what the number you are crediting is a fact about**: a leader inside the box is the obstacle,
not evidence about the road beyond it.

## Sampling a tile grid by stepping world points aliases

And it aliases where it matters. Probing `position + forward * step * TILE_SIZE` is correct almost
everywhere and wrong at exactly one place: a car stopped at the stop line is a few pixels from the
paint, so both neighbouring samples miss the zebra, the car decides there is nothing to give way to,
and pulls away with somebody standing on it.

**Walk the tiles** — `world_to_tile` once, then integer steps — whenever the question is about tile
types rather than about distance. **Start at step zero**, too: a car's own tile is the difference
between "not there yet" and "already across".

## Signals

**A signalled grid has a capacity, and the population has to respect it.** Signals with arbitrary
offsets stop a car at *every* junction, so the cycle is derived from the block spacing
(`SIGNAL_PROGRESSION_BLOCKS`). Junction control gives the road a throughput it did not have, so the
car population is a number about capacity as well as about noise: a car waiting at a light beside
you is louder for longer than one going past.

**The green wave serves one direction, and a two-way wave is not available at any setting.** The
arithmetic, and why the asymmetric offset is the best answer rather than a compromise, is the
`Tuning.SIGNAL_PROGRESSION_BLOCKS` docstring. Two things to carry, because the shape recurs:

- **An identity is not the property.** Asserting `cycle / travel` is an even multiple is *true* and
  pins nothing, because it is not the condition the sentence beside it claims.
  `tests/test_crowd.gd` walks a car down the platoon instead.
- **The stopped fraction is not the speed spread.** A car's speed drifts it against the wave, but
  it does not live long enough on the spine to drift out of a green band, and the fast half stops
  more than the slow half. The mechanism is the main arm's red share of the cycle and that only half
  the traffic gets the wave.

## A weighting applied inside a fixed split cannot cross it

Cars pick their **axis** by weight, not 50/50 before the corridor — otherwise no weight at all can
put more than half the traffic on one street. Walkers keep the even split on purpose, because a
sidewalk has no hierarchy for them to follow.

**Ask what the weight is competing inside of**: a number that looks like a global priority is a
local one if something upstream has already chosen the bracket.

## The traffic fairness contract

A car is lethal and is **not** an event, so `validate_event()` never sees it.
`Tuning.validate_traffic()` is its equivalent and runs on boot. Two things stand in for the
telegraph: the **painted carriageway**, which is permanent and learnable and which she chooses to
step onto, and the **horn**, which must be long enough to walk the whole width of it with the
doubled hard-fail margin.

**The horn can only be as early as the car is watching her, and `validate_traffic()` cannot see
that.** `Crowd._physics_process` hands the strike and the horn only the cars within
`CAR_ZEBRA_SIGHT` (200px) of her, so a car sounds its horn at `min(CAR_HORN_TIME × speed, 200px)`,
and every car faster than `200 / CAR_HORN_TIME` (125px/s) warns later than `CAR_HORN_TIME` — under
the contract's own `required_horn_time()` above 144px/s, which is most of `CAR_SPEED`'s range.
A check of the horn against the carriageway that reads only `Tuning` passes whatever that radius
is, so **a change to either the horn or the radius the crowd watches her from is checked against
the other by hand.**

**If anything else ever becomes lethal without being in the catalogue, it needs its own stated
contract in the same place.** A hard fail with no written contract is a bug waiting to be called a
difficulty setting.

**The main road replaces the courtesy with a clock, so the clock is the contract.** Traffic on the
spine does not give way at a zebra — what stops it is the light — so the thing standing between her
and a hard fail is the length of the **side street's** green, and `Tuning.validate_signals()` states
it in the same shape: long enough to walk the carriageway with the doubled margin.

Two things are easy to get backwards. The green that matters is the **other** arm's, because she
crosses the main road while the main road is stopped. And the amber is a **clearance** period rather
than a warning — the crossing arm stays red through it and a car too close to stop is counted as
already in the box — so lengthening it buys her nothing and lengthening the side green buys her
everything.

**A dark light hands the main road back to the side street's contract.** On the last night the
blackout cuts the power (`TrafficSignals.powered`), so `is_signalled()` answers false on the spine
and the box rule negotiates its junctions as it does every other street's — no crowd code knows the
difference, and none should. The spine's traffic still does not give way at a zebra, since that is
the street's kind rather than its light, so the clock is gone and nothing replaces the courtesy:
**what keeps a crossing of the dark spine fair is the painted carriageway and the horn**, and the
horn has to be long enough, at the spine's speed, to walk the spine's whole carriageway with the
doubled margin. The spine's carriageway is `carriageway_width()` like every street's and the horn is
seconds of the car's own travel, so `validate_traffic()` is the check, and `validate_signals()` says
so beside the green it checks. **Anything that asks whether a spine junction has lights standing on
it — where to put a head — asks `has_lights()`, never `is_signalled()`**, or a city built dark
draws no heads at all.

## A rig that steps the parts is not running the whole

Several suites walk the crowd by hand — `for agent in crowd.agents(): agent._process(step)` — so
that a minute of traffic does not take a minute. That skips the frame *around* the agents:
`Crowd._physics_process`, which resolves the queue and rebuilds `TrafficIndex`. `claim()` is written
to outlive one frame and nothing bounds it, so with nothing rebuilding, every recycle stays.

**When a rig drives a subsystem by hand, ask what the engine was doing around it** — and if the
answer is "keeping something bounded", the rig is not slow, it is wrong. `Crowd.step()` is the whole
frame and is what a rig calls.

## The crowd is one picture on purpose

The whole crowd shares one walker drawing (`art/crowd/walker_*`), because **a crowd is what an
authored event has to stand out from**. This is the deliberate opposite of the one-picture-per-row
rule for the catalogue.
