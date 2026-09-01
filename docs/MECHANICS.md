# Nappy — Mechanics & Tuning

All constants live in `src/autoload/tuning.gd` (autoload name `Tuning`) so they can be
balanced in one place. Values below are the design intent; the script is the source of truth.

## The two meters

### Sleepiness (0 → 100)

The win meter. Fills only under the right conditions.

| Condition | Rate (per second) |
| --- | --- |
| Walking, excitement below calm threshold | `+0.42` |
| Walking, in a **four-block calm zone** | `+0.42 × 21` = `+8.8` |
| Walking, in a **two-block** calm area | `+0.42 × 29.7` = `+12.5` |
| Walking, in a **single-block** calm area | `+0.42 × 42` = `+17.6` |
| Running | `0` (never fills while running) |
| Idle / near-idle | `-1.0` (drains) |
| Excitement at or above `CALM_THRESHOLD` | `0` (frozen, never drains) |

**Key rule:** while `excitement >= CALM_THRESHOLD` (default `35`), sleepiness does not rise
at all. It does not drain either — the baby is just too interested in the world.

At `sleepiness = 100` the baby falls asleep and the day enters its **return phase**.

**Where a day is won.** These three numbers are pitched against the *day*, not against each
other, and they are what makes the walk the game:

- A whole day of undisturbed street walking reaches about **76** of 100. The street is real
  progress and can never be enough, so circling the starting block cannot win a day.
- A calm stretch clears the meter in **11.3s** in a four-block zone and **5.7s** in a single
  block, and the walk out has already contributed. A second in a park is worth twenty-one on the
  pavement, because the park has to be *obviously* the answer. **The reward moves whenever the walk
  to it gets harder**: everything between the doorstep and the park — a solid catalogue, a crowd
  that bites, a pacing man, a robber — is spent on the way there, which is where the day is meant
  to be lost, and a reward left the same length while the journey grows turns the park into a wait.
- Standing still drains faster than walking fills, so waiting is never a strategy — but it
  drains *slower* than a calm zone fills, so stopping to let something pass stays a move
  worth making.

**And the calm has to be big enough to walk in.** The three rates above are jointly sufficient for
a *lap*: progress requires motion, so a calm area smaller than a stretch of walking is somewhere you
circle rather than somewhere you go. A four-block calm zone is 704px square — 10.8s corner to corner
against the 11.3s a full meter takes — so the calm is a route. A **2×1** zone is the same claim on
one axis: 704px long, 7.7s end to end against the 8.0s two blocks fill in. Both margins are narrow
and it is the relationship rather than either number that has to survive: **a calm area must be more
than one lap wide.** See `docs/CITY.md`, "Calm zones".

**The rate is a curve over the lot's size, and it exists to pay for that lap rather than to be
generous.** It goes as `1 / sqrt(blocks)`, normalised so a 2x2 zone is the base — **21x for four
blocks, 29.7x for two, 42x for one.**

**It divides by the side rather than by the block count**, and that is the trap in it: a 1x1
against a 2x2 is a factor of two in width and *four* in area, so dividing by blocks makes a single
block four times a zone where twice is what the design wants. It is also what the design says in
words — *a lap is a length, not an area.* Paying inversely to width pays every size about the same
for one traverse of itself — **1.4 traverses for a single block against 1.05 for a zone**, against
2.75x apart at a flat rate — so a small calm area is not the weaker destination for a reason that
has nothing to do with what it is, and *which* calm area to head for stays a real question.
`tests/test_generator.gd` holds that ratio rather than either number.

**A day is aimed at a minute of play, with a grace of three.** Dusk at 180s is the outer bound, not
the target: a day walked well is over in about a minute, and the rest of the clock is there for a
day that goes wrong. It also means the day is not lost to the *meter* — once calm ground is reached
the meter is a formality — so **the difficulty has to live in the walk**, which is what every
obstacle between the doorstep and the park is for.

The first two are asserted in terms of `day_length()` rather than as numbers
(`tests/test_meters.gd`), so lengthening the day cannot quietly make the street sufficient
again. `tests/test_balance.gd` then checks the same claim against a real city with that
day's crowd and events standing in it.

### Excitement (0 → 100)

The lose meter. Anything interesting in the world pushes it up.

Sources:

| Source | Contribution |
| --- | --- |
| Proximity to an active event | `intensity × falloff(distance)` per second |
| Proximity to a passer-by | `4.2 × falloff(distance)`, inner `22`, outer `55` |
| Proximity to a passing car | `5.4 × falloff(distance)`, inner `38`, outer `104` |
| Running | `+ (speed − walk_speed) / (run_speed − walk_speed) × 14.0` per second |
| Standing in an alley | `+3.0` per second (slow, constant dread) |
| Sudden events (cat dash) | one-shot impulse on trigger |

The crowd is the same kind of quantity as an event and is summed the same way, which is
what makes the **noise floor emergent**. There is no city-wide "background noise" number
anywhere; a street is loud in proportion to how busy it is, and a park is quiet because
nobody is in it. Both facts are visible on screen, which a constant never could be.

Excitement moves at the **net** rate, `incoming − decay`:

| Player state | Decay per second |
| --- | --- |
| Walking | `3.5` |
| Running | `0.5` |
| Idle | `0.0` |
| In a calm zone | decay × `2.2` |

**The ordering is motion-shaped, and that is the model.** The pram is a rocking chair with wheels
on: what settles a baby is being pushed. Walking settles her most, running is still motion and
settles a little, and standing still settles nothing at all.

**An idle decay faster than walking is the trap here**, and it is the ordering a physical reading
of "resting calms her" produces: it makes standing still the strongest move in the game — a full
meter cleared in seventeen seconds for seventeen points of sleepiness, anywhere, including the
middle of a street she has no business being on. A trace of that reads as a minute or more with no
entry in it at all.

Netting rather than "decay only when nothing is happening" is what makes the decay column
matter. Two consequences fall out of it, and both are wanted:

- **Standing still freezes the meter** rather than clearing it: the day stops moving in both
  directions at once. Waiting is not a plan, and the counterplay it replaces was always the better
  one — walk somewhere quiet, which is what the calm-zone multiplier is for and what the whole
  route is about.
- **Sprinting past an event is far worse than walking past it** — running contributes
  excitement *and* drops decay to almost nothing, so the same event hits roughly three
  times as hard. Panic is punished twice, everywhere except against the one thing that
  chases (see "Running that matters" below).

It also sets a floor on what counts as an event: a source weaker than `3.5` cannot move
the meter on a walking player at all. That is deliberate — it is what lets an empty alley
apply constant *pressure* (`+3.0`) without ever being a threat on its own.

The crowd is pitched deliberately across that line. One person at arm's length is `4.2`,
just over the walking decay, so brushing past somebody costs — and the pavement is two
tiles wide, so *how close to pass* is a choice the player makes rather than a toll they
pay. One car is `5.4`, over the walking decay but nowhere near enough to matter alone: no single car
is dangerous. The danger is that on a main road there is always another one, and the arterial's
mean load sits between one and three times the **walking** decay. Above three it fills the meter
faster than the street can be crossed, which is a street nobody can use rather than a route
decision; `tests/test_crowd.gd` holds both ends of that.

**Every one of those comparisons is against the *walking* decay**, because standing still settles
nothing: the only question a street has to answer is what it costs to walk down, which is what a
route is made of.

At `excitement = 100` → **crying** → day lost.

## Baby state machine

```
        ┌────────────────────────────────────────────┐
        │                                            │
   ┌────▼────┐  sleepiness = 100   ┌────────┐        │
   │  AWAKE  ├────────────────────▶│ ASLEEP │        │
   └────┬────┘                     └───┬────┘        │
        │                              │              │
        │ excitement = 100             │ excitement ≥ │
        │                              │ WAKE_THRESH  │
        ▼                              └──────────────┘
   ┌─────────┐                     (sleepiness drops to 50,
   │ CRYING  │  day lost            back to AWAKE)
   └─────────┘
```

While `ASLEEP`:

- Sleepiness is pinned at 100.
- Excitement still accumulates, but from a *lower* baseline — a sleeping baby is harder to
  disturb. Incoming excitement is multiplied by `SLEEPING_SENSITIVITY` (default `0.55`).
- If excitement crosses `WAKE_THRESHOLD` (default `60`), the baby wakes: sleepiness resets
  to `WAKE_SLEEPINESS_PENALTY` (default `50`) and the day continues.
- If excitement reaches 100 while asleep, the baby wakes *crying* → day lost.

This makes the walk home a real second act rather than a victory lap.

## Movement

