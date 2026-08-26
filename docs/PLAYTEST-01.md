# Playtest 01 — findings and plan

First time the game has been played by a human. Thirteen items, recorded verbatim in
intent, with what each one actually implies and what it costs.

The short version: **four are done, one is foundational and blocks five others, and two
require reversing decisions that are currently written down as invariants.**

---

## The findings

### Done in `feature/playtest-fixes`

| # | Finding | Resolution |
| --- | --- | --- |
| 1 | No way home once the baby is asleep | Arrow pointing home during the return phase, pinned to the screen edge with a distance when home is off-screen |
| 5 | Pram canopy offset when moving sideways; zebra crossings wrong for vertical roads; lane markers drawn through intersections | All three fixed — see the commit; the zebra was genuinely backwards, stripes run *parallel* to traffic |
| 6 | Day starts with the player standing on the door | Days start on the doorstep, facing the street |
| 10 | README gives away the meta narrative | README is spoiler-free; `docs/` keeps everything and says so |

### Outstanding

| # | Finding | Size | Blocked by |
| --- | --- | --- | --- |
| 13 | Use real asset files, not `_draw()` calls. Tiles for generative content (buildings, streets) rather than generating on the fly | **L** | — |
| 3 | More going on: people walking around, cars on the street making noise | M | 13 |
| 8 | Far more of it — "think New York level" | M | 13, 3 |
| 9 | Passing a person barely moves the excitement meter | S | 3 |
| 2 | Too easy: circling the starting block fills the sleepiness meter | S | 4 |
| 4 | Needs a constant/periodic base noise floor so standing in one place cannot work. Reaching a calm area should be a *requirement* for getting through a day | M | 3 |
| 7 | More variety in areas and events — calm areas could be park, forest, apartment-block courtyard, etc. | M | 13 |
| 12 | Prune the road network per day with blockers (roadworks, fallen tree, car accident) so the route is a real decision. Avoidable, but clearly "not that way". **Several viable routes, and several quiet destinations to choose between** | M | *(done, M16)* |
| 11 | Stylised city map at the start of a round for route planning; updates as destructive events change the city | M | 7, 12 |

---

## What the findings actually mean

### 2 + 4 are one problem, and fixing it changes the core loop

Today any quiet ground fills the meter, so the starting block is a valid strategy and the
city is decoration. The fix is not a difficulty tweak — it is a re-pitch of where sleep
comes from:

| | now | proposed |
| --- | --- | --- |
| Ordinary street | fills the meter at 2.2/s | fills it *slowly* — not enough to finish a day |
| Calm area | 1.75× faster | the only place a day can actually be won |
| Standing still | drains | drains |

**Recommendation: a neutral street should still make progress, just never enough.** Making
it strictly zero turns every day into "run to the park, stand there", which is a worse game
than "make progress on the way, bank it in the park". The number to hit: a day (330 s, or
264 s after the curfew) must be unwinnable on street gain alone, and comfortably winnable
with one good calm stretch.

**The base noise floor should be emergent, not a constant.** A magic city-wide number would
work mechanically and mean nothing. The crowd from 3/8 *is* the floor: a busy street is
loud because it is busy, a park is quiet because nobody is in it, and the player can see
exactly why in both cases. That makes 4 depend on 3 rather than standing alone.

### 12 narrows the choice; it does not remove it

*Clarified after the first draft of this plan.* The pruned network is **not** a tree with a
single forced route. It is a subgraph: pruned hard enough that the route is a real decision
rather than an open field, but leaving **several viable paths and several quiet destinations
to choose between**.

That distinction is the whole value of the mechanic. A single forced path is not a decision,
it is a corridor — and it would make the fixed city pointless, since there would be nothing
to know. What makes it interesting is being able to see three ways to two different parks
and having to work out which one today's blockers have made expensive.

It also mostly dissolves the apparent conflict with `docs/CITY.md`, which guarantees at
least two topologically distinct routes from home to every park and enforces it in
`tests/test_generator.gd` by closing each street segment in turn. Restated:

- The **layout** stays fully redundant. That guarantee is unchanged.
- A **day** may prune it, but must leave at least two distinct routes to at least two
  distinct calm areas. That is a new and stronger day-level invariant than the current
  "one walkable route to a park", and it is what the M16 validator has to enforce.
- Closures must be legible *before* the player has committed to a street.

The scheduler already has most of the machinery (`_ensure_the_city_is_still_walkable`); it
needs to count distinct routes and destinations rather than just find one.

### 11 makes the city mutable — by design, and further than a scar overlay

*Revised after the first draft.* The first version of this plan proposed keeping `CityMap`
immutable and bolting a thin overlay of scars onto it. That is too weak. The actual
requirement:

> The city is mutable day to day by **recontextualising areas**. The generator should plan
> the purpose of each city block in advance, so every block can transition smoothly from
> day to day depending on what happened.

So a block is not a fixed thing with damage painted on it. A block has a **planned arc** — a
set of purposes it may take — and each day it presents whichever one the run's history has
brought it to. A park can be requisitioned as a staging ground. A residential block can burn
and stay burnt. A commercial street can be boarded up, then barricaded.

This is much stronger than a scar list, and it is what makes the map screen worth having:
you are not looking at damage markers, you are looking at a city that has become a different
city while you walked around in it.

