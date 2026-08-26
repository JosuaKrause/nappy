# Handoff

**Last updated:** end of the M15 session.
**Read this first, then [PLAYTEST-01.md](PLAYTEST-01.md), then [TODO.md](TODO.md).**

---

## Where things are

`main` is green and playable. `./tools/test.sh` → **7187 checks, 0 failures** (~2m20s);
`./tools/check.sh` → OK; `./tools/run.sh` plays it.

- **M0–M9 complete.** Full 14-day run, four-act escalation, resistance subquest, three
  endings. Documented in `docs/`.
- **M11 complete.** The four quick wins from the first playtest (home arrow, three graphics
  glitches, day-start position, spoiler-free README).
- **M12a complete.** Ground is now authored SVG tiles + a `TileSet` + a `TileMapLayer`.
- **M12b complete.** Buildings are assembled from `assets/buildings/*.svg`, and their
  heights are whole tiles.
- **M12c complete.** The rig, the props and the event bodies are sprites. `Palette` was
  trimmed to the colours the code still chooses. **M12 is done** — nothing draws its own art
  out of primitives any more.
- **M13 complete.** The city has its own traffic: ~530 agents in act I, on a per-corridor
  and per-act density. The crowd is the noise floor, and the two invisible ambient road
  bands were deleted rather than left alongside it.
- **M14 complete.** The day is re-pitched against calm ground. A whole day of undisturbed
  street walking reaches 79 of 100; a calm stretch clears the meter in 119s.
- **M15 complete.** Blocks have purposes and arcs. Four kinds of calm, three degraded forms,
  planned up front, tracked in a run-scoped `CityState`, repainted every morning.

## What to do next, in order

### M16 — route pressure

Finding 12. A per-day pruned road network with legible blockers, and the day-level
invariant: **at least two distinct routes to at least two distinct calm areas.** The
scheduler already has most of the machinery in `_ensure_the_city_is_still_walkable`; it
needs to count distinct routes and destinations rather than just find one.

Two things M15 leaves on the table for it:

- **Canal path** was the one item from finding 7's list deliberately left out. It means
  impassable water and bridges — a change to *where the player can walk*, which is M16's
  subject. Every M15 purpose is guaranteed not to move a walkable tile; a canal would be the
  single exception, so it belongs with the milestone that owns closures.
- **Legibility before commitment.** Closures have to be visible *before* the player has
  walked down the street. Nothing in M15 does that; the overview camera is the only place
  the city's shape is currently readable, and that is a dev flag.

### Then M17 — the route map

The planning screen, rendering the block states M15 introduced: what the city has become,
not what it was generated as. `CityState.changed_on(block)` is already recorded for exactly
this — shading "this is new" is what makes the screen worth opening twice.

See `PLAYTEST-01.md`. Do not reorder them — the sequencing rationale is in that document
and each depends on the one before.

---

## Standing decisions

Taken in the M12a session and still governing everything after it. All four are recorded in
`PLAYTEST-01.md`; repeated here because they change the design.

1. **Assets are SVG.** Confirmed. Graphics get refined later — *"for now we need something
   workable"*, so do not gold-plate the art. Generating images or using freely-licensed
   assets is also acceptable.
2. **An ordinary street makes sleep progress, but never enough** to finish a day alone.
   A day must be unwinnable on street gain and comfortably winnable with one calm stretch.
3. **Finding 12 narrows the route choice, it does not remove it.** Not a single forced path
   — several viable routes and *several quiet destinations to choose between*. The day-level
   invariant to enforce in M16: at least two distinct routes to at least two distinct calm
   areas.
4. **The city is mutable day to day, by recontextualising areas.** *(Implemented in M15.)*
   The generator plans each block's *purpose arc* up front so blocks transition coherently.
   This **superseded the "`CityMap` is immutable for the run" invariant in `CLAUDE.md`** —
   replaced by: the street lattice and block boundaries are fixed; what a block *is* may
   change, only along its planned arc. Rendering reads block state, so `City.start_day()`
   repaints the ground and re-dresses the blocks every morning.