| Property | Value |
| --- | --- |
| Walk speed | `92 px/s` |
| Run speed | `168 px/s` |
| Acceleration | `700 px/s²` |
| Friction (deceleration) | `900 px/s²` |
| Idle threshold | speed `< 12 px/s` counts as idle |

Controls: arrow keys or WASD to walk, hold **Shift** to run, **E** to interact,
**Esc** to pause.

The stroller faces the movement direction and lags slightly behind the mother, so the
player can read direction at a glance.

## The street has physics

**A crowd that is a field with a picture attached is not a street.** If you can walk through a
person, through a car, through a queue at a bus stop, and the only thing that happens is that a
number moves, then the route is never a decision: every pavement is identical, none of them can
hurt you, and a day can cross the whole city without meeting anything.

Four mechanisms, all of them in `src/crowd/crowd.gd`, all of them about the *player* — which
is why they live there rather than in `CrowdAgent`, which has no business knowing she exists.

### A body is solid

| | |
| --- | --- |
| Contact radius | `14 px`, centre to centre, released past `19 px` |
| Separation | positional, `70%` to them and `30%` to her |
| Deflection | `55 px/s`, decayed by `FRICTION` |
| Cost | one jolt: `18/s` fading over `1.2 s`, so **~10.8 points** |

The jolt is pitched against what the *authored* content costs: the crowd is most of what a street
costs and must not be all of it.

**The radius is set by the lane spacing, not by a body's width.** Pedestrian lanes are one tile
apart, so the only line with no contact on it is the midline between two of them. At 18px there is
no such line anywhere on a two-tile pavement, and walking the arterial costs eleven bumps in forty
seconds however carefully it is done — a toll, not a decision. At 14px the same walk is two.

Three things about it that only show up by walking a rig down a real pavement and reading the
meter, none of which a data-level test can see:

- **Somebody bumped along their own line of travel steps aside**, rather than being pushed
  further along it. She walks at 92 and they walk at 60, so pushing them straight ahead
  separates nobody: it ploughs a wedge of pedestrians down the pavement in front of her, all of
  them permanently in contact and permanently loud.
- **A contact startles once, not once per frame.** `CrowdAgent.touching` is the hysteresis.
- **The separation is positional and the deflection is not.** Resolving position means two
  bodies can never end up inside each other however fast she is going; the velocity kick on
  top is what makes a crowd somewhere you get pushed around. It is applied with
  `move_and_collide` rather than folded into `velocity`, because `velocity` is what
  `is_idle()` and `run_excess_ratio()` answer from and those two questions are about the
  *player*, not about the crowd.

### The bump is a source, not a write

**Excitement stays a pure query.** A contact does not touch `Baby.excitement`; it *startles
the person she walked into*, and `Crowd` sums that agent like it sums every other one. So
contacts still compose by plain addition, there is still no ordering to get wrong, and
`City.total_excitement_at` still adds exactly two things. See the **events** skill.

### A car is lethal

Stepping into the carriageway in front of a moving car ends the day (`hard_fail`
`car_strike`). The strike volume is a **box** — 26px along the car, 14px across — because a
car is two tiles long and one wide, and a radius that covered its length would kill people
standing beside it. It only counts while she is standing on a road tile, and a car below
`20 px/s` cannot run anybody over, so a car halted at a zebra is scenery.

### The traffic fairness contract

A car is not an event: it has no telegraph, it is not in the catalogue, and
`validate_event()` never sees it. Two things stand in for the telegraph, and
`Tuning.validate_traffic()` checks the second on boot.

1. **The road itself.** The carriageway is painted, permanent and learnable, and the kerb is
   an edge she chooses to step over. Same shape of contract as `alley_robbery`, where the
   alley is the warning.
2. **The horn.** A car sounds it `1.6 s` out at anybody standing in its lane, which must
   exceed the time to walk the whole width of the carriageway with the doubled margin every
   hard fail is owed: `64px × 2 / 92 = 1.39 s`. The horn is itself a jolt (~8 points), so a
   near miss costs something even when it stays a near miss.

The horn also raises the **exclamation mark over the player**, the load-bearing cue of the visual
vocabulary. See docs/EVENTS.md.

Belt and braces: the strike box is geometrically incapable of reaching over the kerb. A car
sits half a tile off the middle of the carriageway, so its far edge is `16 + 14 = 30 px` out
and the kerb is at `32`. `tests/test_crowd.gd` asserts it, because a box that reached the
pavement would kill people who never stepped off it and would look exactly like a fair death.

