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

A 1-tile sidewalk was the first attempt and had to go: the rig's collision circle is 28 px
across, so a 32 px sidewalk left 2 px of clearance and walking a street felt like threading
a needle. Two tiles of sidewalk is the number the whole layout is sized around.

### Three kinds of street

Every corridor is the same shape and they are not the same street. All of it is fixed for the run
and decided before a tile is laid — see `CityGenerator._assign_street_kinds`.

| Kind | How many | What it is |
| --- | --- | --- |
| `ORDINARY` | everything else | Two lanes, a zebra at every junction, and traffic that gives way to somebody standing at the kerb. |
| `MAIN` | **one**, north to south | The spine. Five times the traffic, signalled at every junction, and **it does not give way**: what stops it is the light. `CityMap.main_road`. |
| `PEDESTRIAN` | **two stretches of three blocks** | A retail precinct: paving frontage to frontage, no kerb, no cars, the busiest pavement in the city, and the best ground outside a park to bring a meter down on. `CityMap.precinct_spans`. |

**With one kind of street the only route question is *which way*; with three it is also *which
kind*, and that is the trade the whole game is made of.** A main road is quick to cross at a light,
lethal anywhere else along it, and bad ground to recover on; a precinct cannot kill you and is full
of people to walk into; an ordinary street is the middle of both.

**Two of the three are places, not classes.** The first build made a main road of each axis and a
precinct of one corridor in each, and it produced a city with three kinds of street and no
hierarchy among them: a spine that crosses itself is two spines, and a precinct you meet on every
third street is what a street is. There is one main road because there is nowhere else it could be,
and a precinct is three blocks with an end you can see — one along the southern shore, one inland.
A span covers its blocks and the junctions between them and stops short of the crossroads at either
end, which is where the bollards are.

The lattice itself does not move. Every corridor is still `sidewalk | road | sidewalk` and the
layout arithmetic is still a modulo, which is why a kind can never disconnect the city or shift a
block. **A wider main road was the obvious alternative and was rejected**: the corridor
cross-section is uniform by construction, a 1-tile pavement is the width M1 found unwalkable, and
doubling a carriageway restates the traffic fairness contract for every street at once. What the
main road gets instead is everything that is actually a route decision — the signals, the
priority, the density, the recovery rate — and a drawing that says so.

### What the ground does to the meter

Since M41 the ground is not calm-or-not; it is a rate, and choosing a route is choosing a recovery
rate. `WorldContext.decay_multiplier()` is the question and `City` answers it from the tile she is
standing on.

| Ground | × decay | Walking decay |
| --- | ---: | ---: |
| Calm (park, forest, quiet square, courtyard, playground) | 2.2 | 7.7/s |
| Precinct | 1.5 | 5.25/s |
| Ordinary street | 1.0 | 3.5/s |
| Main road | 0.6 | 2.1/s |

It is the first time since M14 that the ground under her feet has done anything except be calm or
not, and it is what makes a precinct worth walking to although it is loud. `is_calm_zone` stays a
threshold beside it, because the *sleepiness* half genuinely is one: only calm ground puts a baby
to sleep.

Tile types:

| Tile | Walkable | Effect |
| --- | --- | --- |
| `BUILDING` | no | Collision. Drawn as an extruded 2.5D box. |
| `SIDEWALK` | yes | Neutral. The default walking surface. |
| `ROAD` | yes | Neutral, but traffic events path along roads. |
| `CROSSING` | yes | Marked road tile; traffic events yield here (mostly). |
| `PARK` | yes | **Calm zone.** Sleepiness ×1.75, excitement decay ×1.6. |
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

**Every piece is kept, including one-tile slivers.** An earlier version dropped anything
narrower than two tiles because slivers look odd; the result was `BUILDING` tiles with no
building node over them — invisible walls the player walks straight through. A sliver
renders as a low wall instead, which is what a 32 px-wide building should look like. The
test asserts that the building rects cover every `BUILDING` tile exactly once.

### Guarantees

Checked by `CityGenerator.validate()` and by `tests/test_generator.gd` across 200 seeds:

- Every walkable tile is reachable from the home.
- At least **3 calm areas**, no two adjacent (so the calm is spread out). An area is one
  block or one four-block zone; see below.
- At least `MIN_CALM_ZONES` (1) of them is a **four-block zone**.
- The home is in the **middle block**, and is at least `MIN_HOME_TO_PARK_TILES` (30) *walking*
  tiles from the nearest park. Both, together — see "The home".
