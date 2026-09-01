# Nappy — The City

## Fixed-for-the-run, different-between-runs

The city is generated once, deterministically, from the **run seed**. Every day of a run
uses the identical layout. Start a new run → new seed → new city.

This is the roguelike contract: the *map* is knowledge you earn and keep for the whole run;
the *events* are the run-to-run and day-to-day variance.

```
run_seed ──▶ CityGenerator ──▶ CityMap (blocks, streets, parks, alleys, home)
                                   │
day_index + run_seed ──▶ EventScheduler ──▶ this day's event set
```

## Grid model

The city is a grid of **blocks** separated by **streets**.

- `BLOCK_SIZE` = 8 × 8 tiles of block interior
- `STREET_WIDTH` = 6 tiles: sidewalk (2) | road (2) | sidewalk (2)
- `CITY_BLOCKS` = 11 × 11 blocks
- Total: 160 × 160 tiles, or 5120 px square at a 32 px tile
- Plus a border one block deep **outside** the map — water, forest or mountainside depending on the
  side — which is art rather than ground. See "The edge of the world"

**Odd on both axes, and that is a constraint.** An odd lattice has a middle block, and the home goes
in it — see "The home" below. Everything downstream is stated over `CITY_BLOCKS` rather than over a
literal (the event budget per block, the crowd population per corridor, the arterial index), so a
resize moves the city and nothing else. It is still a density change: re-measure rather than assume.

**A 1-tile sidewalk does not work**: the rig's collision circle is 28 px across, so a 32 px
sidewalk leaves 2 px of clearance and walking a street is threading a needle. Two tiles of sidewalk
is the number the whole layout is sized around.

### Three kinds of street

Every corridor is the same shape and they are not the same street. All of it is fixed for the run
and decided before a tile is laid — see `CityGenerator._assign_street_kinds`.

| Kind | How many | What it is |
| --- | --- | --- |
| `ORDINARY` | everything else | Two lanes, a zebra at every junction, and traffic that gives way to somebody standing at the kerb. |
| `MAIN` | **one**, north to south | The spine. Five times the traffic, signalled at every junction, and **it does not give way**: what stops it is the light. Its crossings are two dotted lines rather than a zebra, because a zebra is a promise it does not make. `CityMap.main_road`. |
| `PEDESTRIAN` | **two stretches of three blocks** | A retail precinct: paving frontage to frontage, no kerb, no cars, the busiest pavement in the city, and the best ground outside a park to bring a meter down on. `CityMap.precinct_spans`. |

**With one kind of street the only route question is *which way*; with three it is also *which
kind*, and that is the trade the whole game is made of.** A main road is quick to cross at a light,
lethal anywhere else along it, and bad ground to recover on; a precinct cannot kill you and is full
of people to walk into; an ordinary street is the middle of both.

**Two of the three are places, not classes.** A main road on each axis and a precinct corridor in
each gives a city with three kinds of street and no hierarchy among them: a spine that crosses
itself is two spines, and a precinct you meet on every third street is what a street is. There is
one main road because there is nowhere else it could be,
and a precinct is three blocks with an end you can see — one along the southern shore, one inland.
A span covers its blocks and the junctions between them and stops short of the crossroads at either
end, which is where the bollards are.

The lattice itself does not move. Every corridor is still `sidewalk | road | sidewalk` and the
layout arithmetic is still a modulo, which is why a kind can never disconnect the city or shift a
block. **A wider main road was the obvious alternative and was rejected**: the corridor
cross-section is uniform by construction, a 1-tile pavement is too narrow to push a pram along, and
doubling a carriageway restates the traffic fairness contract for every street at once. What the
main road gets instead is everything that is actually a route decision — the signals, the
priority, the density, the recovery rate — and a drawing that says so.

### What the ground does to the meter

The ground is not calm-or-not; it is a rate, and choosing a route is choosing a recovery rate.
`WorldContext.decay_multiplier()` is the question and `City` answers it from the tile she is
standing on.

| Ground | × decay | Walking decay |
| --- | ---: | ---: |
| Calm (park, forest, quiet square, courtyard, playground) | 2.2 | 7.7/s |
| Precinct | 1.5 | 5.25/s |
| Ordinary street | 1.0 | 3.5/s |
| Main road | 0.6 | 2.1/s |

A rate rather than a state is what makes a precinct worth walking to although it is loud.
`is_calm_zone` stays a threshold beside it, because the *sleepiness* half genuinely is one: only
calm ground puts a baby to sleep.

Tile types:

| Tile | Walkable | Effect |
| --- | --- | --- |
| `BUILDING` | no | Collision. Drawn as an extruded 2.5D box. |
| `SIDEWALK` | yes | Neutral. The default walking surface. |
| `ROAD` | yes | Neutral, but traffic events path along roads. |
| `CROSSING` | yes | Marked road tile; traffic events yield here (mostly). |
| `PARK` | yes | **Calm zone.** The sleepiness and decay multipliers above; the sleepiness one is a curve over the lot's size. |
| `SQUARE` | yes | Open plaza. Neutral, high visibility, gathering events spawn here. |
| `ALLEY` | yes | +3.0/s excitement. Shortcut between blocks. Resistance contact point. |
| `PLAYGROUND` | yes | Permanent excitement source (see EVENTS). Sits inside parks. |
| `HOME` | yes | Start and goal tile. |

## Generation algorithm

1. **Seed** a `RandomNumberGenerator` with `run_seed`.
2. **Lay the street grid** — a regular lattice of blocks and streets.
3. **Assign districts** — each block gets a district tag that biases its contents:
   - `RESIDENTIAL` (most common) — plain buildings
   - `PARK` — the whole block becomes a calm zone with trees and paths
   - `COMMERCIAL` — buildings + a `SQUARE` carved out of the block
   - `INDUSTRIAL` — larger buildings, more alleys, no parks
   - `CIVIC` — one big building; later becomes regime infrastructure
4. **Carve alleys** — each non-park block has a seeded chance of a through-alley bisecting
   it. Commercial blocks are exempt: they already have a plaza carved out, and a second
   hole through the same lot leaves slivers and an alley opening onto a square.
5. **Place playgrounds** — every `PARK` district gets 1 playground, inset from the edge.
6. **Place home** — a 2×2 notch in the south edge of the **middle block**, slid sideways if the
   notch would land in an alley. The middle block is claimed as `RESIDENTIAL` before step 3, so
   nothing calm can be rolled into it and no zone can absorb it. See "The home" below.
7. **Validate** — see below. On failure, retry with `seed + 1`, up to 64 attempts.

### Carving is rect subtraction

Every hole — alley, plaza, home notch — is applied to the block's list of building rects by
the same `_subtract(outer, hole)` operation, which returns the up-to-four rects that remain.
Holes compose without special cases, and the building rects are exact by construction.

**Every piece is kept, including one-tile slivers.** Dropping anything narrower than two tiles
because slivers look odd leaves `BUILDING` tiles with no building node over them — invisible walls
the player walks straight through. A sliver renders as a low wall instead, which is what a 32
px-wide building should look like. The test asserts that the building rects cover every `BUILDING`
tile exactly once.

### Guarantees

Checked by `CityGenerator.validate()` and by `tests/test_generator.gd` across 200 seeds:

- Every walkable tile is reachable from the home.
- Every calm area is somewhere calm ground may go: clear of the home, clear of the map's outer
  ring of blocks, and clear of the two block columns beside the spine. See "Where calm ground may
  go".
- At least **5 calm areas**, no two adjacent (so the calm is spread out). An area is one
  block or one multi-block zone; see below.
- At least `MIN_CALM_ZONES` (1) of them is a **zone**, and at least one zone is the **2×2
  square** — the shape the lap argument is stated over.