### The zebra is a negotiation

Traffic **gives way** at a crossing somebody is waiting at: a car looks `CAR_ZEBRA_SIGHT`
(200 px) ahead, which is nearly four times the 53 px it needs to stop from top speed. The
margin is the point — the slowing has to be *visible from the kerb*, because a player deciding
whether to step off needs to see the car slowing rather than discover afterwards that it would
have.

So the crossing is the safe way over and jaywalking is the fast way over, which is the choice the
zebra exists to offer.

**A car gives way *at a place*.** Braking toward **zero speed** from wherever it noticed leaves a
car stopped wherever the curve ran out — with four times the room it needs, most of a block short —
and says nothing about not stopping on the paint. Both halves of that are the same missing thing:
somewhere to stop.

Three rules, and they are separable:

- **The target is the stop line**, `CAR_STOP_LINE_SETBACK` before the near edge of the zebra.
  Measured to the car's centre, so its nose ends up a few pixels clear of the paint.
- **The approach is shaped by `CAR_ZEBRA_APPROACH_BRAKE`, not by `CAR_BRAKE`.** The gentle rate
  is what makes the easing begin as the crossing comes into sight; `CAR_BRAKE` stays in reserve
  for the emergency. Shaping it with the hard brake makes the onset of braking and the commit
  point the same instant, and then no car ever stops at all.
- **A car too close to stop commits and clears the crossing.** Measured against the *paint*
  rather than the line: overrunning into the setback is a car stopped a little close, and
  overrunning onto the zebra is the thing being prevented. Since sight is four times the
  braking distance, this only ever fires for somebody who stepped up after the car had
  committed, never for a player already waiting — and there the horn is the contract rather
  than the brake.

Why it matters more than tidiness: the painted carriageway is one of the two things standing in
for a telegraph in the traffic fairness contract. A car halted on the zebra cannot hurt anybody
— it is under `CAR_STRIKE_MIN_SPEED` — but it is *unreadable* scenery parked on the one place
the game has told the player is the safe way across.

### Which side of the road

**The city drives on the right**, and that is a rule about the side of the road relative to
*travel*, so it flips with the axis. **Stating it over the lane offset is the trap**: "offset 3
runs the positive way along the axis" is eastbound in the southern lane on an east-west street,
which is right-hand traffic, and southbound in the eastern lane on a north-south street, which is
left-hand traffic. `road_direction()` and `road_lane()` are a pair that both take the axis, and
`tests/test_crowd.gd` asserts it for both axes and both directions: the lane a car is in is the one
on its own right.

**Nothing in a suite or a screenshot can see that going wrong.** Separation, headway, capacity and
noise are all true whichever side anybody drives on, and a stopped frame does not say which way a
car is pointing. It shows up the moment a human watches a junction.

**Walkers have no side convention**, and that is deliberate. They are not mirrored — they are
unordered, which is a different thing. Giving them one is a design change with a measured cost
attached: the contact numbers the pavement is balanced on — eleven bumps down a lane centre against
one on the midline — assume somebody may be coming the other way in any lane.

### Traffic queues

A car keeps `CAR_HEADWAY_TIME` seconds of clear road in front of it and never closes to less
than `CAR_GAP_MIN`, which is a car's own length plus a nose. The two wants compose by taking
the lower, so a queue at a zebra is the front car stopping and everybody behind it honouring
the headway rather than a special case for queues.

The **separation is positional**, not a brake, and that is the load-bearing part. A brake keeps
a gap that already exists and cannot open one that does not: two cars inside each other both
choose zero and stay there forever, and recycling puts a car into a lane at a point it cannot
see. `Crowd.space_out_the_traffic()` resolves each lane from the front backwards, so a whole
chain comes apart in one pass. It is the same shape as the player's bump, for the same reason —
see the **events** skill.

The relationship, rather than the numbers: **the headway has to outlast the time it takes to
brake from cruise**, or a car cannot physically honour the gap it is keeping and the queue
resolves by interpenetration again however good the controller is.

## The world near you

Nothing is loaded upfront: the crowd and the events exist in the few blocks around the player and
nowhere else.

**The city is 160×160 tiles and the visible world is 640×360 px — about 20×11 tiles, well under one
percent of it.** A city-wide population is divided by that before any of it reaches the player,
which is how a hundred cars read as a street you can ignore. The licence for spending the budget
locally is that continuity of a car you cannot see is unobservable, so it is free to give away, and
density where somebody is looking is not.

