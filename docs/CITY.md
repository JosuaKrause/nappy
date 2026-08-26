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
- At least **3 park districts**, no two adjacent (so calm zones are spread out).
- The home is at least `MIN_HOME_TO_PARK_TILES` (30) *walking* tiles from the nearest park.
- Building rects tile the `BUILDING` tiles exactly, with no overlaps and no gaps.

### Route redundancy

The design wants at least two distinct routes from home to every park, so that a spoiled or
blocked route always has an alternative. This holds **by construction** rather than by
search: carving only ever happens *inside* blocks, so the street lattice is never cut, and
a full lattice cannot be disconnected by removing any single corridor.

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

## Barricades and closures (later acts)

From Act III the generator's output is post-processed per day:

- `CHECKPOINT` tiles can appear on streets, converting them to blocked-or-costly.
- `BARRICADE` tiles fully block a street segment from Act IV.

Closures are validated the same way as generation: home must remain connected to at least
one unspoiled calm zone, or the day is unwinnable and the scheduler retries.

## Rendering (2.5D)

Top-down camera with a fake vertical extrusion:

- Ground is a `TileMapLayer` over `assets/ground_tileset.tres`. Kerbs, centre lines and
  zebra crossings are authored tiles chosen per cell by `GroundTiles`, not geometry
  recomputed on every redraw.
- Buildings fill exactly their lot: the front wall takes the southern `height` px and the
  roof takes the rest. Fitting the mass inside the lot is what keeps extrusions off the
  street — a roof overhanging northward would hide the player whenever she walked along that
  sidewalk. A taller building therefore shows more wall and less roof, which is what an
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
  correctly.
- Sprite anchor is the *feet*, not the centre, so y-sorting matches the ground plane. A
  `Sprite2D` with `centered = false` puts the node at the sprite's *top-left*, which makes
  y-sort compare the wrong edge; use `offset` to draw upward from the ground plane instead.

Art lives in `assets/` as hand-editable SVG — tiles under `assets/tiles/`, building tiles
under `assets/buildings/`, sprites under `assets/props/` — with a per-act palette
multiplied over it.
