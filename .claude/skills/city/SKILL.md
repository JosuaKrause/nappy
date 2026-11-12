---
name: city
description: Rules for the city — the lattice and what may change about it, tile types, block purposes, closures, the street hierarchy, and the guarantees that keep every day winnable. Load this BEFORE touching src/city/, CityMap, CityGenerator, StreetNetwork, ClosurePlanner, RouteTree, or anything about streets, blocks, calm areas or road closures.
---

# The city

**The rules not to miss:**

- **The lattice is fixed for the run.** Only a block's purpose changes, along the arc planned for
  it, and no purpose change moves a walkable tile.
- **Every day stays winnable**: at least two distinct calm areas stay reachable from home.
- **Closures and events are checked before they are accepted, never repaired afterwards.**
- **Anything new that closes a street goes through `ClosurePlanner`.** Nothing enforces it.
- **Every route search takes `CityMap.blocked_segments()`**, the absent streets with the closures.
- **Anything that travels the lattice asks `CityMap.is_street()`**, not `is_walkable()`.
- **The street outside the home is never closed**: a doorway is not a route.
- **A closure is silent**: it shapes the route and adds nothing to the meter.
- **One main road, two precincts**, and every reader of the street hierarchy agrees.
- **Never the bare word "blocker"**: it answers three questions with one word.

Three reference files beside this one are read on demand: `references/adding-things.md` before
adding a tile type, a block purpose or a closure kind; `references/sweeps.md` before writing a
flood fill or any per-tile sweep; `references/street-kinds-and-ground.md` before changing the
street hierarchy or a ground's decay multiplier.

## The lattice is fixed; what a block *is* is not

The street lattice, the block boundaries, the carves and the building footprints are all fixed for
the run. What may change is a block's **purpose** — a park can be requisitioned, a commercial street
can go dark, a residential block can burn — and only ever along the arc `CityGenerator` planned for
it up front. **The geometry the player learns stays true; the meaning of it does not.**

**No purpose change may move a walkable tile.** `tests/test_blocks.gd` pushes every block to the end
of its arc across the suite's seeds and asserts the walkable set is identical tile for tile. Per-day
*closures* remain events with an `obstructs_radius`, not tile edits.

## The lattice is not a full grid

Every city has one or two calm zones (`Tuning.CALM_ZONE_SHAPES`: 2x2, 2x1 or 1x2), each absorbing
the streets between its blocks, so the lattice has holes in it — T-junctions where an absorbed
street used to meet one, and in a square zone a junction in the middle that nothing reaches (counts
in `docs/CITY.md`, "Calm zones"). Three consequences:

- **Route redundancy is not true by construction.** A full lattice cannot be disconnected by
  removing one corridor; this one can. It is checked by search — `StreetNetwork.route_count()`.
- **The absent streets are a set, not a hole in the enumeration.** `StreetNetwork` still enumerates
  the full grid; `CityMap.has_street()` says which of them this city has, and
  `CityMap.blocked_segments()` merges the ones it does not with today's closures. **Every route search takes that
  merged set** — one that takes only the closures will happily route down the middle of a park and
  overstate the redundancy.
- **A block is not the unit; a lot is.** `block_plans`, `block_layouts` and `calm_blocks` are keyed
  by the block that *anchors* a lot, so a zone is one entry with several blocks of ground. Anything
  counting calm areas counts a zone once. `CityMap.anchor_of()` and `lot_rect()` reach its other
  blocks.

**An absorbed street is calm ground, not a closure.** The tiles are park and the player walks over
them — a zone is a shortcut as well as a destination. Only the *lattice* lost the street, which is
why the absent streets are a set of segment keys and `closed_tiles` is a set of tiles. **Anything that
travels the lattice asks `CityMap.is_street()`, not `is_walkable()`.**

## Every day stays winnable, and always has somewhere else to go

The scheduler guarantees one unspoiled park and a walkable route from home to a park. On top of
that, `ClosurePlanner` keeps **at least two distinct calm areas reachable**
(`ClosurePlanner.MIN_CALM_AREAS_REACHABLE`), checked **before accepting each closure**. Anything new that
closes a street must go through it. `tests/routes_closures_rig.gd`, which
`tests/test_routes_closures_a.gd`, `_b` and `_c` run, holds every day the planner plans to the
count; **a closure made outside the planner is unenforced**, since no suite sees one.

**Two areas is the count; reachability is the strength.** Two *areas* is what stops a day arriving
where the only calm left is the one this morning spoiled; dropping to one reachable area is an
unwinnable day. **No one street cuts off all the calm** is the guarantee's own statement — by
Menger, two routes to different areas means no single street is a cut — and
`tests/test_routes_lattice.gd` asserts that sentence directly, about the city rather than about
each area.

**A day's narrow target is kept reachable the same way.** On day 9 (a named door), day 12 (a
park's swing) and the last night (the power station's front door), the route tree, `ClosurePlanner`
and the day's route rules (`RouteJunctionsRule`, `RouteSidewalkRule`, `PacingOpeningRule` and
`RouteGroundRule`, no body on a route's ground off the streets, and for the scars and the park
spoilers none on any route tile or the street she starts on) each keep
at least one tile of the day's target pool (`ResistanceSteps.target_candidates()`, for the step
`ResistanceSteps.narrow_target_on()` names) reachable from home, checked before a closure or a body
is accepted. Anything new that closes a street or stands a body on those days goes through the same
checks; `docs/CITY.md`, "Guarantees", states what the guarantee does not cover, and
`tests/test_resistance_reach_narrow.gd` plans the three days.