**The crowd is a field.** `CrowdField` is a `CROWD_FIELD_RADIUS` box centred on the player.
Agents that pass the edge they are heading for — or fall further behind the edge they came in
at than the entry band is deep, or end up on a street the box no longer reaches — are recycled
into a band outside the edge they will re-enter through. `Tuning.CROWD_PEDESTRIANS_PER_ACT` and
`CROWD_CARS_PER_ACT` are populations *of the field*.

The radius has one floor and it is the screen: half the viewport diagonal is the furthest
anything visible can be from the camera, so an agent recycled outside that is always off-camera
when it appears, whichever way she is facing.

**Events stream.** `EventScheduler` still plans the whole day across the whole city — every
guarantee the game makes is a property of the *plan*, so nothing about one usable park, two
routes to two calm areas, one-shots firing once, or determinism from a seed is touched. What
changed is when a plan becomes a node: `EventManager.stream_around()` puts a planned event in
the world when the player comes within `EVENT_STREAM_RADIUS` and takes it away again when she
leaves, with `EVENT_STREAM_HYSTERESIS` so pacing on the boundary does not rebuild it every
other frame. An event that has finished is **spent**: streaming may take an event away and give
it back while it is running, and may never rewind one that is over.

`EVENT_STREAM_RADIUS` has a second floor on top of the screen one, and it is what makes
streaming an event legal rather than a way of dropping things on people: it is wider than the
widest field in the catalogue, so an event is outside its own outer radius at the moment it
becomes visible.

The gameplay consequence is larger than the frames. Without streaming a day can pass with **zero**
events ever coming within reach: a twenty-second event planted across the city at dawn is over
before the player could have reached it. An event that waits for her is an event she meets.

**And some events have no place at all.** `EventDef.SpawnMode.AHEAD_OF_PLAYER` events are
budgeted by the day and sited by `EventDirector`, which puts them across her line
`AHEAD_LEAD_DISTANCE` in front of her while she is walking. See docs/EVENTS.md, "Where an event
happens", for which events earn that and what the contract on them is.

## One event per block

**The density target is one event per block**, and streaming is what makes it computable: the
stream radius is a knowable fraction of the map, so what she is standing in is a knowable fraction
of what the day planned. `EventScheduler.budget_for()` is stated per block for the same reason, and
the caps have to move before the budget — see docs/EVENTS.md, "The density, and why it is caps
before budget".

What the density does to the game is a change of kind, not of degree. A street with one event every
four blocks is a street with an event *on* it — you see it, you route around it, and the rest of the
walk is empty. A street with one event per block has no empty stretch to route into, so the question
stops being *"can I avoid this"* and becomes **"which of these is cheapest to walk through"**. That
is the route decision the whole game is about, and a sparse city cannot ask it.

## Excitement falloff

Each active event has an `intensity`, an `inner_radius` and an `outer_radius`.

```
contribution(d) = intensity                              , d <= inner_radius
                = intensity × (1 − t²)                   , inner < d < outer
                = 0                                      , d >= outer_radius
   where t = (d − inner_radius) / (outer_radius − inner_radius)
```

**The shape has a shoulder on it, and that is a design decision rather than an implementation
detail.** The meter has to go substantially up from some way off rather than waiting for contact.

**`(1 − t)²` is the shape that looks equally reasonable and inverts the game.** It puts a
**quarter** of the intensity at the midpoint of the falloff band and six percent three quarters of
the way out, so a café at 12/s sits under the 3.5/s walking decay across the whole outer 60% of its
own field — and a run log written at an event's own outer radius reads `events 0.0`. An event you
are not charged for until you touch it is not something to route around, it is something to bump
into.

`1 − t²` holds **three quarters** of the intensity at the midpoint and reaches zero only at the
outer edge. Two consequences worth knowing before touching it again:

- **The telegraph contract is unaffected.** It is stated over *distance* — how far she has to walk
  to be outside the radius — and no radius moved.
- **It applies to the crowd too, and the crowd compensates in radius.** A field that bites from a
  distance is right for an authored event and wrong for one of a couple of hundred bodies, so the
  pedestrian and car outer radii are tight (55 and 104) — a close pass costs what it should and the
  summed street floor lands where the balance wants it.