- The home is in the **middle block**, and is at least `MIN_HOME_TO_PARK_TILES` (30) *walking*
  tiles from the nearest park. Both, together — see "The home".
- Building rects tile the `BUILDING` tiles exactly, with no overlaps and no gaps.

## The home

**It is the middle block, and that is not a preference.** Half the directions out of a boundary
block are a wall, and a city you can only leave two ways is smaller than the one that was generated.

**Two rules compete for the same thing** — *the walk out has to be long enough to matter*: the home
in the middle, and `MIN_HOME_TO_PARK_TILES` between the doorstep and the nearest park. Settling that
by walking the home **outward** from the centre until it is far enough from calm ground is what puts
the front door against the boundary, one or two blocks off centre on most seeds.

So the competition is settled somewhere else. The middle block is claimed before any purpose is
assigned, and **calm ground is kept a clearance of blocks away from it**
(`CityGenerator._too_near_the_home`) — so the distance guarantee holds where the home *is*, rather
than deciding where it goes. The clearance is derived from `MIN_HOME_TO_PARK_TILES` rather than
authored beside it: a block `d` away starts `d × period()` tiles out, of which `BLOCK_SIZE` is the
home's own lot, so the clearance is the smallest `d` clearing the guarantee. It is a floor, not the
guarantee — walking is not straight-line — and `validate()` still checks the real thing.

**And that is what the lattice size is for.** Both rules can only hold on a city whose centre is
`MIN_HOME_TO_PARK_TILES` of walking from every park — a 7×7 lattice is not, and 11×11 is, with the
home central on every seed and the guarantee satisfied with room to spare.

**One consequence of a central doorstep is a difficulty change hiding inside a layout change, and it
is not measured.** The crowd is a *field* of fixed population in a fixed-size box around the player,
and `CrowdField.corridor_range` clamps that box to the city — so a doorstep near the boundary has
the box hanging over the wall and the same agents spread across fewer streets, while one in the
middle has the full set of corridors in range and the same population covering more of them. Day 1
at the front door should therefore be *thinner* per street than a boundary doorstep, which is the
opposite direction from the open crowd difficulty question. It wants measurements — contacts in a
forty-second walk down a lane centre against the midline, and the mean wait at an arterial kerb —
rather than an assumption.

## Calm zones

A calm **area** is one place to go, and it is either a single block or a **zone**: several blocks
with the streets between them absorbed, painted as one unbroken piece of ground. Every city has one
or two zones.

A zone's footprint is one of `Tuning.CALM_ZONE_SHAPES` — **2×2**, **2×1** or **1×2** — and the
first one a city places is always the square, so the guarantee the shapes were added under survives
word for word: **every city has somewhere with a route through it rather than a lap round it.**

What a footprint costs the lattice is stated over the rect rather than over a side: a `w × h` zone
absorbs `w(h−1) + h(w−1)` streets — **four** for the square and **one** for a rectangle — has
`2(w + h)` streets round it, and contains `(w−1)(h−1)` junctions, which is **none** for a
rectangle. **Anything written as `2 · CALM_ZONE_BLOCKS · (CALM_ZONE_BLOCKS − 1)` is the square's
answer to the first of those**, and it agrees with the general one only while every zone is a
square.

| | one block | 2×1 zone | 2×2 zone |
| --- | --- | --- | --- |
| ground | 8×8 tiles | 22×8 tiles | 22×22 tiles |
| a full meter of calm | 5.7 s | 8.0 s | 11.3 s |
| traverses of itself to fill it | 1.4 | 1.05 | 1.05 |

The rate curve needed nothing adding for the new shape and that is the point of it being a curve:
`sleepiness_calm_multiplier` is `1 / sqrt(blocks)`, so a two-block lot lands between the other two
and pays for about one traverse of its long side, exactly as the square pays for one diagonal. A
rectangle is a *length* rather than a diagonal — you walk it end to end, and which end you come in
at is a route decision the square does not offer.

**The reason zones exist at all is the lap.** A player who reaches a single calm block spends the
sleep phase walking in a circle inside it, and that is not a bug and not a balance problem — it is
exactly what the rules ask for. Standing still *drains* sleepiness, so progress requires motion; a
calm block is eight tiles across; and progress-requires-motion plus small-calm-area is jointly
sufficient for a lap. A shorter day changes how many laps there are and cannot remove the lap, and
no balance pass will.

The numbers are the table above, and `tests/test_generator.gd` asserts them as relationships
rather than as values: a traverse is worth a real share of a full meter and **not** the whole of
it — if arriving filled the meter, arriving would be the whole game — and the three sizes are
within half of each other in traverses-per-meter.

**The rate is a curve over the lot's width, which is what keeps the small ones worth going to**: a
single block is paid for its size, so *which* calm area to head for is a question about where it is
rather than about how big it is. The curve pays for the lap; it does not make the block bigger, and
the geometry is untouched — a block is a lap and a zone is a route.

The rest of the calm stays single-block on purpose. Which calm area to head for is a real question
only when they are different from each other: a small quiet square two streets away against a big
park across the city is the decision that spoiling yesterday's park exists to make matter, and a
city of nothing but zones would flatten it again.

### Where calm ground may go

**One question, asked of a footprint**, so a single block, a zone and a courtyard obey one rule
rather than three that drift apart — `CityGenerator._calm_may_sit_here`. Three clauses:

- **Never near the home.** The oldest of the three: the walk out has to be worth walking, and with
  the home pinned to the middle block this is where that is settled. See "The home".
- **Never in the outer ring of blocks.** *"Another way to get density is to make a rule to not have
  a calm area at the edge of the map or next to the main road."* A calm area against the boundary
  has the ring of frontages behind it, so half its approaches are a wall and it is a destination
  you can only arrive at from one side. This clause is also almost all of the density argument:
  the ring is **40 of the lattice's 121 blocks**.
- **Never in either block column beside the main road.** Worth only **eight** blocks on top of the
  ring, because the spine runs down the middle where the home clearance has already taken a 5×5
  out — so this one is justified on design rather than on density. `decay_multiplier` is 0.6 on
  the spine, so a park you can hear the main road from is not calm ground; and if calm never sits
  beside it, **crossing it always leads somewhere worth crossing for**, which is what makes it a
  soft block rather than a wall. It is the expendable clause by the player's own words — *"the not
  next to main road rule is not that important, you can remove it if it loses too much freedom"* —
  so if the field ever gets too tight, this comes out before `MIN_CALM_BLOCKS` or the
  non-adjacency rule are touched.

The eligible field, on the 11×11 lattice, for a single calm area:

| eligible blocks | count |
| --- | ---: |
| the lattice minus the 5×5 home clearance | 96 |
| + no calm in the outer ring | 56 |
| + no calm in the two columns beside the spine | **48** |

**Measured over 40 seeds, and the room is there.** Nothing lands at the edge or beside the spine,
against 4.42 areas per city touching the edge and 1.50 beside the spine with the clauses off, and
the count is unmoved — 8.85 areas of which 3.00 courtyards, against 8.43 of which 2.55, with open
calm inside its 5–7 band throughout. Generation retries per city are **0.00**, against 0.50 with the
home clearance stated as a distance instead: a courtyard cut beside the front door fails the
home-distance guarantee and rolls the whole map again, where the clearance refuses the block.

**The spine clause is stated over `map.main_road`** and nothing else. `CrowdLanes.arterial_index` is
the *default* a map is built from, and **asking it where the spine is is the trap**: it answers for
both axes, which is how a phantom east-west arterial gets into a busyness curve and a zone that
would absorb the middle east-west corridor gets refused. There is one main road, it runs north to
south, and a guard on the other axis is a guard on nothing.

