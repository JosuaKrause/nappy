# What a route actually costs

Read this before arguing from the cost table, changing the falloff, the walking decay, a field's
radius or intensity, or `EventScheduler.WALL_WORTH_OF_COST`, and before adding a row that is free
or one that is cheaper to run past. How the table is generated and reviewed is in `SKILL.md`.

## What the falloff and the decay do to a price

**Walking through an event costs, and the falloff's shoulder is why.** `Field.falloff()` (`src/field.gd`) is `1−t²`
between the inner and outer radius, not `(1−t)²`. The squared-complement form puts a quarter of the
intensity at the midpoint and six percent three quarters of the way out, which makes three quarters
of every radius in the game free and an event a thing to bump into rather than a thing to route
around.

**Two short lists hold every row that is allowed to be free, and both are in
`tests/test_events_costs.gd`.** The **scenery** (`_SCENERY`: `burnt_shell`, `poster_crew`,
`poster_crew_square`) is there so a street looks different rather than costs something. The
**detainers** (`_PRICED_BY_THEIR_CAPTURE`: `chatting_mother`, `checkpoint_hut`, `checkpoint_post`)
are priced somewhere else entirely: their cost is `CHAT_EXCITEMENT` charged over the hold, so a
field sized to clear the walking decay as well would charge the same body twice, and the test holds
them to charging their capture instead. A **third** free row has to be a decision somebody takes
rather than a number nobody checked.

**Raising the walking decay does not lower every row's cost by the same amount.** The decay is
netted off over the *time* the crossing takes, so a wide, moderate row loses far more of its price
than a narrow, intense one — `protest` is the case — which is how a wide field ends up friction
rather than a wall. `EventScheduler.WALL_WORTH_OF_COST` is stated in points of the meter, so it is
re-derived from the cost table whenever a rate moves rather than left alone.

Two consequences of the falloff shape that are easy to get wrong:

- **The telegraph fairness contract does not care.** It is stated over *distance* — how far she has
  to walk to be outside the radius — so what she pays while inside one is not its business.
- **The crowd does not want it.** A field that bites from a distance is right for an authored event
  and wrong for one of a crowd's bodies. The crowd pays it back in *radius* rather than in
  intensity, so a close pass costs what it always did.

**Running is the wrong move against every event you route around bar one, and the right move against
the one kind of thing that follows you.** `EXCITEMENT_FROM_RUNNING` plus the collapsed decay
(`EXCITEMENT_DECAY_WALKING` down to `EXCITEMENT_DECAY_RUNNING`) is a fixed price per second, so it
beats the shorter exposure for every row whose mean emission along the line stays under the
threshold those numbers set — which is every row but `car_accident`, the one asked to cost more
than half the meter to squeeze past. `tests/test_events_costs.gd` asserts it row by row and names that
exemption by id (`_RUNNING_IS_CHEAPER`) rather than skipping it, because a rule that is only ever
*measured* breaks silently when the falloff moves. **A second name on that list is a design
decision, not a number** — any row that has to charge fifty points inside a short field will cross
the threshold, and the answer is either a wider quieter field or accepting that sprinting past
saves a little. The exception is a row with an `EventDef.pursuit`: walking and running give **opposite outcomes**
rather than the same outcome at two prices. Nothing pursues before `Tuning.RUN_TAUGHT_DAY` — day 1
teaches the arrow keys and day 3 teaches the run, with the thing that requires it.

## Facts the cost table does not cover

**The cost of a route is not only the events on it.** A contact with a pedestrian is ~10.8 points
and a car's horn ~8, and neither is in the catalogue. **A balance argument that reaches for the cost
table alone is answering a narrower question than it thinks.**

**Most stationary rows are solid**, so "walk straight through the centre" is a line the player
cannot take against much of the catalogue. The integral is still the right price for *being close*;
being stopped by a body is a route cost the table has never counted.

**The careless line and the careful line**: contacts down an arterial lane centre against contacts
on the midline between two lanes. **The ratio, not either number, is what makes the crowd a
decision.** The line has to be wide enough to aim at, so `CrowdLanes.SIDEWALK_LANE_SPREAD` widens it
by moving a footway's two lanes toward its edges. **Widen the street, not the body** — `BUMP_RADIUS`
is what makes a contact mean *walking into somebody*. Why the radius is set by the lane spacing is
`docs/MECHANICS.md`, "A body is solid".

**When two systems price the same choice, check they are not pricing it in opposite directions.**
Contacts and ambient noise are the pair that can do it: if one rewards the line the other punishes,
a player who finds either has found the other's punishment. That is not a balance error, it is a
design that cannot be played.

**Walking an ordinary sidewalk is free; standing on one is not.** Every line across an ordinary
footway is net recovery while walking — its crowd charges less over a walk than the walking decay
pays back. The cost of standing is `EXCITEMENT_DECAY_IDLE`, which is zero recovery, and not the
crowd.

**The ground multiplies the decay, so a crowd load compared to the raw constant is the wrong
comparison** — the spine gives back almost nothing and a park twice what a street does. State a
floor against `City.decay_multiplier()` at the point it was measured, or the same number flatters
one street and libels the other. `tests/probes/m117_decay.gd` walks each ground and prints the net
rate, which is how these are set rather than derived.
