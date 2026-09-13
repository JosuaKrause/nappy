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
| `ORDINARY` | everything else | Two lanes, a zebra at every junction with a carriageway on the far side, and traffic that gives way to somebody standing at the kerb. Where the far side is a precinct there is no carriageway to zebra: the street ends at the precinct's edge instead, a T rather than a crossroads. |
| `MAIN` | **one**, north to south | The spine. Five times the traffic, signalled at every junction, and **it does not give way**: what stops it is the light. Every crossing at one of its junctions — the side street's two arms as well as its own — is two dotted lines rather than a zebra, because one light governs all four and a zebra on any of them is a promise the traffic there does not make. `CityMap.main_road`. |
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
A span covers its blocks and the junctions between them, and its paving reaches the road edge of
the crossroads at either end: the box's own carriageway still crosses a real street, so a car
reaching the precinct has an ordinary T to turn at, but the box's precinct-side sidewalk band is
paving too, which is what keeps the crossing street from painting a zebra over a road that stops a
pavement's width later. That is where the bollards stand: a line of posts across the carriageway
at the paving's edge, so the street reads as closed on purpose rather than as the road running out.
The pavements either side of the posts run straight past them onto the precinct's own paving — a
pram walks through, a car does not. **Nothing drives on the span itself, on either axis.** A
street crossing it internally meets paving rather than a carriageway and gets no zebra — the box is
brick from edge to edge — so what would be a crossroads elsewhere is a T at a precinct's edge, the
precinct's own pavement continuing past it as the third arm.

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
   hole through the same lot leaves slivers and an alley opening onto a square. **The middle
   block is exempt too**, unconditionally rather than through its own `RESIDENTIAL` chance: an
   alley there is a second, unguarded way onto ground nothing on it may ever threaten. See
   "The home" below.
5. **Place playgrounds** — every `PARK` district gets 1 playground, inset from the edge.
6. **Place home** — a 2×2 notch centred on the south edge of the **middle block**. The middle
   block is claimed as `RESIDENTIAL` before step 3, so nothing calm can be rolled into it and no
   zone can absorb it; exempted from step 4, every tile of its lot is still `BUILDING` when the
   notch is carved, so it is never slid to clear an alley the roll no longer creates. See "The
   home" below.
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
street that does not go through. The same predicate carries every other thing standing in a street:
a held segment, a soft seal's pavements, and the tiles under any stationary solid body
(`CityMap.obstructed_tiles`), so the crowd goes round a café the way it goes round a seal — see
docs/MECHANICS.md, "The crowd goes round a seal".

The zebras on a zone's edge are the case that looks obvious and is not. A crossing sits where a
*pavement* lane meets a *carriageway*, so most of them still make sense — the pavement is there
and the road is there, and only the arm of the junction beyond has gone. What does not is the
**stub**: the quarter of each T-junction on the zone's side, which nothing drives down (a car
diverting turns on the junction's own road band, a tile earlier) and nothing has to cross. That
becomes pavement, so the road visibly ends at the junction instead of poking into the park.

**A dead end's plug and a big building's mass leave the same stub**, and `CityGenerator` seals it
the same way — over "ground that just stopped being a street" rather than three times, once for a
zone, once for a wall built right at a junction's mouth, and once for a mass that swallows a whole
street. `_seal_stub_crossings` is the one function every hard blocker calls after it takes its
street: no zebra leads to ground that is no longer a street, whatever took it.

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

**A hard seal, a region wall and a soft seal carry the same tell**, on the same predicate a
closure does (`CrowdAgent._cannot_go_on`): a hard seal or a wall stands bodies kerb to kerb, so
both walkers and cars turn off at the last junction the same way they do for a closure; a soft
seal takes both pavements and leaves the carriageway, so a walker turns away while a car drives
straight through, reading as a street quiet on foot and ordinary on the road. A region **door** is
the one crossing this mostly does not apply to — a car brakes and queues for the gate instead of
diverting, because a door is a crossing the day's own structure means to keep open.

**A walker's answer at a door is its own**, drawn once when it is placed so that it cannot change
halfway down a street. One in four (`Tuning.WALKER_DOOR_TURN_BACK_FRACTION`) turns back at the last
junction exactly the way it would at a wall — it gets no carve-out, so the door reads to it as the
wall either side of it does. One in eight (`Tuning.WALKER_DOOR_PASS_FRACTION`) walks straight
through. Everybody else is **held at the hut on their own sidewalk**, the way she is held at it,
in four states: *walking* up to it, *waiting* stopped beside it in their last facing while whoever
is inside is seen to, *inspection* inside the hut and not drawn for
`Tuning.WALKER_DOOR_HOLD_SECONDS` (1s, under her own two), and *emerging* on the far side on the
same lane, carrying a cooldown that keeps that hut from taking them again until they have left its
area. One walker inside a hut at a time, and the line behind it never grows past
`Tuning.WALKER_DOOR_QUEUE_MAX`: a walker whose lookahead first sees a door that is already that
busy turns back at the last junction instead of joining it, so a busy door never grows a queue down
the sidewalk.

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
plus three of its own — interior blocks only, since the edge of the world is a ring of frontages
rather than somewhere to put a wall; single-block lots only, since a four-block zone is already
a lot; and never on a precinct's own paving, checked over the whole mass — both block interiors and
the street between them — rather than only the street being removed.