- Building rects tile the `BUILDING` tiles exactly, with no overlaps and no gaps.

## The home

**It is the middle block, and that is not a preference.** The two rules about the home used to
compete for the same thing — *the walk out has to be long enough to matter* — and the competition
was settled by walking the home **outward** from the centre until it was far enough from calm
ground. Measured over ten seeds on the old 7×7 lattice, it landed 1.97 blocks off centre and was
central in four of ten: *"I spawn too often at the edge, leaving only a few ways into the rest of
the city."* Half the directions out of a boundary block are a wall, and a city you can only leave
two ways is smaller than the one that was generated.

The competition is settled somewhere else now. The middle block is claimed before any purpose is
assigned, and **calm ground is kept a clearance of blocks away from it**
(`CityGenerator._too_near_the_home`) — so the distance guarantee holds where the home *is*, rather
than deciding where it goes. The clearance is derived from `MIN_HOME_TO_PARK_TILES` rather than
authored beside it: a block `d` away starts `d × period()` tiles out, of which `BLOCK_SIZE` is the
home's own lot, so the clearance is the smallest `d` clearing the guarantee. It is a floor, not the
guarantee — walking is not straight-line — and `validate()` still checks the real thing.

**That is what the size is for.** At 7×7 the two rules cannot both hold: the centre of a 7×7 city is
rarely 30 tiles of walking from every park. Measured over ten seeds:

| | 7×7, home biased to centre | 9×9, home in the middle |
| --- | ---: | ---: |
| Offset from centre | 1.97 blocks | **0.00** |
| Central in | 4/10 seeds | **10/10** |
| Home → nearest calm | 32.0 tiles | 39.4 |
| Guarantee satisfied | 9/10 | **10/10** |
| Calm areas lie in | 2.9 of 4 directions | **3.7 of 4** |
| Directions with two blocks of city behind them | 3.4 of 4 | **4.0 of 4** |

**One consequence is a difficulty change hiding inside a layout change, and it is not measured yet.**
The crowd is a *field* of fixed population in a fixed-size box around the player, and
`CrowdField.corridor_range` clamps that box to the city — so near the boundary the box hung over the
wall and the same agents were spread across fewer streets. A doorstep in the middle has the full set
of corridors in range, so the same population covers more of them. Day 1 at the front door should
therefore be *thinner* per street than it was, which is the opposite direction from the open crowd
difficulty question. It wants the crowd milestone's own measurements — contacts in a forty-second
walk down a lane centre against the midline, and the mean wait at an arterial kerb — not an
assumption.

## Calm zones

*(M21.)* A calm **area** is one place to go, and it is either a single block or a **four-block
zone**: 2×2 blocks with the streets between them absorbed, painted as one unbroken piece of
ground 22 tiles square. Every city has one or two of them.

The reason is playtest 03, finding 2, asked for again by playtests 04 and 05: the traced player
spent **twenty seconds walking in a circle** inside a courtyard. That is not a bug and it is not
a balance problem — it is exactly what the rules ask for. Standing still *drains* sleepiness, so
progress requires motion; a calm block is eight tiles across; and progress-requires-motion plus
small-calm-area is jointly sufficient for a lap. M18's shorter day cut the number of laps and
could not remove the lap, and no further balance pass will.

The numbers, and `tests/test_generator.gd` asserts them as a relationship rather than as
values:

| | one block | four-block zone |
| --- | --- | --- |
| ground | 8×8 tiles, 256 px | 22×22 tiles, 704 px |
| corner to corner at `WALK_SPEED` | 3.9 s | 10.8 s |
| a full meter of calm | 23.8 s | 23.8 s |

So a stretch of calm in a zone is two or three traverses of somewhere with sides to it, and a
stretch in a block is six laps of a lawn. It is deliberately *not* a whole meter in one crossing
— arriving must not be the whole of it.

The rest of the calm stays single-block on purpose. Which calm area to head for is a real
question only when they are different from each other: a small quiet square two streets away
against a big park across the city is the decision M24 made matter, and a city of nothing but
zones would flatten it again.

### What a zone does to the lattice

This is the part that costs something. A zone absorbs the two horizontal streets between its
rows and the two vertical ones between its columns, so:

- The **junction in the middle of the zone is gone** — nothing reaches it.
- The four junctions on the zone's edges become **T-junctions**. The lattice is no longer a
  full grid and can no longer be derived from a coordinate, which is what M21 was always
  going to be.
- **Route redundancy stops being true by construction** and has to be checked by search. See
  below.

Two rules keep a zone from taking something the city cannot spare:

