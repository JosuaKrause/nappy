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
| 12 | Force limited paths: build a tree of allowed routes and block the rest with excitement-overload events (roadworks, fallen tree, car accident). Avoidable, but clearly "not that way" | M | 7 |
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

### 12 reverses an existing guarantee

`docs/CITY.md` currently guarantees **at least two topologically distinct routes** from home
to every park, and `tests/test_generator.gd` enforces it by closing each street segment in
turn. Finding 12 asks for the opposite: deliberately prune the network to a tree so the
route is forced.

Both can be true if the guarantee is restated as being about the **layout**, not the day:
the lattice is always fully connected, and a *day* may close it down to a tree. What has to
be preserved is weaker and more important — every day must leave at least one walkable
route to a usable calm area, and the closures must be legible before you have committed to
a street. The scheduler already has the machinery (`_ensure_the_city_is_still_walkable`).

### 11 needs a mutable city, which is currently forbidden on purpose

`CLAUDE.md` lists "the `CityMap` is immutable for the run" as an invariant, and per-day
closures are events rather than tile edits — that is what keeps the map learnable. But 11
wants the burnt-out house to *be* burnt out on the map the next morning.

The way through is a second layer rather than a change to the first: keep `CityMap` as the
immutable layout, and add a run-scoped `CityState` overlay holding what has happened to it
(scars, permanent closures). The map screen renders layout + overlay. `GameState.scars`
already holds most of this and is the seed of that overlay.

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

**M12 — Asset pipeline** — finding 13. Authored SVG assets, a `TileSet` for ground, modular
building tiles, sprites for the rig and props. No new content: this milestone should end
looking near-identical to today, which is what makes it reviewable. Everything after it
gets cheaper.

**M13 — Density and life** — findings 3, 8, 9. Ambient pedestrians and traffic as real
moving agents, at a density the streets can carry. Retune the per-person excitement so
passing someone reads. The crowd becomes the noise floor.

**M14 — Balance** — findings 2, 4. Re-pitch street vs calm-area sleepiness so a day cannot
be won without reaching calm ground. Depends on M13, because the floor is the crowd.

**M15 — Area variety** — finding 7. More calm-area types (park, forest, courtyard, quiet
square, canal path) and matching district and event variety.

**M16 — Forced routes** — finding 12. A per-day allowed network with legible blockers, plus
the restated connectivity guarantee.

**M17 — Route map** — finding 11. The `CityState` overlay and the planning screen at the
start of a day, showing what the city has become.

### Order rationale

- 13 first, because it is the gate on five others.
- 3 before 4, because the crowd *is* the noise floor.
- 7 before 12, because forced routes are only interesting across varied ground.
- 11 last, because a planning map is only worth drawing once there is something to plan
  around — varied areas, closures, and a city that visibly changes.

### Decisions wanted before M14 and M16

1. **Should an ordinary street make any sleep progress at all?** Recommendation: yes, but
   never enough to finish a day alone.
2. **Confirm 12 supersedes the two-routes guarantee** as described above — the layout stays
   redundant, the day may be a tree.
3. **SVG for assets**, on the strength of "the vector assets look okay". Pixel art would be
   the other credible answer and would change the whole look.