### What a zone does to the lattice

This is the part that costs something. A zone absorbs the two horizontal streets between its
rows and the two vertical ones between its columns, so:

- The **junction in the middle of the zone is gone** — nothing reaches it.
- The four junctions on the zone's edges become **T-junctions**. The lattice is not a full grid and
  cannot be derived from a coordinate, which is the price of a zone and is most of what makes one
  worth having.
- **Route redundancy stops being true by construction** and has to be checked by search. See
  below.

Two rules keep a zone from taking something the city cannot spare, and both are the rules every
calm area obeys, asked of the whole footprint:

- **Somewhere calm ground may go at all** — see "Where calm ground may go". The clause that keeps
  calm out of the two columns beside the spine is also what stops a zone absorbing a stretch of it,
  so this needs no guard of its own.
- **Never beside other calm**, the same rule a single calm block obeys.

The streets it absorbed live in `CityMap.absent_segments`, and `CityMap.blocked_segments()` adds
them to whatever a day has closed. Every route search takes that set, so the graph half of
`StreetNetwork` — route counting, the invariant, the doorway exemptions — needs no special case: a
street that is not there is a street that is permanently shut, as far as a search is concerned.
What is *not* true of a closure is true here and matters: **the ground is calm and
open**, and the player walks over it. A zone is a shortcut as well as a destination.

The crowd asks a different question. An agent travels the lattice, so it checks `is_street()`
and diverts at the T-junction rather than strolling across the grass — the same move a
barricade already produces, with the same good side effect: the street with nobody on it is the
street that does not go through.

The zebras on a zone's edge are the case that looks obvious and is not. A crossing sits where a
*pavement* lane meets a *carriageway*, so most of them still make sense — the pavement is there
and the road is there, and only the arm of the junction beyond has gone. What does not is the
**stub**: the quarter of each T-junction on the zone's side, which nothing drives down (a car
diverting turns on the junction's own road band, a tile earlier) and nothing has to cross. That
becomes pavement, so the road visibly ends at the junction instead of poking into the park.

### Route redundancy

The design **wants** at least two distinct routes from home to every calm area, so that a spoiled
or blocked route always has an alternative. On a full lattice that holds **by construction** rather
than by search: carving only ever happens *inside* blocks, so the street lattice is never cut, and a
full lattice cannot be disconnected by removing any single corridor.

**A calm zone puts holes in the lattice, so the construction argument does not survive it** and the
property is checked. `StreetNetwork.route_count()` is that check — the same one the day's closures
use — and a zone's absent streets simply join the closed set it is given.

**And what is checked is weaker than the wanted property, on purpose.** The second route is an
**offer** (see "How the corridor is built", and `RouteTree`, which manages it for 241 areas of 241
the map allows one to) rather than something placement is gated on. Three things hold instead, and
each is stated where its decision is taken:

| | |
|---|---|
| the generator | every calm area stays **reachable**, whatever hard blockers took |
| the day | at least `MIN_CALM_AREAS_REACHABLE` calm areas are still reachable after the closures |
| the city | **no single street cuts off all the calm** — the winnability sentence edge-disjointness stands in for, asserted directly |

The count of *areas* is two, because one of them may be the one the day has just spoiled.

`tests/test_generator.gd` checks it directly by closing each street segment in turn and
confirming a park is still reachable — with one exemption. **The street outside the home is
a genuine single point of failure**: the home is a notch in a block with one exit, so
sealing that segment seals the player in, however well connected the rest of the city is.
That is a constraint on where Act IV may place a barricade, not a flaw in the layout.

## Spoiling calm zones

A park that is always safe would collapse the game into one memorised loop, so the day **spoils**
the calm areas she has already settled in this act — `EventScheduler._spoil_the_parks_she_used`.
Three things about it here; the mechanism and its measurements are in `docs/EVENTS.md`, "The city
remembers where she went".

- **It is the ones she used, not a roll over the map.** A calm area she has never settled in is
  left alone by a rule of its own: nothing is *placed* near unvisited calm in the first place.
- **A spoiler is a crowd of ordinary events covering the ground**, not one event standing in it.
  Calm ground is denied by out-emitting the decay on it, which a single source does over a fraction
  of a lot. Outside what the spoilers deny, the lot keeps its calm multipliers.
- **At least one calm area is always usable.** `_ensure_one_usable_park` is the last line under it,
  for the day she has settled in every calm area there is. The player has to find out which.

## Road closures

Every morning a few streets are shut. This is the one thing in the game that changes **where the
player may walk** from one day to the next — block purposes change what a place is *worth* walking to and never move a walkable
tile, and that difference is the whole design.

### The unit is a street, not a tile

The lattice is a graph: a **junction** at each end of every block — one more per axis than there are
blocks — and the **streets** between them, each one block long and one corridor wide.
`StreetNetwork` owns that view of the city, and a closure takes out one whole street. A few hundred
segments is cheap enough that validating a whole day's closures costs less than one tile-level flood
fill.

Half a street would be a closure the player cannot see the shape of, and a whole corridor
would delete a route rather than narrow the choice. A street is the unit the player already
thinks in, because it is the thing between two decisions.

### Legible before it costs anything

The barriers stand at the **two mouths** of the closed street, where it meets the junctions
at either end — never half way down. That is the legibility promise, and it is precise:

> You never commit to a street without having already seen that it is shut.

Standing at a junction, the barrier across the mouth is right there, and the sign on its
middle panel faces you. It cannot be discovered half way down, because there is nothing to
discover half way down — you were stopped at the entrance.

Traffic is the second channel and it carries further: crowd agents divert at the junction
rather than driving into a barrier, so **the street with nobody on it is the street that is
shut**, readable from a block away. That was not designed, it fell out of making the crowd
respect closures, and it is better than the thing it fell out of.

What this does *not* give is planning-time legibility — knowing a street is shut before you
are standing next to it. That would be a route map, which is backlogged; see `docs/TODO.md`.

### Guiding her to the calm — what the game actually does

**Everything the city does about calm areas is a floor under winnability. None of it is
guidance.** Set out in full, because the difference between the two is the whole of the open
question below:

**At generation, once per run — where they are:**

| | |
|---|---|
| how many | 5–7 areas, derived as an act's worth of days **plus one** |
| how far | at least `MIN_HOME_TO_PARK_TILES` (30) of **walking** distance from home — the calm is earned |
| how spread | no two calm areas anywhere in each other's eight-block ring, corners included |
| where not | never at the map edge, never beside the spine — see "Where calm ground may go" |
| what shape | mostly single-block, with one or two zones of 2×2, 2×1 or 1×2 — the first zone is always the square |

**Each day — what is protected:**

- `ClosurePlanner` shuts 1 street a day in act I, rising to 4, and accepts a candidate **only if
  at least two distinct calm areas are still reachable after it**.
- `EventScheduler._calm_to_leave_alone` refuses the ground: **nothing is placed near a calm area
  she has not used this act**, so those stay clean rather than being cleaned up afterwards.
- `EventScheduler._ensure_one_usable_park` is the last line under it, for the day she has used
  every calm area there is and nothing was protected.
- `_spoil_the_parks_she_used` spoils the ones she has already settled in **this act**, which is
  what stops her going back to the same bench every day.
- `_ensure_the_city_is_still_walkable` drops obstructions that would seal the city.

**One thing that reads as guidance and was not designed as any:** the crowd respects closures, so
a shut street is the street with nobody on it, and that is legible from a block away.

**And here is the gap: the game does not guide her to calm ground.**

- **A closure points, and nobody has walked past one.** It is a **wall**: never on the day's
  corridor, preferentially on a turning off it — see "Where a closure goes" below. Whether that
  **reads** as guidance to a person is unanswered; the picture says the walls are where they should
  be, and that is all anybody knows.
