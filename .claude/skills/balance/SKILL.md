---
name: balance
description: Rules for changing any balance or density number — event density, crowd density, Tuning constants — and the measured facts about what a route actually costs. Load this BEFORE editing src/autoload/tuning.gd, max_per_day, budget_for, CROWD_*_PER_ACT, or any number a player can feel.
---

# Balance

**All balance numbers live in `src/autoload/tuning.gd` and nowhere else.** Prefer a named constant
in `Tuning` over a literal anywhere gameplay can feel it.

**Expect tests to push back.** Several encode *relationships*, not values — traffic noise must stay
under the walking decay; a fast mover must telegraph across its whole radius. If a test fails,
decide whether the relationship or the number is wrong. **Do not just update the test.**

**A test asserting a relationship beats one asserting a value.** `intensity < walking decay`
survives rebalancing; `intensity == 3.2` does not.

## Never derive a density — measure it

**Change the event density:** `max_per_day` in the catalogue **first**, then
`EventScheduler.budget_for()`, because **a budget the catalogue cannot spend is not density**. Then
**measure what a day places**, over several seeds, since `_ensure_the_city_is_still_walkable` drops
obstructions that would seal the city.

A temporary probe suite that prints per-day counts takes two minutes and is the only honest way to
set it. **Measure four things and not one:**

- **placed per day**
- **live inside `EVENT_STREAM_RADIUS`**
- **on screen at once**
- **met on a route**

They move by different multiples, and only the last is what the player is complaining about.

## Two levers, and which one binds differs by day

A **cap** binds when the day reaches it. A **weight** binds when it does not, because a row is only
offered as often as its weight. **Raising a cap the day never reaches does nothing at all** — that
is "a budget the catalogue cannot spend is not density" at the other end.

## Ask what a number is *per*

`budget_for()` multiplies by `CITY_BLOCKS.x * CITY_BLOCKS.y`, because the target is per block. A
flat budget is a statement about one lattice size and nothing else: grow the city and the same
events spread thinner, which is the density silently falling while every constant still reads as
correct.

The crowd is the deliberate opposite — it is a population of the **field** around the player rather
than of the city, so it does **not** scale with the lattice.

## Crowd density

`Tuning.CROWD_PEDESTRIANS_PER_ACT` / `CROWD_CARS_PER_ACT`, and `CrowdLanes.ARTERIAL_BUSYNESS`, which
is one street's share of the three or four corridors in the box rather than of sixteen.

Then **measure it**, with a throwaway probe over a minute of a real day:

- how often there is a safe gap to cross the arterial, and an ordinary street
- the mean wait at the kerb
- contacts in a forty-second walk down a lane centre **and** holding the midline between two lanes
- whether any two cars share a lane closer than a car's length

A lane has a **capacity**, and past it the arterial jams solid and no controller helps. The
junctions have a capacity too, so the car number is not only a noise number — **measure the mean
speed and the stopped fraction alongside the floor**, or a road that reads as "busy" in a screenshot
is a car park in motion. The honest answer to "the main road is too quiet" has twice been **fewer
cars**.

## What a route actually costs

The full table is in `docs/EVENTS.md`, "What an event actually costs". **Regenerate it whenever a
rate in `Tuning` moves** — it is the fastest way to see what a balance change did to the whole
catalogue.

**Walking through an event costs, and the falloff's shoulder is why.** `Tuning.falloff` is `1−t²`
between the inner and outer radius, not `(1−t)²`. The squared-complement form puts a quarter of the
intensity at the midpoint and six percent three quarters of the way out, which makes three quarters
of every radius in the game free and an event a thing to bump into rather than a thing to route
around. `dog_walker` is +36.5, `cafe_tables` +20.1, and one row stays negative on purpose —
`burnt_shell` is a reminder rather than an obstacle. `tests/test_events.gd` names exactly that one
as the exemption, so a **second** negative event has to be a decision somebody takes rather than a
number nobody checked.

Two consequences of the falloff shape that are easy to get wrong:

- **The telegraph fairness contract does not care.** It is stated over *distance* — how far she has
  to walk to be outside the radius — so what she pays while inside one is not its business.
- **The crowd does not want it.** A field that bites from a distance is right for an authored event
  and wrong for one of two hundred and forty bodies. The crowd pays it back in *radius* rather than
  in intensity, so a close pass costs what it always did.

**Running is the wrong move against every event you route around, and the right move against the one
kind of thing that follows you.** `EXCITEMENT_FROM_RUNNING` plus the collapsed decay (3.5/s → 0.5/s)
beats the shorter exposure for every row that merely emits, and `tests/test_events.gd` asserts it
row by row — it had only ever been *measured*, and a change to the falloff shape broke it silently
in four rows before anyone noticed. The exception is `EventDef.pursues`: walking and running give
**opposite outcomes** rather than the same outcome at two prices. Nothing pursues before
`Tuning.RUN_TAUGHT_DAY` — day 1 teaches the arrow keys and day 3 teaches the run, with the thing
that requires it.

## Facts the cost table does not cover

**The cost of a route is not only the events on it.** A contact with a pedestrian is ~10.8 points
and a car's horn ~8, and neither is in the catalogue. **A balance argument that reaches for the cost
table alone is answering a narrower question than it thinks.**

**Most stationary rows are solid**, so "walk straight through the centre" is a line the player
cannot take against about two thirds of the catalogue. The integral is still the right price for
*being close*; being stopped by a body is a route cost the table has never counted.

**The careless line and the careful line**, five seeds of forty-second walks: 73 contacts down an
arterial lane centre against 5 on the midline between two lanes — **14.6:1**. The ratio, not either
number, is what makes the crowd a decision.

**The careful line has to be wide enough to aim at.** A contact fires inside `BUMP_RADIUS` of a lane
centre, so with lanes a tile apart the clear line is `32 − 2 × 14` = four pixels, which is not
something a player aims at. `CrowdLanes.SIDEWALK_LANE_SPREAD` widens it by moving the two lanes of a
footway toward the pavement's own edges. **Widen the street, not the body** — `BUMP_RADIUS` is what
makes a contact mean *walking into somebody*, and buying the same line by shrinking it would make a
contact require a near-perfect overlap.

**When two systems price the same choice, check they are not pricing it in opposite directions.**
Contacts and ambient noise are the pair that can do it: if one rewards the line the other punishes,
a player who finds either has found the other's punishment. That is not a balance error, it is a
design that cannot be played.

**Walking an ordinary pavement is free; standing on one is not.** Every line across an ordinary
footway is net recovery while walking — the crowd charges 55–87 points over forty seconds against a
decay that pays back 140. The cost of standing is `EXCITEMENT_DECAY_IDLE`, which is zero recovery,
and not the crowd.

## The noise floor is emergent, never a constant

A street is loud because there are people and cars on it, which the player can see. **If you find
yourself adding a city-wide "background noise" number, that is the thing this rule exists to stop.**

## Re-measure rather than quote

A measurement in a doc has a shelf life. This project once carried "the careful line is gone"
through four milestones after it had stopped being true, because nobody re-measured after the crowd
moved. **When a number is load-bearing for an argument, take it again.**
