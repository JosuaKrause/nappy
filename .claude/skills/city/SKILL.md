---
name: city
description: Rules for the city — the lattice and what may change about it, tile types, block purposes, closures, the street hierarchy, and the guarantees that keep every day winnable. Load this BEFORE touching src/city/, CityMap, CityGenerator, StreetNetwork, ClosurePlanner, RouteTree, or anything about streets, blocks, calm areas or road closures.
---

# The city

## The lattice is fixed; what a block *is* is not

The street lattice, the block boundaries, the carves and the building footprints are all fixed for
the run. What may change is a block's **purpose** — a park can be requisitioned, a commercial street
can go dark, a residential block can burn — and only ever along the arc `CityGenerator` planned for
it up front. **The geometry the player learns stays true; the meaning of it does not.**

**No purpose change may move a walkable tile.** `tests/test_blocks.gd` pushes every block to the end
of its arc across 40 seeds and asserts the walkable set is identical tile for tile. Per-day
*closures* remain events with an `obstructs_radius`, not tile edits.

## The lattice is not a full grid

A four-block calm zone absorbs the streets between its own blocks, so the city has one or two holes
in it, four T-junctions per hole, and a junction in the middle of each zone that nothing reaches.
Three consequences:

- **Route redundancy is not true by construction.** A full lattice cannot be disconnected by
  removing one corridor; this one can. It is checked by search — `StreetNetwork.route_count()`.
- **The absent streets are a set, not a hole in the enumeration.** `StreetNetwork` still enumerates
  the full grid; `CityMap.absent_segments` says which of them this city does not have, and
  `CityMap.blocked_segments()` merges it with today's closures. **Every route search takes that
  merged set** — one that takes only the closures will happily route down the middle of a park and
  overstate the redundancy.
- **A block is not the unit; a lot is.** `block_plans`, `block_layouts` and `calm_blocks` are keyed
  by the block that *anchors* a lot, so a zone is one entry with four blocks of ground. Anything
  counting calm areas counts a zone once. `CityMap.anchor_of()` and `lot_rect()` reach the other
  three blocks.

**An absorbed street is calm ground, not a closure.** The tiles are park and the player walks over
them — a zone is a shortcut as well as a destination. Only the *lattice* lost the street, which is
why `absent_segments` is a set of segment keys and `closed_tiles` is a set of tiles. **Anything that
travels the lattice asks `CityMap.is_street()`, not `is_walkable()`.**

## Every day stays winnable, and always has somewhere else to go

The scheduler guarantees one unspoiled park and a walkable route from home to a park. On top of
that, `ClosurePlanner` keeps **at least two distinct calm areas reachable**
(`Tuning.MIN_CALM_AREAS_REACHABLE`), checked **before accepting each closure** rather than repairing
the day afterwards, so a bad set never exists even briefly. Anything new that closes a street must
go through it — `tests/test_routes.gd` fails the build if it does not.

**Two areas is the count; reachability is the strength.** Two *areas* is what stops a day arriving
where the only calm left is the one this morning spoiled; dropping to one reachable area is an
unwinnable day. **No one street cuts off all the calm** is the guarantee's own statement — by
Menger, two routes to different areas means no single street is a cut — and `tests/test_routes.gd`
asserts that sentence directly, about the city rather than about each area.

Two exemptions, and they are the same exemption at both ends of the journey: **a doorway is not a
route.** The street outside the home is never closed (the home is a notch with one exit), and an
area is reached by arriving at *either end* of a street it opens onto, so a courtyard with one
archway is still reachable two ways.

**Counting distinct routes is a max flow, not a search for routes.** Two BFS augmentations on a
64-node graph, not a flood fill over ten thousand tiles — which is why it can run on every candidate
closure, every day.

## Check before accepting; never repair afterwards

**Closures are checked before they are accepted.** The obvious shape — place N closures, then drop
them until the day is legal — has an order-dependent answer and a window where the day is illegal.
Testing each candidate against the invariant before accepting it is the same cost and has neither
problem.

**The same rule applies to events.** Refusing the ground (`EventScheduler._calm_to_leave_alone`)
keeps every unvisited calm area clean and *raises* the density, because a repair spends the budget
twice. **If you find yourself writing a pass that deletes what a previous pass placed, this is the
rule you are about to rediscover.**

## The words for placement

The full table is `docs/CITY.md`, "The words for it". Three axes, not one:

- **Permanence** — `hard` (pruned into the layout, whole run) or `soft` (placed for one day).
- **Effect** — `lethal` (ends the day), `impassable` (stops passage, does not kill), or `costly`
  (passable at a readable price).
