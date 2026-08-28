# Nappy — Mechanics & Tuning

All constants live in `src/autoload/tuning.gd` (autoload name `Tuning`) so they can be
balanced in one place. Values below are the design intent; the script is the source of truth.

## The two meters

### Sleepiness (0 → 100)

The win meter. Fills only under the right conditions.

| Condition | Rate (per second) |
| --- | --- |
| Walking, excitement below calm threshold | `+0.42` |
| Walking, in a **calm zone** | `+0.42 × 10` = `+4.2` |
| Running | `0` (never fills while running) |
| Idle / near-idle | `-1.0` (drains) |
| Excitement at or above `CALM_THRESHOLD` | `0` (frozen, never drains) |

**Key rule:** while `excitement >= CALM_THRESHOLD` (default `35`), sleepiness does not rise
at all. It does not drain either — the baby is just too interested in the world.

At `sleepiness = 100` the baby falls asleep and the day enters its **return phase**.

**Where a day is won.** These three numbers are pitched against the *day*, not against each
other, and they are what makes the walk the game:

- A whole day of undisturbed street walking reaches about **76** of 100. The street is real
  progress and can never be enough — so circling the starting block, which used to win a
  day outright, now cannot win one at all.
- A calm stretch clears the meter in about **24s**, and the walk out has already
  contributed. A second in a park is worth ten on the pavement, which is the whole of what
  playtest 02's finding 1 asked for: the park has to be *obviously* the answer.
- Standing still drains faster than walking fills, so waiting is never a strategy — but it
  drains *slower* than a calm zone fills, so stopping to let something pass stays a move
  worth making.

**And the calm has to be big enough to walk in.** *(M21.)* The three rates above are jointly
sufficient for a *lap*: progress requires motion, so a calm area smaller than a stretch of
walking is somewhere you circle rather than somewhere you go. A four-block calm zone is 704px
square — 10.8s corner to corner against the 23.8s a full meter takes — so the calm is a route.
See `docs/CITY.md`, "Calm zones".

**A day is aimed at a minute of play, with a grace of three.** Dusk at 180s is the outer
bound, not the target. That is deliberate after M18: a day walked well is over in about a
minute, and the rest of the clock is there for a day that goes wrong. It also means the day
is not lost to the *meter* — once calm ground is reached the meter is a formality — so the
difficulty has to live in the walk. Making it live there is what playtest 02's findings 2
and 3 are for.

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

*(Idle was `6.0` — the **fastest** of the three — until M33. That made standing still the
strongest move in the game: a full meter cleared in seventeen seconds for seventeen points of
sleepiness, anywhere, including the middle of a street she had no business being on. Playtest 07,
finding 3: "not walking at all shouldn't reduce excitement either — otherwise I can just stop in
the middle of the street and wait until everything is good." Two runs in that playtest's traces
have a seventy-four-second gap in them with no entry at all.)*

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

*(Stated against the walking decay since M33. It was the idle decay, which was the fastest of the
three rates and was therefore the right reference for "she stops here and waits". Standing still
settles nothing now, so the only question a street has to answer is what it costs to walk down —
which is what a route is made of.)*

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

*(M19. Playtest 02, findings 2 and 3; playtest 03, finding 1.)*

Until M19 the crowd was a **field with a picture attached**. You could walk through a person,
through a car, through a queue at a bus stop, and the only thing that happened was that a
number moved. That is why the route was never a decision: every pavement was identical and
none of them could hurt you, and the traced day of playtest 03 crossed the whole city without
meeting anything.

Four mechanisms, all of them in `src/crowd/crowd.gd`, all of them about the *player* — which
is why they live there rather than in `CrowdAgent`, which has no business knowing she exists.

### A body is solid

| | |
| --- | --- |
| Contact radius | `14 px`, centre to centre, released past `19 px` |
| Separation | positional, `70%` to them and `30%` to her |
| Deflection | `55 px/s`, decayed by `FRICTION` |
| Cost | one jolt: `18/s` fading over `1.2 s`, so **~10.8 points** |

The cost row is playtest 07's: it was `26/s` and ~15.6 points until M33, when the authored
content finally started carrying the share the crowd had been carrying alone.

