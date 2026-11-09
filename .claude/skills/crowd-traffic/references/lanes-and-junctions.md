# Placement, lanes and junction boxes

Read this before touching how a car or a walker is placed, recycled, queued, stopped by a body or a
barrier, or let through a junction: `Crowd`, `LaneMover` (the class `CrowdAgent` extends, which
holds an agent's lane, heading and steps), `LaneStrategy` and its `CarStrategy` and
`WalkerStrategy`, `TrafficIndex`, `GroundShape`.

## A placement is not a separation

**And the separation must not be doing the placement's job.** Front-to-back resolution
**compounds**: the shortfall a car sees is its own overlap plus everything already moved ahead of
it, so a bunched queue shunts the rearmost car several lengths backwards in one frame. A car
choosing an arm of a junction has to look before it commits:

- **`TrafficIndex` is the look, and it is a tick stale on purpose.** A car covers a few pixels in a
  tick and the question is about a car's length.
- **Two placements in the same frame cannot see each other**, and that is not a rare case —
  recycling is what happens to every car that leaves the box, and they all aim at the same entry
  band. `TrafficIndex.claim()` is the smallest thing that closes it.
- **A retry is not a guarantee.** Re-rolls into a busy lane still all miss now and then.
  `CarStrategy.join_the_back_of_the_queue()` is the fallback, because behind the last car is the one
  place in a lane that is free by construction.

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
re-rolls its position and finds bollards every time, so `LaneMover.setup()` picks another street.

## A lane is a queue; a junction is a box

`Crowd._give_way_at_junctions()` is the rule, and every clause of it is load-bearing:

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

## A gap is a snapshot

**"Do not block the box" has to know the queue is moving.** `Crowd._can_clear_the_box` credits the
leader's speed for one `CAR_HEADWAY_TIME` — the same horizon the car-following rule already trusts
it for — but **only when the leader is already past the far side**. Crediting it unconditionally
lets a car follow its leader *into* the box.

**Ask what the number you are crediting is a fact about**: a leader inside the box is the obstacle,
not evidence about the road beyond it.

## An approach arrives late, so the guarantee is positional

**A brake and a sidestep both aim at a point and get there a frame after they should.** So *"nothing
ever stands inside a solid body"* cannot be bought by tuning either of them —
`LaneMover._keep_out_of_a_body()` holds the proposed step inside the tile the agent started the step
on, before the step is committed (`MoveProposal`), which is the same shape `nudge_back()` already
has for the backward direction.

**The sideways half is given up before the forward half, and the ordering is the whole of it.**
Refusing both at once wedges a walker crossing a sidewalk beside a body for good, because its
steering target does not move and the identical step is refused on every frame after. Undoing only
the cross step leaves it walking along the street beside the body and crossing once it is past.

**And an agent already standing somewhere it may not be is left alone**, or the guard turns a bad
placement into a permanent one.

## A lane decision is stated over the lane, not over where the body happens to be

`LaneMover._detour` has already carried a walker off its own lane, so a scan taken from the tile it
is **standing on** finds the clear lane it just moved into, lets the detour go, and steers it
straight back into the body it was avoiding — a two-frame oscillation that reads as a walker
standing in a café.

**`LaneMover._lane` is where the walker belongs and the detour is how far off it currently is.** State the
decision over the first and it is stable while the second is being acted on. Ties go to `_lane`,
which is what makes *"and it steps back afterwards"* happen at all.

**A car's lookahead is the same rule.** `LaneMover._look_ahead()` walks tiles from the car's *lane centre*,
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
has to decide while the last junction is still in front of it, which is what `LaneMover.LOOKAHEAD_TILES` is
measured to reach. A walker's answer costs a stride and can be taken anywhere, so it acts only when
the barrier is the **next tile** (`LaneStrategy.acts_within`).

**Deciding early is not free: a street a walker gives up from a junction away is a street with
nobody on it for its whole length.** A walker gives up only where it touches an impassable wall and
goes on into the section until it cannot continue (PLAYTEST-78). So a walker picking an arm asks
only whether the arm is street **at all** (`WalkerStrategy._no_street_ahead()`), never what is
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

## Sampling a tile grid by stepping world points aliases

And it aliases where it matters. Probing `position + forward * step * TILE_SIZE` is correct almost
everywhere and wrong at exactly one place: a car stopped at the stop line is a few pixels from the
paint, so both neighbouring samples miss the zebra, the car decides there is nothing to give way to,
and pulls away with somebody standing on it.

**Walk the tiles** — `world_to_tile` once, then integer steps — whenever the question is about tile
types rather than about distance. **Start at step zero**, too: a car's own tile is the difference
between "not there yet" and "already across".

## A weighting applied inside a fixed split cannot cross it

Cars pick their **axis** by weight, not 50/50 before the corridor — otherwise no weight at all can
put more than half the traffic on one street. Walkers keep the even split on purpose, because a
sidewalk has no hierarchy for them to follow.

**Ask what the weight is competing inside of**: a number that looks like a global priority is a
local one if something upstream has already chosen the bracket.
