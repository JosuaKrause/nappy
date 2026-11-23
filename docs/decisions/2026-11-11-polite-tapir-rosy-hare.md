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

## Verified

- `tools/test.sh probes/m181_resistance_targets.gd` on the base (26ec12450) and on this branch's
  head gives an identical table: all 120 rows (per seed and per day 9, 12 and 14: candidates, legal,
  open and reachable, and where the contact is put), ending "40 of 120 placements unreachable or
  nowhere", the same 40 on both, all of them day 14's station rows.
- `tools/test.sh resistance_reach_narrow resistance_placement_kinds events_scheduler route_rig
  routes_closures`: 11829 checks, 0 failures.
- `check_layers.py`, `check_field_reads.py`, `check_test_only_members.py`, `pycheck.sh` and
  `lint.sh` pass; `rg "target_candidates"` over `src`, `tests`, `tools`, `docs` and
  `.claude/skills`, bar the records, comes back empty.