---

## Gotchas learned in M15

- **A carved interior needs a way in.** Courtyards were sealed rects the first time and the
  connectivity check failed on *every seed*. The archway is now part of `BlockLayout`, and
  it is paved as an alley on purpose: reaching hidden calm costs a few seconds of somewhere
  you would rather not be.
- **Put arc invariants in the arc, not in the callers.** A commercial block could be planned
  to go dark on day 10 and then burn on day 3, because two independent rolls wrote their own
  `from_day`. `BlockPlan.then()` now clamps each step to at least the previous step's day.
  `tests/test_blocks.gd` found it on 13 of 24 seeds.
- **Protect the calm ground, not the block.** `_ensure_one_usable_park` matched events
  against the whole block lot. For a courtyard — four tiles inside a residential block —
  that stripped every event off streets the player was never going to settle on. It matches
  `BlockLayout.open_rect` now.
- **Calm ground must not read as a rooftop.** From above, the first quiet-square paving was
  the same warm beige as the building roofs. Since M14 finding calm ground is the whole
  game, so the tile is deliberately cooler than anything else in the palette. This will
  matter more in M17, where the map screen *is* the view.
- **`var x := SomeEnum.keys()[i]` will not parse.** The value is a Variant, and "inferred
  from a Variant value" is an error, not a warning. Annotate: `var x: String = ...`.

## Known slow: `tests/test_balance.gd` is 94s of the suite's 138s

Per-suite timings are printed by `tools/test.sh` now. `test_balance.gd` steps a real `Baby`
through fourteen full days at 1/60s against a real city, and each step sums over ~530 crowd
agents — roughly 150 million distance checks. It is doing real work and it is the test that
justifies M14, so it has not been cut; but if the suite needs to get faster, that is where
all of the time is. Sampling every third physics step would probably be honest.

## Gotchas learned in M14

- **Pitch balance numbers against the day, not against each other.** The old numbers were
  all mutually consistent and the day was still winnable by circling the block, because
  nothing tied the fill rate to `day_length()`. The two tests that matter now are written
  as `GAIN * day_length(day) < METER_MAX` and `METER_MAX / calm_gain < day_length * 0.6`,
  so lengthening the day cannot quietly make the street sufficient again.
- **Arithmetic is necessary and not sufficient.** Whether a park fills the meter depends on
  whether the crowd pushes it over the freeze threshold, which no data-level test can see.
  `tests/test_balance.gd` stands a real `Baby` in a real city with that day's crowd and
  events. It is what caught that the claim needed checking on all fourteen days, not one.
- **Check the short day.** A calm stretch of 139s looked fine against the 330s day and was a
  stopwatch race against the 264s curfew one. Every balance claim here is measured against
  `day_length(RUN_LENGTH_DAYS)`.

## Gotchas learned in M13

- **A runtime error in a test suite hangs the runner; it does not fail it.** `run_tests.gd`
  calls each suite synchronously and quits at the end, so an error aborts `_ready()` before
  the quit and the headless process sits there printing nothing. Deleting `busy_road` left
  three suites calling `by_id("busy_road").intensity`, and the symptom was a test run that
  produced *no output at all* for six minutes. No output means an error, not a slow suite.
- **A negative-width `Rect2` normalises** — already in `CLAUDE.md` from M12c, and it bit
  again here: it is the same helper the whole crowd draws through.
- **Moving a `Node2D` does not invalidate its draw list.** The transform is applied when the
  retained list is replayed, so 530 agents only need `queue_redraw()` when their *picture*
  changes — a turn, a flip — not when they move. That is the difference between 530 redraws
  a frame and a handful.
- **Give each agent its own RNG.** Seeded per agent from the day, not shared, so a turn
  taken at a junction cannot depend on the order agents happen to reach junctions in — which
  frame timing would otherwise decide, and determinism would be a lie.

