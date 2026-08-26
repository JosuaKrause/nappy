# Playtest 02 — findings and plan

Second human playtest, taken after M15. Six findings, recorded verbatim in intent, with
what each one implies and what it costs.

The short version: **the loop is right and the street is empty of consequence.** Five of the
six findings say the same thing from different angles — the walk has to be the dangerous
part, and right now the only thing that costs you anything is the clock. One finding (1)
says the reward at the end of the walk is not legible either.

Two of them change the city lattice, which M16 and M17 are built on. **They are queued
behind the milestones already in flight** — see "What this does to M16 and M17" below for
what that costs and the two things it is worth changing about M16 now rather than later.

---

## The findings

| # | Finding | Size | Blocked by |
| --- | --- | --- | --- |
| 1 | The difference of a park is barely noticeable. The bars should be way shorter — circling a park for two minutes to fill the meter is too long, the multiplier needs to be higher | **S** | — |
| 2 | Going to and from a park bears no risk. I don't bump into people (that should bump excitement and displace us both); I cannot hit cars (that should be an instant loss) | M | — |
| 3 | Cars should stop at crossings when I am close. There should be things that force me to cross the street: sidewalk restaurants that raise excitement very fast, dog walkers that are a fast loss if I get too close. If I see a dog walker ahead I might have to turn around and cross at the zebra, waiting for a car to stop | **L** | 2 |
| 4 | Cars run through each other. A faster car should slow down, or overtake when the opposite lane is clear. Needs 8-direction driving. An overtake into oncoming traffic should crash, and a crash is an exciting event to clear fast | **L** | — |
| 5 | The calm zones are too small — they should be four blocks combined. Needs T-junctions and L-bends, and cars that can turn | **L** | 4 |
| 6 | Main roads with higher traffic and traffic lights instead of crossings; side roads with the current volume and zebras. A main road is a natural excitement source and it should not be possible to walk along a full block of one — it should be crossed, and crossing it should be a challenge | **L** | 4, 5 |

### Follow-up notes, same playtest

| # | Finding | Size | Blocked by |
| --- | --- | --- | --- |
| 7 | I walked through each zone without any repercussion, and I don't see a circle on every entity | **S to see, L to fix** | — |
| 8 | **No circles around entities.** How dangerous a thing is should be visible from *looking at the thing*. If more is needed: a symbol flashing above the entity; always a symbol flashing at the screen edge if it is off-screen; a symbol above the *player* when they are too close, so they know they have to be somewhere else | **L** | — |
| 9 | Include running in the fairness equation — for some entities it should be *necessary* to run | M | 8 |
| 10 | **Telemetry**, so a playtest can be read rather than described: did the player idle or walk in circles, how many entities were nearby and which, did they have to cross the street, did they have to run to get away, did they go to the same park every day | M | — |
| 11 | Track which calm zone the player used, and block off at least one of yesterday's with an event. Calm options should shrink as the run goes on | M | 10 |
| 12 | Later acts have fewer people on the street; put patrols back in to compensate — a harder cost to encounter, and possibly requiring a run | M | 9 |

---

## What the findings actually mean

### 1 is the cheapest change on the list and it re-pitches the whole day

M14 pitched the meters against the *day*: a whole day of street walking reaches 79 of 100,
and a calm stretch fills the meter in 119 s. The second number is the complaint. Two
minutes of standing in a park is not a reward, it is a wait, and at 3.5x the street it is
not even obviously faster than what the player was already doing.

The re-pitch this finding asks for:

| | M14 | proposed |
| --- | --- | --- |
| Ordinary street | 0.24/s — 79 of 100 over a whole day | ~0.16/s — about half a bar over a whole day |
| Calm ground | 3.5x — 119 s to fill | **~12x — under a minute to fill** |
| Excitement decay on calm ground | 1.6x | ~2.2x, so the park reads on *both* bars |

That makes a day comfortably winnable once calm ground is reached, which sounds like it
removes the difficulty — and it does, from the meter. **That is the point, and it is what
findings 2 and 3 are for.** The tension moves out of the meter and into the walk. A day
should be lost on the way to the park, not in it.

The M14 relationship that must survive: **a day stays unwinnable on street gain alone.**
Lowering the street rate strengthens it rather than threatening it, so
`tests/test_meters.gd` keeps its shape and only its margins move.

### 2 + 3 + 4 are one finding: the street has no physics

Today the crowd is a *field*. It contributes excitement by distance and nothing else — you
can walk through a person, through a car, through a queue at a bus stop, and the only thing
that happens is a number moves. That is why the route is not a decision: every pavement is
identical and none of them can hurt you.

