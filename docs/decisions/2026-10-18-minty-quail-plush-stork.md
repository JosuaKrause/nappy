# minty-quail — No hidden globals in the crowd, city, routes and world statics (hidden-statics) · 2026-11-02


minty-quail's `hidden-statics.md`, the statics under `src/crowd/`, `src/city/`, `src/routes/` and
`src/world/` (18 `static var`s). The item stays open for the rest.

**Built.**
- `SealPlanner._candidates` and `_escape_candidates` are gone: `candidates()` and
  `escape_candidates()` build their table on each call (12 and 4 small objects, twice per planned day: `plan_day` and the alley-mouth sealing each ask).
- `ReachabilityGrid._mask_components` is gone: `build()` makes its 16-entry table as a local, and
  `test_reachability_grid.gd` reads it through `_components_by_mask()`.
- Their entries left `tests/shared_state.gd` and `tools/layer_map.py` (the cache entry and the
  `SealPlanner` static exception for `day_planner.gd`), so `check_layers.py` lists one break fewer.

**Left as they are, and why** (the builder's judgement, open to overturn):
- Immutable constants are not hidden globals: the five `Mover.of(...)` filters
  (`CarStrategy._car_today`, `LaneStrategy._closed_today`, `WalkerStrategy._walker_today`,
  `_soft_sealed_today`, `_bodies_today`), `CityMap._WALKABLE` and `_CALM` (tables built from `Tile`'s
  constants).
- `Mover._shared` is a pure memo, not a constant: an intern table filled on the first `Mover.of()` of
  each flag set, every entry a pure function of its flags, so no caller can leave a different value;
  dropping it would allocate on hot paths.
- `StreetNetwork._segments`, `_by_key` and `_adjacency` memoize the fixed lattice
  (`Tuning.CITY_BLOCKS`, a `const`), so no caller can leave a different value; handing a network to
  their dozens of static callers is the item's remaining work.
- `PosterArt._torn` (15 composed textures) needs an owner that outlives the day's city, since the
  city is rebuilt daily and recomposing a whole atlas page per day would change load time; that owner
  is `main`, which this pass did not touch.
