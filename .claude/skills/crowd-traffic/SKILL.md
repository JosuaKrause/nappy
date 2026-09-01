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
choosing an arm of a junction has to look before it commits. Three things to carry:

- **`TrafficIndex` is the look, and it is a frame stale on purpose.** A car covers three pixels in a
  frame and the question is about a car's length.
- **Two placements in the same frame cannot see each other**, and that is not a rare case —
  recycling is what happens to every car that leaves the box, and they all aim at the same entry
  band. `TrafficIndex.claim()` is the smallest thing that closes it.
- **A retry is not a guarantee.** Six re-rolls into a busy lane all miss about once a minute.
  `_join_the_back_of_the_queue()` is the fallback, because behind the last car is the one place in a
  lane that is free by construction.

**The one place a large correction is right is frame zero of a day**, where the crowd is placed
without consulting itself and the first pass unpacks it. Nobody has seen a previous frame of that
street. **Do not "fix" it by spacing the crowd in `start_day`**: that turns a random morning into
tight platoons at minimum headway, and three balance tests correctly object.

**And a retry is not a guarantee one scale out either.** When re-rolling the small decision keeps
failing, re-take the big one — a car handed a corridor whose visible stretch is all precinct
re-rolls its position and finds bollards every time, so `CrowdAgent.setup` picks another street.

## A lane is a queue; a junction is a box

`Crowd.give_way_at_junctions()` is the rule and four clauses of it are load-bearing:

- **Only crossing traffic conflicts.** Two cars meeting head-on are in different lanes and pass.
- **A car that cannot stop is counted as already in the box**, not asked to brake — the zebra's
  commit rule, because braking too late means stopping *in* the thing.
- **Nothing enters a box it cannot leave.** Without this one clause a single backed-up queue takes
  the streets either side of it with it.
- **Nearest first, then right before left.** Distance alone leaves a symmetric arrival undecided and
  right-before-left alone deadlocks four cars in a ring; in that order there is exactly one winner
  per box per frame. A light overrides the whole negotiation where there is one.

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

**The green wave serves one direction, and a two-way wave is not available at any setting of this
constant.** With offsets `j·travel`, a car going *with* the wave holds its phase exactly, and one
going *against* it advances `2·travel` per junction, which is only constant if the cycle **divides**
`2·travel` — true at `blocks = 1` and nowhere else. That needs `cycle = 2·travel` = 5.7s, and the
side green plus its ambers is 9.0s before the main road gets a second. The asymmetric offset is the
*best* answer, not a compromise: `θ = travel` gives 72% overall, and `θ = cycle/2` — the
symmetric-looking one — puts both directions on a three-phase sweep at 47%.

Two things to carry, because the shape recurs:

- **An identity is not the property.** Asserting `cycle / travel` is an even multiple is *true* and
  pins nothing, because it is not the condition the sentence beside it claims.
  `tests/test_crowd.gd` walks a car down the platoon instead.
- **The stopped fraction is not the speed spread.** `CAR_SPEED` is 130–185 against a wave tuned for
  157.5, so a slow car drifts 0.6s per junction — but a car lives 3.8 junctions on the spine and
  needs 13 to drift out of a green band, and the **fast** half stops more than the slow half. Drift
  is real and it is not the mechanism. The mechanism is that the main arm is red 53% of the cycle
  and only half the traffic gets the wave.

## A weighting applied inside a fixed split cannot cross it

Cars pick their **axis** by weight, not 50/50 before the corridor — otherwise no weight at all, 5 or
50 or any number, can put more than half the traffic on one street. Walkers keep the even split on
purpose, because a pavement has no hierarchy for them to follow.

**Ask what the weight is competing inside of**: a number that looks like a global priority is a
local one if something upstream has already chosen the bracket.

## The traffic fairness contract

A car is lethal and is **not** an event, so `validate_event()` never sees it.
`Tuning.validate_traffic()` is its equivalent and runs on boot. Two things stand in for the
telegraph: the **painted carriageway**, which is permanent and learnable and which she chooses to
step onto, and the **horn**, which must be long enough to walk the whole width of it with the
doubled hard-fail margin.

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

## A rig that steps the parts is not running the whole

Several suites walk the crowd by hand — `for agent in crowd.agents(): agent._process(step)` — so
that a minute of traffic does not take a minute. That skips the frame *around* the agents:
`Crowd._physics_process`, which resolves the queue and rebuilds `TrafficIndex`. `claim()` is written
to outlive one frame and nothing bounds it, so with nothing rebuilding, every recycle stays.

**When a rig drives a subsystem by hand, ask what the engine was doing around it** — and if the
answer is "keeping something bounded", the rig is not slow, it is wrong. `Crowd.step()` is the whole
frame and is what a rig calls.

## The crowd is one picture on purpose

Two hundred and forty bodies share one `person.svg`, because **a crowd is what an authored event has
to stand out from**. This is the deliberate opposite of the one-picture-per-row rule for the
catalogue.