**The radius is set by the lane spacing, not by a body's width.** Pedestrian lanes are one
tile apart, so the only line with no contact on it is the midline between two of them. At
18px there was no such line anywhere on a two-tile pavement, and walking the arterial cost
eleven bumps in forty seconds however carefully it was done — a toll, not a decision. At 14px
holding that line takes the same walk down to two.

Three things about it that were found by walking a rig down a real pavement and reading the
meter, none of which a data-level test can see:

- **Somebody bumped along their own line of travel steps aside**, rather than being pushed
  further along it. She walks at 92 and they walk at 60, so pushing them straight ahead
  separates nobody: the first version ploughed a wedge of pedestrians down the pavement in
  front of her, all of them permanently in contact and permanently loud.
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
`City.total_excitement_at` still adds exactly two things. See the invariant in `CLAUDE.md`.

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

The horn also raises the **exclamation mark over the player** — the load-bearing cue of the
M22 vocabulary, built here because M19 is what creates the danger. See docs/EVENTS.md.

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

So the crossing is the safe way over and jaywalking is the fast way over, which is the choice
finding 3 asked for.

**A car gives way *at a place*** *(M29, playtest 05 finding 1: "the cars stop at weird positions
for the zebra crossing. Sometimes half a block away, sometimes **on** the crosswalk.")*. Both
halves of that are the same missing thing. Until M29 a car braked toward **zero speed** from
wherever it noticed, so it came to rest wherever the curve ran out — and with four times the
room it needed, that was most of a block short. Nothing said *do not stop on the paint* either.

Three rules now, and they are separable:

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

### Which side of the road *(M29)*

**The city drives on the right**, and that is a rule about the side of the road relative to
travel — so it flips with the axis, and until M29 it did not. `CrowdLanes` stated the
convention over the lane *offset*: offset 3 runs the positive way along the axis. On an
east-west street that is eastbound in the southern lane, which is right-hand traffic. On a
north-south street it is southbound in the eastern lane, which is left-hand traffic.

Playtest 05, finding 2: *"the cars are not consistently driving on the right side."* It was
invisible to the whole suite, because separation, headway, capacity and noise are all true
whichever side anybody drives on, and invisible in a screenshot, because a stopped frame does
not say which way a car is pointing. It shows up the moment a human watches a junction.
`road_direction()` and `road_lane()` are now a pair that both take the axis, and
`tests/test_crowd.gd` asserts the thing that was never asserted: for both axes and both
directions, the lane a car is in is the one on its own right.

**Walkers have no side convention**, which was checked at the same time and is deliberately
left alone. They are not mirrored — they are unordered, which is a different thing. Giving them
one is a design change with a measured cost attached: M19's contact numbers, eleven bumps down
a lane centre against one on the midline, are what the pavement is balanced on and they assume
somebody may be coming the other way in any lane.

### Traffic queues *(M27)*

A car keeps `CAR_HEADWAY_TIME` seconds of clear road in front of it and never closes to less
than `CAR_GAP_MIN`, which is a car's own length plus a nose. The two wants compose by taking
the lower, so a queue at a zebra is the front car stopping and everybody behind it honouring
the headway rather than a special case for queues.

The **separation is positional**, not a brake, and that is the load-bearing part. A brake keeps
a gap that already exists and cannot open one that does not: two cars inside each other both
choose zero and stay there forever, and recycling puts a car into a lane at a point it cannot
see. `Crowd.space_out_the_traffic()` resolves each lane from the front backwards, so a whole
chain comes apart in one pass. It is the same shape as the player's bump, for the same reason —
see the invariant in `CLAUDE.md`.

The relationship, rather than the numbers: **the headway has to outlast the time it takes to
brake from cruise**, or a car cannot physically honour the gap it is keeping and the queue
resolves by interpenetration again however good the controller is.

## The world near you *(M27)*

Playtest 04, and the instruction it was emphasised in: *"don't load everything upfront — only
load / spawn things in the surrounding few blocks of the player when needed; consistency is not
that important, nobody can run after cars anyway to confirm they are still there off screen."*

The city is 104×104 tiles and the screen is 40×22 of them — **0.8% of it**. Every population
number was being divided by that, which is why 110 cars read as a street you could ignore. The
second clause is the licence: continuity of a car you cannot see is unobservable, so it is free
to give away, and density where somebody is looking is not.

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

The gameplay consequence is larger than the frames. Playtest 03 traced a day with **zero**
events ever coming within reach: a twenty-second event planted across the city at dawn is over
before the player could have reached it. An event that waits for her is an event she meets.

**And some events have no place at all.** `EventDef.SpawnMode.AHEAD_OF_PLAYER` events are
budgeted by the day and sited by `EventDirector`, which puts them across her line
`AHEAD_LEAD_DISTANCE` in front of her while she is walking. See docs/EVENTS.md, "Where an event
happens", for which events earn that and what the contract on them is.

## One event per block *(M28)*

Playtest 05, finding 6, and it is the number M27 left open. Streaming made the density
*computable* — a 900px radius is about 23% of the map, so what she is standing in is a knowable
fraction of what the day planned — and the answer came back embarrassing: **1.8 events live
around her, one met on a whole day's walking.** The player asked for one event per block, the
dog-walker decision to arrive at least twice on day 1, and to be able to find a café at all.

Day 1 now plans **50 events across 49 blocks**, of which about eleven are instantiated at any
moment and **3.3 are on screen**. Day 14 plans 97. The full before-and-after table, and the
reason the caps had to move before the budget, are in docs/EVENTS.md, "The density, and why it
is caps before budget".

What this does to the game is a change of kind, not of degree. A street with one event every
four blocks is a street with an event *on* it — you see it, you route around it, and the rest of
the walk is empty. A street with one event per block has no empty stretch to route into, so the
question stops being *"can I avoid this"* and becomes **"which of these is cheapest to walk
through"**. That is the route decision the whole game is about, and until M28 the city was too
sparse to ask it.

## Excitement falloff

Each active event has an `intensity`, an `inner_radius` and an `outer_radius`.

```
contribution(d) = intensity                              , d <= inner_radius
                = intensity × (1 − t²)                   , inner < d < outer
                = 0                                      , d >= outer_radius
   where t = (d − inner_radius) / (outer_radius − inner_radius)
```

**The shape has a shoulder on it, and that is a design decision rather than an implementation
detail.** *(M33, playtest 07 finding 18: "the excitement should go substantially up from
relatively far away — I shouldn't have to get actual contact to get penalized.")*

It was `(1 − t)²` for thirty-two milestones, which puts a **quarter** of the intensity at the
midpoint of the falloff band and six percent three quarters of the way out. A café at 12/s was
therefore under the 3.5/s walking decay across the whole outer 60% of its own field, and the run
logs said so in as many words: every `near` entry written at an event's own outer radius read
`events 0.0`. An event you are not charged for until you touch it is not something to route
around, it is something to bump into — which inverts the whole game.

`1 − t²` holds **three quarters** of the intensity at the midpoint and reaches zero only at the
outer edge. Two consequences worth knowing before touching it again:

- **The telegraph contract is unaffected.** It is stated over *distance* — how far she has to walk
  to be outside the radius — and no radius moved.
- **It applies to the crowd too, and the crowd compensates in radius.** A field that bites from
  a distance is right for an authored event and wrong for one of two hundred and forty bodies. The
  pedestrian and car outer radii came in (88 → 55, 170 → 104) so that a close pass costs exactly
  what it did and the summed street floor lands where it was.

## Running that matters

*(M33, playtest 07: "the run button is a trap shouldn't be an invariant — there should be
legitimate cases where running is required.")*

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
| Bounded | gives up after `PURSUIT_TIME`, **or** as soon as she has opened `PURSUIT_BREAK_OFF`, because a run is priced per second and an unbounded chase is a loss however well it is played |

Its telegraph is the **approach**, the way a fire engine's is. A pursuer that stands still while it
telegraphs hands her more ground in two seconds than the entire chase can take back; what she is
owed is `PURSUIT_MIN_NOTICE` seconds of visibly being closed on. `Tuning.validate_pursuit()` is the
whole contract and it runs on load.

### The stand-off, and what a contract in seconds cannot say *(M35)*

> *"I like the running tutorial on day 3 but I don't know how to solve it yet — I died every
> time."* — playtest 08, finding 4.

The contract above passed every line of itself while the dog was killing people, and the reason is
worth carrying: **it was stated entirely in speeds and durations, and a pursuit is played out in
distances.** The trace says where the notice went. `EventDirector` sites what the day owes across
her line 184px ahead — which is *where she was already walking* — so the dog closed at 148px/s
against her 92, covered the gap in three quarters of a second, and then stood **inside its own
lethal radius** for the remaining 1.7 seconds of a telegraph that was not yet allowed to kill her.
The instant it was, it did: 12px, from a standing start, with nothing she could have done after the
first second.

Two changes, and they are the same change twice — the contract restated as geometry:

- **`Tuning.pursuit_standoff()`.** The telegraph is spent closing to `inner_radius + speed ×
  PURSUIT_REACTION` and *holding* it, backing off if she walks in, because she will: it is sited in
  front of her and forward is where she was going. Clamping the approach at zero instead would have
  left the contract true of the dog and false of the encounter — it would stand politely still
  while she closed the gap herself.
- **`Tuning.PURSUIT_BREAK_OFF`.** It gives up when it has been beaten: it got to her and she opened
  the gap again, or it never got near her at all. Without it the price of the *right* answer was
  set by the clock rather than by the escape — forty points whether she reacted on the first frame
  or the last — and playtest 08's trace has her running, doing exactly what the HUD asked, and
  losing the day to the meter at 100 with the dog 87px behind her.

The dog also came down from 148px/s to 130 and from intensity 22 to 12. 130 is *symmetric*: walking
loses 38px a second and running gains 38, which is the version of "opposite outcomes" a player can
feel. And it is lethal — it does not also need to be the loudest thing in act I.

Measured on a rig (`tests/test_events.gd` walks the same three answers, and `--flee` plays them in
a real day):

| she | outcome | cost |
| --- | --- | ---: |
| walks into it | caught 0.4s after the lunge | the day |
| walks away | caught 2.1s after the lunge | the day |
| runs the moment it appears | shakes it off in 1.5s | 21 points |
| runs when it reaches her | shakes it off in 1.7s | 24 points |
| dithers 2.4s, then runs | caught | the day |

The gradient is the design: reacting sooner costs less, and every wrong answer costs the same thing.

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

## Calm zones

Parks, quiet squares and courtyards are `CALM` tiles. Inside them:

- Sleepiness gain ×`10` — a second in a park is worth ten on the street *(M18)*
- Excitement decay ×`2.2`, so the park reads on **both** bars

But calm zones are contested — see `docs/CITY.md` (spoiling) and `docs/EVENTS.md`.

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

**Five since M35**, and it was three from M6 to M34. *(Playtest 08: "we need more nerves let's try
5?")* Three was set when a lost day also advanced the calendar, so a nerve cost a day of the
fourteen as well as a life; M32 took that half away and left the number. Three attempts against an
act I that grew teeth in M31 is what ended playtest 08's run on **day 3**, two of them on the same
charging dog — a run that ends before act II ends before the game has shown what it is. Five is a
number to be measured, not derived: the run log's `nerve` entries say where they went.

**A nerve buys a retry of the same day.** *(Playtest 06, finding 4, closing a design question
open since M6: "what happens if we fail — do we repeat the same day? We shouldn't advance the
day, that's for sure.")* The calendar moves only when a day is **won**, so the nerves are
failed attempts spread wherever they are needed and the fourteen days are fourteen days
the player actually plays. Before this, a lost day cost a nerve *and* a day — which punished
twice for one mistake and hid act I from the player who needed act I most.

Three consequences, all of them chosen:

- **A retry is the same day.** The city, the closures and the whole event plan are deterministic
  from the seed and the day number, which is what makes a retry worth having in a game about
  learning a route.
- **What the run spent stays spent.** Consumed one-shots and advanced block arcs are run
  history, not day content: a fire that burnt a block down did happen. The one exception is
  **where she settled**, which belongs to the attempt — see `GameState.finish_day()`.
- **The run cannot end by running out of days while nerves remain.** The bad ending is the only
  way to lose, and the run length becomes a promise rather than a budget.