What the three findings add, in one sentence each:

- **A body is solid.** Walking into someone bumps them, bumps you, and spikes the baby.
- **A car is lethal.** Stepping into the carriageway in front of one ends the day.
- **The pavement can be blocked.** A café spilling onto the pavement, a dog on a long lead:
  things that make *this side of the street* the wrong side, and send you to the crossing.
- **The crossing is a negotiation.** Cars stop for you when you are close enough — so the
  crossing is the safe way over, and jaywalking is the fast way over.

Together those turn the block into the unit of route planning, which is a much finer grain
than the street closures M16 was going to add. **A player choosing which side of the road to
walk down is making the decision finding 12 asked for, forty times a day instead of twice.**

The one to be careful with is the dog walker as a *fast loss*. An instant loss from a mobile
source on the pavement is exactly the case `Tuning.required_telegraph_time()` doubles the
margin for. A dog that kills at 40 px has to be legible about four seconds out, which is
fine for something that moves slower than walking pace — but the fairness contract is not
optional here, and `validate_event()` checks geometry, not whether the player understood.

### 2's collision bump is the first thing that ever pushed a value at the baby

`docs/ARCHITECTURE.md` and `CLAUDE.md` both carry the same invariant: **excitement is a pure
query.** Events never push; the baby asks the world for the total at its position and the
world sums `contribution_at()` over what is live. That is why events compose by addition and
why an event can be tested without a scene.

A collision bump is a push. Keep the invariant by making the bump a *source* rather than a
write: a contact spawns a very short, very intense, very small source at the point of
contact, and it is summed like everything else. Same for the jolt of a car passing close.
The rule to hold on to is the one in `CLAUDE.md`: **do not add a code path that writes to
`Baby.excitement` from outside.**

### 4 is a prerequisite, not a polish item

Overtaking needs cars to leave their lane; leaving a lane needs a car to be somewhere other
than on a rail; and turning off a corridor needs 8-direction driving. Findings 5 and 6 both
need cars that can turn, because a T-junction and an L-bend are turns by definition.

So 4 comes before 5 and 6 even though it looks like the least urgent of the three.

The crash it produces is free content in the best way: an event the *simulation* authored,
in a place the player can see coming, which then has to be walked away from. It should go
through `EventCatalogue` like everything else so it inherits the telegraph contract.

### 5 + 6 rebuild the lattice

These are the expensive ones and they are the same job:

- **A calm zone is four blocks, not one.** So the streets *inside* a calm zone are not
  built, and the lattice stops being a full grid: the junctions on its edge become
  T-junctions, and its corners become L-bends.
- **Roads come in two kinds.** Main roads carry more traffic and are controlled by lights;
  side roads carry today's volume and are crossed at zebras. A main road is a *barrier*: you
  cross it, you do not walk it. That divides the city into quarters joined at the lights,
  which is a permanent, learnable version of what per-day closures were going to do
  temporarily.

Consequences worth writing down before starting:

- `CityMap`'s whole layout maths is "position within the period tells you which band you are
  in". A lattice with holes in it cannot be derived from a coordinate any more; it needs to
  be *generated* and stored. That is the single biggest change in this plan.