- **Role** — what the scheduler placed it *for*: `wall` (bounds the corridor), `friction` (sits
  inside it), or `set piece` (placed so she meets it).

The **corridor** is the ground a day's routes run through. **Do not reintroduce the bare word
"blocker"** for any of these: three questions answered by one word is why this design had to be
restated three times.

## A closure is silent

Closures change the shape of the route and contribute nothing to the meter — the noise of a street
is the crowd, the danger is the events, the shape is the closures. A noisy roadworks already exists
as the `construction` event. **Do not let a closure emit**; it would be a third thing for
`City.total_excitement_at` to sum, and that list is exactly two long on purpose.

This is **consistent** with the diversion design in `docs/CITY.md`, "Guiding her to the calm". A
road closure there is *"not lethal but prevents full access"* — an absolute stop that does not kill
and does not shout. The things that guide by being **expensive** are ordinary catalogue events, and
they already emit. What diversions ask is that closures and events be **placed to point somewhere**,
which is a scheduler decision and not a change to what a closure is.

## The street hierarchy

`CityGenerator._assign_street_kinds` decides *where* (`CityMap.main_road`,
`CityMap.precinct_spans`); `Tuning.PRECINCT_BLOCKS`, `PRECINCT_BUSYNESS`, `EVENT_PRECINCT_WEIGHT`
and the `EXCITEMENT_DECAY_*_MULTIPLIER` trio decide *what it means*.

**Five places have to agree and the failure mode of each is silent:**

- `GroundTiles` — what it looks like
- `CrowdLanes.busyness_for` + `walkable_offsets` — who walks and drives there
- `City.decay_multiplier` — what the ground does to the meter
- `TrafficSignals.is_signalled` — whether its junctions have lights

**The trap is scale. There is one main road and there are two precincts, and that is the design
rather than a parameter.** One of each per *axis* is three kinds of street and no hierarchy among
them: a spine that crosses itself is two spines, and a precinct you meet on every third street is
what a street is. **If a kind starts appearing in every third corridor, it has stopped being a
place.**

**Which corridor is the main road is a fact about a city, so read it off the map.** Computing it as
`index == arterial_index(blocks)` per axis makes a phantom arterial on the other axis, weighted like
the real one but with no lights, no dark asphalt and no clearway.

## The ground is a rate, not a category

Calm 2.2, precinct 1.5, ordinary street 1.0, main road 0.6, multiplying the excitement decay — so
choosing a route is choosing a **recovery rate** and not only a set of things to walk past. It is
what makes a precinct worth walking to although it is loud, and most of what *"a main road is
crossed, not walked"* means arithmetically.

## Adding things

**Add a tile type** — `GameEnums.TileType`, then `src/city/tile.gd` (walkable / calm / alley / road
/ colour), then an SVG in `assets/tiles/`, then `assets/ground_tileset.tres` **and**
`src/city/ground_tiles.gd` in the same order (the source ids are positional and mirrored by hand),
then wherever the generator should emit it.

**Add a block purpose** — `GameEnums.BlockPurpose`, the ground it puts down in
`CityMap.open_tile_for`, `Tile.is_calm` if it is calm ground, and the arcs that may reach it in
`CityGenerator._plan_arcs`. If it is calm, check `MIN_CALM_BLOCKS_AT_END` still holds — `validate()`
will tell you, on every seed, if it does not. **Write it against `map.lot_rect(block)` rather than
`CityMap.block_rect(block)`**, or it will be a quarter of the ground on a four-block calm zone and
nobody will notice on the lots that are one block.

**Add a closure kind** — `RoadClosure.Kind`, a row in `RoadClosure.KINDS` (name, first day, weight),
an SVG in `assets/closures/`, and a line in `ClosureMarker.CAUSES` — unless it has nothing to leave
in the road, like `CORDON`, in which case the barriers are the whole of it. Nothing else: the kinds
differ in look and timing only, because a street you cannot walk down is a street you cannot walk
down.

## Performance notes that are really correctness notes

**A `Dictionary` keyed by `Vector2i` hashes a Variant on every lookup.** Fine for a set of today's
closures; not fine for a flood fill, where it costs about 3.6× a flat `PackedInt32Array` indexed by
tile. Two things that come with it: **paint the blocked set into the grid before the sweep** rather
than asking about it per neighbour, since building a `Vector2i` four times per tile is most of what
is left; and **write the four neighbour steps out** rather than looping an offset array, because the
loop's own bounds test costs more than the arithmetic it guards.

Same shape one level down: a `Tile.is_walkable()` call per tile becomes a `PackedByteArray` indexed
by tile type, built *from* `Tile.is_walkable` so it stays the one place that decides.