## Gotchas learned in M12c

- **A negative-width `Rect2` does not flip `draw_texture_rect`** — it is normalised, so the
  sprite lands a full width sideways. It reads as art sliding off its own shadow rather than
  as a failed flip, which is how it was found. `Sprites.draw_standing()` mirrors the
  transform around the anchor instead, and is the only place that does.
- **A sprite cannot swing its own legs.** The mother's gait was a procedural stride and a
  bob; with the legs drawn into the art, both had to become a two-frame swap. The bob is
  baked into the second frame rather than added on top, or the two would compound.
- **Deleting the colours was part of the job.** Two thirds of `Palette` no longer painted
  anything once the art moved into SVG, and a constant that looks authoritative but controls
  nothing is a trap for whoever tries to retint the game next. What stayed is what the code
  still picks at runtime: light, act cast, aura, chalk, shadow, building variant.

## Gotchas learned in M12b

- **Edge overlays beat corner tiles.** The roof parapet is four edge tiles drawn on top of
  the roof fill, each transparent apart from its own band. A corner cell takes two of them
  and the parapet turns by itself — no corner tiles, and no combinatorial explosion when a
  roof is only one tile deep and a row has to be both its north and its south edge.
- **Multiply the colour, not the art.** Wall and roof fills are authored near-white and
  passed the variant colour as `draw_texture`'s modulate, so six roof colours cost one
  asset. Windows are drawn *after*, unmodulated: a lit window is the same warm colour
  whatever the building is painted.

## Gotchas learned in M12a

Beyond the ones already in `CLAUDE.md`:

- **`Sprite2D` with `centered = false` puts the node at the sprite's top-left.** Y-sorting
  then compares the wrong edge. Everything in this project is feet-anchored: put the node on
  the ground plane and use `offset` to draw upward.
- **A y-sort tie is broken by tree order.** The front door sits in the wall of the building
  above it at exactly the same `y`, so it has to be added to the tree *after* the buildings.
- **A tile cannot carry a line that falls on its own edge.** The road centre line sits on the
  seam between the two carriageway tiles, so it is authored as two halves that meet
  (`road_line_e`/`_w`, `road_line_n`/`_s`).

## How the asset pipeline is put together

- `assets/tiles/*.svg` — 17 ground tiles, 32×32, hand-editable. **There is no regeneration
  script**; they were emitted once and are now the source of truth.
- `assets/ground_tileset.tres` — one `TileSetAtlasSource` per tile. **Source ids are
  positional and `src/city/ground_tiles.gd` mirrors them by hand.** Adding a tile means
  appending to both, in the same order.
- `src/city/ground_tiles.gd` — the only place that decides which tile a cell gets.
- `assets/buildings/*.svg` — 11 building tiles, 32×32. `wall`/`roof` are fills (modulated);
  `wall_edge_*`, `wall_base`, `roof_edge_*`, `window_*` are alpha overlays drawn on top at
  full colour. No `TileSet` here: `Building._draw()` assembles them per lot, which keeps one
  node per building and lets a lot pick its own colour.
- `assets/rig/`, `assets/props/`, `assets/events/` — feet-anchored sprites, drawn through
  `Sprites.draw_standing()`: the node sits on the ground plane, the art rises from it.
  Anything whose size carries meaning (a fire's flames, a barrier's width) passes an
  explicit size rather than using the texture's own.

Run `./tools/check.sh` after touching assets; it does the import pass that generates
`.import` files.

---

## Working agreement

From `CLAUDE.md`, which is the fuller version:

- Feature branch per milestone, `--no-ff` merge to `main` when green.
- Run `check.sh`, `test.sh`, and a `shot.sh` screenshot before committing anything visual.
  A green `check.sh` says nothing about whether the game looks right.
- Commit the docs in the same commit as the code.
- Update **this file** at the end of each work session.