- **There is no cue of any kind toward calm.** No marker, no map, no HUD line, nothing on the
  ground. "Planning-time legibility" is named a paragraph above as not existing.
- **The main road as a soft block** — the one thing in the design that would divide the city into
  a near half and a far half — is designed and not built; see `docs/TODO.md`.
- **Blockers are not placed to guide anybody**, which is the whole of it. The design is below.

### Diversions — the design

**Everything about how a blocker is presented is already solved.** The silhouettes, the caret, the
badge, the meters — none of that is the problem. **The problem is placement, and only placement.**

**Two axes, and they are independent.** The first is *permanence*, and it is what hard and soft
mean here — not severity, and not how a thing looks:

| | what it means | what it is made of |
|---|---|---|
| **Hard blocker** | the **layout** has pruned edges that cannot be traversed — permanent for the run | cul-de-sacs, big buildings |
| **Soft blocker** | placed **for a given day**, and changes from day to day | road closures, fallen tree, restaurants, dog walker, homeless yeller |

The second axis splits the soft ones by what they cost:

- **Lethal** — ends the day.
- **Mild / benign** — a price, not a stop.
- **Road closures are their own case**: *not lethal, but they prevent full access.* An absolute
  stop that does not kill.

**The purpose of a blocker is to guide the player to a calm zone.** That is the sentence every
placement rule has to serve, and it gives each kind a different job:

- **Hard and lethal blockers form the paths.** They are the walls. They are placed *"in a way to
  form paths through the map towards the calm zone"* — the route is what is left between them.
- **Benign blockers go on the route.** Not walls: texture. They are placed on the path she is meant
  to take, *"to make it more challenging / force the player to think their route through better"*.
- **A benign blocker suggests a scenario.** The specific one: *"turning around on the curb to cross
  the street and continue"* — a restaurant, a dog walker, a yeller. It is a **local** answer, a
  street to cross rather than a route to rethink, and that is what separates it from a wall.
- **Road closures shape the day without ending it, and they are guidance rather than hindrance.**
  *"A road block becomes guidance and is not a hindrance. It flips its role."* A closure is a
  **wall**: it is placed off the day's tree, to prune the ways that lead nowhere she should go, and
  it is how the set of available routes changes between days. It is **not** placed where it will be
  met — a closure exists to make a route obvious, not to make one harder.

**The main road is the challenge to overcome, and it is what makes a run have an arc — emergent by
construction, and nothing enforces it.** As calm areas on her side are used up they are spoiled,
which closes off parts of that side, and eventually the only calm left is across the spine. She is
never *held* on one side and never steered at the road — she may cross whenever she wants, and
crossing on day 1 is playing correctly rather than early.

**That is a constraint on what may be built.** The arc falls out of exhaustion plus spoiling, both
of which already exist. Nothing may be added that withholds the far side, gates it behind a day
number, or nudges her toward a crossing — a player who crosses on day 1 is playing correctly.

**Sealing off a section of the map is allowed, and it is the point.** A combination of hard and
soft blockers may make an entire section inaccessible. That is fine — *"the purpose is to guide the
player away from that section anyway, since there are no calm zones in that area."*

**A route to a calm area is not stable across days, and that is the mechanism rather than a side
effect.** The hard blockers hold still for the whole run — they are what the player *learns* — and
the soft ones re-cut the map every morning, so the same destination is reached a different way on
two consecutive days. A city worth knowing plus a day worth reading.

### Hard blockers

There are two. A **dead end** is one street with one end built over; a **big building** is two
neighbouring blocks joined into one mass with the street between them built over. They share a
placement pass, a reference tree and a gate, and each takes exactly one street out of the lattice —
what differs is the size of the thing left standing there.

A dead end is **one street, gone from the lattice, with one end built over**. Four to eight of
them per city, rolled from the city RNG, so they hold still for the whole run and are what the
player learns while the closures re-cut the map every morning.

**The ground stops, and that is the whole difference from a zone's absorbed street.** An absorbed
corridor is *calm ground rather than a closure* — the tiles are park and she walks over them, which
is exactly right for a shortcut and exactly wrong for a hard blocker.
`CityMap.dead_ends` is kept separate from `absent_segments` for that reason: the two are absent
for opposite reasons, and anything reasoning about **why** a street is missing has to tell them
apart. Anything asking *can a route go this way* wants `blocked_segments()`, which is both and
does not care.

**They are placed against a tree rather than before one**, so that no combination of them can seal
a region off. `RouteTree.for_the_run` is that tree, and it is a **witness**: it reaches every calm area the
run will ever use, so a blocker that takes no street off it cannot have made any of them
unreachable. Candidates therefore exclude the tree rather than the reachability gate merely
rejecting them afterwards — and day 1's calm is all the calm there will ever be, because an arc
only ever takes calm ground away.

Four kinds of street may not be a dead end, and the last is the one that only shows on the ground:

- **The street outside the front door.** The oldest exemption in the project.
- **The main road.** There is one of it and a spine with a hole in it is not a spine.
- **A precinct**, which is a place rather than a road.
- **Anything running alongside calm ground.** A dead end is a claim about where you can get to,
  and the claim is made on the *lattice* while the player walks on *tiles* — so a street with a
  park down one side is a street you walk into and step sideways out of, whatever the graph says.
  It is the absorbed-corridor rule read backwards: calm ground beside a dead end makes the dead end
  a doorway.

**A big building joins two blocks, and it is a landmark.** One or two per city: two neighbouring
blocks and the street between them, built as a single mass twenty-two tiles long and tall enough to
be the tallest thing in the district. **Every other street around the pair stays**, and so does
every junction — a car still turns at all of them — so what is gone is one road and not the grid
around it. It is a `BlockPurpose` with an empty `BlockLayout` on each block, which is what keeps it
solid for the whole run: a repaint finds nothing to paint back. It obeys the same four exclusions
plus two of its own — interior blocks only, since the edge of the world is a ring of frontages
rather than somewhere to put a wall, and single-block lots only, since a four-block zone is already
a lot.

**A landmark that took the whole ring around its two blocks would be an island in the lattice** —
four streets removed by one roll of the dice, where this removes one. The four-sided kind is a
separate type, recorded in `docs/TODO.md` and not built; what makes it separate is not its size but
what it does to the graph, and that is the question it would have to answer for itself.

`--spawn landmark` stands the player on the pavement off the long side of one, which is where the
seam would show if the two blocks read as two buildings. A picture of the *grid* does not answer
that: the whole claim of a landmark is about how it reads from the street.

**The gate is reachability: every calm area the run will ever use can still be walked to.**

It is not the stronger two-routes gate, and the difference costs almost nothing either way: with
candidates already off the reference tree, **99% of them pass either gate**, and a city gets 5.9
dead ends against a rolled 4–8.

What makes reachability the *right* gate here rather than merely an allowed one is that
cul-de-sacs are the point. Every dead end takes one of some area's ways in, so a two-routes rule
refuses exactly the interesting candidates — and *"sealing off a section of the map is allowed,
and it is the point."* What a hard blocker may never do is make calm unreachable, because it
holds for the whole run: a day can be bad, a run cannot be dead.

### The words for it

These are the words the rest of the project uses — in docs, in identifiers and in the telemetry
map's legend. **Three independent questions get asked about every blocker**, and one word for all
three answers none of them.

**Permanence — hard or soft.** Settled above: in the layout for the whole run, or placed for a day.

**Effect — what it does to a route that meets it.** Three values, and *lethal* is not the top of a
scale, it is a different thing:

| | | |
|---|---|---|
| **lethal** | ends the day | charging dog, robber, the carriageway |
| **impassable** | stops passage, does not kill | road closures |
| **costly** | passable at a price she can read before committing | restaurant, dog walker, yeller |