## Running that matters

Running is deliberately the wrong move against every event you route **around**. The numbers above
are why: `EXCITEMENT_FROM_RUNNING` (14/s) plus the collapsed decay outweighs the shorter exposure
for every row in the catalogue, and `tests/test_events.gd` asserts it row by row. That is not an
accident to be tuned away — an event that merely emits is a *place*, and the answer to a place is
a route.

The exception is the one kind of thing a route cannot answer: something that **follows**.
`EventDef.pursues` marks it, and three properties make walking and running give *opposite
outcomes* rather than the same outcome at two prices:

| | |
| --- | --- |
| Speed | strictly between `WALK_SPEED` and `RUN_SPEED`, by `PURSUIT_MIN_MARGIN` either side |
| Lethal | `hard_fail`, so the alternative to running is losing the day rather than paying points |
| Bounded | gives up after `PURSUIT_TIME`, **or** after `Tuning.PURSUIT_SHAKEN_OFF` seconds of the gap opening, because a run is priced per second and an unbounded chase is a loss however well it is played |

Its telegraph is the **approach**, the way a fire engine's is. A pursuer that stands still while it
telegraphs hands her more ground in two seconds than the entire chase can take back; what she is
owed is `PURSUIT_MIN_NOTICE` seconds of visibly being closed on. `Tuning.validate_pursuit()` is the
whole contract and it runs on load.

### The stand-off, and what a contract in seconds cannot say

**A contract stated entirely in speeds and durations can pass every line of itself while the dog is
killing people, because a pursuit is played out in distances.** A pursuer sited across her line a
couple of hundred pixels ahead — *where she was already walking* — closes that gap in under a second
and then stands **inside its own lethal radius** for the rest of a telegraph that is not yet allowed
to kill her. The instant it is, it does, from a standing start, with nothing she could have done
after the first second.

Two rules answer it, and they are the same rule twice: the contract restated as geometry.

- **`Tuning.pursuit_standoff()`.** The telegraph is spent closing to `inner_radius + speed ×
  PURSUIT_REACTION` and *holding* it, backing off if she walks in, because she will: it is sited in
  front of her and forward is where she was going. Clamping the approach at zero instead leaves the
  contract true of the dog and false of the encounter — it stands politely still while she closes
  the gap herself.
- **`Tuning.PURSUIT_SHAKEN_OFF`.** It gives up once the gap has been **opening** for that long.
  Without a break-off at all, the price of the *right* answer is set by the clock rather than by the
  escape — the same forty points whether she reacted on the first frame or the last, which is a
  player doing exactly what the HUD asked and losing the day to the meter with the dog well behind
  her.

`charging_dog` is 130px/s and intensity 12 for two reasons worth keeping. 130 is *symmetric*:
walking loses 38px a second and running gains 38, which is the version of "opposite outcomes" a
player can feel. And it is lethal — it does not also need to be the loudest thing in act I.

### Why the break-off is a rate and not a distance

A break-off stated as a distance needs two inequalities to be safe — walking must not reach it
inside the chase, running must — and they pull against each other in the same three numbers. That is
how a stand-off widened to buy reaction time eats the escape from the other end, and how a robber's
trigger, which has to fit *between* the two, ends up with an eleven-pixel window to live in.

Stated as a rate, both facts come free from the speed clauses that were already there. A pursuer is
faster than a walk and slower than a run, so the gap can only open while she is running and must
close while she walks:

- **Walking away can never end a chase.** Not "loses if the arithmetic works out" — it cannot happen
  at any distance, for any row, at any radius.
- **Running away always ends one**, in `PURSUIT_SHAKEN_OFF` seconds plus the about-turn, and no
  slower for a large pursuer than for a small one.

The measured encounter, on a rig that **accelerates** (`tests/test_events.gd`, `_answer_rig`) — a
constant-speed rig cannot see any of this, because nobody can turn round in nought seconds:

| she | outcome | cost |
| --- | --- | ---: |
| turns and runs at the lunge | it gives up 1.1s later, 68px at the closest | 0.86s of running, **12 points** |
| dithers 0.1s, then runs | it gives up, 45px at the closest | 0.86s, 12 points |
| dithers 0.2s or more | caught | the day |
| walks away | caught | the day |
| stands still | caught | the day |

**The price of the answer is flat, and that is the design**: running from a thing that follows costs
about a tenth of the meter, and hesitating costs the day. What reacting sooner buys is margin — 68px
against 45 — rather than a discount.