**A precinct is paved frontage to frontage, so nothing that takes ground for itself may cover any
of it, and that is a constraint on where a footprint may land rather than a repair once it has.** A
calm zone obeys the identical rule for the identical reason: an open zone would only ever repaint a
precinct's corridor as park, but an apartment complex absorbs its streets *solid*, the same as a big
building's mass, so both are checked before their footprint is accepted. `CityGenerator.
_touches_a_precinct` is the one place either question is asked.

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
`Corridor` is the one translation from the tree's cells to the tile a placement actually happens
on — *inside*, *rim* or *away* — so an event, a closure and the telemetry picture all mean the
same thing by the words.

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
almost never goes wrong that way: the two routes to one area share no **cell** by construction —
`ReachabilityGrid`'s two-tile-square unit, the grain the whole corridor is now grown on — so a
single site covers both only on the rare street where the two routes' cells still resolve to the
same `StreetNetwork.Segment`, a street being three cells wide. *"At least two places"* is arithmetic
on the common case rather than a rule anybody enforces, and the rare exception is measured, not
guarded against, in `tests/test_events.gd`.
It comes out at two to six sites against about fifteen routes.

**Two invariants this runs into, and both are smaller than they look.**

- **Chokepoints and edge-disjointness barely conflict at all.** Read as a single tile every route
  crosses, a chokepoint *would* break the tree's two-ways-in guarantee. It is a bundle, and the
  design keeps at least two distinct paths standing by construction — which is the same thing the
  guarantee is protecting. Its **formulation**: *distinct* means **sharing no cell**
  (`ReachabilityGrid.CELL`, two tiles square, the grain `RouteTree` grows on), and corridors that run
  together and then separate share plenty of street even so. The guarantee to keep is *"the calm is
  reachable and no single closure decides the day"*; cell-disjointness is one way to get it and is
  stricter than the design needs.
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
unwinding to reason about. Reachability is asked of `ReachabilityGrid` — a flood fill over the
day's tiles, with a candidate's barrier tiles added on top — rather than of the junction graph:
the graph only knows a street is an edge, and cannot see that a park or an alley beside a closed
street offers a way round it. `StreetNetwork.route_count()`'s unit-capacity max flow on the
junction graph still stands behind the structural guarantee below, which is a fact about the fixed
lattice rather than something asked fresh of every candidate.

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
| `FALLEN_TREE` | day 1 | A tree down across the road, roots and all — only on a street that has trees, and it takes one of their pits with it. |
| `CRASH` | day 1 | Two cars that met. |
| `CORDON` | day 4 | Barriers and an order. Act II closes streets on purpose. |
| `RUBBLE` | day 12 | A facade in the road. |

The escalation is the point: act I closes a street by accident, act II by order, act IV by
bringing the building down. Mechanically they are identical — a street you cannot walk down
is a street you cannot walk down — and that is deliberate, because a closure that also had
rules would be an event.

**`FALLEN_TREE` only happens where a tree stood, and the tree that fell is the one that is
missing.** *(2026-09-11, the player: "fallen trees should only be possible on streets with trees
and one spot should be empty (the fallen tree's spot)".)* `ClosurePlanner._pick_kind` drops the
kind from the roll entirely on a street `StreetTrees` never planted — a gate, not a preference —
and weights it up on one it did, since tree-lined streets are a small fraction of the city and a
day closes between one and four of them. The closure then takes one of that street's own pits,
**the one nearest the middle of the street it closed**, and that pit stands empty for the day:
`City.refresh_street_trees()` does not draw the tree there. A gap at the far end of the street
would read as two different trees, which is why the choice is the planner's rather than the first
pit it finds.

**`fallen_tree_seal` is the same rule in the other pass.** `SealPlanner` offers that picture only
on a tree-lined street too, stands its whole-street scene on a pit rather than beside one, and
empties it. It is the single exception to "a tree and an event never share ground" — see
"Rendering (2.5D)" below, and `docs/EVENTS.md`, "Where in the city, and why".

`StreetTrees.planted()` is the one source of truth all of them read — what `City` draws, which
segment may carry a felled tree, and which pit that felled tree takes — so the closure marker's
picture and the standing trees beside it can never be two different species.

**A closure is silent, and so is every seal but one.** A `RoadClosure` contributes nothing to the
excitement meter: the noise of a street is the crowd on it and the danger of a street is the events
on it, and a closure is the *shape* of the route and nothing else. A noisy roadworks already exists
as the `construction` event, which emits and obstructs; keeping the two apart is what stops `City`
growing a third thing to sum, and keeps "excitement is a pure query" true. All five kinds in the
table above are silent, `CRASH` included — the two cars it leaves in the road are a picture.

**The one exception is the `car_accident` seal, and it is the player's own.** *(2026-09-12: "a car
crash right now has a full bounding box even though there are gaps in the sprite. the bounding box
should only be the crashed cars but it should emanate an excitement field that prevents the player
from walking past it".)* That row is a `SealPlanner` scene rather than a `RoadClosure` — see
"Sealing the tree" — and it is now solid only where its two cars are, so the debris and the
pavements either side of them are ground she can walk. What closes them is
`Tuning.CAR_ACCIDENT_INTENSITY`, a field over the scene's own band that costs more than half the
meter to squeeze past. **It is still not a third thing to sum**: a seal is a catalogue row, so it
emits the way every event does and `City.total_excitement_at` is unchanged. What has changed is
that a seal may be loud, and only this one is — the fallen tree (one trunk kerb to kerb) and the
burst main (a crater between two barriers) leave no gaps to close and stay at zero.

**The seal still seals.** `ClosurePlanner` goes on counting a closed street as closed for the route
guarantee, and `CityMap.held_segments` still keeps the crowd off a hard seal's street; both are
stated over `obstructs_radius` — the ground the scene *closes*, unmoved at 96px — rather than over
the bodies it puts down. That is the conservative direction and deliberately so: taking obstruction
away can only add reachable ground, so a day proved winnable against the whole-street band is still
winnable with two cars standing in it.

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
  over every off-corridor street of a sample of days across several seeds.

**And the rim is where a wall is worth anything**: a closure in the far corner of the map is not a
decision, it is scenery. A closure at the mouth of a turning is read from the junction, which is
where the wrong way is still a choice — the same reason `RoadClosure` seals both mouths rather than
putting one sign half way down a street.

**Never on a calm area's own access street, and that is a third exclusion beside the tree and the
doorstep.** A park is walked *through*, so a barrier on any of its access streets — every street
round its lot, since `ClosurePlanner._access_segments` finds all of them — closes nothing, and
reads as broken by anybody standing at it looking at the open ground beside it. A courtyard is a
pocket with one door, so a barrier beside it is a real closure — except on the one street its
archway opens onto, which is its own access street and closing it seals the courtyard rather than
lengthening the walk to it. Both halves are the same rule: a calm area's access streets are refused
outright rather than merely weighted down. It is stated over the cells the barrier touches rather
than over the map, because the global version — does this closure lengthen the best route to any
calm area — does not work on a lattice with several calm areas scattered across it: removing one
street almost never lengthens the walk to any of them, so a filter stated that way would refuse
almost nothing. See `docs/DECISIONS.md` under M45 for the measurement.

### Everything else has to know

A closed street's ground goes into `CityMap.closed_tiles` wherever the barriers actually cut it
off — which is most of it, but not necessarily all: an alley mouth or a courtyard archway can open
onto the middle of a closed street, and the ground beside it is still reachable from that side
however the two mouths are sealed. `ReachabilityGrid` is what tells the difference, flooding the
day's tiles with every barrier tile added on top; what the flood never reaches is what
`closed_tiles` holds.

- The **event scheduler** places nothing there, shortens a mobile event's route so it stops
  before a barrier, and counts closures as part of what is in the way when it checks that a
  park is still reachable.
- The **crowd** diverts at the junction. Cars turn as well as walkers, which they otherwise
  never do.
- The **resistance** never puts a contact behind one. Steps expire, so that would silently
  cost a run its good ending.

### Sealing the tree

**A road closure is not what makes off-corridor ground closed.** `ClosurePlanner` shuts a handful
of streets a day — one in act I, rising to four — which is guidance at the scale of a route
decision, not a wall around the whole city. `SealPlanner` (`src/routes/seal_planner.gd`) is the
separate pass that does that: every street off the day's tree, real and not the home's own —
about 187 of the lattice's 264 on a typical day — carries a **seal**, so the corridor stops being
the *cheapest* way through and becomes the *only* free one. It is planned the same morning as the
closures, off the same tree, and counted apart from the day's event budget: a seal is a fact about
where she may walk, not a piece of the catalogue's variety.

**Two strengths, both obstacles from the existing catalogue rather than a new mechanism.** A
**hard** seal — `barricade`, from act IV — stands several bodies across the street's whole width,
sidewalk to sidewalk, so nothing gets past. A **soft** seal takes both pavements (`construction`,
`cafe_tables`, `market_stall` or `delivery_van`, one on each side) and leaves the carriageway open:
the road is always still there, so a soft seal always costs time, never the day. **A thing whose
job is to stand in the way costs route and nothing else** — `construction`, `delivery_van` and
`barricade` carry no field at all, so they cost only the detour; `cafe_tables` and `market_stall`
are genuine sources as well as bodies and still charge the meter, tightly, to whoever actually
stands at the tables or the stall. Every day from day 1 has a working soft pair; the hard one only
from act IV, since `barricade` is the only row today drawn as a citywide wall rather than a street
event — the milestone that draws more pictures for both strengths costs nothing here but longer
candidate lists.

**The doorstep is exempt, for the same reason a closure never stands there**: the home is a notch
with one exit, and a seal on its own street would seal her in on the first frame. **The join
between the home street and the rest of the tree is protected too, not merely the home street
itself.** `RouteTree` grows a **trunk** from the home street outward to the nearest tree ground
after every branch has grown, so at least one street meeting the home street's own junctions is
always tree ground — the fact `SealPlanner` already reads to refuse a seal. Without it, which
street that join landed on was whatever a branch's own random walk happened to reach home through,
and on a bad roll every street the home led to could be off-tree and sealed at once.

**The main road is exempt too, and a route never runs along it in the first place.** `RouteTree`
refuses to grow a strand along the spine's own length — she may still cross it wherever she likes,
which is unchanged and unrestricted — so the main road is off every day's tree by construction.
Sealing it as well would wall the one street the design deliberately leaves open, so `SealPlanner`
refuses it outright rather than treating "off the tree" as reason enough. It is already the worst
ground in the game to stand on (0.6× decay against an ordinary street's 1.0), which is why making
it *not a route* is the whole of the fix.

**Alleys are not streets, so they are never sealed — a through-alley's *mouth* can be, and only
sometimes.** An alley that touches the tree at either end stays open outright, which is the way
round a wall the design asks for; one that touches it at neither end is a *candidate* to be walled
at both mouths, so it can never bridge two sealed streets into a second city behind them — but only
`Tuning.ALLEY_MOUTH_SEAL_CHANCE` of those candidates actually are, rolled once per qualifying alley,
so an alley reads as the occasional exception rather than a wall of its own.

**A final pass thins the seals.** A small `Tuning.SEAL_THINNING_FRACTION` of the day's soft pairs
lose one body — never a hard seal, never an alley mouth — so a wrong turn stays open long enough to
be taken and discovered rather than reading as a wall on sight the moment she glances down it.

**The winnability guarantee is not repeated here, it is true by construction.** A seal never
stands on tree ground or the doorstep — the two things the tree and `ClosurePlanner` already
guarantee a route through, and the trunk above is what makes the first of those cover the join as
well — so nothing a seal does can cut the corridor. `EventScheduler._ensure_the_city_is_still_
walkable` stays what it always was, a repair pass for the catalogue's own placements; sealing needs
no equivalent; `tests/test_seals.gd` measures the guarantee over many seeds and days instead of
asserting it at runtime.

### The escape is a chain, not a tree

The walk out of the city on the last night is planned by `FinalePlanner`
(`src/finale/finale_planner.gd`) and is the one route in the game that is **not** a `RouteTree`.

**A day grows a tree because a day has to stay winnable whichever way she goes**: several strands
to several calm areas, with two distinct routes to each counted as a max flow. The escape asks the
opposite question — *which single walk does she take, and what does it cost* — so it grows **two
ordered chains** instead: the service exit, three calm areas one after another, and an edge. One
street-walk between consecutive stops and nothing else open, with no branch and no second way to
any of them.

**Two chains, and they share no cell after the door.** One ends at the tunnel at the north end of
the spine and one at the bridge at its south end — the two exits `CityEdge` already draws and
already lets her walk into. The second is grown with every cell of the first treated as wall, so
they part at the service exit, or as near it as the lattice allows, and the choice is made once, at
the door. The home lot sits between the two ends of the spine, so neither exit is trivially nearer.

**A stop is a connected component of calm ground**, which is a park lot, a four-block zone, a
forest, a quiet square or a courtyard without the planner having to know which. Distinctness then
needs no rule: two stops are different components or they are the same stop. Slivers under
`FinalePlanner._SMALLEST_CALM_AREA` are dropped, because a calm area has to be big enough to have a
route through it.

**The rule that makes any of this legal is the one that was already there: a route *out* of the
city is never a route to a calm area.** The tunnel and the bridge are the last stretch of the
spine, walkable and lethal like every other carriageway, and `tests/test_blocks.gd` holds that they
never count as calm — which is why an edge can be the end of a chain without a day's own guarantees
having anything to say about it.

**Everything off the chains is sealed**, by `SealPlanner.plan_finale()`, which takes the chains'
open cells where `plan_day` takes a tree. Three differences, each for a reason the escape changes:
seals are all **hard**, since a soft one leaves the carriageway open and the brief is a single path;
the **main road is sealed like anything else**, because the chains *end* on the spine and leaving
the rest of it open would join them at the one street that touches both exits; and **every alley
mouth off the chains** is walled rather than a fraction of the qualifying ones. The doorstep stays
exempt for the reason it always is.

**A street is spared only where a chain walks it**, measured at the street's own midpoint, which is
where a hard seal stands. Asking the looser question — does a chain touch this street at all —
spares every street at every junction the walk turns at, which is several times as much open ground
as the chains themselves.

### Regions and the wall

**Every junction in the lattice belongs to exactly one of `Tuning.REGION_COUNT` regions**, decided
once at generation from the city's own seed and stored on `CityMap`. A segment whose two ends share
a region is that region's interior; one whose ends differ is a **boundary segment**. The main road is
ordinary ground to the partition — a boundary may cut it, which is the one place the gate over the
roadway means anything. Regions are decided before any day's routes are, and a day's `RouteTree`
grows with no knowledge of them, so a boundary can never make a route worse; it only decides,
afterwards, which of the crossings already on a grown route are doors and which are wall.

**Atoms keep the boundary off ground a route has to reach or use whole.** Before growth, every
junction at either end of a calm area's own access segments is unioned into one atom, and so is a
commercial square's own frontage — open, non-street ground that can border more than one street is
the same shape of bypass whether or not it is calm. The same union covers the near, still-walkable
junction of any dead end or built-over street either kind of ground's buffer touches, because a
cul-de-sac's stub is real tile-level ground even though its street is not in the lattice, plus the
home street's two junctions and every junction along a precinct span's own corridor. A claim during
growth always takes a whole atom at once, so no boundary segment ever borders calm ground or a
square, is the home street, or cuts a precinct.

**Regions are grown by a round-robin flood.** `Tuning.REGION_COUNT` seed junctions are chosen by
farthest-point sampling over the real-segment graph — `absent_segments`, both the zone-absorbed and
the built-over kind, is never traversed — with the graph's own seed deciding only the first pick and
never choosing two seeds from the same atom. Growth then proceeds one step per region in turn, each
claim taking a junction's whole atom, so the regions come out comparable in size rather than the
first seed's flood eating the map before the others start.

**An alley is not an atom; it is a second kind of crossing.** Its two bordering streets are not
unioned together — a city's worth of alleys chained that way collapses the partition toward one
giant region holding every calm area, since an alley touches all four corners of its own block. An
alley is a **crossing** instead when the ground at its two mouths (see below) belongs to two
different regions; one whose two mouths agree is left untouched, exactly as it always was.

**The wall stands at a crossing's mouth, one tile deep, never a segment's midpoint.** A boundary
segment's wall stands at one of its two ends (`CityMap.boundary_wall_at_a`, decided at generation);
a crossing alley's wall stands at both of its mouths. One tile deep is deliberate: the roadblock
row's own width reaches roughly two tiles along a street each way, wide enough to cover a nearby
alley's mouth outright from a segment's midpoint, and the mouth is where a barrier already stands for
every other closure in the game. **A crossing alley's own two wall bodies carry a narrower
override again, to their own mouth rather than a neighbour's**: the row's shape becomes a point of
half the alley's own width (`RegionPlanner._alley_mouth_wall_body()`), so the barrier draws and
collides at exactly the alley's own `ALLEY_WIDTH_TILES × Tuning.TILE_SIZE` (64px) instead of the
row's own 120px reach, which used to lie over the roof edges of the lots either side of the mouth
(`docs/playtests/PLAYTEST-57.md`, "Roofs"). The whole of a boundary segment's ground therefore belongs to the
region at its **far** end, away from the wall — which end carries it is nudged at generation so that
matching an alley's other, real bordering street's ground keeps as many alleys as possible from
becoming crossings at all.

**The wall is the day's, not `absent_segments`.** From `Tuning.REGION_WALL_FIRST_DAY` every morning,
a crossing — a boundary segment or a crossing alley — the day's `RouteTree` uses is a **door**;
every other crossing is **wall**, placed as hard seals of the roadblock row. Before that day nothing
is drawn at all — the partition exists from generation, but the milestone's own words are
"checkpoints in the later acts."

**The tree wins, unconditionally, over the partition.** A region holding no calm area gets no doors
on every day its own boundary happens to be off the tree — which is every day unless the tree
genuinely has to cross it to reach calm ground elsewhere, and on that day the crossing is a door
regardless of what the region holds. A region edge may never affect a path is the stronger rule, so
nothing here may override what the tree already decided; there is no separate exemption for the
home region either; a door is exactly a boundary crossing the tree uses and nothing else changes
that.

**A door stands the same three-body geometry a wall would, passable instead of held.** A street
door gets a `checkpoint_hut` on each pavement lane and a `checkpoint_gate` over the road between
them, at the wall's own three positions (`SealPlanner.positions_across` at `Tuning.TILE_SIZE`,
which comes out at three across `STREET_WIDTH`); an alley door gets a single `checkpoint_post` at
each of its two mouths. `RegionPlanner._add_door_bodies`/`_add_alley_door_bodies` build them
alongside the wall's own bodies, in `RegionPlan.door_bodies`. The toll is paid at a hut or a post —
see docs/EVENTS.md, "Checkpoints" — the gate only ever stops a car, never her.

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
| `BOARDED_UP` | no | A commercial block gone dark. Every window shuttered and unlit, every storefront shuttered — see "The city degrades". |
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

## The city degrades

Block purposes tell the story of the run in the streets she can walk into or out of; the ground
under her feet tells the same story without a word. Cracked paving, litter, garbage sacks and
shuttered shopfronts read the same one curve, `Tuning.degradation_for(day)` — zero through the
early days, rising from `Tuning.DEGRADATION_FIRST_DAY` (day 5, one day into act II, so the ground
catches up with what the act already told her rather than turning on the same morning) to 1.0 on
the run's last day, the way `EventScheduler.budget_for()` rises. **None of it changes what a route
costs** — not a tile's type, not its cost, not the crowd's lanes — it is presentation, the same way
a closure is silent and a scar is a mark rather than an obstruction. One exception is stated below
rather than smuggled in.

- **Cracked ground.** `GroundTiles` gives a plain road, sidewalk or alley tile a crack level —
  hairline, cracked, or broken, two patterns each — from a fixed per-tile roll compared against
  the curve: a tile that has already crossed its own roll stays cracked, and the level worsens as
  the curve pushes further past it, so the same tile shows the same crack on the same day every
  time and the share of cracked ground only ever grows. **Pavement cracks before road** — a lower
  threshold, since she walks the pavement and looks at it while the carriageway is behind her — a
  kerb, a road line, a crossing and the main road keep their own markings regardless, since no
  cracked variant of those exists.
- **Loose litter.** Small ground decals — an eaten apple, a newspaper, a crushed cup, a torn bag,
  a rolled can — placed at generation from the curve and a seeded roll, on pavements, alleys and
  squares. Never on the road's own lanes and never inside a calm area, which falls out of the
  eligible ground rather than needing its own check: neither is either. They carry no body, no
  field and no y-sort — `CityDecals` draws them flat, between the ground and the buildings, so they
  lie under everything the way a kerb or a centre line does.
- **Garbage sacks.** Alleys carry sacks from the curve's own first day; building fronts a couple
  of days after that — the city's services failing in the back streets before they fail on the
  ones she actually shops on. A single sack is a `Prop` with a `GroundShape` for its shadow and no
  body, drawn exactly like a bollard; a heaped pile is the same, also with no body — whether a pile
  that narrows an alley should obstruct her is a decision for when one is actually seen standing in
  an alley she has to use, not before. The mouse in the alley (`alley_mouse`) prefers a tile beside
  a standing pile once both exist, as extra copies in the scheduler's own candidate roll rather
  than as a new placement rule.
- **The storefronts shutter.** A `BOARDED_UP` block's ground floor shows `storefront_
  {a,b,c,d}_shuttered.svg` in place of whatever plain or awning shop stood there, and every window
  above it shows the shuttered pair, dark — services gone the same day the block itself went dark.
  Short of a block actually boarding, a share of ordinary `COMMERCIAL` ground floors shutters too
  as the curve rises past each shop's own fixed roll, which is the city thinning out ahead of any
  one block's arc reaching `BOARDED_UP`. A door never moves; only what stands either side of it
  does.

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
  drive cars into the sea. The rule holds at both ends of a journey: `CrowdAgent.
  _keep_within_the_room_beyond_the_map` clamps a freshly recycled agent to the same tile (or the
  same `OUT_OF_SIGHT`, for a car on the spine) that a departing one is held to, so the entry-side
  fallback that only fires when every recycle roll misses cannot hand a walker the reach that
  belongs to a car on the bridge. **And the same room is what lets a car arrive by them.** The
  crowd's box is clamped to the map, so beside the tunnel the band a southbound spine car enters
  through is the stretch past the north edge, and `CrowdAgent._entry_band_fits` accepts a band
  that reaches that far only for the agent the departure rule already lets go that far. Refusing
  it for everybody would make the traffic through both holes one-way — cars that only ever leave
  — and `tests/test_crowd.gd` stands at each end and counts spine cars out of bounds by which way
  they point.

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

- **And the same predicate covers a hard seal, a region wall and a soft seal.** `CityMap.
  held_segments` (the day's no-catalogue-row ground) and `CityMap.soft_sealed_tiles` (a soft seal's
  own pavement tiles, kept apart because its carriageway is not held) are what `CrowdAgent.
  _cannot_go_on` asks alongside a closure: a hard seal or a wall shuts the whole street to both
  walkers and cars, a soft seal shuts only the pavements so a car still crosses it, and a region
  door is carved out of the held check for everybody the door means to let through — a car brakes
  and queues for the gate the way it does at a light, and so does a walker unless its own answer at
  a door is to turn back, in which case it gets no carve-out and the door reads to it exactly like
  the wall either side of it. A walker that does cross is held at the hut on its own sidewalk,
  which is `Crowd._hold_walkers_at_doors()` and `WalkerDoorHold` rather than anything the tile map
  says: the hut's own ground point, one body inside at a time, and the line waiting behind it.

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
where believing it ends the day. **The paint belongs to the junction, not the arm**: one light
governs every crossing where the spine meets a side street, so all four — the two across the
spine's own carriageway and the two across the side street's — are dotted lines marking the
pedestrian safe zone, not only the pair that happens to cross the wider road.

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
  no face to point with, so *where it stands* is what says which road it is talking about — and
  what you can see of it says the rest. The head facing down the screen is drawn face-on with its
  lamp, the two facing across it are drawn edge-on with the lamp as a cone under the visor, and the
  head north of the junction, which faces up the screen at the southbound traffic, shows its back
  and no lamp at all: the face-on head across the junction already carries that arm's whole
  message, and a lamp on a back plate would be a light shining out of the back of a box.
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
  lethal; the danger needs nothing of its own. The two are not the same depth: the bridge carries
  the road the whole width of the band, and the tunnel carries it only as far as the portal's
  opening (`CityEdge.TUNNEL_DEPTH_TILES`), fading to dark inside the mouth, with mountain painted
  above the portal both under and over the traffic so a leaving car is never seen on the rock.
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
  `GroundLayers` builds their illustrated textures from shared bases and transparent details
  when the TileSet is prepared. Grass clump arrangements vary by city seed and cell coordinates;
  the source IDs, tile types and walkable geometry stay fixed. `--svg` selects the vector art.
- Buildings fill exactly their lot: the front wall takes the southern `height` px and the
  roof takes the rest. Fitting the mass inside the lot is what keeps extrusions off the
  street. (It does *not* by itself keep an extrusion off the player: the mass is inside the lot and
  still north of the origin a y-sort would compare, which is why buildings are their own layer —
  see below.) A taller building therefore shows more wall and less roof, which is what an oblique
  view of a taller building should look like. **The collision body follows the lot with one
  exception**: its own north edge — the top of the wall in this projection — sits
  `Building.NORTH_EDGE_INSET` (6px) south of the lot's own north edge, so she can step a little
  way into it rather than stop a tile short. The south edge is untouched.
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
- **A roof carries furniture, seeded per building from its block's own starting purpose**
  (`Building.district`) — vents, HVAC boxes and a straight-and-corner duct run on `INDUSTRIAL`,
  skylights on `CIVIC`, mostly water tanks with the odd vent on `RESIDENTIAL` and `COMMERCIAL`.
  Every unit sits on an interior cell — never the perimeter row or column a roof's own edge tiles
  already draw — so nothing overhangs the silhouette, and how many a roof carries scales with how
  many interior cells it has. The vent is the one thing on a roof that moves: it swaps between its
  two rotor frames on a timer of its own, and nothing else up there is animated. Furniture is
  painted by `Building._draw()` itself, above its own roof tiles and inside the layer of buildings
  under the entities — never the y-sorted layer a street prop or the player draws in — so a unit
  is never compared against anything on the pavement.
- **A front is district and block purpose, read the same way a roof's furniture is.** Each complete
  two-column span of a `COMMERCIAL` building is a 64×36px storefront. Each facade samples the
  four types in seeded, shuffled groups, using each once before repeating and avoiding an
  immediate repeat between groups; the same building keeps its order across days. An awning
  variant appears on a seeded share. Each is a substitution for the wall's ground-floor plinth:
  the storefront's fill is opaque, so it covers the ordinary windows under both columns the same
  way the plinth always did. An odd final column remains ordinary wall, and a facade only one wall
  row tall keeps its wall base so the complete store fits. Each storefront has a 26×34px entrance
  aligned to the shared ground line. A `CIVIC` building's entrance carries `civic_portico.svg`, and a seeded share
  of `RESIDENTIAL` facades tall enough for one carries a fire escape over their bottom two rows —
  both drawn as overlays, after the wall, rather than replacing a texture the way a storefront
  does. The awning is the one piece of a front that leaves the wall plane; it stays inside the
  wall's own footprint rather than reaching over the pavement's walkable band.
- **A building's upper-floor windows carry one of three styles, rolled once for the whole
  building**: the plain pair, a tall sash pair, or a shuttered pair that lights up like any other —
  ordinary street variety, unconnected to the day or the block's own condition. Going
  `BOARDED_UP` overrides the roll and forces the shuttered pair, dark, the same shutter the
  degrading city's own storefronts use — see "The city degrades".
- **Street trees stand only on a handful of tree-lined runs, and a run is a *place*.** A run is a
  straight stretch of `Tuning.STREET_TREE_RUN_MIN_BLOCKS`–`STREET_TREE_RUN_MAX_BLOCKS` (three to
  five) consecutive blocks along one street line, horizontal or vertical, and there are
  `Tuning.STREET_TREE_RUNS` of them placed at random across the map, well under the
  `Tuning.STREET_TREE_MAX_LINED_FRACTION` (a quarter) ceiling `tests/test_blocks.gd` holds over a
  seed sweep. Every street outside every run is bare. **Rare on purpose, and the reason is the
  events rather than the look**: a tree standing beside a van or a yeller is a second silhouette
  to read past, and a street full of them is a street where an obstacle is hard to spot.
- **Inside a run, pits sit at `Tuning.STREET_TREE_PIT_SPACING` — two lot-lengths — on each kerb**,
  measured along the whole run rather than street by street, so a four-block run carries about two
  pits a side rather than two per street. `StreetTrees.planted()` is the one function that decides,
  fixed for the run like a building rather than rebuilt daily like a park's own trees, since a
  street's frontage does not change with what a block behind it currently is. A tree stands at the
  kerb-side tile of a pavement, never within a
  tile of either end of its street (which is already where every crossing and every fixed
  checkpoint mouth stands — see "What closes a street" above) and never within a tile of the
  home's own door. It is a `Prop` like a park tree, feet-anchored so she passes behind its canopy,
  and like a park tree it has no body: she walks through a street tree exactly as she walks
  through one in a park, so a pavement with trees costs the route nothing a bare one does not.
- **A tree and an event never share ground.** *(2026-09-12, the player: "events can only be placed
  where no trees are (except for the fallen tree which must empty out one tree lot)".)* The trees
  are the city's and fixed for the run while the events are the day's, so the day is what yields:
  `EventScheduler._open_ground_for` refuses any tile a standing tree occupies or its footprint
  reaches, the same way it refuses a closed street, and `SealPlanner._seal_along_tile` steps a
  seal's bodies along the street to the nearest clear cross-section. Both refuse where the
  candidate is offered rather than moving something afterwards. So a van, a café, a market stall,
  a yeller, a dog walker or a seal is never in or behind a tree, and the only thing that ever
  stands in a pit is the tree that fell out of it. The escape's own plan keeps the same rule
  through the same two functions — `EventScheduler._finale_ground` refuses a tree's ground and
  `SealPlanner.plan_finale` steps its seals off one — **with one exception the escape has and a
  day does not**: a seal stepped off a tree may land on ground one of the chains walks, and there
  it stands in the tree instead, since a picture overlapping a picture is better than the one way
  out of the city being walled. `tests/test_finale.gd` holds that exception to a small share of
  the escape's bodies rather than letting it become the ordinary case.
- **A pit the day emptied has no tree in it.** A `FALLEN_TREE` closure and a `fallen_tree_seal`
  each take one of their street's own pits — see "What closes a street" above —
  and `CityMap.is_tree_pit_emptied` is what `City.refresh_street_trees()` reads to leave that one
  prop undrawn for the day. The planting itself never changes: where a city's trees stand is a
  fact about the run, which one is lying in the road is a fact about the day, so the day's answer
  lives beside `closed_tiles` rather than inside `StreetTrees`.
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
Illustrated PNG counterparts and ground component pairings are documented in
[VISUALS.md](VISUALS.md); the runtime selects them by default with SVG fallback.