**Role — what the scheduler is placing it *for*.** `GameEnums.BlockerRole`, recorded on the thing
that was placed rather than derived from it: the same `cyclist` row is
a wall on a day it is rolled onto a street and nothing at all when the director sites one in front
of her.

- **wall** — placed to *bound* the corridor. Hard blockers are always walls; lethal soft ones are
  walls for a day. **Never inside the corridor**, preferentially on the rim — the turnings off it,
  which is where a wall can be seen from and therefore where it bounds anything
  (`EVENT_WALL_RIM_WEIGHT`).
- **friction** — placed *inside* the corridor, on the route she is meant to take, to make the route
  worth thinking about. Costly blockers. A weight (`EVENT_CORRIDOR_WEIGHT`) rather than a rule,
  because a city whose off-route streets are empty reads as a set.
- **set piece** — an authored one-shot placed so that she actually **meets** it, rather than so it
  exists somewhere. See the fire engine below.
- **none** — not placed against the corridor at all, which is the honest answer for an ambient
  playground, a scar the run left, the spoilers of a park she used, and anything the director sites
  in front of her. It is not a leftover bin: calling the charging dog a wall would claim a
  placement nothing made.

The three are stated relative to the corridor and none of them means anything without one.
`Corridor` is the one translation from
the tree's segment keys to the tile a placement actually happens on — *inside*, *rim* or *away* —
so an event, a closure and the telemetry picture all mean the same thing by the words.

And the thing the roles are stated relative to needs a name too: **the corridor** — the ground
today's routes run through, from the doorstep to the calm areas that are still worth reaching.
"Wall" and "friction" mean nothing until there is a corridor to be outside or inside of.

### How the corridor is built

**The target is every calm area still available that day, not one of them.** Each gets a corridor
and **the player chooses which to take** — the guidance is the set of offers, not a single
instruction. So the day's plan is a small **tree**: the doorstep at the root, one path per
available calm area.

**One corridor per calm area, and overlaps are a resource rather than a problem.** Paths may share
ground on the way out and separate later, since they end in distinct places. Where several
corridors run together, that shared stretch is a **chokepoint**.

**A chokepoint is a bundle, not a guarantee.** It narrows *how many places* a thing has to be in
order to be met; it never narrows it to one. Even in the ideal case — a day with exactly two
distinct paths — anything that must be encountered has to exist in **at least two** places. So the
value of a chokepoint is arithmetic: it is what makes "every route touches one of these" cost two
or three candidate sites instead of a dozen. **Anything written as "the tile she must cross" is
wrong**, and it is the easiest sentence in this section to write by accident.

**A calm area is reached two distinct ways where the map allows it**, and one will often be longer
than the other. That asymmetry is **incidental**: nothing should be tuned to produce it and no rule
should depend on it. Calling it *what makes the pair a choice rather than a mirror* reads a design
goal into an artefact of how the two routes are found.

**And it is a niceness, not a promise.** An area with one way in is a legitimate area; the second
route is an offer the day makes when the ground allows one. What must still hold absolutely is only
that **some** calm is reachable.

### Two strands side by side, and the street between them

Two strands of corridor running down neighbouring streets with nothing between them are not two
routes she chooses between; they are **one wide easy region**, and the choice they were supposed to
create is not there. The finding is about the corridor's *shape on the ground* rather than about
what a catalogue row costs.

It looked at first like a contradiction of the section above — *"the player can walk the beginning
of path A and then switch to path B without noticing, and that is fine… the constraint is on the
graph and never on spacing"* — so it went back, and the answer dissolves it rather than choosing a
side:

> *"Apply nuance here. Sometimes put a blocker between (wall or event) and sometimes leave it open
> — this is not as important as going off the path completely."*
> *"Only directly adjacent paths (with a single street connecting both) counts for this case
> obviously. Everything further apart should just naturally be never connectable."*

Three things, and the third is the one that resolves it:

- **Sometimes, not always.** Either of the two costed things — a **closure**, which makes the
  switch impossible, or an **event**, which makes it expensive — and sometimes nothing at all. It is
  variety in what one gap is worth, not a rule that closes every gap. A day that closed them all
  would have turned one corridor into several separate ones, which is exactly the star this design
  refuses to grow.
- **It ranks below "off the corridor has to cost".** Closing a gap matters less than making the
  ground away from the corridor expensive, which is the general case of the same idea.
- **Only directly adjacent.** A **gap** is one street with a strand of corridor crossing each of its
  two ends. Two strands further apart have off-corridor ground between them, which is lethal or very
  costly on its own — so they are separated *by the map*, and nothing has to be placed. The
  constraint on the **tree** is untouched; this is about a **placement** in one specific street.

Nothing here changes how the tree is grown. `RouteTree.gaps()` is a question asked of the finished
thing, and both answers to it are weights on placements that already exist: `CLOSURE_GAP_BIAS` aims
the day's closure quota at a gap, and `EVENT_WALL_GAP_WEIGHT` offers a gap's pavement more often to
a **very costly** wall. Not to a lethal one — a gap is on the rim, which is the costly end of the
range, and a thing that ends the day one turning off a route she is being guided down is the
gradient inverted.

**And a strand is a stretch of corridor rather than a branch.** A single branch that runs out along
one street and home along the next one down is two parallel lines with a free step between them, and
the player switching between them cannot see — and has no reason to care — that they are the same
colour. What tells two *routes* apart is `RouteTree.branches_on()`, and that is the telemetry's
question: the trace has to be able to say she left one path and joined another.

**Placement follows the tree, not a budget.** Plan the tree first and place from it — possibly with
a budget *per role and per region*, but not a single per-block number that the whole city competes
for. And the important half: **budget is not spent on what she never sees.** So the day places
**placeholders**, and a placeholder is resolved into a concrete row when she actually reaches it.

**Which means the one-shots must bind late.** *"This has to influence the design of one-off events
so they actually happen on the route the player chose and in front of the player instead of
somewhere else in the city — e.g. fire truck, which alley contains the note."* An authored one-shot
is not a place the day picks at dawn; it is a promise the day makes and the route redeems.

### A set piece has to be met

An authored set piece that fires once per run and is missed is a fairness contract and a silhouette
spent on nothing — which is what placing it like everything else, at a legal spot somewhere on the
map, produces on a day she may never walk that way.

So a **set piece is sited against the tree**: the day picks a **set** of candidate sites such that
**every corridor passes at least one**, and the one she reaches is the one that fires. That is
better than choosing a site on her chosen route, because it needs no knowledge of what she chose —
the guarantee is structural, and it holds whichever way she goes. `docs/EVENTS.md`, "A set piece is
offered on every route and happens on one", is the built mechanism.

It may not be *steered onto her*: `AHEAD_OF_PLAYER` is for moments, and a fire engine is
deliberately a **place**. What makes it a place and still unmissable is the candidate set, not a
director.

**"All routes" is load-bearing and means routes, not destinations.** A covering set that counts an
area as met when **either**
of its two ways in is met comes back as a **single** street on nine planned days out of 32 — the
one they all share on the way out. Placed there, the set piece is met by a player who takes the
first way out of everywhere and missed by one who takes the second, which is the "tile she must
cross" mistake with a covering set drawn round it. Covering every route costs nothing extra and
cannot go wrong that way: the two routes to one area share no street by construction, so no single
site can cover both, and *"at least two places"* is arithmetic rather than a rule anybody enforces.
It comes out at two to six sites against about fifteen routes.

**Two invariants this runs into, and both are smaller than they look.**

