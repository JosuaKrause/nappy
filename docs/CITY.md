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

- `BLOCK_SIZE` = 6 × 6 tiles of building interior
- `STREET_WIDTH` = 3 tiles (1 sidewalk, 1 road, 1 sidewalk conceptually; walkable)
- `CITY_BLOCKS` = 7 × 7 blocks by default

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
4. **Carve alleys** — each non-park block has a seeded chance of a through-alley bisecting it.
5. **Place playgrounds** — every `PARK` district gets 1 playground near its edge.
6. **Place home** — on a `RESIDENTIAL` block edge, biased toward the map centre so that no
   direction is strictly better.
7. **Validate** — flood-fill from home; every walkable tile must be reachable. Regenerate
   with `seed + 1` if not.

Guarantees the generator must satisfy (asserted in debug):

- At least **3 park districts**, no two adjacent (so calm zones are spread out).
- Home is at least `MIN_HOME_TO_PARK` tiles from the nearest park (you must earn the calm).
- At least two topologically distinct routes from home to every park (so a spoiled or
  blocked route always has an alternative).

## Spoiling calm zones

A park that is always safe would collapse the game into one memorised loop. So each day,
the scheduler may **spoil** calm zones:

- Each park has a per-day chance (`PARK_SPOIL_CHANCE`, default `0.35`) of hosting a
  spoiling event: a dog meet-up, a busker, a school outing, later a checkpoint or a rally.
- A spoiled park keeps its calm-zone multipliers *outside* the event's radius — so a big
  park can still be partially usable. Small parks get wiped out entirely.
- **At most `MAX_SPOILED_PARKS` (default: all but one) parks are spoiled on a given day.**
  There is always at least one usable calm zone. The player just has to find out which.

## Barricades and closures (later acts)

From Act III the generator's output is post-processed per day:

- `CHECKPOINT` tiles can appear on streets, converting them to blocked-or-costly.
- `BARRICADE` tiles fully block a street segment from Act IV.

Closures are validated the same way as generation: home must remain connected to at least
one unspoiled calm zone, or the day is unwinnable and the scheduler retries.

## Rendering (2.5D)

Top-down camera with a fake vertical extrusion:

- Ground tiles are drawn flat.
- Buildings are drawn as a **roof polygon offset upward by `height`** plus two visible side
  faces, shaded darker. This is the "2.5D from the top" look.
- Everything is `y_sort_enabled`, so the player passes behind and in front of props
  correctly.
- Sprite anchor is the *feet*, not the centre, so y-sorting matches the ground plane.

No external art assets are required for the prototype — buildings, props and characters are
drawn procedurally in `_draw()` with a per-act palette.