- **Never the arterial.** A zone may absorb any corridor but the main road, which is the noise
  floor, the thing that has to be crossed, and the street a player learns first.
- **Never beside other calm**, the same rule a single calm block obeys, stated over the whole
  2×2 footprint.

The streets it absorbed live in `CityMap.absent_segments`, and `CityMap.blocked_segments()` adds
them to whatever a day has closed. Every route search takes that set, so the graph half of
`StreetNetwork` — route counting, the invariant, the doorway exemptions — needed no change at
all: a street that is not there is a street that is permanently shut, as far as a search is
concerned. What is *not* true of a closure is true here and matters: **the ground is calm and
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

The design **wanted** at least two distinct routes from home to every calm area, so that a spoiled
or blocked route always has an alternative. Until M21 this held **by construction** rather than by
search: carving only ever happened *inside* blocks, so the street lattice was never cut, and a
full lattice cannot be disconnected by removing any single corridor.

**A calm zone puts holes in the lattice, so the construction argument is gone** and the property
is now checked. `StreetNetwork.route_count()` is that check and always was — M16 built it for
the day's closures — and a zone's absent streets simply join the closed set it is given.

**And since 2026-08-31 what is checked is weaker, on purpose.** *"The two routes guarantee is not
a hard rule"* — the second route is an **offer** (see "How the corridor is built", and
`RouteTree`, which manages it for 241 areas of 241 the map allows one to) rather than something
placement is gated on. Three things hold instead, and each is stated where its decision is taken:

| | |
|---|---|
| the generator | every calm area stays **reachable**, whatever hard blockers took |
| the day | at least `MIN_CALM_AREAS_REACHABLE` calm areas are still reachable after the closures |
| the city | **no single street cuts off all the calm** — the winnability sentence edge-disjointness was standing in for, now asserted directly |

The count of *areas* deliberately did not move with it: two, because one of them may be the one
the day has just spoiled.

`tests/test_generator.gd` checks it directly by closing each street segment in turn and
confirming a park is still reachable — with one exemption. **The street outside the home is
a genuine single point of failure**: the home is a notch in a block with one exit, so
sealing that segment seals the player in, however well connected the rest of the city is.
That is a constraint on where Act IV may place a barricade, not a flaw in the layout.

## Spoiling calm zones

A park that is always safe would collapse the game into one memorised loop. So each day,
the scheduler may **spoil** calm zones:

- Each park has a per-day chance (`PARK_SPOIL_CHANCE`, default `0.35`) of hosting a
  spoiling event: a dog meet-up, a busker, a school outing, later a checkpoint or a rally.
- A spoiled park keeps its calm-zone multipliers *outside* the event's radius — so a big
  park can still be partially usable. Small parks get wiped out entirely.
- **At most `MAX_SPOILED_PARKS` (default: all but one) parks are spoiled on a given day.**
  There is always at least one usable calm zone. The player just has to find out which.

## Road closures

*Playtest 01, finding 12, implemented in M16.* Every morning a few streets are shut. This is
the one thing in the game that changes **where the player may walk** from one day to the
next — block purposes change what a place is *worth* walking to and never move a walkable
tile, and that difference is the whole design.

### The unit is a street, not a tile

The lattice is a graph: 8x8 **junctions** and the 112 **streets** between them, one block
long and one corridor wide. `StreetNetwork` owns that view of the city, and a closure takes
out one whole street.

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
are standing next to it. That is M17's route map, and the sequencing is deliberate.

### Guiding her to the calm — what the game actually does

