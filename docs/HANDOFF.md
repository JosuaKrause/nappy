# Handoff

**Last updated:** end of the M12b session.
**Read this first, then [PLAYTEST-01.md](PLAYTEST-01.md), then [TODO.md](TODO.md).**

---

## Where things are

`main` is green and playable. `./tools/test.sh` → **2649 checks, 0 failures**;
`./tools/check.sh` → OK; `./tools/run.sh` plays it.

- **M0–M9 complete.** Full 14-day run, four-act escalation, resistance subquest, three
  endings. Documented in `docs/`.
- **M11 complete.** The four quick wins from the first playtest (home arrow, three graphics
  glitches, day-start position, spoiler-free README).
- **M12a complete.** Ground is now authored SVG tiles + a `TileSet` + a `TileMapLayer`.
- **M12b complete.** Buildings are assembled from `assets/buildings/*.svg`, and their
  heights are whole tiles.

**In progress: M12 (the asset pipeline).** M12a and M12b landed. M12c has not started.

## What to do next, in order

### M12c — the rig, props and events

`stroller.gd`, `prop.gd` and `event_instance.gd` are still `_draw()`. The rig needs
direction variants; it already has side and end-on profiles, so three SVGs (side, front,
back) plus a horizontal flip covers eight directions.

### Then M13 → M17

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
4. **The city is mutable day to day, by recontextualising areas.** The generator plans each
   block's *purpose arc* up front so blocks transition coherently. This **supersedes the
   "`CityMap` is immutable for the run" invariant in `CLAUDE.md`** — replaced by: the street
   lattice and block boundaries are fixed; what a block *is* may change, only along its
   planned arc. Rendering must read block state, so `City._paint_ground()` has to become
   per-day rather than once per run.

---

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
- `assets/props/door.svg` — the first sprite asset; the pattern for M12c.

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