**The open question is the window at the lunge**, which the table puts between 0.1s and 0.2s. She is
walking *into* the thing at that instant, so the gap closes at `pursue_speed + WALK_SPEED` and the
stand-off is worth about a third of the `PURSUIT_REACTION` it was bought with; reversing a walk into
a run costs another 0.37s on top. A player answers during the **telegraph**, where the dog is
visible and closing for two and a half seconds, so the lunge is the worst case rather than the
expected one — but the worst case is what a contract is for. Widening it means widening the
stand-off, and a stand-off much past 180px is a dog that visibly reverses away from her through its
own telegraph, which a player has watched and called nonsense. See `docs/PLAYTEST-10.md`, section C.

### A pursuer can be a place before it is a moment

`charging_dog` is a **moment**: the director sites it in front of her and the chase is the whole of
it. `EventDef.pursues_within` is the other shape — a thing that is **somewhere**, that you can see
and price and route around, and that becomes a chase if you do not. Three states rather than two:

| | it emits | it can kill | it moves |
| --- | --- | --- | --- |
| **waiting** | at full strength | no | no |
| **noticing** (`telegraph_time`) | at full strength | no | closes to the stand-off |
| **chasing** (`duration`) | at full strength | yes | holds, then comes |

Two things are deliberately not the same as an ordinary telegraph. The **clock starts when it
notices**, not when the day put it there — a robbery whose telegraph ran at dawn four streets away
would arrive with no notice in it at all. And its notice does **not** damp what it is emitting:
`TELEGRAPH_INTENSITY_FRACTION` means *this has not started yet*, and a man who has been standing in
that alley since she came round the corner has started. What has not started is the lunge.

`validate_pursuit()` gained two clauses for the trigger and a third that was found by measuring
rather than by thinking. It has to notice her from **outside its own stand-off**, or the notice is
spent standing still; from **inside its own field**, or it decides about her before she could have
felt it; and from **inside its break-off** — which is the one that bit. At a trigger of 170 against
a break-off of 170 the rig strolled away from the robber every time, because she was already
standing at the distance that means it has lost her.

**All three clauses are stated over derived quantities**, which is what lets the robber's trigger
and field move — as the stand-off changes, the trigger has to stay outside it and the field outside
the trigger, so *on sight* keeps coming before *he has seen you* — without any clause being
rewritten.

| she | outcome | cost |
| --- | --- | ---: |
| walks up and stops | caught | the day |
| walks up and past | caught | the day |
| walks away at a walk | caught | the day |
| runs when he stands up | shakes him off in 1.5s | 21 points |
| dithers a second, then runs | shakes him off in 1.6s | 22 points |

### A beat rather than a journey

`EventDef.paces` walks a route and turns round at the ends, for ever. It is the difference between
a `dog_walker`, which is *going somewhere* and is gone at the end of thirty tiles, and a man
shouting, who is **at** a place. Without it the only way to say the second thing is to make him
stationary, and a stationary source on a fixed patch is a line you draw once rather than something
to time.

A paced event never reaches the end of its path, so it never departs and never expires: it is a
fixture that moves. The price is its body — anything mobile is exempt from "solid things are solid",
because a moving wall on a two-tile pavement pins her against a building. What stops you walking
through a man shouting is the meter: intensity 14 over 210px.

**Nothing pursues before `RUN_TAUGHT_DAY` (day 3).** Day 1 teaches the arrow keys and says nothing
about running; day 3 is when something comes after the pram, and the HUD says *Hold SHIFT to run*
on the frame it telegraphs rather than at dawn — a line of text at dawn is a control list, and the
same line over a dog at the pram is an instruction. `EventDirector` moves the first pursuit of that
day to the head of its queue, so the lesson is not left to a weight of 1.4.

## Telegraphing

Every event has a `telegraph_time` (default `2.5 s`, longer for big events) during which:

- The event is **visible** (sprite, warning ring, audio cue).
- It emits at most `TELEGRAPH_INTENSITY_FRACTION` (default `0.15`) of its full intensity.

A telegraph the player cannot perceive is not a telegraph. **Every cue must be legible with
the sound off** — audio reinforces the warning, it never carries it (see docs/EVENTS.md,
"Audio is never the only channel"). `Tuning.validate_event()` checks the geometry and cannot
tell whether the player was actually warned, so that part is on the author.