- **Chokepoints and edge-disjointness barely conflict at all.** Read as a single tile every route
  crosses, a chokepoint *would* break `ClosurePlanner`'s two-routes rule. It is a bundle, and the
  design keeps at least two distinct paths standing by construction — which is the same thing the
  invariant is protecting. What may still need loosening is its **formulation**: *distinct* means
  **sharing no street**, and corridors that run together and then separate share plenty. The
  guarantee to keep is *"the calm is reachable and no single closure decides the day"*; the
  edge-disjoint max-flow reading is one way to get it and is stricter than the design needs. A
  decision, but a small one.
- **A retried day discards what happened in the failed one**, so late binding costs nothing: the
  **plan** is identical on every attempt — the same tree, the same placeholders, the same candidate
  sets, all deterministic from the seed and the day number — and the **resolutions** she caused by
  walking are thrown away and made again. Determinism is a property of the offer, never of what she
  did with it. The thing that would be a bug is a placeholder resolving off a stream shared with the
  rest of the day, because then *where she walked* would move everything planned after it.

**No invariant forbids any of this**, which is worth stating because it is easy to assume
otherwise. `_park_is_reachable` asks only that **some** calm area is still reachable from home, not
that the city stays connected, so a sealed quarter is legal. `ClosurePlanner`'s two-distinct-routes
rule is likewise about reaching calm rather than about global connectivity.

So the honest summary: **the city permits routes to calm and protects them from becoming
impossible. It never suggests one.**

### The invariant

> **At least two distinct calm areas can still be walked to.**

`ClosurePlanner` checks it *before* accepting each closure rather than repairing the day
afterwards, so the set it produces always satisfies it and there is no order-dependent
unwinding to reason about. Counting routes is a unit-capacity max flow on the junction graph,
asked for one path.

**It is not *"two distinct routes to two distinct calm areas"*, and the difference matters.**
Edge-disjointness — two routes sharing no street — is a **stand-in** for winnability: by Menger,
two routes means no single street is a cut. The sentence it stands in for is asserted directly, and
about the city rather than about each area: **no one street cuts off all the calm**
(`tests/test_routes.gd`). The second route to any given area is an offer the day makes when the map
allows one.

**The count of areas is two**, because one of them may be the one the day has spoiled this morning;
one reachable area is the unwinnable day this invariant exists to prevent, and going below two
would be a separate decision.

Both ends of the journey are exempt from being charged for their own doorway:

- The **home street** is never closed. The home is a notch in a block with one exit, so
  sealing that street seals the player in however well connected the rest of the city is.
  This exemption predates closures — see "Route redundancy" above.
- An area is reached by arriving at **either end** of a street it opens onto. So a courtyard
  with a single archway is still reachable two ways; the routes differ everywhere except the
  doorway. Shutting that one street does put the courtyard out of reach for the day, and the
  invariant is what keeps that safe: two *other* areas can still be walked to.

### What closes a street

| Kind | From | What it is |
| --- | --- | --- |
| `ROADWORKS` | day 1 | A trench, a spoil heap and a length of pipe. |
| `FALLEN_TREE` | day 1 | A tree down across the road, roots and all. |
| `CRASH` | day 1 | Two cars that met. |
| `CORDON` | day 4 | Barriers and an order. Act II closes streets on purpose. |
| `RUBBLE` | day 12 | A facade in the road. |

The escalation is the point: act I closes a street by accident, act II by order, act IV by
bringing the building down. Mechanically they are identical — a street you cannot walk down
is a street you cannot walk down — and that is deliberate, because a closure that also had
rules would be an event.

**A closure is silent.** It contributes nothing to the excitement meter. The noise of a
street is the crowd on it and the danger of a street is the events on it; a closure is the
*shape* of the route and nothing else. A noisy roadworks already exists as the `construction`
event, which emits and obstructs; keeping the two apart is what stops `City` growing a third
thing to sum, and keeps "excitement is a pure query" true.

### How heavy

`CLOSURES_PER_ACT` is `[1, 2, 3, 4]` — four streets of a few hundred on the worst day. That is a
city that has had a bad morning, not a city under siege, and it is deliberately light: the route
pressure the player actually feels is at the scale of a *block*, and it comes from what is standing
on the street rather than from what is shut.

### Where a closure goes — a wall, off the corridor

**A closure is never placed on the day's corridor**, and preferentially lands on a turning off it
(`CLOSURE_WALL_BIAS`). A closure is a **wall**: it prunes the ways that lead nowhere she should go
so that the ways that remain are obvious, and putting one across her route is the defect rather than
the point.

**The bias reads as an obstacle rule with its sign flipped, and that is the trap in it.** Biasing
closures *toward* the streets on a shortest way to calm is the same arithmetic and the opposite
design: it makes a closure something to be met, which degrades the good ways instead of pruning the
bad ones. The sanity check inverts with it — *"a closure nobody would have walked is pointless"* is
right for an obstacle and exactly backwards for a signpost.

Two consequences, and the first is what makes the rest of the day's placement possible at all:

- **The corridor is still walkable once the barriers are up.** `City.start_day` grows the tree,
  `ClosurePlanner` excludes every street on it, and the events are then placed against that same
  tree. Nothing has to re-derive a corridor after the closures, and no closure can cut one.
- **The invariant is the second opinion rather than the guard.** A wall off the tree cannot cut the
  tree, so `_invariant_holds` should never refuse a candidate. It is still checked on every one —
  two independent mechanisms is the point — and a refusal writes a `plan` line saying the wall and
  the corridor disagree about where she is going. `tests/test_routes.gd` asserts it never happens,
  over every off-corridor street of every day of four seeds.

**And the rim is where a wall is worth anything**: a closure in the far corner of the map is not a
decision, it is scenery. A closure at the mouth of a turning is read from the junction, which is
where the wrong way is still a choice — the same reason `RoadClosure` seals both mouths rather than
putting one sign half way down a street.

### Everything else has to know

A closed street is not somewhere anyone can get to, so the whole street goes into
`CityMap.closed_tiles` and not just the two barriers:

- The **event scheduler** places nothing there, shortens a mobile event's route so it stops
  before a barrier, and counts closures as part of what is in the way when it checks that a
  park is still reachable.
- The **crowd** diverts at the junction. Cars turn as well as walkers, which they otherwise
  never do.
- The **resistance** never puts a contact behind one. Steps expire, so that would silently
  cost a run its good ending.

## Block purposes

The street lattice is fixed for the run. What a block *is* is not.

Every block is generated with an **arc**: the ordered list of purposes it may pass through,
and for each one the earliest day it may be reached and what has to happen first. Planning
the arc up front is what makes the transitions coherent — a block never has to invent a
plausible next state at runtime — and it is what lets the generator check the *whole run*
in one place instead of leaving the scheduler to rescue each day.

| Purpose | Calm? | What it is |
| --- | --- | --- |
| `PARK` | yes | Grass, trees, a playground. Contested calm: the swings are ambient noise. |
| `FOREST` | yes | Denser trees, darker floor, no playground. The quietest ground there is. |
| `QUIET_SQUARE` | yes | Paved and empty. Calm without being green. |
| `COURTYARD` | yes | A court cut inside a residential block, reached by an archway. Hidden calm. |
| `RESIDENTIAL` `COMMERCIAL` `INDUSTRIAL` `CIVIC` | no | Built over: the ordinary city. |
| `REQUISITIONED` | **no** | Calm ground taken by the regime. The same ground, churned; no longer calm. |
| `BOARDED_UP` | no | A commercial block gone dark. Every window unlit. |
| `BURNT_OUT` | no | A built block that burned and stayed burnt. |