- The generator guarantees in `docs/CITY.md` are stated over a full lattice ("a full lattice
  cannot be disconnected by removing any single corridor"). With holes, route redundancy
  stops being true by construction and has to be checked by search. The M16 WIP already has
  the search — see below.
- "It should not be possible to walk along a full block of a main road" needs a mechanism,
  not just a hostile number. Either the main road has no pavement to walk on, or walking it
  is a hazard the way finding 3's café is. The second reads better and reuses 3's work.

### 7 is two separate things, and one of them is a real hole

**"I don't see it on every entity"** is working as designed, and the design is the problem.
The circles are `EventAuraLayer`, and it only draws **events**. The ~530 crowd agents draw
nothing, because the crowd is the emergent noise floor rather than a set of authored
dangers. So on a typical street the great majority of the people you can see have no ring,
a handful do, and there is nothing on screen explaining the difference. Two `city_wide`
sources (the loudspeaker masts, the curfew announcement) have no ring either, and that is a
documented hole rather than a design.

**"No repercussion"** is not a bug. It is arithmetic, and it is worse than it looks.

What it costs to walk in a straight line through the *middle* of each event, against a
100-point meter that freezes sleep at 35 and cries at 100. Measured against the M18 rates,
integrating the real falloff along the path and subtracting the walking decay:

| Event | walk through | run through | verdict |
| --- | ---: | ---: | --- |
| `poster_crew` | **−2.2** | +14.5 | free |
| `dog_walker` | **−0.1** | +18.5 | free |
| `barricade` | **−0.4** | +16.9 | free |
| `playground` | +0.3 | +21.6 | free |
| `delivery_van` | +1.9 | +22.5 | free |
| `busker` | +3.8 | +29.2 | free |
| `police_patrol` | +5.7 | +29.6 | mild |
| `homeless_yeller` | +5.8 | +33.2 | mild |
| `construction` | +8.1 | +33.0 | mild |
| `cat_dash` | +10.4 | +22.9 | mild |
| `checkpoint` | +13.7 | +38.2 | mild |
| `protest` | +25.0 | +56.5 | real |
| `burning_building` | +29.8 | +53.5 | real |
| `abduction` | +32.9 | +53.7 | real |
| `military_convoy` | +49.2 | +69.8 | severe |
| `night_raid` | +56.6 | +78.2 | severe |
| `fire_truck` | +64.6 | +83.9 | severe |
| `firefight` | +92.8 | +105.1 | severe |

Two things fall out of that table, and the second is the more important one.

**Eleven of eighteen cost under fifteen points, and three are negative.** Walking straight
through a `dog_walker`, a `poster_crew` or a `barricade` is *better than walking around it*,
because at 3.5/s the walking decay outruns what they emit. Act I and act II have no teeth at
all; the entire escalation is back-loaded into acts III and IV, where it is genuinely
dangerous. So the player learns, correctly, in the days where the game is teaching them,
that the rings do not matter — and then act III kills them.

**Running is never the right answer to anything.** Not once, in the whole catalogue. Running
costs `EXCITEMENT_FROM_RUNNING` (9/s at full sprint) *and* drops the decay from 3.5/s to
0.5/s, and those two together outweigh the shorter exposure for every event in the game,
including the ones you would obviously sprint away from. The run button is a trap in the
literal sense: pressing it is always wrong.

That matters for finding 9. **Making running necessary is not a tuning change.** No
adjustment to `required_telegraph_time` can make running correct, because running's cost
structure is built to punish it and the excitement model has no term that running can beat.
It needs a *mechanic* running escapes — something that pursues, or a lethal radius that
grows, or a window that closes — and then the fairness equation has to be stated over
`RUN_SPEED` for those events rather than `WALK_SPEED`. Finding 12's patrols are the obvious
first customer.

### 8 replaces the aura layer, and it is a better answer

The rule this changes is not "how do we draw a field", it is **where danger information
lives**. Today it lives in an overlay that describes geometry the player cannot otherwise
see. The direction in finding 8 is that it should live in the *thing*:

> How dangerous something is should be visible from looking at it.

That is strictly better, and for a reason the current design cannot fix: a ring tells you
where the falloff band ends, which is a number, not a threat. A silhouette that reads as
dangerous tells you what to do about it.

What replaces it, in the order the information is needed:

1. **The entity itself.** Posture, size, colour, what it is doing. A patrol should look like
   a patrol from across a street.
2. **A symbol above the entity**, flashing, only when one is genuinely needed — a telegraph
   that has started, an event about to reach full strength.
3. **A symbol at the screen edge**, always, when the entity is off-screen and closing. This
   is M22 as already filed, and finding 8 makes it non-optional rather than a polish item.
4. **A symbol above the player**, in two distinct states, and this is the piece that makes
   the other three safe to shrink — the player is never left guessing whether *they* are the
   one in trouble:
   - **A flashing exclamation mark when the player is standing in a soon-to-be danger zone.**
     Not "there is something dangerous nearby" but "this spot is about to be bad, move." It
     fires on a telegraph whose radius already covers the player, on the path of something
     fast that is still off-screen, on the road when a car is coming through.
   - **A "too close" cue** for danger that is already live and already on them.

   The first of those is the most valuable cue in the whole vocabulary, and it is worth
   saying why. The telegraph fairness contract promises that a player who starts walking away
   the instant an event becomes visible gets clear in time. Every other cue tells the player
   *that a thing exists*; only this one tells them **the promise is now about you, and the
   clock has started**. It is the difference between information and instruction, and it is
   what makes a fast mover survivable without needing the player to have done the geometry.

The invariant that survives all of this unchanged is the one that matters most:
**audio is never the only channel** (docs/EVENTS.md). The symbol vocabulary is the visual
channel, built and judged first; audio is redundancy on top of it.

The thing to be careful about: the aura, for all its faults, is *continuous* — it shows the
field breathing with the pulse, so a pulsing event can be timed. A symbol is discrete. Any
replacement has to keep some way of reading "this is swelling right now", or the pulse
envelope stops being playable and becomes random.

### 10 is the highest-leverage item in this document

Everything else here is a guess until somebody plays it, and every playtest so far has cost
a human sitting down and then describing what happened in prose. Telemetry turns that into
data that can be read directly:

- **Where the time went.** Idle, walking, running, on calm ground, per day.
- **Whether the route was a route.** Distinct streets used, revisits, whether the player
  doubled back, whether they crossed the road and where.
- **What was near.** Entity ids and how close, sampled — which turns "passing a person barely
  moves the meter" from an impression into a distribution.
- **Whether running ever happened**, and what was nearby when it did. Given the table above,
  the expected answer today is "no", and that is worth confirming.
- **Which calm zone**, every day, which is also exactly what finding 11 needs to *function*.

It is deliberately not analytics-for-its-own-sake: every field above answers a question that
is currently open in this document. It should be a local file per run, not a service.

### 11 needs 10 to exist first

"Block off one of yesterday's calm zones" is a rule that needs a record of yesterday, and
that record is one of telemetry's fields. Once it exists the rule is small: on day N, the
scheduler biases a spoiling event toward a calm area the player settled in on day N−1.

The design intent underneath it — **the options shrink as the run goes on** — is already
half-built. M15's arcs requisition calm blocks on a schedule, and
`MIN_CALM_BLOCKS_AT_END` (2) is the floor. What finding 11 adds is that the shrinking should
be *responsive*: the city takes away the park you have come to rely on, rather than a park.
That is a much sharper version of the same story, and it is the difference between a
difficulty curve and a regime that is paying attention.

One risk to hold onto: this can slide into feeling unfair — punished for playing well. The
protection is that it spoils a zone with an *event*, which is avoidable and visible, rather
than removing it. And M16's route invariant still guarantees two calm areas with two routes
each, so there is always somewhere else.

### 12 fixes something act III broke on purpose

Act III empties the streets, and `CROWD_PEDESTRIANS_PER_ACT` drops from 420 to 90. That was
deliberate and it is one of the best things in the game — the city becomes *easier* to put a
baby to sleep in, and that is the horror. But it also means the noise floor collapses exactly
when the game is supposed to be at its worst, so acts III and IV lean entirely on a handful
of large authored events.

Patrols are the right answer because they are the same fiction: the people are gone and the
state is still out there. Mechanically they want to be the first events built around
**encounter cost** rather than ambient emission — expensive to be near, cheap to avoid, and
the first thing in the game running is the correct answer to.

### What this does to M16 and M17

**Both are finished first, ahead of everything in this document.** M16's first half is
already committed on `feature/route-pressure`: `src/routes/street_network.gd`, which turns
the lattice into a graph of junctions and streets and counts *segment-disjoint* routes from
the doorstep to each calm area by unit-capacity max flow.

What that ordering costs, stated honestly so it is a decision and not an accident:

- The **lattice enumeration** in `street_network.gd` assumes a full grid. M21 deletes that
  assumption, so that half gets rewritten once.
- The **graph half** — route counting, the two-routes-to-two-areas invariant, the doorstep
  and doorway exemptions — survives the change untouched, and matters *more* afterwards:
  with holes in the lattice, route redundancy stops being true by construction and has to be
  checked by search. This file is that search.
- **Closure placement will need re-tuning** after M21, because a main road nobody walks
  along is a pointless thing to close. The mechanism survives; the weights do not.
- **M17's map screen gets drawn twice** — once against today's grid, once against M21's
  lattice. Accepted deliberately: a planning map makes the *next* playtest sharper, and the
  next playtest is what decides whether M19–M21 are aimed correctly.

Two pivots inside M16 worth making now rather than after:

1. **Drop the canal.** It was the one item on M16's list that moves a walkable tile — an
   exception to the rule every other purpose obeys. M21 generates a lattice with holes in it
   as its whole subject, so water and bridges belong there, where "the lattice is not a full
   grid" is already true and paid for. Building it now means building it twice.
2. **Keep the closure count modest.** M16 was going to be the thing that made the route a
   decision. Findings 2 and 3 do that at block scale, forty times a day; closures do it at
   city scale, a few times a day. Tuned as though closures were the only source of route
   pressure, they will be far too heavy once M19 lands.

### 9, 10 and 11 together: where the difficulty actually comes from

Three decisions in this document now point at the same place, and they only make sense read
together:

- **M18 took the difficulty out of the meter.** Once calm ground is reached a day is a
  formality. That was deliberate (decision 1) and it means the meter can no longer be the
  thing that makes a day hard.
- **Decision 9 says the walk has to be hard from day one.** Not just from act III, which is
  where all of it currently is.
- **Decision 10 says the *extra* difficulty is opt-in**, through the resistance.

So the load-bearing difficulty is the walk, in every act, and the resistance sits on top of
it for players who want more. That is a coherent shape, and it puts the weight on M19 —
bodies, lethal cars, hazards that force a crossing — because that is the milestone that has
to make an act I street cost something. The cost table under finding 7 is the measurement it
will be judged against.

**Two consequences worth being explicit about:**

**The resistance stops being optional flavour and becomes the difficulty selector — and that
is fine.** This project has carried an open question since M8: *how visible should the
resistance be to a player ignoring it?* It is now **resolved, and resolved by leaving it
alone.** A player who wants to be challenged explores, and exploring is exactly what finds a
chalk mark on an alley wall. The dial does not need advertising, because wanting the dial and
finding the dial are the same behaviour. No quest log, no marker, no HUD nag.

What it *does* need is to not depend on a mechanic nothing else teaches — see below.

**A harder day one meets a nerve economy nobody has tested.** Three nerves, fourteen days, a
lost day advances the calendar rather than repeating it. If act I genuinely threatens, early
losses become normal, and the run may be decided before act III arrives. That is a question
for telemetry rather than for argument — *where do nerves actually go?* — and it is a field
M23 should carry.

### Teach the controls; do not teach a key that exists once

Two halves of the same principle, and they pull in opposite directions, which is why they are
worth stating together.

**Delete the interact key.** The resistance contact is held with `E`, and `E` is used in
**exactly one place in the entire game** — `contact_point.gd`, one line. A key that appears
once is a key that has to be taught, and teaching it costs more than it is worth. Make the
hold **automatic on proximity**: standing near the mark is the hold.

Nothing is lost by that, and this is worth checking rather than assuming. The mechanic's cost
was never the keypress — it was *standing still in an alley while a patrol might come past*,
with progress decaying the moment you walk away. Proximity carries all of that unchanged. The
only thing that goes is a control to explain.

It also *helps* the decision above: a player who wanders down an alley and sees a bar start
filling has discovered the difficulty dial by walking near it. With `E`, the same player walks
past a chalk mark and learns nothing.

**But the main controls do need teaching**, because there are two and one of them is
non-obvious:

- **Arrows/WASD to walk** — shown briefly at the start of day 1.
- **Shift to run** — shown after the first, once moving is understood.

And then a **scripted day-1-only event that requires a short run**, after the first block.
Being made to use it once, in a safe place, is worth more than any amount of on-screen text.

The dependency is sharp and easy to miss: **that event cannot be built before M25.** Running
is currently the wrong move against every event in the catalogue (see finding 7), so a
tutorial that forces a run would be teaching the player a move that is never correct again —
which is worse than not teaching it. M25 is what makes running the right answer to something;
the tutorial teaches that answer.

---

## The plan

Numbered after the existing milestones rather than renumbering them, so that "M16" means the
same thing in this document as it does in the commit log. **Execution order is the order
below, which is also numeric**: the two milestones already planned finish first, and this
playtest's work queues behind them. M16 and M18 are done; the one place the numeric order is
worth arguing with is M23, and the argument is made under it.

**M16 — route pressure.** Finding 12 from playtest 01. A per-day pruned network with legible
blockers, and the day-level invariant: at least two distinct routes to at least two distinct
calm areas. In flight. Canal dropped to M21; closure counts kept modest.

**M17 — the route map.** The planning screen, rendering the block states M15 introduced.

**M18 — the park has to be worth it.** Finding 1. Re-pitch the sleepiness rates so calm
ground fills the meter in under a minute and reads as obviously different from the street.
Small, and the first thing this playtest's findings ask for, so it leads the new work.

**M19 — bodies on the street.** Findings 2 and 3. Collision for pedestrians and the player,
lethal cars, pavement hazards that force a crossing, cars that stop at zebras. The collision
bump stays a *source*, not a write.

This is the milestone decision 9 lands on: it has to make an **act I** street cost something,
not just an act IV one. Build the mechanisms here; set the numbers after M23, per decision
11. The cost table under finding 7 is the before-picture.

**M20 — traffic that behaves.** Finding 4. Car following and overtaking, 8-direction
driving, and the crash as a catalogue event.

**M21 — the city overhaul.** Findings 5 and 6, plus the canal dropped out of M16.
Four-block calm zones, a generated lattice with T-junctions and L-bends, main roads with
lights against side roads with zebras.

**M22 — danger you can read.** Findings 7 and 8. **Delete the aura circles.** How dangerous
something is becomes visible from the thing itself, and the rest is a small symbol
vocabulary: above an entity when it needs one, at the screen edge when it is off-screen and
closing, and above the *player* — a flashing exclamation mark when they are standing in a
soon-to-be danger zone, plus a "too close" cue for danger already on them.

This absorbs the "screen-edge indicator for fast movers" item that was sitting in M10, and
finding 8 makes it non-optional rather than polish. The **telegraph fairness contract** says
a player who starts walking away the instant an event becomes visible gets clear before it
hurts — and `Tuning.validate_event()` checks the *geometry* of that, not whether the player
could see it. A `fire_truck` at 190 px/s spends most of its 3.5 s warning outside the
viewport, so the contract passes while the promise breaks. M19's lethal cars make that worse.

The symbol has to say *what* is coming, not merely that something is: "get off this street"
and "do not step off the kerb" are different moves. And it has to keep one thing the ring did
well — showing an event *swelling*, so a pulse can still be timed.

**M23 — telemetry.** Finding 10. A per-day trace written to a local file, and a summary a
developer can read: where the time went, whether the route was a route, what was near and how
near, whether running ever happened, which calm zone was used. Every field answers a question
that is currently open in this document.

**Now a gate, not just a recommendation.** Decision 11 defers the act I/II difficulty pitch
until real runs can be read, so the balance half of M19 cannot be finished before this lands.
It is also the only item here that makes every *other* item cheaper to judge, and M24 cannot
be built without one of its fields. Filed in numeric order all the same, but M19's mechanisms
and M23 want building close together, with the numbers set afterwards from what the traces
say.

Two fields exist because of decisions 9 and 11 specifically: **where the nerves went** — which
day, which failure, which act — and **what was nearby when a day was lost**. Those are what
answer "is day one too hard" without anyone having to have an opinion about it.

#### What M23 records

**The shape is a chronological log, not a metrics dump.** One plain-text file per run, read
top to bottom, in which what happened and *in what order* is reconstructable by a human with
no tool. A page of aggregates says a day was hard; a log says the closure sent them north,
the convoy came through at 0:48, they ran, and the park was already spoiled when they got
there. Only the second one explains anything.

Something like:

```
day 3  act 1  run seed 8812  city seed 8813  length 180.0s
   0.0  start    doorstep (52,88), facing north
   0.0  roll     one-shot fire_truck: 0.42 >= 0.33  -> not today
   0.0  plan     closed: roadworks h(2,5) | events: busker(38,44) dog_walker(41,52) x4
   0.0  plan     calm: park(3,2) forest(5,6) courtyard(1,4)
  11.3  closure  saw roadworks h(2,5) from junction (3,5)
  12.9  turn     doubled back east
  31.6  near     busker 62px   exc 14.2 rising
  44.8  calm     entered park (3,2)
  48.1  freeze   sleep frozen, exc 36.4  (playground 118px)
  62.0  run      started running, 1.8s, nearest dog_walker 91px, exc 21 -> 34
  71.2  asleep   sleepiness 100, exc 18, elapsed 71.2s
  96.4  home     WON, 83.6s to spare
```

**Record what cannot be recovered from the code**, and nothing else. The run is deterministic
from a seed, so most of what the game decides is already recomputable and recording it would
be noise:

| Record | Do not record |
| --- | --- |
| **The seed the generator actually used.** `generate()` retries with `seed + 1`, so the run seed alone does not reproduce a city | The city layout, block purposes, building rects — all recomputable from that seed |
| **Random outcomes that branch the run**: a one-shot that fired or did not, with the roll and the threshold; which block arc advanced and what caused it; the alley trap roll; which calm zone got spoiled | The falloff curve, meter rates, event intensities and radii — they are in `Tuning` and the catalogue |
| **What the player did, in order**: where they went, when they turned back, when they ran, when they crossed a road, when they stopped | Derived aggregates like the circling ratio or total distance — computable from the trace, and a reading aid at best |
| **What the world did to them**: what came within range and how close, when sleep froze and what was near when it did, which closure they saw and whether it changed their direction | Which tiles are calm, which streets exist — recomputable |
| **The outcome and its cause**: result, elapsed, margin, what was nearby at the moment of a loss, which nerve went and on which day | — |

Random outcomes are the important half of that, and the reason is specific to this project:
rolls that depend on **run history** — a one-shot already consumed, a fire that only burns a
block because something burned there, a scar that exists because of what the player did — are
not recomputable from a seed at all without replaying the whole run with identical input. They
are the story of the run and they have to be written down as they happen.

Each entry still has to earn its place: **every line answers a question that is open in this
document.** The questions, and the entries that answer them:

| Question | Answered by |
| --- | --- |
| Is day one too hard? *(decisions 9, 11)* | `start` / `asleep` / `home` lines with elapsed and margin, and on a loss what was nearby at the moment it happened. Plus which nerve went, on which day — the nerve economy has never been tested against a game that bites early |
| Did the player idle, or walk in circles? | `turn` entries for doubling back, and the position trace. The circling ratio is computed *when reading*, not stored |
| How many entities were nearby, and which? | `near` entries: what it was, how close, and what excitement was doing. Turns the cost table under finding 7 from arithmetic into what happened to a person |
| Did the player have to cross the street? | `cross` entries — where, and whether at a zebra. Judges finding 3, and M21's main-roads-as-barriers later |
| Did the player have to run — and did it help? | `run` entries: duration, what was in reach when it started, excitement before and after. Today the answer should always be "it made things worse" |
| Same park every day? | `calm` entries naming the block. Also the one thing **M24 cannot be built without** |
| Was a day lost to noise or to the clock? | `freeze` entries — when sleep froze and what was near. Freezing is the invisible failure; the result code alone never says which it was |
| Are M16's closures a decision or scenery? | `closure` entries: seen from where, and whether the player then changed direction |
| Did the player ever find the difficulty dial? | `contact` entries — offered, approached, held, completed, failed *(decision 10)* |

Three constraints on the implementation, all non-negotiable:

- **It must not touch gameplay.** No global RNG, no `day_rng()` stream, nothing that changes
  a placement or a roll. A trace that perturbs the run it is measuring is worse than no
  trace, and this project's determinism invariant is the thing that makes replaying a bad
  run possible at all.
- **It must be readable without a tool.** It is for a human deciding whether day one is too
  hard. If reading it needs a script that does not exist yet, it will not get read.
- **Order is the record.** Timestamps on every line, one line per thing that happened. An
  aggregate can always be computed from an ordered log; the order can never be recovered from
  an aggregate.

**M24 — the city remembers where you went.** Finding 11. Record the calm zone the player
settled in; on the next day bias a spoiling event toward it. The options narrow as the run
goes on, and they narrow *at the player* rather than at random.

Protected against feeling like a punishment for playing well by two things already in place:
it spoils with an avoidable, visible **event** rather than removing the ground, and M16's
route invariant still guarantees two calm areas with two routes each.

**M25 — patrols, and running that matters.** Findings 9 and 12. Patrols to put pressure back
into the emptied streets of acts III and IV, built around **encounter cost** rather than
ambient emission — and the first thing in the game that running is the correct answer to.

The prerequisite is structural, not numeric: today running is *never* correct, for any event
in the catalogue (see the table under finding 7). A patrol therefore needs a mechanic running
escapes — something that pursues, a lethal radius that grows, a window that shuts — and its
fairness contract has to be stated over `RUN_SPEED` rather than `WALK_SPEED`.

**M26 — teaching the controls, and one less control to teach.** Two halves, both from the
section above.

*Delete the interact key.* `E` appears in exactly one line of the game. The resistance hold
becomes automatic on proximity, which loses nothing — the cost was always standing still in an
alley, not the keypress — and gains a player who discovers the difficulty dial by walking near
it rather than by knowing a key.

*Teach the two that remain.* Arrows/WASD at the start of day 1, then shift, then a scripted
day-1-only event that requires a short run after the first block.

**Comes after M25**, and the dependency is not schedule, it is correctness: forcing a run
before running is ever the right answer teaches a move that is never correct again.

### Order rationale

- M16 and M17 first because they are in flight and because a route map makes the playtest
  that judges M18–M21 a much better playtest.
- Within the new work: 1 first, because it is one afternoon and it changes how every later
  playtest feels.
- 2 and 3 before 4, because a car that cannot be hit does not need to avoid other cars yet,
  and because 3 is what makes the pavement a decision.
- 4 before 5 and 6, because a T-junction is a turn and today a car cannot turn.
- 5 and 6 together, because a four-block calm zone and a main-road barrier are the same
  change to the same generator.
- 7 and 8 are one milestone (M22) because they are one decision: the circles go, and what
  replaces them has to cover every case the circles were covering, including the ones they
  were covering badly.
- 9 and 12 are one milestone (M25) because "running should sometimes be necessary" and
  "later acts need patrols" are the same feature seen from two ends.
- 10 before 11, because 11 needs a record of yesterday and that record is one of 10's fields.

### Decisions

1. **The difficulty moves out of the meter and into the walk.** Taken as the reading of
   findings 1–3 together: a day that is comfortably winnable *once you are standing on calm
   ground* is correct, provided getting there and getting home is where the day is lost.
2. **The collision bump is a source, not a write.** Excitement stays a pure query.
3. **A main road is crossed, not walked** — enforced by making walking it hostile, reusing
   finding 3's hazard mechanism, rather than by deleting its pavement.
4. **M16's closures stay planned, and go first.** They narrow the choice at city scale;
   findings 2 and 3 narrow it at block scale. Both are wanted. Closures are tuned light on
   the understanding that block-scale pressure is coming.
5. **The canal moves from M16 to M21**, where a lattice that is not a full grid is already
   the subject.
6. **The aura circles are deleted, not restyled.** Danger belongs in the entity, with a small
   symbol vocabulary for the cases the entity cannot carry on its own. A ring communicates a
   falloff radius, which is a number; a silhouette communicates a threat.
7. **Running has to be made correct before it can be made necessary.** It is currently the
   wrong move against every event in the catalogue, so finding 9 is a mechanic to build, not
   a constant to change.
8. **Telemetry is a local file per run, not a service**, and every field it records answers a
   question that is open in this document. If a field does not, it does not go in.
9. **The beginning is challenging too.** Not extremely difficult — but a player who never
   meets danger never learns to deal with it, and the measurement under finding 7 says act I
   and act II currently cost almost nothing. The early game teaching "events are safe" and
   act III then killing you is the worst of both.
10. **Difficulty is self-selected through the extra quests.** The resistance is the dial: a
   player who wants a harder run takes the detours, holds the contacts, and spends time in
   alleys they would otherwise avoid. That is why the base game has to be challenging on its
   own — the dial adds difficulty, it does not supply it.
11. **The act I/II numbers are set from data, not from argument.** Build the mechanisms
   (M19), ship telemetry (M23), read real runs, then pitch. Nobody has to guess how hard day
   one should feel, and this document should stop trying to.
12. **Telemetry is an ordered log, not a metrics dump.** What happened, in what order,
   readable top to bottom by a human. An aggregate can be computed from an ordered log; the
   order can never be recovered from an aggregate.
13. **Record what the code cannot recompute, and nothing else.** Above all the *random
   outcomes that branch a run* — a one-shot that fired, a block arc that advanced, an alley
   trap that was set. Those depend on run history, so no seed reproduces them. Everything
   derivable from the seed, `Tuning` or the catalogue stays out.
14. **The resistance stays hidden, and loses its key.** Wanting the difficulty dial and
   finding it are the same behaviour, so no marker is needed *(this resolves an open question
   carried since M8)*. But the hold becomes automatic on proximity: `E` appears in one line of
   the game, and a control that appears once costs more to teach than it is worth.

### Open questions for the next playtest

- Does a day that is winnable in forty seconds of park still feel like a day, or does the
  clock stop mattering? If it does, the answer is a *longer walk* — a calm zone further out
  — rather than a slower meter. *(M18 shipped; this is the first thing to look at.)*
- Is an instant loss the right weight for a dog? It is the same punishment as an abduction,
  which is act III's worst thing.
- With main roads as barriers, is 7x7 blocks still the right city size?
- ~~How much of act I and II should have teeth?~~ **Decided: the beginning is challenging
  too.** See decision 9. What is still open is *how* challenging, and that is deliberately
  not being argued — it is being measured once M23 is in.
- **What replaces "the field is breathing"?** The ring tracks current emission, so a pulsing
  event can be timed and walked past between beats. A discrete symbol cannot do that. If
  nothing replaces it, the pulse envelope becomes noise rather than a thing to play against.
- **Does the player ever find out why they lost?** With no aura and no numbers, "the meter
  filled" needs a legible cause. This is the same question telemetry answers for the
  developer, asked on behalf of the player.