Two exemptions, and they are the same exemption at both ends of the journey: **a doorway is not a
route.** The street outside the home is never closed (the home is a notch with one exit, so sealing
that street seals the player in), and an area is reached by arriving at *either end* of a street it
opens onto, so a courtyard with one archway is still reachable two ways.

**Counting distinct routes is a max flow, not a search for routes.** Two BFS augmentations over the
junction graph, not a flood fill over every tile — which is why it can run on every candidate
closure, every day.

## Check before accepting; never repair afterwards

**Closures and events are checked before they are accepted.** The obvious shape — place N closures,
then drop them until the day is legal — has an order-dependent answer and a window where the day is
illegal, and the guarantee then rests on the repair with nothing checking the result. Testing each
candidate against the invariant before accepting it is the same cost and has neither problem. The
same holds for events: refusing the ground (`CalmAreas.unused_ground()`) keeps every unvisited
calm area clean and *raises* the density, because a repair empties ground the draw already filled. **If
you find yourself writing a pass that deletes what a previous pass placed in order to make a
guarantee true, this is the rule you are about to rediscover.**

**One exception, and the direction is what makes it one:** a pass that only ever *removes*
obstruction is safe, because every guarantee here is about **reaching** somewhere and taking a
barrier away can only add reachable ground. The seal-thinning pass
(`SealPlanner._thin_soft_pairs`, which drops one body of `SealPlanner.SEAL_THINNING_FRACTION` of the
day's soft seals so the walls do not read as guardrails) is that case, where a pass that added or
moved a seal would not be. **The test is monotonicity, not intent**: a pass that removes some things
and places others is not covered, and neither is one whose removal could make a *cost* guarantee
false rather than a reachability one. State the direction argument next to any such pass, or the
next reader deletes it on sight.

## The words for placement

The full table is `docs/CITY.md`, "The words for it". Three axes, not one:

- **Permanence** — `hard` (pruned into the layout, whole run) or `soft` (placed for one day).
- **Effect** — `lethal` (ends the day), `impassable` (stops passage, does not kill), or `costly`
  (passable at a readable price).
- **Role** — what the scheduler placed it *for*: `wall` (bounds the corridor), `friction` (sits
  inside it), or `set piece` (placed so she meets it).

The **corridor** is the ground a day's routes run through. **Do not reintroduce the bare word
"blocker"** for any of these: it answers three questions with one word.

## A closure is silent

Closures change the shape of the route and contribute nothing to the meter — the noise of a street
is the crowd, the danger is the events, the shape is the closures. A noisy roadworks already exists
as the `construction` event. **Do not let a closure emit**; it would be a third set in
`WorldContext.excitement_sources` (`City` extends `WorldContext` and fills it with the events' and
the crowd's, which `Baby` sums), and that list is exactly two long on purpose.

**One seal is loud, and it is the shape of the exception that matters.** `car_accident` is solid
only where its two cars are (PLAYTEST-63), so its picture's own gaps are walkable and
`EventCatalogue.CAR_ACCIDENT_INTENSITY` is what stands in them, an excitement field that keeps her from
walking past. **That is a catalogue row emitting, not a closure emitting** — a seal is an
`EventDef`, so nothing is added to the sum. A `RoadClosure` contributes nothing, and a seal whose
picture leaves no gap (`fallen_tree`, `burst_water_main`) carries `intensity = 0.0`. The test for a
new one is whether the body can match the picture: where it can, the silence stands.

Diversions (`docs/CITY.md`, "Diversions — the design") ask that closures and events be **placed to
point somewhere** — a scheduler decision, not a change to what a closure is.

## The street hierarchy

`CityGenerator._assign_street_kinds()` decides *where* (`CityMap.main_road`,
`CityMap.precinct_spans`); `Tuning.PRECINCT_BLOCKS`, `CrowdLanes.PRECINCT_BUSYNESS`,
`EventScheduler.EVENT_PRECINCT_WEIGHT` and `City`'s `EXCITEMENT_DECAY_*_MULTIPLIER` family decide
*what it means*.

**Every place that reads it has to agree, and the failure mode of each is silent:**

- `CityMap.street_kind` — what kind of street a stretch is
- `GroundTiles` — what it looks like
- `CrowdLanes.busyness_for` + `walkable_offsets` — who walks and drives there
- `City.decay_multiplier` — what the ground does to the meter
- `TrafficSignals.has_lights()` — whether its junctions have lights standing on them, a fact about
  the street. Whether a light decides a junction now is `is_signalled()`, the traffic's question,
  false with the power off (the **crowd-traffic** skill, "The traffic fairness contract")

**There is one main road and there are two precincts, and that is the design rather than a
parameter**; which corridor is the main road is read off the map, never computed per axis. **The
ground is a rate, not a category**: calm, precinct, ordinary street, alley and main road each
multiply the excitement decay (`City.decay_multiplier()`), so choosing a route is choosing a
recovery rate. The traps of both, and how the multipliers are re-derived when the walking decay
moves, are `references/street-kinds-and-ground.md`.