A step is taken when its **cause** fires: `SCHEDULED` (the day arrived — requisitions and
boardings), `FIRE` (something burned there), or `MILITARY` (the army came down this street).
The event causes come from scars: `EventManager` funnels every scar through one place, so a
fire cannot leave a shell without the block being given the chance to move. A cause that
arrives at a block whose arc is not waiting for it does nothing at all, which is what keeps
the city coherent — a fire in a park leaves a burnt shell and does not turn the park into a
burnt-out block.

Causes fire during the day; the city presents the result the **next morning**.
`CityMap.repaint()` runs at the start of a day, so the fire burns today and the street is
ashes tomorrow.

### What is fixed, and what is absolute

The `CityMap` is not immutable for the run, and the rule that replaces immutability is:

> The street lattice, the block boundaries, the carves and the building footprints are fixed
> for the run. What a block *is* may change, and only ever along the arc the generator
> planned for it.

The half that is absolute is that **no purpose change may move a walkable tile**.
`tests/test_blocks.gd` pushes every block to the end of its arc across two dozen seeds and
asserts the walkable set is identical tile for tile. Nothing here can seal a street, open a
shortcut or invalidate a route the player learned on day 1. Per-day **closures** are the
one deliberate exception, and they are per-day, sealed at both ends and validated against
the route invariant before they are accepted — see "Road closures" above.

`CityGenerator.validate()` also guarantees that at least `MIN_CALM_BLOCKS_AT_END` blocks stay calm
for the whole run. A day can only be won on calm ground, so an arc set that requisitions everything
makes an unwinnable run rather than a hard one.

### Where the state lives

- `BlockPlan` — one block's arc. Fixed at generation, never mutated.
- `BlockLayout` — the carves (open rect, playground, square, alley, courtyard passage).
  Also fixed, which is why repainting a block on day 12 re-rolls nothing: the same court is
  a court on day 1 and churned mud on day 12, in the same place and the same size.
- `CityState` — run-scoped, on `GameState`. Only records how far along each arc the run has
  got. A day is therefore reconstructible from a seed, a day number and the causes fired.

## Life on the streets

The city carries its own traffic: several hundred people on the pavements and several dozen
cars on the roads, as real agents rather than a noise number. They are the reason a street
is loud, and the reason a park is quiet.

- **Lane-following, not pathfinding.** An agent belongs to one lane of one corridor,
  advances along it and steers toward the lane's centre. Walkers turn at junctions and keep
  to the pavement they are already on; cars drive straight and are recycled at the map edge.
  The population is fixed for the day, so the streets never quietly empty out over
  five minutes.
- **Density is per corridor, not uniform.** Each corridor has a busyness seeded from the
  *city*, so the busy streets are the same streets every morning and learning the quiet ones
  is worth something. The arterial is much the busiest, and it is the same arterial the
  event scheduler uses.
- **And it is per kind, because the two populations do not want the same streets.** A precinct
  corridor is the busiest **pavement** in the city and keeps its ordinary weight of cars, which
  divert at the bollards — the three blocks are closed to them and the eight either side are not.
  Because the crowd is a box around the player, "the busiest corridor" delivers its people to
  wherever on it she is standing.
- **A precinct carries more of the day than a length of ordinary pavement.** Its tiles are offered
  to the event scheduler `EVENT_PRECINCT_WEIGHT` times over, which is a retail street said as a
  weighting rather than as a new placement rule.
- **The road has a capacity**, which is what junction control gives it: without a box to wait in,
  two cars on crossing arms drive through each other and the network's throughput is unbounded. So
  the car population (`CROWD_CARS_PER_ACT`) is smaller than an uncontrolled network would want — a
  car waiting at a light beside you is louder for longer than one going past, and a population set
  before the box was rationed puts the arterial's noise floor above the ceiling
  `tests/test_crowd.gd` states. **The honest answer to *"the main road is too quiet"* has twice
  been something other than more cars.**
- **Density is per act.** The crowd thins as the occupation settles in: act III's streets
  are close to deserted, which makes the city *easier*. See docs/NARRATIVE.md.
- **Nobody walks through a park.** The crowd lives on the street lattice only, which is the
  structural half of "a park is quiet because nobody is in it". `tests/test_crowd.gd`
  asserts the middle of every park is out of earshot.

- **A car leaves the city by the bridge and the tunnel, and nowhere else.** This is *"nothing
  vanishes while you are looking at it"* — the rule written for events — arriving at the crowd,
  which does not otherwise need it: a recycle happens at the edge of a box nowhere near anything
  she can see, and the three holes in the boundary are exactly where that is not true. A car on the
  spine going north or south may overrun the map by `OUT_OF_SIGHT`; **everybody else keeps a
  tile**, because outside the map is water, forest and mountainside, and `_paint_outside_the_map`
  lays carriageway out there at the spine's own width and nowhere else. A general allowance would
  drive cars into the sea.

- **And nobody walks into a cul-de-sac's wall.** The crowd is the one thing that travels the
  lattice without asking `blocked_segments()`, and it does not need to — a dead end is a street
  with its far end built over, so the *tiles* say so. What it has to do is **look** at them, tile
  by tile, cached per tile. **A single probe fired some distance ahead is the trap**: it answers
  *is there something coming up* and looks straight past a two-tile wall into the open road behind
  it, so an agent entering the street from the junction beside the wall never sees it. Walking the
  tiles is also *cheaper* than the probe, because an agent covers a tile in about twenty frames.
  Measured with the probe: **eight agents inside a wall at once, and something in one on 87% of
  frames**; zero now, and `tests/test_crowd.gd` stands the field at a dead end so it can see it at
  all.

- **Bodies are solid, and cars are lethal.** Walking into somebody displaces you both and startles
  them; stepping into the carriageway in front of a moving car ends the day; traffic gives way at a
  zebra somebody is waiting at. **A contact deflects rather than blocking** — the separation is
  resolved positionally, so nothing can ever be walked into and stuck on, because stopping her dead
  in a crowd would fight the one verb the game has. See docs/MECHANICS.md, "The street has
  physics", for the geometry and the traffic fairness contract.

## Traffic signals

Every junction the spine passes through is signalled, and no other one is: one column of the
lattice, and every crossing of the main road.
`TrafficSignals` owns the phase; `City` owns the object and the heads that show it; `Crowd`
advances the clock, because that is what a rig steps.

**A signal is a timing problem where a zebra is a gap-hunting one.** An ordinary crossing is a
negotiation with a driver who can see you and gets better the longer you look; a signalled one is
a wait with a known end. Having both is what makes *which street* worth asking about.

**And the two look different.** A zebra says *the traffic gives way to you* and the spine's traffic
does not — so painting one there makes the opposite promise at every junction of the one street
where believing it ends the day. The spine's crossings are two dotted lines marking the pedestrian
safe zone.

**The tile type is the same on both, and that is the point.** Painting the crossing away entirely
would leave a walker crossing a side street standing on open carriageway, and the one thing a zebra
is for is saying where a person on a road is meant to be. So what differs is the picture, in
`GroundTiles._crossing_variant`, and nothing that reads `CROSSING` has to know — except the trace,
which must not say *"at a zebra"* on a street that has none.

- **The cycle is derived, not authored.** It is `2 × SIGNAL_PROGRESSION_BLOCKS` junction-to-junction
  travelling times. Without a progression, two thirds of the traffic stands still — measured.
- **The wave runs one way, and it cannot run two.** A car going with it holds its phase at
  every junction; a car going against it advances two travel times per junction and meets a green
  at chance. Measured on the wave alone: **93% green with it, 51% against**. It is not fixable —
  a two-way wave needs a 5.7s cycle and the side green plus its ambers is 9.0s — and the
  asymmetric offset beats every symmetric one on average. `Tuning.SIGNAL_PROGRESSION_BLOCKS`
  carries the derivation; `tests/test_crowd.gd` walks a car down the platoon rather than
  restating the arithmetic.
