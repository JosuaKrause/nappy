# polite-tapir — The narrow target's pool is the model's · 2026-11-23

**The ask.** Every listed layer break is fixed, moved in the map, or declared permanent with its
reason (the design review's reading, which the player approved, inbox #1268 in olive-ferret). The
calendar of the resistance (data) computed the tiles of a narrow task's contact on the city's map,
and so named four classes of the model.

## What was built

- **`NarrowTargetPool`** (`src/routes/narrow_target_pool.gd`, static only, typed from its first line)
  holds the one function that was `ResistanceSteps.target_candidates()`, now `tiles(step, map,
  region_plan)`. Its body and its doc comment moved as they were. It is in the model by its folder,
  so the map gained no line: the pool is half of a route guarantee (one tile of it stays reachable
  from home), `ClosurePlanner` beside it is its first reader, and an edit under `src/routes/` loads
  the city skill that states the guarantee.
- **`ResistanceSteps` keeps `NARROW_KINDS` and `narrow_target_on()`**, pure functions of the
  calendar, and names no class above data. The five production calls and the four in tests and the
  probe read `NarrowTargetPool.tiles()` with the arguments they had.
- **`tools/layer_map.py`** loses the four entries (`BlockLayout`, `CityGenerator`, `CityMap`,
  `RegionPlan`) that listed the calendar's reads of the map.

## Choices open to overturn

- **The pool lives in `src/routes/`** (the design's). The plainer alternative is
  `src/resistance/narrow_target_pool.gd` with a `FILES` line placing it in the model; it adds a map
  line and loses the city skill on the file.
- **No suite of its own** (the design's): the pool is held on real cities by
  `test_resistance_reach_narrow`, `test_resistance_placement_kinds` and `test_events_scheduler`; one on
  a hand-built map would restate the three branches.
- **The three reads of `step.target_kind` moved with the body.** `Step`'s fields stay public for every
  reader; putting them behind methods is `field-reads.md`'s, for all readers at once.