*(Written down in playtest 14, because it had never been stated anywhere and the answer to "how
does the game guide the player to a calm zone" turned out to be that it does not.)*

**Everything the city does about calm areas is a floor under winnability. None of it is
guidance.** Set out in full, because the difference between the two is the whole of the open
question below:

**At generation, once per run — where they are:**

| | |
|---|---|
| how many | 5–7 areas, derived as an act's worth of days **plus one** |
| how far | at least `MIN_HOME_TO_PARK_TILES` (30) of **walking** distance from home — the calm is earned |
| how spread | no two calm areas anywhere in each other's eight-block ring, corners included |
| where not | never at the map edge, never beside the spine *(M47)* |
| what shape | mostly single-block, with one or two four-block zones |

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

**And here is the gap.** *(Playtest 14: "I still don't feel the game guiding me to calm zones via
obstacles.")*

- ~~**Closures are chosen at random** from a shuffled list of legal candidates. Nothing chooses
  them to *point* anywhere.~~ *(Closed by M50 step 2.)* A closure is a **wall** now: never on the
  day's corridor, preferentially on a turning off it. See "Where a closure goes" below. What has
  not been answered is whether that **reads** as guidance to a person — the picture says the walls
  are where they should be, and nobody has walked past one.
- **There is no cue of any kind toward calm.** No marker, no map, no HUD line, nothing on the
  ground. "Planning-time legibility" is named a paragraph above as not existing.
- **The main road as a soft block** — the one thing in the design that would divide the city into
  a near half and a far half — is planned in M47 and not built.
- **Blockers are not placed to guide anybody**, which is the whole of it. The design is below.

### Diversions — the design *(given by the player, 2026-08-31)*

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
never *held* on one side and never steered at the road: *"it's not a hard rule that she doesn't go
over the main road until it's the only option — I was predicting player behaviour, but players can
cross whenever they want."*

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

### Hard blockers *(M50 step 1)*

*"Cul-de-sacs and big buildings don't exist yet — but we need them to implement proper hard
blockers."* Both exist now. A **dead end** is one street with one end built over; a **big
building** is two neighbouring blocks joined into one mass with the street between them built over.
They share a placement pass, a reference tree and a gate, and each takes exactly one street out of
the lattice — what differs is the size of the thing left standing there.

A dead end is **one street, gone from the lattice, with one end built over**. Four to eight of
them per city, rolled from the city RNG, so they hold still for the whole run and are what the
player learns while the closures re-cut the map every morning.

**The ground stops, and that is the whole difference from a zone's absorbed street.** M21's rule
is that an absorbed corridor is *calm ground rather than a closure* — the tiles are park and she
walks over them, which is exactly right for a shortcut and exactly wrong for a hard blocker.
`CityMap.dead_ends` is kept separate from `absent_segments` for that reason: the two are absent
for opposite reasons, and anything reasoning about **why** a street is missing has to tell them
apart. Anything asking *can a route go this way* wants `blocked_segments()`, which is both and
does not care.

**They are placed against a tree rather than before one.** *"First construct an example tree from
the initial map, then place the hard blockers — that way we can't block off regions entirely."*
`RouteTree.for_the_run` is that example, and it is a **witness**: it reaches every calm area the
run will ever use, so a blocker that takes no street off it cannot have made any of them
unreachable. Candidates therefore exclude the tree rather than the reachability gate merely
rejecting them afterwards — and day 1's calm is all the calm there will ever be, because an arc
only ever takes calm ground away.

Four kinds of street may not be a dead end, and the last was found by building it:

- **The street outside the front door.** The oldest exemption in the project.
- **The main road.** There is one of it and a spine with a hole in it is not a spine.
- **A precinct**, which is a place rather than a road.
- **Anything running alongside calm ground.** A dead end is a claim about where you can get to,
  and the claim is made on the *lattice* while the player walks on *tiles* — so a street with a
  park down one side is a street you walk into and step sideways out of, whatever the graph says.
  It is M21's rule read backwards: calm ground beside a dead end makes the dead end a doorway.

**A big building joins two blocks, and it is a landmark.** One or two per city: two neighbouring
blocks and the street between them, built as a single mass twenty-two tiles long and tall enough to
be the tallest thing in the district. **Every other street around the pair stays**, and so does
every junction — a car still turns at all of them — so what is gone is one road and not the grid
around it. It is a `BlockPurpose` with an empty `BlockLayout` on each block, which is what keeps it
solid for the whole run: a repaint finds nothing to paint back. It obeys the same four exclusions
plus two of its own — interior blocks only, since the edge of the world is a ring of frontages
rather than somewhere to put a wall, and single-block lots only, since a four-block zone is already
a lot.

*"A big building just connects two blocks… we can add a building type with all four roads closed
but that's a different building type. But I want one that just connects two blocks (closes one
road)."* **(2026-08-31.)** The first version took the whole ring, which made every landmark an
island in the lattice: four streets removed by one roll of the dice, where what was asked for
removes one. The four-sided kind is a separate type, recorded in `docs/TODO.md` and not built —
what makes it separate is not its size but what it does to the graph, and that is the question it
would have to answer for itself.

`--spawn landmark` stands the player on the pavement off the long side of one, which is where the
seam would show if the two blocks were still two buildings. It exists because they shipped with a
picture of the *grid* and no picture of the *city*: the whole claim of a landmark is about how it
reads from the street.

**The gate is reachability: every calm area the run will ever use can still be walked to.**

M50 built it as the strong gate — two distinct routes to every area — deliberately, because
weakening a winnability guarantee as a *side effect* of adding dead ends would have been an
overturn nobody chose. It was moved on purpose on 2026-08-31, when the player pointed out the
two-routes guarantee had never been a hard rule. Measured either way it costs almost nothing:
with candidates already off the reference tree, **99% of them pass either gate**, and a city gets
5.9 dead ends against a rolled 4–8.

What makes reachability the *right* gate here rather than merely an allowed one is that
cul-de-sacs are the point. Every dead end takes one of some area's ways in, so a two-routes rule
refuses exactly the interesting candidates — and *"sealing off a section of the map is allowed,
and it is the point."* What a hard blocker may never do is make calm unreachable, because it
holds for the whole run: a day can be bad, a run cannot be dead.

### The words for it

**Adopted 2026-08-31.** *("Like the terminology, let's adopt it consistently.")* These are the
words the rest of the project uses for this — in docs, in identifiers and in the telemetry map's
legend. Three independent questions get asked about every blocker, and the project used to answer
all three with the word "blocker".

**Permanence — hard or soft.** Settled above: in the layout for the whole run, or placed for a day.

**Effect — what it does to a route that meets it.** Three values, and *lethal* is not the top of a
scale, it is a different thing:

| | | |
|---|---|---|
| **lethal** | ends the day | charging dog, robber, the carriageway |
| **impassable** | stops passage, does not kill | road closures |
| **costly** | passable at a price she can read before committing | restaurant, dog walker, yeller |

**Role — what the scheduler is placing it *for*.** `GameEnums.BlockerRole` since M50 step 2, and
it is recorded on the thing that was placed rather than derived from it: the same `cyclist` row is
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

The three are stated relative to the corridor and none of them means anything without one, which
is why they arrived in the same milestone as `RouteTree`. `Corridor` is the one translation from
the tree's segment keys to the tile a placement actually happens on — *inside*, *rim* or *away* —
so an event, a closure and the telemetry picture all mean the same thing by the words.

And the thing the roles are stated relative to needs a name too: **the corridor** — the ground
today's routes run through, from the doorstep to the calm areas that are still worth reaching.
"Wall" and "friction" mean nothing until there is a corridor to be outside or inside of.

### How the corridor is built *(answered by the player, 2026-08-31)*

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
wrong**, and a first draft of this section said exactly that.

**A calm area is reached two distinct ways where the map allows it**, and one will often be longer
than the other. That asymmetry is **incidental** — *"if it happens it happens, if not it doesn't"* —
so nothing should be tuned to produce it and no rule should depend on it. A draft of this section
called it "what makes the pair a choice rather than a mirror", which was reading a design goal into
an artefact of how the two routes are found.

**And it is a niceness, not a promise.** *"Having two distinct paths is really a niceness to the
user. If we cannot construct a path B at all, let's not try."* An area with one way in is a
legitimate area; the second route is an offer the day makes when the ground allows one. What must
still hold absolutely is only that **some** calm is reachable. See `docs/TODO.md`, M50, for the
construction and for the one thing this trades away.

**Placement follows the tree, not a budget.** Plan the tree first and place from it — possibly with
a budget *per role and per region*, but not a single per-block number that the whole city competes
for. And the important half: **budget is not spent on what she never sees.** So the day places
**placeholders**, and a placeholder is resolved into a concrete row when she actually reaches it.

**Which means the one-shots must bind late.** *"This has to influence the design of one-off events
so they actually happen on the route the player chose and in front of the player instead of
somewhere else in the city — e.g. fire truck, which alley contains the note."* An authored one-shot
is not a place the day picks at dawn; it is a promise the day makes and the route redeems.

### A set piece has to be met

*"The fire + fire truck — it should be used in a way that the player actually encounters it on
their chosen route, so we could dynamically choose it from a candidate set on that day."*

The fire engine is the only one-shot in act I and it is currently placed like everything else: a
legal spot somewhere on the map, on a day she may never walk that way. An authored set piece that
fires once per run and is missed is a fairness contract and a silhouette spent on nothing.

So a **set piece is sited against the tree**, and the shape is the player's: *"we can have multiple
candidate places and make sure all routes touch at least one of them."* The day picks a **set** of
candidate sites such that **every corridor passes at least one**, and the one she reaches is the
one that fires. That is better than choosing a site on her chosen route, because it needs no
knowledge of what she chose — the guarantee is structural, and it holds whichever way she goes.

It may not be *steered onto her*: `AHEAD_OF_PLAYER` is for moments, and a fire engine is
deliberately a **place**. What makes it a place and still unmissable is the candidate set, not a
director.

**"All routes" is load-bearing and means routes, not destinations.** *(Measured in M50, when
`RouteTree.covering_sites` was built.)* A covering set that counts an area as met when **either**
of its two ways in is met comes back as a **single** street on nine planned days out of 32 — the
one they all share on the way out. Placed there, the set piece is met by a player who takes the
first way out of everywhere and missed by one who takes the second, which is the "tile she must
cross" mistake with a covering set drawn round it. Covering every route costs nothing extra and
cannot go wrong that way: the two routes to one area share no street by construction, so no single
site can cover both, and *"at least two places"* is arithmetic rather than a rule anybody enforces.
It comes out at two to six sites against about fifteen routes.

**Two invariants this runs into, and both turned out smaller than a first pass claimed.**

- **Chokepoints and edge-disjointness barely conflict at all.** A first draft read a chokepoint as
  a single tile every route crosses, which *would* have broken `ClosurePlanner`'s two-routes rule.
  It is a bundle, and the design keeps at least two distinct paths standing by construction — which
  is the same thing the invariant is protecting. What may still need loosening is its
  **formulation**: *distinct* currently means **sharing no street**, and corridors that run together
  and then separate share plenty. The guarantee to keep is *"the calm is reachable and no single
  closure decides the day"*; the edge-disjoint max-flow reading is one way to get it and is
  stricter than the design needs. A decision, but a small one.
- **A retried day discards what happened in the failed one.** *"Retrying a day doesn't retain any
  decisions made on that day — the failed day doesn't exist anymore."* So late binding costs
  nothing: the **plan** is identical on every attempt — the same tree, the same placeholders, the
  same candidate sets, all deterministic from the seed and the day number, which is what M39
  fixed — and the **resolutions** she caused by walking are thrown away and made again. Determinism
  is a property of the offer, never of what she did with it. The thing that would still be a bug is
  a placeholder resolving off a stream shared with the rest of the day, because then *where she
  walked* would move everything planned after it.

**Nothing in the current invariants forbids any of this**, which is worth stating because a session
once thought otherwise. `_park_is_reachable` asks only that **some** calm area is still reachable
from home, not that the city stays connected, so a sealed quarter is already legal.
`ClosurePlanner`'s two-distinct-routes rule is likewise about reaching calm rather than about
global connectivity. What is missing is not permission — it is that **closures are drawn at random
from the legal candidates and events are placed by budget and weight, so neither has ever been
asked where the player is trying to go.**

So the honest summary: **the city permits routes to calm and protects them from becoming
impossible. It never suggests one.**

### The invariant

> **At least two distinct calm areas can still be walked to.**

`ClosurePlanner` checks it *before* accepting each closure rather than repairing the day
afterwards, so the set it produces always satisfies it and there is no order-dependent
unwinding to reason about. Counting routes is a unit-capacity max flow on the junction graph,
asked for one path.

**It read *"at least two distinct routes to at least two distinct calm areas"* from M16 to
2026-08-31**, where distinct meant sharing no street. *"The two routes guarantee is not a hard
rule."* Edge-disjointness was a **stand-in** for winnability — by Menger, two routes means no
single street is a cut — and the sentence it stood in for is now asserted directly and about the
city rather than about each area: **no one street cuts off all the calm**
(`tests/test_routes.gd`). The second route to any given area is an offer the day makes when the
map allows one.

What did **not** move is the count of areas. Two, because one of them may be the one the day has
spoiled this morning; one reachable area is the unwinnable day this invariant has existed to
prevent, and going there would be a separate decision.

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

`CLOSURES_PER_ACT` is `[1, 2, 3, 4]` — four streets out of 112 on the worst day. That is a
city that has had a bad morning, not a city under siege, and it is deliberately light: M16
was drafted as though closures would be the only thing making a route interesting, and
playtest 02's findings 2 and 3 put route pressure at the scale of a *block* instead.

### Where a closure goes — a wall, off the corridor *(M50 step 2)*

**A closure is never placed on the day's corridor**, and preferentially lands on a turning off it
(`CLOSURE_WALL_BIAS`). That is the flip: *"a road block becomes guidance and is not a hindrance.
It flips its role."*

It is worth setting the two side by side, because the numbers are identical and the meaning is
opposite. Until M50 a street was *useful* if it lay on a shortest way from the door to some calm
ground give or take a block, and a useful street was `CLOSURE_ROUTE_BIAS` = 5 times likelier to be
shut — because a closure was an **obstacle**, and an obstacle nobody meets is scenery. A closure is
now a **wall**: it prunes the ways that lead nowhere she should go so that the ways that remain are
obvious, and putting one across her route is the defect rather than the point. The bias survived
the inversion at the same strength; what it is measured against turned upside down.

Two consequences, and the first is what makes the rest of the day's placement possible at all:

- **The corridor is still walkable once the barriers are up.** `City.start_day` grows the tree,
  `ClosurePlanner` excludes every street on it, and the events are then placed against that same
  tree. Nothing has to re-derive a corridor after the closures, and no closure can cut one.
- **The invariant became the second opinion rather than the guard.** A wall off the tree cannot
  cut the tree, so `_invariant_holds` should never refuse a candidate. It is still checked on every
  one — two independent mechanisms is the point — and a refusal now writes a `plan` line saying the
  wall and the corridor disagree about where she is going. `tests/test_routes.gd` asserts it never
  happens, over every off-corridor street of every day of four seeds.

The old bias's own reason survives too, and it is what the rim is for: a closure in the far corner
of the map is not a decision, it is scenery. A closure at the mouth of a turning is read from the
junction, which is where the wrong way is still a choice — the same reason `RoadClosure` seals both
mouths rather than putting one sign half way down a street.

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
| `RESIDENTIAL` `COMMERCIAL` `INDUSTRIAL` `CIVIC` | no | Built over, as before. |
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

### What this replaces, and what is still absolute

This supersedes the old "the `CityMap` is immutable for the run" rule. The replacement:

> The street lattice, the block boundaries, the carves and the building footprints are fixed
> for the run. What a block *is* may change, and only ever along the arc the generator
> planned for it.

The half that is still absolute is that **no purpose change may move a walkable tile**.
`tests/test_blocks.gd` pushes every block to the end of its arc across two dozen seeds and
asserts the walkable set is identical tile for tile. Nothing here can seal a street, open a
shortcut or invalidate a route the player learned on day 1. Per-day **closures** are the
one deliberate exception, and they are per-day, sealed at both ends and validated against
the route invariant before they are accepted — see "Road closures" above.

`CityGenerator.validate()` also guarantees that at least `MIN_CALM_BLOCKS_AT_END` blocks
stay calm for the whole run. Since M14 a day can only be won on calm ground, so an arc set
that requisitions everything makes an unwinnable run rather than a hard one.

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
- **The road has a capacity now.** Junction control gave it one; before that two cars on crossing
  arms drove through each other and throughput was unbounded. The same forty-six cars put the
  arterial's noise floor above the ceiling `tests/test_crowd.gd` states, because a car waiting at a
  light beside you is louder for longer than one going past. Thirty restores the floor to what the
  same street measured before any of it.
- **Density is per act.** The crowd thins as the occupation settles in: act III's streets
  are close to deserted, which makes the city *easier*. See docs/NARRATIVE.md.
- **Nobody walks through a park.** The crowd lives on the street lattice only, which is the
  structural half of "a park is quiet because nobody is in it". `tests/test_crowd.gd`
  asserts the middle of every park is out of earshot.

- **And nobody walks into a cul-de-sac's wall.** *(M51, playtest 15 finding 1: "cars and people
  go through cul-de-sacs".)* The crowd is the one thing that travels the lattice without asking
  `blocked_segments()`, and it does not need to — a dead end is a street with its far end built
  over, so the *tiles* say so. What it needed was to **look** at them. Avoidance was a single
  probe fired seven tiles ahead, which answers *is there something coming up* and looks straight
  past a two-tile wall into the open road behind it: an agent entering the street from the
  junction beside the wall never saw it. It walks the tiles now, cached per tile — which is both
  correct and *cheaper* than the probe, because an agent covers a tile in about twenty frames.
  Measured at a dead end before the fix: **eight agents inside a wall at once, and something in
  one on 87% of frames**; zero after, and `tests/test_crowd.gd` stands the field at a dead end so
  it can see it at all.

- **Bodies are solid, and cars are lethal.** *(M19, replacing "agents have no collision: the
  player walks through them".)* Walking into somebody displaces you both and startles them;
  stepping into the carriageway in front of a moving car ends the day; traffic gives way at a
  zebra somebody is waiting at. The old rule was right about the risk it was avoiding —
  stopping her dead in a crowd would fight the one verb the game has — and the answer is that
  a contact **deflects** rather than blocking: the separation is resolved positionally so
  nothing can ever be walked into and stuck on. See docs/MECHANICS.md, "The street has
  physics", for the geometry and the traffic fairness contract.

## Traffic signals

Every junction the spine passes through is signalled, and no other one is — nineteen of a hundred.
`TrafficSignals` owns the phase; `City` owns the object and the heads that show it; `Crowd`
advances the clock, because that is what a rig steps.

**A signal is a timing problem where a zebra is a gap-hunting one.** An ordinary crossing is a
negotiation with a driver who can see you and gets better the longer you look; a signalled one is
a wait with a known end. Having both is what makes *which street* worth asking about.

- **The cycle is derived, not authored.** It is `2 × SIGNAL_PROGRESSION_BLOCKS` junction-to-junction
  travelling times. Without a progression, two thirds of the traffic stands still — measured.
- **The wave runs one way, and until M46 this said two.** A car going with it holds its phase at
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

A lane is a queue and a junction is a **box**. Until M41 only the queue was modelled: two cars on
crossing arms each read a clear lane ahead, both entered, and the positional resolve then did the
only thing it can — move a body. Measured over ninety seconds of the arterial: **3,776 overlapping
crossing-axis pairs, one in half of all frames, the deepest 39 px into a 40 px footprint.** Every
assertion about the traffic passed the whole time, because each car's own lane was legal.

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

The lattice already ended in T-junctions and nobody could see it. The outermost corridor on each
side is a whole street, and every interior street runs into it and stops — which is what a T is —
but there was nothing beyond its far pavement, so the boundary read as a road with a void along
one side and the map stopped at an invisible wall.

- **The border is the land, and each side says why the city ends.** South a bulkhead and then open
  water, no buildings; east and west a fence, then grass going into forest; north scree and then
  mountainside. Built to the player's brief in playtest 14, and it replaced M41's ring of
  frontages rather than dressing it. `City._paint_outside_the_map` is the whole of it — ground
  rather than objects, outside the map, where no tile, route or event can reach.
- **The camera may see past the boundary.** It was clamped to the last walkable tile, which is why
  the edge would have gone on looking like a wall however much was built out there.
- **The spine leaves by a tunnel north and a bridge south.** *"That way it's not an artificial end
  but an emergent end."* They are lethal for the reason every stretch of carriageway is lethal;
  nothing new was needed for the danger.
- **There is no east or west exit, and there is no east-west main road.** Both existed in M41 and
  both are gone. *"East/west is a hard no. There is only one main road and it is from north to
  south."* A carriageway running out into a wood was a road to nowhere, and the corridor it ran on
  is an arterial in no other part of the game.

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
  street. (It does *not* keep every extrusion off the player: the mass is inside the lot and
  still north of the origin y-sort compares, which is the bug above.) A taller building therefore shows more wall and less roof, which is what an
  oblique view of a taller building should look like.
- **Building heights are whole tiles.** They used to be continuous floats, which a tiled
  facade cannot honour without stretching a tile. Quantising also makes the "a roof always
  shows" rule exact instead of approximate: the wall takes at most `floor(depth * 0.55)`
  rows and never the last one. A one-tile sliver is the single exception — it is all wall,
  capped by a parapet, because a roof there would have to overhang the lot behind it.
- Buildings are assembled from 32px tiles: a wall fill, a roof fill, edge overlays and
  windows. The fills are authored near-white and multiplied by the variant's colour, so the
  six roof colours still cost one asset each rather than six. Edges are overlays drawn on
  top, which is why a corner needs no dedicated corner tile — it takes two edge overlays
  and the parapet turns.
- Everything is `y_sort_enabled`, so the player passes behind and in front of props
  correctly — with one deliberate exception. **Buildings are a layer of their own, beneath the
  entities, and sort against nothing but each other.** *(M37, playtest 07 finding 4: "the warning
  indicators render below roofs".)* A building's origin is the south edge of its lot and its mass
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
  what is in the way. **M34 turned that round and made it a rule for the whole catalogue**: an
  event that stands still is *solid at the width it is drawn*, which is the same statement read
  from the other end. See `docs/EVENTS.md`, "Solid things are solid".

Art lives in `assets/` as hand-editable SVG — ground tiles under `assets/tiles/`, building
tiles under `assets/buildings/`, the player under `assets/rig/`, scenery under
`assets/props/`, event bodies under `assets/events/` — with a per-act palette multiplied
over the whole canvas. `Palette` holds only the colours the code still chooses at runtime;
a tree's green lives in the file that draws the tree.