**Structure it as:**

- `CityGenerator` produces, per block, its **purpose plan**: the role it starts in and the
  states it can transition into. Planned up front so the transitions are always coherent —
  a block never has to invent a plausible next state at runtime.
- A run-scoped `CityState` holds each block's **current** purpose and the day it changed.
- Day transitions apply consequences: a fire burns a block out, a convoy barricades one, the
  regime requisitions another. Events cause transitions rather than leaving markers.
- **Rendering reads block state, not the layout**, so ground tiles and buildings both change
  with it. `City._paint_ground()` therefore has to be re-run per day, not once per run.
- The route map renders the same block states, which is why it comes last.

**This supersedes the "`CityMap` is immutable for the run" invariant in `CLAUDE.md`.** The
replacement invariant is weaker but still load-bearing: *the street lattice and block
boundaries are fixed for the run; what a block **is** may change, and only ever along the
arc the generator planned for it.* The geometry you learn stays true; the meaning of it does
not.

It also folds finding 7 in: an "area type" and a "block purpose" are the same concept, so
M15 becomes the block-purpose vocabulary and M17 renders it.

### 13 has to come first

Findings 3, 7, 8, 11 and 12 all add visual content: pedestrians, cars, new area types,
blockers, a map screen. Every one of them built against `_draw()` is built twice. The
asset pipeline is the expensive item and it is also the gate.

Roughly 600 lines of `_draw()` across `city.gd`, `building.gd`, `prop.gd`, `stroller.gd`
and `event_instance.gd` get replaced. Direction, given "the vector assets look okay":

- **SVG source files** under `assets/`, which Godot imports and which stay editable.
- **Ground → `TileSet` + `TileMapLayer`.** Streets, sidewalks, crossings, park, alley,
  plaza, and the kerbs and markings as autotile terrain rather than computed lines.
- **Buildings → modular tiles** (facade, roof, corner) assembled from the generator's
  rects, not one procedural box per lot.
- **Characters and props → sprites**, with the 8-direction facing the pram already needs.

---

## Plan

Each is a branch, merged when green, as before.

**M11 — Playtest fixes** *(done)* — findings 1, 5, 6, 10.

**M12 — Asset pipeline** *(done)* — finding 13. Authored SVG assets, a `TileSet` for ground, modular
building tiles, sprites for the rig and props. No new content: this milestone should end
looking near-identical to today, which is what makes it reviewable. Everything after it
gets cheaper.

**M13 — Density and life** *(done)* — findings 3, 8, 9. Pedestrians and traffic as real
moving agents on a per-corridor, per-act density. Passing someone reads because a close
pass is pitched just over the walking decay while the width of the pavement is not. The
crowd is the noise floor, and the two invisible ambient road bands it replaced were
deleted rather than kept alongside it.

**M14 — Balance** *(done)* — findings 2, 4. Street gain re-pitched against the *day*: a
whole day of undisturbed street walking reaches 79 of 100, so the walk out is real progress
and can never finish on its own, and a calm stretch clears the rest in about two minutes.
Standing still drains faster than walking fills but slower than a calm zone fills, so
waiting is never a strategy and stopping to let something pass still is.

**M15 — Block purposes** *(done)* — findings 7 and the structural half of 11. Four calm
purposes (park, forest, quiet square, courtyard) and three degraded ones (requisitioned,
boarded up, burnt out), per-block arcs planned at generation, and the run-scoped
`CityState`. Rendering reads block state rather than layout: `City.start_day()` repaints the
ground and re-dresses every block, so a requisitioned park stops having swings in it.

**Canal path is not in.** It is the one item from the finding's list that was left out, and
deliberately: a canal means impassable water and bridges, which is a change to *where the
player can walk* rather than to what a place is worth walking to. That belongs with M16's
route work, not here — every other purpose in M15 is guaranteed not to move a walkable tile,
and a canal would be the single exception.

**M16 — Route pressure** — finding 12. A per-day pruned network with legible blockers, and
the day-level invariant: at least two distinct routes to at least two distinct calm areas.

**M17 — Route map** — the presentation half of finding 11. The planning screen at the start
of a day, rendering the block states M15 introduced — what the city has become, not what it
was generated as.

### Order rationale

- 13 first, because it is the gate on five others.
- 3 before 4, because the crowd *is* the noise floor.
- 7 before 12, because forced routes are only interesting across varied ground.
- 11 splits: its *structure* (block purposes and transitions) is M15, because everything
  else needs it; its *presentation* (the map screen) is M17, because a planning map is only
  worth drawing once there is something to plan around.

### Decisions

Taken as the recommended defaults unless stated otherwise.

1. ~~Should an ordinary street make any sleep progress at all?~~ **Decided: yes, but never
   enough to finish a day alone.** A day must be unwinnable on street gain alone and
   comfortably winnable with one good calm stretch.
2. ~~Confirm 12 supersedes the two-routes guarantee.~~ **Superseded by the clarification
   above:** the layout guarantee is unchanged, and the day gets a *stronger* one — at
   least two distinct routes to at least two distinct calm areas.
3. **SVG for assets**, on the strength of "the vector assets look okay". Taken as default;
   pixel art was the other credible answer and would have changed the whole look.