The design contract: *from the moment an event becomes visible, the player must have enough
time to walk out of its outer radius at normal walking speed.* Event authoring must satisfy

```
telegraph_time × walk_speed >= escape_distance × margin
```

where `margin` is 2 for `hard_fail` events, and

```
escape_distance = outer_radius − inner_radius     for anything at or below walking pace
                = outer_radius                    for anything FASTER than walking
```

The split matters. A stationary event, or one slower than the player (a dog walker at
32 px/s), only has to be walked away from, so clearing the falloff band is enough. Something
faster than the player — a fire engine at 190 px/s — cannot be outwalked at all; it sweeps
its entire outer radius along the street, and the only escape is getting off its line. So
it must give enough warning to clear the *full* radius. That is why the fire engine's
telegraph is 4 seconds and not the 2.9 the band rule would have allowed.

`Tuning.validate_event()` asserts this on load, and `tests/test_events.gd` checks it over
the whole catalogue, so an unfair event fails loudly rather than quietly ruining a run.

## Calm zones, and what every other ground does

Parks, quiet squares, forests and courtyards are `CALM` tiles. Inside them:

- Sleepiness gain ×`21` in a four-block zone, more in a smaller one — a second in a park is worth
  twenty-one on the street. Only calm ground fills the sleepiness bar at all, which is why that half
  stays a threshold rather than a rate.
- Excitement decay ×`2.2`, so the park reads on **both** bars.

**And the excitement half is a rate everywhere**, not calm-or-not:
`WorldContext.decay_multiplier()` answers with what this ground does, and the order is

    calm 2.2  >  precinct 1.5  >  ordinary street 1.0  >  main road 0.6

so a route is a **recovery rate** and not only a set of things to walk past. Two consequences worth
holding on to. A precinct is worth walking to although it is loud — a retail street is busy, and it
is still the best ground outside a park to bring a meter down on. And the main road is the same
sentence inverted: it is the one ground in the city that is actively bad at letting her recover,
which is what *"a main road is crossed, not walked"* means arithmetically. Walking its
length loses a day in about fifteen seconds; that is the intent, measured.

But calm zones are contested — see `docs/CITY.md` (spoiling) and `docs/EVENTS.md`. The spoiling
remembers a whole **act** rather than a night, and the city has one calm area per day of the longest
act plus one in reserve (`Tuning.calm_areas_needed()`), so finding a new one is the work of an act
and the parks go quiet again when it turns.

## Alleys

Alley tiles apply a constant `+3.0/s` excitement trickle. They are shortcuts, and they are
where the resistance meets. Both facts are the point: the fastest route and the story route
are the ones that cost you the baby's calm.

## Day timer

Each day runs for `DAY_LENGTH_SECONDS` (default `180 s`, 3 minutes) of in-game dusk, and is
aimed at being won in about a third of that.
Running out is a day loss. The timer is shown as a light-level shift rather than a number,
with an explicit clock in the HUD corner.

## Nerves

The run-level health bar. Starts at 5. Every lost day costs one. At 0 the run ends with the
bad ending. Nerves never regenerate — this is what makes an early bad day matter.

**Five is a number to be measured, not derived**, and nobody has played a run against it: the run
log's `nerve` entries are what say where they went. What makes it hard to reason about from first
principles is that a nerve is worth more now that it buys only a retry — three attempts were set
when a lost day *also* advanced the calendar, so a nerve cost a day of the fourteen as well as a
life. A run that ends on day 3 ends before the game has shown what it is.

**A nerve buys a retry of the same day.** The calendar moves only when a day is **won**, so the
nerves are failed attempts spread wherever they are needed and the fourteen days are fourteen days
the player actually plays. A lost day costing a nerve *and* a day punishes twice for one mistake and
hides act I from the player who needs act I most.

Three consequences, all of them chosen:

- **A retry is the same day.** The city, the closures and the whole event plan are deterministic
  from the seed and the day number, which is what makes a retry worth having in a game about
  learning a route.
- **What the run spent stays spent.** Consumed one-shots and advanced block arcs are run
  history, not day content: a fire that burnt a block down did happen. The one exception is
  **where she settled**, which belongs to the attempt — see `GameState.finish_day()`.
- **The run cannot end by running out of days while nerves remain.** The bad ending is the only
  way to lose, and the run length becomes a promise rather than a budget.
