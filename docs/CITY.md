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
- `CITY_BLOCKS` = 7 × 7 blocks by default
- Total: 104 × 104 tiles, or 3328 px square at a 32 px tile

A 1-tile sidewalk was the first attempt and had to go: the rig's collision circle is 28 px
across, so a 32 px sidewalk left 2 px of clearance and walking a street felt like threading
a needle. Two tiles of sidewalk is the number the whole layout is sized around.

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
6. **Place home** — a 2×2 notch in the south edge of a `RESIDENTIAL` block, biased toward
   the map centre so that no direction is strictly better, and slid sideways if the notch
   would land in an alley.
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
- The home is at least `MIN_HOME_TO_PARK_TILES` (30) *walking* tiles from the nearest park.
- Building rects tile the `BUILDING` tiles exactly, with no overlaps and no gaps.

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

The design wants at least two distinct routes from home to every calm area, so that a spoiled or
blocked route always has an alternative. Until M21 this held **by construction** rather than by
search: carving only ever happened *inside* blocks, so the street lattice was never cut, and a
full lattice cannot be disconnected by removing any single corridor.

**A calm zone puts holes in the lattice, so the construction argument is gone** and the property
is now checked. `StreetNetwork.route_count()` is that check and always was — M16 built it for
the day's closures — and a zone's absent streets simply join the closed set it is given.

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

### The invariant

> **At least two distinct routes to at least two distinct calm areas.**

Distinct means **sharing no street**. Two routes may cross at a junction; if they run down
the same street they are one route with a detour in it.

`ClosurePlanner` checks it *before* accepting each closure rather than repairing the day
afterwards, so the set it produces always satisfies it and there is no order-dependent
unwinding to reason about. Counting routes is a unit-capacity max flow on the junction
graph — by Menger's theorem the count is also "how many streets it would take to cut this
area off", which is the honest reading of the guarantee.

Both ends of the journey are exempt from being charged for their own doorway:

- The **home street** is never closed. The home is a notch in a block with one exit, so
  sealing that street seals the player in however well connected the rest of the city is.
  This exemption predates closures — see "Route redundancy" above.
- An area is reached by arriving at **either end** of a street it opens onto. So a courtyard
  with a single archway can still have two routes to it; the routes differ everywhere except
  the doorway. Shutting that one street does put the courtyard out of reach for the day, and
  the invariant is what keeps that safe: two *other* areas still have two ways in.

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

Closures are aimed rather than scattered. A street is *useful* if it lies on a shortest way
from the door to some calm ground give or take a block, and a useful street is
`CLOSURE_ROUTE_BIAS` times likelier to be the one that is shut — because a closure in the far
corner of the map is not a decision, it is scenery.

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
- **Density is per act.** The crowd thins as the occupation settles in: act III's streets
  are close to deserted, which makes the city *easier*. See docs/NARRATIVE.md.
- **Nobody walks through a park.** The crowd lives on the street lattice only, which is the
  structural half of "a park is quiet because nobody is in it". `tests/test_crowd.gd`
  asserts the middle of every park is out of earshot.

- **Bodies are solid, and cars are lethal.** *(M19, replacing "agents have no collision: the
  player walks through them".)* Walking into somebody displaces you both and startles them;
  stepping into the carriageway in front of a moving car ends the day; traffic gives way at a
  zebra somebody is waiting at. The old rule was right about the risk it was avoiding —
  stopping her dead in a crowd would fight the one verb the game has — and the answer is that
  a contact **deflects** rather than blocking: the separation is resolved positionally so
  nothing can ever be walked into and stuck on. See docs/MECHANICS.md, "The street has
  physics", for the geometry and the traffic fairness contract.

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