- **The side street's green is the fairness contract.** She crosses a main road while the main road
  is red, which is while the side street is green, so that green has to be longer than the walk
  across the carriageway with the doubled hard-fail margin. `Tuning.validate_signals()` on boot.
- **The amber is a clearance period, not a warning.** The crossing arm stays red through it, and a
  car too close to stop is counted as already in the box.
- **Four heads per junction, each beside the carriageway it stops.** From directly above a head has
  no face to point with, so *where it stands* is what says which road it is talking about.
- **The clock restarts with the day.** Not because a signal is a property of a day, but because two
  attempts at the same day must find the same cars at the same lights. What is learnable is the
  pattern, not where the cycle happens to be.

## Junctions

A lane is a queue and a junction is a **box**, and the box is the half that is easy to leave out.
With only the queue modelled, two cars on crossing arms each read a clear lane ahead, both enter,
and the positional resolve then does the only thing it can — move a body. Measured that way over
ninety seconds of the arterial: **3,776 overlapping crossing-axis pairs, one in half of all frames,
the deepest 39 px into a 40 px footprint** — with every assertion about the traffic passing
throughout, because each car's own lane was legal.

`Crowd.give_way_at_junctions()` decides whose turn it is, once a frame, per junction:

- **Only crossing traffic conflicts.** Two cars meeting head-on are in different lanes and pass;
  holding them would stop the city for nothing.
- **A car that cannot stop is counted as already in the box** rather than asked to brake, so nobody
  is waved in on top of it. That is the zebra's commit rule applied to a box.
- **Nothing enters a box it cannot leave.** A car whose own queue has no room beyond the junction
  waits short of it. Without this one rule a single backed-up queue takes the streets either side
  of it with it.
- **Nearest first, then right before left.** Distance alone leaves a symmetric arrival undecided;
  right-before-left alone deadlocks four cars in a ring. In that order there is exactly one winner
  per box per frame, and a light overrides the whole negotiation where there is one.

A collision stays possible because the commit rule is deliberate, and when it happens it
**startles the cars it happened to** — loud where it happened, composing by addition like every
other body. It is not a catalogue row: an event nobody meets in a run is a silhouette and a
fairness contract spent on decoration.

## The edge of the world

The lattice ends in T-junctions: the outermost corridor on each side is a whole street, and every
interior street runs into it and stops. What makes that legible is what is drawn beyond its far
pavement — without it the boundary reads as a road with a void along one side, and the map stops at
an invisible wall.

- **The border is the land, and each side says why the city ends.** South a bulkhead and then open
  water, no buildings; east and west a fence, then grass going into forest; north scree and then
  mountainside. It is the land rather than a ring of frontages dressing the edge.
  `City._paint_outside_the_map` is the whole of it — ground rather than objects, outside the map,
  where no tile, route or event can reach.
- **A band runs the full width of the map, and there is nothing at a corner.** North and south own
  the corners outright, so the mountain and the water run the whole way across and the fence, grass
  and forest are what is left in between. **Giving a corner to whichever side it is further out of
  sounds reasonable and draws a diagonal**: the place where two distances are equal is a 45° line,
  which is not what a coastline or a mountain does. Deliberately no headland, no bay and no new
  terrain, and `--spawn corner:nw|ne|sw|se` is how it is looked at.
- **The camera may see past the boundary.** Clamped to the last walkable tile, the edge goes on
  looking like a wall however much is built out there.
- **The spine leaves by a tunnel north and a bridge south**, so the city ends because the land does
  rather than because the map stops. They are lethal for the reason every stretch of carriageway is
  lethal; the danger needs nothing of its own.
- **There is no east or west exit, and there is no east-west main road.** There is one main road
  and it runs north to south. A carriageway running out into a wood is a road to nowhere, and the
  corridor it would run on is an arterial in no other part of the game.

**No walkable tile moved.** The exits are the last stretch of the spine as it already was, which
she could already stand on and already be killed on. That matters because the walkable set is
asserted tile for tile across every seed and block arc, and because a route out of the city must
never count as a route to a calm area.

## Rendering (2.5D)

Top-down camera with a fake vertical extrusion:

- Ground is a `TileMapLayer` over `assets/ground_tileset.tres`. Kerbs, centre lines and
  zebra crossings are authored tiles chosen per cell by `GroundTiles`, not geometry
  recomputed on every redraw.
- Buildings fill exactly their lot: the front wall takes the southern `height` px and the
  roof takes the rest. Fitting the mass inside the lot is what keeps extrusions off the
  street. (It does *not* by itself keep an extrusion off the player: the mass is inside the lot and
  still north of the origin a y-sort would compare, which is why buildings are their own layer —
  see below.) A taller building therefore shows more wall and less roof, which is what an oblique
  view of a taller building should look like.
- **Building heights are whole tiles**, because a tiled facade cannot honour a continuous height
  without stretching a tile. Quantising also makes the "a roof always shows" rule exact instead of
  approximate: the wall takes at most `floor(depth * 0.55)`
  rows and never the last one. A one-tile sliver is the single exception — it is all wall,
  capped by a parapet, because a roof there would have to overhang the lot behind it.
- Buildings are assembled from 32px tiles: a wall fill, a roof fill, edge overlays and
  windows. The fills are authored near-white and multiplied by the variant's colour, so the
  six roof colours still cost one asset each rather than six. Edges are overlays drawn on
  top, which is why a corner needs no dedicated corner tile — it takes two edge overlays
  and the parapet turns.
- Everything is `y_sort_enabled`, so the player passes behind and in front of props
  correctly — with one deliberate exception. **Buildings are a layer of their own, beneath the
  entities, and sort against nothing but each other.** A building's origin is the south edge of its lot and its mass
  extends a whole block north of it, so y-sorting drew it in front of everything on the pavement
  running up the side of that block — visible wherever the two also overlapped in **x**, which is
  anything wider than the 16px from a tile centre to the lot edge. A person (18px) never
  overlapped, a lorry (62px) always did, and the things in between are the ones that move: the
  player hugging a frontage, and every cue drawn above an entity's head. That is why it read as an
  occasional glitch rather than as a rule.

  The fix is not a better comparison. Buildings tile their lots exactly and no lot tile is
  walkable, both asserted in `tests/test_generator.gd`, so **nothing can ever legitimately stand
  behind a building** — and two things that can never be on opposite sides of each other have no
  business being sorted against each other.
- Sprite anchor is the *feet*, not the centre, so y-sorting matches the ground plane. A
  `Sprite2D` with `centered = false` puts the node at the sprite's *top-left*, which makes
  y-sort compare the wrong edge; use `offset` to draw upward from the ground plane instead.

- The rig, the props and the event bodies are sprites too. The mother has two frames per
  direction — the stride is a frame swap, because with the legs drawn into the sprite there
  is nothing left to swing. Three directions plus a mirror covers all eight: side, front,
  back.
- Anything whose *size* carries meaning is drawn at that size rather than at the art's own.
  A fire's flames scale with what it is currently emitting, and a blocking object is drawn
  by repeating a segment across exactly the width it obstructs — so what is on screen is
  what is in the way. **The catalogue states the same rule from the other end**: an event that
  stands still is *solid at the width it is drawn*. See `docs/EVENTS.md`, "Solid things are solid".

Art lives in `assets/` as hand-editable SVG — ground tiles under `assets/tiles/`, building
tiles under `assets/buildings/`, the player under `assets/rig/`, scenery under
`assets/props/`, event bodies under `assets/events/` — with a per-act palette multiplied
over the whole canvas. `Palette` holds only the colours the code still chooses at runtime;
a tree's green lives in the file that draws the tree.
